/*********************************************************
*Class        :  ABSLAMC_BulkCloseLeadConverterUtility
*Author       :  Asmita Mathur
*Created Date :  24/09/2024
*Last Modified:  24/09/2024
*Description  :  Class for bulk lead closing
*********************************************************/
@SuppressWarnings('PMD.ApexSOQLInjection')

public with sharing class ABSLAMC_BulkCloseLeadConverterUtility implements ASF_BulkCSVToRecordConverter{
    
    public ASF_BulkCaseProcessorUtility.ConvertionResult convertJSONRows(Map<Id, String> jsonRows){
        //Each row will be
        //{'Lead ID (System Identifier)':'00005150','Lead Status (Won/Lost)':'Won', 'Comments/Remarks':'Some comments'}

        ASF_BulkCaseProcessorUtility.ConvertionResult resultWrapper = new ASF_BulkCaseProcessorUtility.ConvertionResult();
        resultWrapper.resultJSONMapRows = new Map<Id, Map<String, String>>();
        resultWrapper.resultJSONRows = new Map<Id, String>();
        resultWrapper.resultRecords = new Map<Id, SObject>();
        Set<String> leadIds = new Set<String>();
        Map<Id, Map<String, String>> rows = new Map<Id, Map<String, String>>();
        for(Id lineItemId : jsonRows.keySet()){
            String eachJSON = jsonRows.get(lineItemId);
            System.debug('eachJSON'+eachJSON);
            Map<String, String> keyValueMap = (Map<String, String>)JSON.deserialize(eachJSON, Map<String, String>.class);
            if(String.isNotBlank(keyValueMap.get('Lead ID (System Identifier)'))){
                leadIds.add(keyValueMap.get('Lead ID (System Identifier)').trim());
            }
            rows.put(lineItemId, keyValueMap);
        }
        Map<String, Lead> leadMap = new Map<String,Lead>();
        for(Lead leadRec : [Select Id, Status, Lead_Number__c from Lead where Lead_Number__c IN :leadIds WITH SYSTEM_MODE]){
            leadMap.put(leadRec.Lead_Number__c, leadRec);
        }

        for(Id lineItemId : rows.keySet()){
            Map<String, String> keyValueMap = rows.get(lineItemId);
            String leadId = String.isNotBlank(keyValueMap.get('Lead ID (System Identifier)'))?keyValueMap.get('Lead ID (System Identifier)').trim():keyValueMap.get('Lead ID (System Identifier)');
            String status = String.isNotBlank(keyValueMap.get('Lead Status (Won/Lost)'))?keyValueMap.get('Lead Status (Won/Lost)').trim():keyValueMap.get('Lead Status (Won/Lost)');
            String comments = String.isNotBlank(keyValueMap.get('Comments/Remarks'))?keyValueMap.get('Comments/Remarks').trim():keyValueMap.get('Comments/Remarks');
            if(leadId == null || leadId.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Lead ID is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(!leadMap.containsKey(leadId)){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Invalid Lead Id');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(status == null || status.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Lead Status is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(status != 'Won' && status != 'Lost'){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Lead Status should be Won or Lost');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(leadMap.get(leadId).Status == 'Won' || leadMap.get(leadId).Status == 'Lost'){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Lead is already '+leadMap.get(leadId).Status);
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            Lead leadRec = leadMap.get(leadId);
            leadRec.Status = status;
            leadRec.Comments_Remarks__c = comments;
            resultWrapper.resultRecords.put(lineItemId, leadRec);
            resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
        }

        return resultWrapper;
    }
    
    public List<Map<String,String>> prepareDownloadTemplate(List<String> columnNames, String objectName, Id listViewId, List<String> selectedRecordIds){
        List<Map<String, String>> listOfRecordsAsMap = new List<Map<String, String>>();
        Map<String, String> mapOfFieldApiToColumnName = new Map<String,String>{
            'Lead_Number__c'=>'Lead ID (System Identifier)',
            'Status'=>'Lead Status (Won/Lost)',
            'Comments_Remarks__c'=>'Comments/Remarks'
        };
        Map<String, String> mapOfColumnNameToFieldApi = new Map<String,String>{
            'Lead ID (System Identifier)'=>'Lead_Number__c',
            'Lead Status (Won/Lost)'=>'Status',
            'Comments/Remarks'=>'Comments_Remarks__c'
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