@SuppressWarnings('PMD.ApexSOQLInjection')
public with sharing class ABHI_BulkCreateCaseConverterUtility implements ASF_BulkCSVToRecordConverter{
    
    public ASF_BulkCaseProcessorUtility.ConvertionResult convertJSONRows(Map<Id, String> jsonRows){
        //Each row will be
        //{'Client Code':'352344','Policy':'ABJABBIL','Issue Code':'ABFL1234', 'Source':'Email', 'Description':'DescriptionXYZ', 'Stop Communication':TRUE}

        ASF_BulkCaseProcessorUtility.ConvertionResult resultWrapper = new ASF_BulkCaseProcessorUtility.ConvertionResult();
        resultWrapper.resultJSONMapRows = new Map<Id, Map<String, String>>();
        resultWrapper.resultJSONRows = new Map<Id, String>();
        resultWrapper.resultRecords = new Map<Id, SObject>();

        Set<String> lans = new Set<String>();
        Set<String> cccExtIds = new Set<String>();
        Set<String> setClientCodes = new Set<String>();
        Map<Id, Map<String, String>> rows = new Map<Id, Map<String, String>>();
        for(Id lineItemId : jsonRows.keySet()){
            String eachJSON = jsonRows.get(lineItemId);
            System.debug('eachJSON'+eachJSON);
            Map<String, String> keyValueMap = (Map<String, String>)JSON.deserialize(eachJSON, Map<String, String>.class);
            if(String.isNotBlank(keyValueMap.get('Policy'))){
                lans.add(keyValueMap.get('Policy').trim());
            }
            if(String.isNotBlank(keyValueMap.get('Issue Code'))){
                cccExtIds.add(keyValueMap.get('Issue Code').trim());
            }
            if(String.isNotBlank(keyValueMap.get('Client Code'))){
                setClientCodes.add(keyValueMap.get('Client Code').trim());
            }
            rows.put(lineItemId, keyValueMap);
        }

        Map<String, Id> lanToAccountIdMap = new Map<String,Id>();
        Map<String, Id> lanToAssetIdMap = new Map<String,Id>();
        for(Account objAccountRec : [SELECT Id, Client_Code__c FROM Account WHERE Client_Code__c IN :setClientCodes AND Business_Unit__c =: ABHI_Constants.ABHI]){
            lanToAccountIdMap.put(objAccountRec.Client_Code__c, objAccountRec.Id);
        }
        for(Asset assetRec : [Select Id, LAN__c, AccountId from Asset where LAN__c IN :lans and Business_Unit__c =: ABHI_Constants.ABHI]){
            lanToAssetIdMap.put(assetRec.LAN__c, assetRec.Id);
        }

        Set<String> extIdFoundSet = new Set<String>();
        for(ASF_Case_Category_Config__c config : [SELECT Id, CCC_External_Id__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c IN :cccExtIds]){
            extIdFoundSet.add(config.CCC_External_Id__c);
        }

        for(Id lineItemId : rows.keySet()){
            Map<String, String> keyValueMap = rows.get(lineItemId);
            Boolean blockCommunicationFlag = false;

            String issueTypeCode = keyValueMap.get('Issue Code').trim();
            String strClientCode = keyValueMap.get('Client Code').trim();
            String lan = keyValueMap.get('Policy').trim();
            String blockCommString = String.isNotBlank(keyValueMap.get('Stop Communication'))?keyValueMap.get('Stop Communication').trim():keyValueMap.get('Stop Communication');
            String source = String.isNotBlank(keyValueMap.get('Source'))?keyValueMap.get('Source').trim():keyValueMap.get('Source');
            String description = String.isNotBlank(keyValueMap.get('Description'))?keyValueMap.get('Description').trim():keyValueMap.get('Description');
            if(issueTypeCode == null || issueTypeCode.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Issue Code is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(lan == null || lan.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Policy No is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(strClientCode == null || strClientCode.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Client Code is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(source == null || source.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Source is required');
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
                keyValueMap.put('Message', 'Issue Code is not valid');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(!lanToAccountIdMap.containsKey(strClientCode)){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Client code is not found');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(!lanToAssetIdMap.containsKey(lan)){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Policy number is not found');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(String.isNotBlank(blockCommString)){
                if(!blockCommString.equalsIgnoreCase('TRUE') && !blockCommString.equalsIgnoreCase('FALSE')){
                    keyValueMap.put('Result', 'FAILURE');
                    keyValueMap.put('Message', 'Invalid Stop Communication value provided - Accepted value - TRUE/FALSE');
                    resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                    resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                    continue;
                }
                try{
                    blockCommunicationFlag = Boolean.valueOf(blockCommString);
                }catch(Exception e){
                    keyValueMap.put('Result', 'FAILURE');
                    keyValueMap.put('Message', 'Invalid Stop Communication value provided - Accepted value - TRUE/FALSE');
                    resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                    resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                    continue;
                }
            }else{
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Invalid Stop Communication value provided - Accepted value - TRUE/FALSE');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            Case caseRec = new Case();
            caseRec.AccountId = lanToAccountIdMap.get(strClientCode);
            caseRec.AssetId = lanToAssetIdMap.get(lan);
            caseRec.CCC_External_Id__c = issueTypeCode;
            caseRec.Source__c = source;
            caseRec.Description = description;
            caseRec.No_Auto_Communication__c = blockCommunicationFlag?'Email;SMS':null;
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
            'LAN__c'=>'Policy',
            'CCC_External_Id__c'=>'Issue Code',
            'Source__c'=>'Source',
            'Description'=>'Description',
            'No_Auto_Communication__c'=>'Stop Communication'
        };
        Map<String, String> mapOfColumnNameToFieldApi = new Map<String,String>{
            'Client Code'=>'Client_Code__c',
            'Policy'=>'LAN__c',
            'Issue Code'=>'CCC_External_Id__c',
            'Source'=>'Source__c',
            'Description'=>'Description',
            'Stop Communication'=>'No_Auto_Communication__c'
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