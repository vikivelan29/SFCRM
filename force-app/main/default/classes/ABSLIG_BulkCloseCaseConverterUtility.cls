public with sharing class ABSLIG_BulkCloseCaseConverterUtility implements ASF_BulkCSVToRecordConverter{
    public ASF_BulkCaseProcessorUtility.ConvertionResult convertJSONRows(Map<Id, String> jsonRows){
        //Each row will be
        //{'Case number':'00005150', 'Stage':'Unresolved', 'Close Unresolved Reason':'Others', 'Close Unresolved Details':'Sample text'}

        ASF_BulkCaseProcessorUtility.ConvertionResult resultWrapper = new ASF_BulkCaseProcessorUtility.ConvertionResult();
        resultWrapper.resultJSONMapRows = new Map<Id, Map<String, String>>();
        resultWrapper.resultJSONRows = new Map<Id, String>();
        resultWrapper.resultRecords = new Map<Id, SObject>();

        Set<String> caseNumbers = new Set<String>();
        Map<Id, Map<String, String>> rows = new Map<Id, Map<String, String>>();
        for(Id lineItemId : jsonRows.keySet()){
            String eachJSON = jsonRows.get(lineItemId);
            System.debug('eachJSON'+eachJSON);
            Map<String, String> keyValueMap = (Map<String, String>)JSON.deserialize(eachJSON, Map<String, String>.class);
            if(String.isNotBlank(keyValueMap.get('Case number'))){
                caseNumbers.add(keyValueMap.get('Case number').trim());
            }
            rows.put(lineItemId, keyValueMap);
        }

        Map<String, Case> caseNumberToCaseMap = new Map<String,Case>();
        for(Case caseRec : [Select Id, CaseNumber, IsClosed, Stage__c, RecordTypeId, CCC_External_Id__c, AccountId from Case where CaseNumber IN :caseNumbers]){
            caseNumberToCaseMap.put(caseRec.CaseNumber, caseRec);
        }

        for(Id lineItemId : rows.keySet()){
            Map<String, String> keyValueMap = rows.get(lineItemId);
            String caseNumber = String.isNotBlank(keyValueMap.get('Case number'))?keyValueMap.get('Case number').trim():keyValueMap.get('Case number');
            String unresolvedDetails = String.isNotBlank(keyValueMap.get('Close Unresolved Details'))?keyValueMap.get('Close Unresolved Details').trim():keyValueMap.get('Close Unresolved Details');
            String unresolvedReason = String.isNotBlank(keyValueMap.get('Close Unresolved Reason'))?keyValueMap.get('Close Unresolved Reason').trim():keyValueMap.get('Close Unresolved Reason');
            String stage = String.isNotBlank(keyValueMap.get('Stage'))?keyValueMap.get('Stage').trim():keyValueMap.get('Stage');
            if(caseNumber == null || caseNumber.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Case number is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(stage == null || stage.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Stage is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(stage.toLowerCase() == 'unresolved' && (unresolvedReason == null || unresolvedReason.trim() == '')){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Close Unresolved Reason is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(!caseNumberToCaseMap.containsKey(caseNumber)){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Invalid Case Number');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(caseNumberToCaseMap.get(caseNumber).IsClosed == true){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Case is already '+caseNumberToCaseMap.get(caseNumber).Stage__c);
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(caseNumberToCaseMap.get(caseNumber).RecordTypeId == ASF_Constants.RT_INTERACTION 
            && (caseNumberToCaseMap.get(caseNumber).AccountId == null || caseNumberToCaseMap.get(caseNumber).CCC_External_Id__c == null)){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Case does not have Account tagged or Issue Type Code tagged');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            Case caseRec = caseNumberToCaseMap.get(caseNumber);
            if(stage == 'Resolved'){
                caseRec.Stage__c = stage;
                caseRec.Status = stage;
                caseRec.Pending_Clarification__c = false;
                caseRec.moved_back__c = false;
                caseRec.Is_Manual_Moved__c = true;
            }else if(stage == 'Unresolved'){
                caseRec.Stage__c = stage;
                caseRec.Status = stage;
                caseRec.Reject_Case__c = true;
                caseRec.Rejected_Reason__c = unresolvedDetails;
                caseRec.Rejection_Reason__c = unresolvedReason;
            }else{ 
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Invalid Stage');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            //Any other BU specific checks - add here
            resultWrapper.resultRecords.put(lineItemId, caseRec);
            resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
        }

        return resultWrapper;
    }

    public List<Map<String,String>> prepareDownloadTemplate(List<String> columnNames, String objectName, Id listViewId, List<String> selectedRecordIds){
        List<Map<String, String>> listOfRecordsAsMap = new List<Map<String, String>>();
        Map<String, String> mapOfFieldApiToColumnName = new Map<String,String>{
            'CaseNumber'=>'Case number',
            'Stage__c'=>'Stage',
            'Rejection_Reason__c'=>'Close Unresolved Reason',
            'Rejected_Reason__c'=>'Close Unresolved Details'
        };
        Map<String, String> mapOfColumnNameToFieldApi = new Map<String,String>{
            'Case number'=>'CaseNumber',
            'Stage'=>'Stage__c',
            'Close Unresolved Reason'=>'Rejection_Reason__c',
            'Close Unresolved Details'=>'Rejected_Reason__c'
        };
        List<String> fieldNames = new List<String>();
        for(String columnName : columnNames){
            if(mapOfColumnNameToFieldApi.containsKey(columnName)){
                fieldNames.add(mapOfColumnNameToFieldApi.get(columnName));
            }
        }
        System.debug('fieldNames'+fieldNames);
        String strFinalQuery;
        if(selectedRecordIds != null && !selectedRecordIds.isEmpty()){
            String strFields = String.join(fieldNames, ',');
            String strWhereClause = ' WHERE ID IN:selectedRecordIds';
            strFinalQuery = 'Select '+ strFields + ' FROM ' + objectName + strWhereClause;
        }
        else if(listViewId != null){
            String strFields = String.join(fieldNames, ',');
            String listViewQuery = ASF_BulkCsvDownloadHelper.getListViewSOQL(objectName, listViewId);
            System.debug('listViewQuery'+listViewQuery);
            String strWhere = '';
            if(listViewQuery.contains('WHERE')){
                strWhere = ' WHERE '+listViewQuery.substringAfter('WHERE');
            }
            
            String strScope = '';
            if(listViewQuery.contains('USING SCOPE')){
                strScope = ' USING SCOPE ' + listViewQuery.substringBetween('SCOPE ',' ') + ' ';
            }
            strFinalQuery = 'Select '+ strFields + ' FROM ' + objectName + strScope + strWhere ;     
        }

        if(String.isNotBlank(strFinalQuery)){
            strFinalQuery = strFinalQuery + ' LIMIT 50000';
            System.debug('strFinalQuery'+strFinalQuery);
            List<SObject> recordsList = Database.query(strFinalQuery);
            for(SObject obj : recordsList){
                Map<String,String> fieldMap = new Map<String,String>();
                for(String fieldName : mapOfFieldApiToColumnName.keySet()){
                    String fieldValue = (String)obj.get(fieldName);
                    fieldValue = fieldValue==null?' ':fieldValue;
                    fieldMap.put(mapOfFieldApiToColumnName.get(fieldName), fieldValue);
                }
                listOfRecordsAsMap.add(fieldMap);
            }
        }

        return listOfRecordsAsMap;
    }
    public List<Map<String,String>> prepareCtstData(List<String> columnNames, String businessUnit){
        return new List<Map<String,String>>();
    }
}