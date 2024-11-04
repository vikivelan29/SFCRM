@SuppressWarnings('PMD.ApexSOQLInjection')
public with sharing class ABHI_BulkAssignCaseConverterUtility implements ASF_BulkCSVToRecordConverter {
    /**
     * @description This method is called from the ASF_BulkCaseProcessorUtility while performing bulk close via csv upload
     * @param jsonRows
     * @param allOutputs - outputWrapper with updated values
     */
  public ASF_BulkCaseProcessorUtility.ConvertionResult convertJSONRows(Map<Id, String> jsonRows){
        //Each row will be
        //{'Case number':'00005150','New Owner':'queue name', 'Internal comments':'Comments'}
        ASF_BulkCaseProcessorUtility.ConvertionResult resultWrapper = new ASF_BulkCaseProcessorUtility.ConvertionResult();
        resultWrapper.resultJSONMapRows = new Map<Id, Map<String, String>>();
        resultWrapper.resultJSONRows = new Map<Id, String>();
        resultWrapper.resultRecords = new Map<Id, SObject>();

        Set<String> caseNumbers = new Set<String>();
        Set<String> ownerNames = new Set<String>();
        Map<Id, Map<String, String>> rows = new Map<Id, Map<String, String>>();
        for(Id lineItemId : jsonRows.keySet()){
            String eachJSON = jsonRows.get(lineItemId);
            System.debug('eachJSON'+eachJSON);
            Map<String, String> keyValueMap = (Map<String, String>)JSON.deserialize(eachJSON, Map<String, String>.class);
            if(String.isNotBlank(keyValueMap.get('Case number'))){
                caseNumbers.add(keyValueMap.get('Case number').trim());
            }
            if(String.isNotBlank(keyValueMap.get('New Owner'))){
                ownerNames.add(keyValueMap.get('New Owner').trim());
            }
            rows.put(lineItemId, keyValueMap);
        }

        Map<String, Case> caseNumberToCaseMap = new Map<String, Case>();
        Map<String, Id> queueUserNameIdMap = new Map<String, Id>();
        for(Case caseRec : [Select Id, CaseNumber, IsClosed, Stage__c, RecordTypeId, CCC_External_Id__c, AccountId from Case where CaseNumber IN :caseNumbers WITH SYSTEM_MODE]){
            caseNumberToCaseMap.put(caseRec.CaseNumber, caseRec);
        }
        for(Group queueRec : [select Id, name, DeveloperName from group where type='Queue' and DeveloperName LIKE 'ABHI_%' and name IN: ownerNames]){
            queueUserNameIdMap.put(queueRec.name, queueRec.Id);
        }
        for(User userRec : [select Id, FederationIdentifier from User where FederationIdentifier IN: ownerNames]){
            queueUserNameIdMap.put(userRec.FederationIdentifier, userRec.Id);
        }
        
        for(Id lineItemId : rows.keySet()){
            Map<String, String> keyValueMap = rows.get(lineItemId);
            String caseNumber = String.isNotBlank(keyValueMap.get('Case number'))?keyValueMap.get('Case number').trim():keyValueMap.get('Case number');
            String newOwner = String.isNotBlank(keyValueMap.get('New Owner'))?keyValueMap.get('New Owner').trim():keyValueMap.get('New Owner');
            String comments = String.isNotBlank(keyValueMap.get('Internal comments'))?keyValueMap.get('Internal comments').trim():keyValueMap.get('Internal comments');
            
            if(caseNumber == null || caseNumber.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Case number is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(newOwner == null || newOwner.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'New Owner is required');
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
            if(!queueUserNameIdMap.containsKey(newOwner)){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Invalid Owner Name');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            Case caseRec = caseNumberToCaseMap.get(caseNumber);
            
            caseRec.ownerId = queueUserNameIdMap.get(newOwner);
            caseRec.comments = comments;
         
            //Any other BU specific checks - add here
            resultWrapper.resultRecords.put(lineItemId, caseRec);
            resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
        }

        return resultWrapper;
    }
  /**
     * @description This method is called from the ASF_BulkCsvController while performing bulk download of records
     * for close operation
     * @param jsonRows
     * @param allOutputs - outputMap with key as field and value as the record value
     */
    public List<Map<String,String>> prepareDownloadTemplate(List<String> columnNames, String objectName, Id listViewId, List<String> selectedRecordIds){
        List<Map<String, String>> listOfRecordsAsMap = new List<Map<String, String>>();
        Map<String, String> mapOfFieldApiToColumnName = new Map<String,String>{
            'CaseNumber'=>'Case number',
            'Owner.Name'=>'New Owner',
            'Comments'=>'Internal comments'
        };
        Map<String, String> mapOfColumnNameToFieldApi = new Map<String,String>{
            'Case number'=>'CaseNumber',
            'New Owner'=>'Owner.Name',
            'Internal comments'=>'Comments'
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
            strFinalQuery = 'Select '+ String.escapeSingleQuotes(strFields) + ' FROM ' + String.escapeSingleQuotes(objectName) + String.escapeSingleQuotes(strWhereClause);
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
            strFinalQuery = 'Select '+ String.escapeSingleQuotes(strFields) + ' FROM ' + String.escapeSingleQuotes(objectName) + String.escapeSingleQuotes(strScope) + strWhere;     
        }

        if(String.isNotBlank(strFinalQuery)){
            strFinalQuery = strFinalQuery + ' LIMIT 50000';
            System.debug('strFinalQuery'+strFinalQuery);
            List<SObject> recordsList = Database.query(strFinalQuery);
            for(SObject obj : recordsList){
                Map<String,String> fieldMap = new Map<String,String>();
                String fieldValue = '';
                for(String fieldName : mapOfFieldApiToColumnName.keySet()){
                    if(fieldName.contains('.') && obj.getSobject((fieldName.split('\\.'))[0]) != null){
                        fieldValue = (String)obj.getSobject(fieldName.split('\\.')[0]).get(fieldName.split('\\.')[1]);
                    }else if(!fieldName.contains('.')){
                        fieldValue = (String)obj.get(fieldName);
                    }
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