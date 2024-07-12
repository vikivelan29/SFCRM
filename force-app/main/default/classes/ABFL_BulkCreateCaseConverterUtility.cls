@SuppressWarnings('PMD.ApexSOQLInjection')

public with sharing class ABFL_BulkCreateCaseConverterUtility implements ASF_BulkCSVToRecordConverter{
    public ASF_BulkCaseProcessorUtility.ConvertionResult convertJSONRows(Map<Id, String> jsonRows){
        //Each row will be
        //{'Loan Account No':'LAN1234','Issue Type Code':'ABFL1234', 'Source':'Email', 'Description':'DescriptionXYZ', 'Block Customer Communication':TRUE}

        ASF_BulkCaseProcessorUtility.ConvertionResult resultWrapper = new ASF_BulkCaseProcessorUtility.ConvertionResult();
        resultWrapper.resultJSONMapRows = new Map<Id, Map<String, String>>();
        resultWrapper.resultJSONRows = new Map<Id, String>();
        resultWrapper.resultRecords = new Map<Id, SObject>();

        Set<String> lans = new Set<String>();
        Set<String> cccExtIds = new Set<String>();
        Map<Id, Map<String, String>> rows = new Map<Id, Map<String, String>>();
        for(Id lineItemId : jsonRows.keySet()){
            String eachJSON = jsonRows.get(lineItemId);
            System.debug('eachJSON'+eachJSON);
            Map<String, String> keyValueMap = (Map<String, String>)JSON.deserialize(eachJSON, Map<String, String>.class);
            if(String.isNotBlank(keyValueMap.get('Loan Account No'))){
                lans.add(keyValueMap.get('Loan Account No').trim());
            }
            if(String.isNotBlank(keyValueMap.get('Issue Type Code'))){
                cccExtIds.add(keyValueMap.get('Issue Type Code').trim());
            }
            rows.put(lineItemId, keyValueMap);
        }

        Map<String, Id> lanToAccountIdMap = new Map<String,Id>();
        Map<String, Id> lanToAssetIdMap = new Map<String,Id>();
        for(Asset assetRec : [Select Id, LAN__c, AccountId from Asset where LAN__c IN :lans and Business_Unit__c = 'ABFL']){
            lanToAccountIdMap.put(assetRec.LAN__c, assetRec.AccountId);
            lanToAssetIdMap.put(assetRec.LAN__c, assetRec.Id);
        }

        Set<String> extIdFoundSet = new Set<String>();
        for(ASF_Case_Category_Config__c config : [SELECT Id, CCC_External_Id__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c IN :cccExtIds]){
            extIdFoundSet.add(config.CCC_External_Id__c);
        }

        for(Id lineItemId : rows.keySet()){
            Map<String, String> keyValueMap = rows.get(lineItemId);
            Boolean blockCommunicationFlag = false;

            String issueTypeCode = keyValueMap.get('Issue Type Code').trim();
            String lan = keyValueMap.get('Loan Account No').trim();
            String blockCommString = String.isNotBlank(keyValueMap.get('Block Customer Communication'))?keyValueMap.get('Block Customer Communication').trim():keyValueMap.get('Block Customer Communication');
            String source = String.isNotBlank(keyValueMap.get('Source'))?keyValueMap.get('Source').trim():keyValueMap.get('Source');
            String description = String.isNotBlank(keyValueMap.get('Description'))?keyValueMap.get('Description').trim():keyValueMap.get('Description');
            if(issueTypeCode == null || issueTypeCode.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Issue Type Code is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(lan == null || lan.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Loan Account No is required');
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
                keyValueMap.put('Message', 'Issue Type Code is not valid');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(!lanToAccountIdMap.containsKey(lan)){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Loan Account Number is not found');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(String.isNotBlank(blockCommString)){
                if(!blockCommString.equalsIgnoreCase('TRUE') && !blockCommString.equalsIgnoreCase('FALSE')){
                    keyValueMap.put('Result', 'FAILURE');
                    keyValueMap.put('Message', 'Invalid Block Customer Communication value provided - Accepted value - TRUE/FALSE');
                    resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                    resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                    continue;
                }
                try{
                    blockCommunicationFlag = Boolean.valueOf(blockCommString);
                }catch(Exception e){
                    keyValueMap.put('Result', 'FAILURE');
                    keyValueMap.put('Message', 'Invalid Block Customer Communication value provided - Accepted value - TRUE/FALSE');
                    resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                    resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                    continue;
                }
            }else{
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Invalid Block Customer Communication value provided - Accepted value - TRUE/FALSE');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            Case caseRec = new Case();
            caseRec.AccountId = lanToAccountIdMap.get(lan);
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
            'LAN__c'=>'Loan Account No',
            'CCC_External_Id__c'=>'Issue Type Code',
            'Source__c'=>'Source',
            'Description'=>'Description',
            'No_Auto_Communication__c'=>'Block Customer Communication'
        };
        Map<String, String> mapOfColumnNameToFieldApi = new Map<String,String>{
            'Loan Account No'=>'LAN__c',
            'Issue Type Code'=>'CCC_External_Id__c',
            'Source'=>'Source__c',
            'Description'=>'Description',
            'Block Customer Communication'=>'No_Auto_Communication__c'
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
}