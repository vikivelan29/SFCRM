/*********************************************************
*Class        :  ABSLAMC_BulkCloseCaseConverterUtility
*Author       :  Asmita Mathur
*Created Date :  24/09/2024
*Last Modified:  24/09/2024
*Description  :  Class for bulk case closing
*********************************************************/
@SuppressWarnings('PMD.ApexSOQLInjection')

public with sharing class ABSLAMC_BulkCloseCaseConverterUtility implements ASF_BulkCSVToRecordConverter{
    public ASF_BulkCaseProcessorUtility.ConvertionResult convertJSONRows(Map<Id, String> jsonRows){
        //Each row will be
        //{'Case Number':'00005150','Closure Stage(Resolved/ Unresolved)':'Resolved', 'Resolution Remarks(For Resolved Stage)':'some comments', 'Close Unresolved Detail(For Unresolved Stage)':'some details for unresolved case', 
        //'Close Unresolved Reason(For Unresolved Stage)':'reason for unresolved case', 'Send Auto Communication?': 'Yes'}
        ASF_BulkCaseProcessorUtility.ConvertionResult resultWrapper = new ASF_BulkCaseProcessorUtility.ConvertionResult();
        resultWrapper.resultJSONMapRows = new Map<Id, Map<String, String>>();
        resultWrapper.resultJSONRows = new Map<Id, String>();
        resultWrapper.resultRecords = new Map<Id, SObject>();

        Set<String> caseNumbers = new Set<String>();
        Set<String> rejectionReasonList = new Set<String>();
        Map<Id, Map<String, String>> rows = new Map<Id, Map<String, String>>();
        for(Id lineItemId : jsonRows.keySet()){
            String eachJSON = jsonRows.get(lineItemId);
            Map<String, String> keyValueMap = (Map<String, String>)JSON.deserialize(eachJSON, Map<String, String>.class);
            
            if(String.isNotBlank(keyValueMap.get('Case Number'))){
                caseNumbers.add(keyValueMap.get('Case Number').trim());
            }
            rows.put(lineItemId, keyValueMap);
        }

        Map<String, Case> caseNumberToCaseMap = new Map<String,Case>();
        for(Case caseRec : [Select Id, CaseNumber, IsClosed, Stage__c, CCC_External_Id__c, RecordTypeId, AccountId from Case where CaseNumber IN :caseNumbers]){
            caseNumberToCaseMap.put(caseRec.CaseNumber, caseRec);
            
        }
        for(LOB_Rejection_Reason__mdt  mdtRec : [SELECT DeveloperName, LOB__c,Reason__c FROM LOB_Rejection_Reason__mdt WHERE LOB__c  = 'ABSLAMC']){
            rejectionReasonList.add(mdtRec.Reason__c);
        }
        for(Id lineItemId : rows.keySet()){
            Map<String, String> keyValueMap = rows.get(lineItemId);
            String caseNumber = String.isNotBlank(keyValueMap.get('Case Number'))?keyValueMap.get('Case Number').trim(): '';
            String caseStage = String.isNotBlank(keyValueMap.get('Closure Stage(Resolved/ Unresolved)')) ?  keyValueMap.get('Closure Stage(Resolved/ Unresolved)').trim(): '';
            String resolutionComments = String.isNotBlank(keyValueMap.get('Resolution Remarks(For Resolved Stage)'))?keyValueMap.get('Resolution Remarks(For Resolved Stage)').trim(): '';
            String unresolvedDetails = String.isNotBlank(keyValueMap.get('Close Unresolved Details(For Unresolved Stage)'))?keyValueMap.get('Close Unresolved Details(For Unresolved Stage)').trim():'';
            String unresolvedReason = String.isNotBlank(keyValueMap.get('Close Unresolved Reason(For Unresolved Stage)'))?keyValueMap.get('Close Unresolved Reason(For Unresolved Stage)').trim():'';
            String autoCommunication = String.isNotBlank(keyValueMap.get('Send Auto Communication?'))?keyValueMap.get('Send Auto Communication?').trim():'';

            if(caseNumber == null || caseNumber.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Case number is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(caseStage == 'Resolved' && (resolutionComments == null || resolutionComments.trim() == '')) {
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Resolution Comments is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;  
            }
            
            if(caseStage == 'Unresolved'){  
               if(unresolvedDetails == null || unresolvedDetails.trim() == '') {
                   keyValueMap.put('Result', 'FAILURE');
                   keyValueMap.put('Message', 'Close Unresolved Details(For Unresolved Stage) is required');
                   resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                   resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                   continue; 
               }
               if(unresolvedReason == null || unresolvedReason.trim() == '') {
                   keyValueMap.put('Result', 'FAILURE');
                   keyValueMap.put('Message', 'Close Unresolved Reason(For Unresolved Stage) is required');
                   resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                   resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                   continue; 
               }
               if(!rejectionReasonList.contains(unresolvedReason)) {
                   keyValueMap.put('Result', 'FAILURE');
                   keyValueMap.put('Message', 'Invalid Close Unresolved Reason(For Unresolved Stage)');
                   resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                   resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                   continue; 
               } 
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
            if(autoCommunication == null || autoCommunication.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Send Auto Communication is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(String.isNotBlank(autoCommunication)){
                if(!autoCommunication.equalsIgnoreCase('Yes') && !autoCommunication.equalsIgnoreCase('No')){
                    keyValueMap.put('Result', 'FAILURE');
                    keyValueMap.put('Message', 'Invalid Block Customer Communication value provided - Accepted value - Yes/No');
                    resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                    resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                    continue;
                }
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
            caseRec.Stage__c = caseStage;
            caseRec.Status = caseStage;
            caseRec.No_Auto_Communication__c  = (autoCommunication.equalsIgnoreCase('Yes')) ? null : 'Email;SMS;WhatsApp';
            if(caseStage == 'Resolved'){
                caseRec.Pending_Clarification__c = false;
                caseRec.moved_back__c = false;
                caseRec.Is_Manual_Moved__c = true;
                caseRec.Resolution_Comments__c = resolutionComments;
            }else if(caseStage == 'Unresolved'){
                caseRec.Reject_Case__c = true;
                caseRec.Rejected_Reason__c = unresolvedDetails;
                caseRec.Rejection_Reason__c = unresolvedReason;
            }else{ 
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Invalid Closure Stage provided - Accepted value - Resolved/Unresolved');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            resultWrapper.resultRecords.put(lineItemId, caseRec);
            resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
        }

        return resultWrapper;
    }

    public List<Map<String,String>> prepareDownloadTemplate(List<String> columnNames, String objectName, Id listViewId, List<String> selectedRecordIds){
        List<Map<String, String>> listOfRecordsAsMap = new List<Map<String, String>>();
        Map<String, String> mapOfFieldApiToColumnName = new Map<String,String>{
            'CaseNumber'=>'Case Number',
            'Stage__c'=> 'Closure Stage(Resolved/ Unresolved)',
            'Resolution_Comments__c'=>'Resolution Remarks(For Resolved Stage)',
            'Rejected_Reason__c'=>'Close Unresolved Details(For Unresolved Stage)',
            'Rejection_Reason__c'=> 'Close Unresolved Reason(For Unresolved Stage)',
            'No_Auto_Communication__c'=> 'Send Auto Communication?'  
                
        };
        Map<String, String> mapOfColumnNameToFieldApi = new Map<String,String>{
            'Case Number'=>'CaseNumber',
            'Closure Stage(Resolved/ Unresolved)' => 'Stage__c',
            'Resolution Remarks(For Resolved Stage)'=>'Resolution_Comments__c',
            'Close Unresolved Details(For Unresolved Stage)' => 'Rejected_Reason__c',
            'Close Unresolved Reason(For Unresolved Stage)' => 'Rejection_Reason__c',
            'Send Auto Communication?'=>'No_Auto_Communication__c'
        };
        List<String> fieldNames = new List<String>();
        for(String columnName : columnNames){
            if(mapOfColumnNameToFieldApi.containsKey(columnName)){
                fieldNames.add(mapOfColumnNameToFieldApi.get(columnName));
            }
        }

        String strFinalQuery;
        if(selectedRecordIds != null && !selectedRecordIds.isEmpty()){
            String strFields = String.join(fieldNames, ',');
            String strWhereClause = ' WHERE ID IN:selectedRecordIds ';
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
                    if(fieldName == 'No_Auto_Communication__c'){
                       fieldValue = fieldValue == null ? 'Yes' : 'No';
                    }
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