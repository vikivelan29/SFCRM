public with sharing class ABSLIG_BulkCreateCaseConverterUtility implements ASF_BulkCSVToRecordConverter{
	public ASF_BulkCaseProcessorUtility.ConvertionResult convertJSONRows(Map<Id, String> jsonRows){
        //Each row will be
        //{'Client Code':'5672118503', 'Asset':'LAN1234', 'Issue Code':'ABFL1234', 'Description':'DescriptionXYZ', 'Subject':'Case Subject'}

        ASF_BulkCaseProcessorUtility.ConvertionResult resultWrapper = new ASF_BulkCaseProcessorUtility.ConvertionResult();
        resultWrapper.resultJSONMapRows = new Map<Id, Map<String, String>>();
        resultWrapper.resultJSONRows = new Map<Id, String>();
        resultWrapper.resultRecords = new Map<Id, SObject>();

        Set<String> lans = new Set<String>();
        Set<String> cccExtIds = new Set<String>();
        Set<String> clientCodes = new Set<String>();
        Map<Id, Map<String, String>> rows = new Map<Id, Map<String, String>>();
        for(Id lineItemId : jsonRows.keySet()){
            String eachJSON = jsonRows.get(lineItemId);
            Map<String, String> keyValueMap = (Map<String, String>)JSON.deserialize(eachJSON, Map<String, String>.class);
            if(String.isNotBlank(keyValueMap.get('Client Code'))){
                clientCodes.add(keyValueMap.get('Client Code').trim());
            }
            if(String.isNotBlank(keyValueMap.get('Asset'))){
                lans.add(keyValueMap.get('Asset').trim());
            }
            if(String.isNotBlank(keyValueMap.get('Issue Code'))){
                cccExtIds.add(keyValueMap.get('Issue Code').trim());
            }
            rows.put(lineItemId, keyValueMap);
        }

        Map<String, Id> lanToAccountIdMap = new Map<String,Id>();
        Map<String, Id> lanToAssetIdMap = new Map<String,Id>();
        Map<String, Id> clientCodeToAccountIdMap = new Map<String,Id>();
        for(Asset assetRec : [Select Id, Policy_No__c, AccountId from Asset where Policy_No__c IN :lans and Business_Unit__c =: ASF_Constants.ABSLIG_BU]){
            lanToAccountIdMap.put(assetRec.Policy_No__c, assetRec.AccountId);
            lanToAssetIdMap.put(assetRec.Policy_No__c, assetRec.Id);
        }
        for(Account accRec : [SELECT Id, Client_Code__c from Account where Client_Code__c IN: clientCodes]){
            clientCodeToAccountIdMap.put(accRec.Client_Code__c, accRec.Id);
        }

        Set<String> extIdFoundSet = new Set<String>();
        for(ASF_Case_Category_Config__c config : [SELECT Id, CCC_External_Id__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c IN :cccExtIds]){
            extIdFoundSet.add(config.CCC_External_Id__c);
        }

        for(Id lineItemId : rows.keySet()){
            Map<String, String> keyValueMap = rows.get(lineItemId);
            String issueTypeCode = keyValueMap.get('Issue Code').trim();
            String lan = keyValueMap.get('Asset').trim();
            String clientCode = keyValueMap.get('Client Code').trim();
            String subject = String.isNotBlank(keyValueMap.get('Subject'))?keyValueMap.get('Subject').trim():keyValueMap.get('Subject');
            String description = String.isNotBlank(keyValueMap.get('Description'))?keyValueMap.get('Description').trim():keyValueMap.get('Description');
            if(issueTypeCode == null || issueTypeCode.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Issue Type Code is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(subject == null || subject.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Subject is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(description == null || description.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Description is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(!extIdFoundSet.contains(issueTypeCode)){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Issue Type Code is not valid');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(lan != null && lan.trim() != '' && !lanToAccountIdMap.containsKey(lan)){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Loan Account Number is not found');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(clientCode != null && clientCode.trim() != '' && !clientCodeToAccountIdMap.containsKey(clientCode)){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Client Code is not found');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            Case caseRec = new Case();
            caseRec.AssetId = lanToAssetIdMap.containsKey(lan) ? lanToAssetIdMap.get(lan) : null;
            if(caseRec.AssetId != null){
                caseRec.AccountId = lanToAccountIdMap.containsKey(lan) ? lanToAccountIdMap.get(lan): null;
            }else{
                caseRec.AccountId = clientCodeToAccountIdMap.containsKey(clientCode) ? clientCodeToAccountIdMap.get(clientCode) : null;
            }
            caseRec.CCC_External_Id__c = issueTypeCode;
            caseRec.Source__c = 'Email';
            caseRec.Description = description;
            caseRec.Subject = subject;
            caseRec.RecordTypeId = ASF_Constants.RT_FRAMEWORK;
            caseRec.Technical_Source__c = 'LWC';
            resultWrapper.resultRecords.put(lineItemId, caseRec);
            resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
        }

        return resultWrapper;
    }

    public List<Map<String,String>> prepareDownloadTemplate(List<String> columnNames, String objectName, Id listViewId, List<String> selectedRecordIds){
        List<Map<String, String>> listOfRecordsAsMap = new List<Map<String, String>>();
        Map<String, String> mapOfFieldApiToColumnName = new Map<String,String>{
            'Client_Code__c'=>'Client Code',
            'LAN__c'=>'Asset',
            'CCC_External_Id__c'=>'Issue Code',
            'Description'=>'Description',
            'Subject'=>'Subject'
        };
        Map<String, String> mapOfColumnNameToFieldApi = new Map<String,String>{
            'Client Code'=>'Client_Code__c',
            'Asset'=>'LAN__c',
            'Issue Code'=>'CCC_External_Id__c',
            'Description'=>'Description',
            'Subject'=>'Subject'
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