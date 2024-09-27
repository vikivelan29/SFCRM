/*********************************************************
*Class        :  ABSLAMC_BulkAssignCaseConverterUtility
*Author       :  Asmita Mathur
*Created Date :  24/09/2024
*Last Modified:  24/09/2024
*Description  :  Class for bulk case assignment
*********************************************************/

public class ABSLAMC_BulkAssignCaseConverterUtility implements ASF_BulkCSVToRecordConverter {
    
    public ASF_BulkCaseProcessorUtility.ConvertionResult convertJSONRows(Map<Id, String> jsonRows){
        //Each row will be
        //{'Case Number':'00005150','Owner Team':'queue name', 'Owner AD ID':'Owner Federation Id'}
        ASF_BulkCaseProcessorUtility.ConvertionResult resultWrapper = new ASF_BulkCaseProcessorUtility.ConvertionResult();
        resultWrapper.resultJSONMapRows = new Map<Id, Map<String, String>>();
        resultWrapper.resultJSONRows = new Map<Id, String>();
        resultWrapper.resultRecords = new Map<Id, SObject>();

        Set<String> caseNumbers = new Set<String>();
        Set<String> ownerTeamNames = new Set<String>();
        Set<String> ownerADIds = new Set<String>();
        Map<Id, Map<String, String>> rows = new Map<Id, Map<String, String>>();
        for(Id lineItemId : jsonRows.keySet()){
            String eachJSON = jsonRows.get(lineItemId);
            System.debug('eachJSON'+eachJSON);
            Map<String, String> keyValueMap = (Map<String, String>)JSON.deserialize(eachJSON, Map<String, String>.class);
            if(String.isNotBlank(keyValueMap.get('Case Number'))){
                caseNumbers.add(keyValueMap.get('Case Number').trim());
            }
            if(String.isNotBlank(keyValueMap.get('Owner Team'))){
                ownerTeamNames.add(keyValueMap.get('Owner Team').trim());
            }
            if(String.isNotBlank(keyValueMap.get('Owner AD ID'))){
                ownerADIds.add(keyValueMap.get('Owner AD ID').trim());
            }
            rows.put(lineItemId, keyValueMap);
        }

        Map<String, Case> caseNumberToCaseMap = new Map<String, Case>();
        Map<String, Id> queueUserNameIdMap = new Map<String, Id>();
        Map<String, Id> userAdIdMap = new Map<String, Id>();
        for(Case caseRec : [Select Id, CaseNumber from Case where CaseNumber IN :caseNumbers WITH SYSTEM_MODE]){
            caseNumberToCaseMap.put(caseRec.CaseNumber, caseRec);
        }
        for(Group queueRec : [select Id, name, DeveloperName from group where type='Queue' and DeveloperName LIKE 'ABSLAMC_%' and name IN: ownerTeamNames]){
            queueUserNameIdMap.put(queueRec.name, queueRec.Id);
        }
        for(User userRec : [select Id, FederationIdentifier from User where FederationIdentifier IN: ownerADIds]){
            userAdIdMap.put(userRec.FederationIdentifier, userRec.Id);
        }
        for(Id lineItemId : rows.keySet()){
            Map<String, String> keyValueMap = rows.get(lineItemId);
            String caseNumber = String.isNotBlank(keyValueMap.get('Case Number'))?keyValueMap.get('Case Number').trim():keyValueMap.get('Case Number');
            String ownerTeam = String.isNotBlank(keyValueMap.get('Owner Team'))?keyValueMap.get('Owner Team').trim():keyValueMap.get('Owner Team');
            String ownerAdId = String.isNotBlank(keyValueMap.get('Owner AD ID'))?keyValueMap.get('Owner AD ID').trim():keyValueMap.get('Owner AD ID');
            
            if(caseNumber == null || caseNumber.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Case number is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if((ownerTeam == null || ownerTeam.trim() == '') && (ownerAdId == null || ownerAdId.trim() == '')){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Owner Team OR Owner AD ID is required');
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
            if(!(queueUserNameIdMap.containsKey(ownerTeam) || userAdIdMap.containsKey(ownerAdId))){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Invalid Owner Team/Owner AD ID');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            String ownerId = String.isNotBlank(userAdIdMap.get(ownerAdId)) ? userAdIdMap.get(ownerAdId) : queueUserNameIdMap.get(ownerTeam);
            Case caseRec = caseNumberToCaseMap.get(caseNumber);
            caseRec.OwnerId = ownerId;
            resultWrapper.resultRecords.put(lineItemId, caseRec);
            resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
        }

        return resultWrapper;
    }
    
    public List<Map<String,String>> prepareDownloadTemplate(List<String> columnNames, String objectName, Id listViewId, List<String> selectedRecordIds){
        List<Map<String, String>> listOfRecordsAsMap = new List<Map<String, String>>();
        Map<String, String> mapOfFieldApiToColumnName = new Map<String,String>{
            'CaseNumber'=>'Case Number',
            'OwnerTeam__c'=>'Owner Team',
            'OwnerId'=>'Owner AD ID'
        };
        Map<String, String> mapOfColumnNameToFieldApi = new Map<String,String>{
            'Case Number'=>'CaseNumber',
            'Owner Team'=>'OwnerTeam__c',
            'Owner AD ID'=>'OwnerId'
        };
        List<String> fieldNames = new List<String>();
        for(String columnName : columnNames){
            if(mapOfColumnNameToFieldApi.containsKey(columnName)){
                fieldNames.add(mapOfColumnNameToFieldApi.get(columnName));
            }
        }
        System.debug('fieldNames'+fieldNames);
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

        if(String.isNotBlank(strFinalQuery)){
            strFinalQuery = strFinalQuery + ' LIMIT 50000';
            System.debug('strFinalQuery'+strFinalQuery);
            List<SObject> recordsList = Database.query(strFinalQuery);
            List<Id> listOfOwner = new List<Id>();
            for(SObject obj : recordsList){
                Map<String,String> fieldMap = new Map<String,String>();
                for(String fieldName : mapOfFieldApiToColumnName.keySet()){
                    String fieldValue = (String)obj.get(fieldName);
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
               Id usrId = listOfRecordsAsMap[i].get('Owner AD ID');
               String federationId = String.isNotBlank(mapOfOwnerFedIden.get(usrId)) ? mapOfOwnerFedIden.get(usrId) : '';
               listOfRecordsAsMap[i].put('Owner AD ID', federationId);
            } 
        }
        system.debug('listOfRecordsAsMap'+listOfRecordsAsMap);
        return listOfRecordsAsMap;
    }
    
    public List<Map<String,String>> prepareCtstData(List<String> columnNames, String businessUnit){
        return new List<Map<String,String>>();
    }

}