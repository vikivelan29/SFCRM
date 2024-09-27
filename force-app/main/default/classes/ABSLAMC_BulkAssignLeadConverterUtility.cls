/*********************************************************
*Class        :  ABSLAMC_BulkAssignLeadConverterUtility
*Author       :  Asmita Mathur
*Created Date :  24/09/2024
*Last Modified:  24/09/2024
*Description  :  Class for bulk lead assignment
*********************************************************/

public with sharing class ABSLAMC_BulkAssignLeadConverterUtility implements ASF_BulkCSVToRecordConverter {
  
    public ASF_BulkCaseProcessorUtility.ConvertionResult convertJSONRows(Map<Id, String> jsonRows){
        //Each row will be
        //{'Lead ID (System Identifier)':'L-1234','Assigned Team':'queue name', 'Assigned User - AD ID':'owner federation Id'}
        ASF_BulkCaseProcessorUtility.ConvertionResult resultWrapper = new ASF_BulkCaseProcessorUtility.ConvertionResult();
        resultWrapper.resultJSONMapRows = new Map<Id, Map<String, String>>();
        resultWrapper.resultJSONRows = new Map<Id, String>();
        resultWrapper.resultRecords = new Map<Id, SObject>();
        Set<String> leadNumbers = new Set<String>();
        Set<String> federationIds = new Set<String>();
        Map<String, Lead> leadNumberToLeadMap = new Map<String, Lead>();
        Map<String, Id> userFedIdToUserMap = new Map<String,Id>();
        Map<String, Id> queueUserNameIdMap = new Map<String, Id>();
        Set<String> assignedTeamNames = new Set<String>();
        Map<Id, Map<String, String>> rows = new Map<Id, Map<String, String>>();
        for(Id lineItemId : jsonRows.keySet()){
            String eachJSON = jsonRows.get(lineItemId);
            System.debug('eachJSON'+eachJSON);
            Map<String, String> keyValueMap = (Map<String, String>)JSON.deserialize(eachJSON, Map<String, String>.class);
            if(String.isNotBlank(keyValueMap.get('Lead ID (System Identifier)'))){
                leadNumbers.add(keyValueMap.get('Lead ID (System Identifier)').trim());
            }
            if(String.isNotBlank(keyValueMap.get('Assigned User - AD ID'))){
                federationIds.add(keyValueMap.get('Assigned User - AD ID').trim());
            }
            if(String.isNotBlank(keyValueMap.get('Assigned Team'))){
                assignedTeamNames.add(keyValueMap.get('Assigned Team').trim());
            }
            rows.put(lineItemId, keyValueMap);
        }
        for(Lead leadRec : [Select Id, Lead_Number__c from Lead where Lead_Number__c IN :leadNumbers WITH SYSTEM_MODE]){
            leadNumberToLeadMap.put(leadRec.Lead_Number__c, leadRec);
        }
        for(User usr :[Select Id, FederationIdentifier from User where FederationIdentifier IN :federationIds]){
            userFedIdToUserMap.put(usr.FederationIdentifier, usr.Id);
        }
        for(Group queueRec : [select Id, name, DeveloperName from group where type='Queue' and DeveloperName LIKE 'ABSLAMC_%' and name IN: assignedTeamNames]){
            queueUserNameIdMap.put(queueRec.name, queueRec.Id);
        }
        
        for(Id lineItemId : rows.keySet()){
            Map<String, String> keyValueMap = rows.get(lineItemId);
            String leadNumber = String.isNotBlank(keyValueMap.get('Lead ID (System Identifier)'))?keyValueMap.get('Lead ID (System Identifier)').trim():'';
            String assignedTeam = String.isNotBlank(keyValueMap.get('Assigned Team'))?keyValueMap.get('Assigned Team').trim():'';
            String assignedUser = String.isNotBlank(keyValueMap.get('Assigned User - AD ID'))?keyValueMap.get('Assigned User - AD ID').trim(): '';            
            if(leadNumber == null || leadNumber.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Lead ID is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(!leadNumberToLeadMap.containsKey(leadNumber)){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Invalid Lead Id');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if((assignedTeam == null || assignedTeam.trim() == '') && (assignedUser == null || assignedUser.trim() == '')){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Assigned Team OR Assigned User - AD ID is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(!(userFedIdToUserMap.containsKey(assignedUser)|| queueUserNameIdMap.containsKey(assignedTeam))){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Invalid Assigned User-AD ID/ Assigned Team');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
           
            Lead leadRec = leadNumberToLeadMap.get(leadNumber);
            String ownerId = String.isNotBlank(userFedIdToUserMap.get(assignedUser)) ? userFedIdToUserMap.get(assignedUser) : queueUserNameIdMap.get(assignedTeam);
            leadRec.OwnerId = ownerId;
            resultWrapper.resultRecords.put(lineItemId, leadRec);
            resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
        }

        return resultWrapper;
        
    }
    public List<Map<String,String>> prepareDownloadTemplate(List<String> columnNames, String objectName, Id listViewId, List<String> selectedRecordIds){
        List<Map<String, String>> listOfRecordsAsMap = new List<Map<String, String>>();
        Map<String, String> mapOfFieldApiToColumnName = new Map<String,String>{
            'Lead_Number__c'=>'Lead ID (System Identifier)',
            'Assigned_Team__c'=>'Assigned Team',
            'OwnerId'=>'Assigned User - AD ID'
        };
        Map<String, String> mapOfColumnNameToFieldApi = new Map<String,String>{
            'Lead ID (System Identifier)'=>'Lead_Number__c',
            'Assigned Team'=>'Assigned_Team__c',
            'Assigned User - AD ID'=>'OwnerId'
        };
        List<String> fieldNames = new List<String>();
        for(String columnName : columnNames){
            if(mapOfColumnNameToFieldApi.containsKey(columnName)){
               fieldNames.add(mapOfColumnNameToFieldApi.get(columnName));
            }
        }

        String strFinalQuery;
        String strFields = String.join(fieldNames, ',');
        if(selectedRecordIds != null && !selectedRecordIds.isEmpty()){
            String strWhereClause = ' WHERE ID IN:selectedRecordIds';
            strFinalQuery = 'Select '+ strFields + ' FROM ' + objectName + strWhereClause;
        }
        else if(listViewId != null){
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
        system.debug('strFinalQuery'+strFinalQuery);
        if(String.isNotBlank(strFinalQuery)){
            strFinalQuery = strFinalQuery + ' LIMIT 50000';
            List<SObject> recordsList = Database.query(strFinalQuery);
            Set<Id> listOfOwner = new Set<Id>();
            for(SObject obj : recordsList){
                Map<String,String> fieldMap = new Map<String,String>();
                for(String fieldName : mapOfFieldApiToColumnName.keySet()){
                    String  fieldValue = (String)obj.get(fieldName);
                    fieldValue = fieldValue==null?' ':fieldValue;
                    fieldMap.put(mapOfFieldApiToColumnName.get(fieldName), fieldValue);
                    if(fieldName == 'OwnerId' && String.isNotBlank(fieldValue)){
                       listOfOwner.add(fieldValue);
                    }
                }
                listOfRecordsAsMap.add(fieldMap);
                
            }
            Map<Id, String> mapOfOwnerFedIden = new Map<Id, String>();
            for(User usr : [Select Id, FederationIdentifier from User where Id IN :listOfOwner]){
                mapOfOwnerFedIden.put(usr.Id, usr.FederationIdentifier);
             }
            
            for (Integer i = 0; i < listOfRecordsAsMap.size(); i++){
               Id usrId = listOfRecordsAsMap[i].get('Assigned User - AD ID');
               String federationId = String.isNotBlank(mapOfOwnerFedIden.get(usrId)) ? mapOfOwnerFedIden.get(usrId) : '';
               listOfRecordsAsMap[i].put('Assigned User - AD ID', federationId);
            }           
        }
        return listOfRecordsAsMap;
            
    }
    public List<Map<String,String>> prepareCtstData(List<String> columnNames, String businessUnit){
        return new List<Map<String,String>>();
    }
}