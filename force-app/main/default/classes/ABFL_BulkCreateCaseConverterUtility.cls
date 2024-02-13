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
            Map<String, String> keyValueMap = (Map<String, String>)JSON.deserializeUntyped(eachJSON);
            lans.add(keyValueMap.get('Loan Account No'));
            cccExtIds.add(keyValueMap.get('Issue Type Code'));
            rows.put(lineItemId, keyValueMap);
        }

        Map<String, Id> lanToAccountIdMap = new Map<String,Id>();
        Set<String> extIdFoundSet = new Set<String>();
       /* for(Asset assetRec : [Select Id, LAN__c, AccountId from Asset where LAN__c IN :lans]){
            lanToAccountIdMap.put(assetRec.LAN__c, assetRec.AccountId);
            
        }

       
        for(ASF_Case_Category_Config__c config : [SELECT Id, CCC_External_Id__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c IN :cccExtIds]){
            extIdFoundSet.add(config.CCC_External_Id__c);
        } */

        for(Id lineItemId : rows.keySet()){
            Map<String, String> keyValueMap = rows.get(lineItemId);
            if(!extIdFoundSet.contains(keyValueMap.get('Issue Type Code'))){
                keyValueMap.put('Result', 'FALSE');
                keyValueMap.put('Message', 'Issue Type Code is not valid');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                continue;
            }
            if(!lanToAccountIdMap.containsKey(keyValueMap.get('Loan Account No'))){
                keyValueMap.put('Result', 'FALSE');
                keyValueMap.put('Message', 'Loan Account Number is not found');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                continue;
            }
           /* Case caseRec = new Case();
            caseRec.AccountId = lanToAccountIdMap.get(keyValueMap.get('Loan Account No'));
            //Do we need to populate Asset lookup?? - Ask Manasa
            caseRec.CCC_External_Id__c = keyValueMap.get('Issue Type Code');
            caseRec.Source__c = keyValueMap.get('Source');
            caseRec.Description = keyValueMap.get('Description');
            Boolean commValue = Boolean.valueOf(keyValueMap.get('Block Customer Communication'));
            caseRec.No_Auto_Communication__c = commValue?'SMS;Email':null;
            
            resultWrapper.resultRecords.put(lineItemId, caseRec);
            resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap); */
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
        if(selectedRecordIds != null){
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