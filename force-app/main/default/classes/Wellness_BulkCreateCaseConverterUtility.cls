/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-15-2024
 * @last modified by  : rsinghnagar@salesforce.com
**/
@SuppressWarnings('PMD.CyclomaticComplexity, PMD.CognitiveComplexity, PMD.StdCyclomaticComplexity, PMD.ExcessiveParameterList, PMD.NcssMethodCount')
public with sharing class Wellness_BulkCreateCaseConverterUtility implements ASF_BulkCSVToRecordConverter{
    /**
    * @description This method is called from the ASF_BulkCaseProcessorUtility while performing bulk create via csv upload
    * @param jsonRows
    * @return ASF_BulkCaseProcessorUtility.ConvertionResult
    */
   public ASF_BulkCaseProcessorUtility.ConvertionResult convertJSONRows(Map<Id, String> jsonRows){
       //Each row will be
       //{'Contract Number':'LAN1234','Issue Type Code':'BSLI1234', 'Issue Type Dropdown':'Issue Type', 'Source':'Email', 'Description':'DescriptionXYZ'}

       ASF_BulkCaseProcessorUtility.ConvertionResult resultWrapper = new ASF_BulkCaseProcessorUtility.ConvertionResult();
       resultWrapper.resultJSONMapRows = new Map<Id, Map<String, String>>();
       resultWrapper.resultJSONRows = new Map<Id, String>();
       resultWrapper.resultRecords = new Map<Id, SObject>();

       Set<String> lans = new Set<String>();
       Set<String> clientIds = new Set<String>();
       Set<String> cccExtIds = new Set<String>();
       Map<Id, Map<String, String>> rows = new Map<Id, Map<String, String>>();
       for(Id lineItemId : jsonRows.keySet()){
           String eachJSON = jsonRows.get(lineItemId);
           Map<String, String> keyValueMap = (Map<String, String>)JSON.deserialize(eachJSON, Map<String, String>.class);
           if(String.isNotBlank(keyValueMap.get('Contract Number'))){
               lans.add(keyValueMap.get('Contract Number').trim());
           }
           if(String.isNotBlank(keyValueMap.get('Member Id/Customer Number'))){
                clientIds.add(keyValueMap.get('Member Id/Customer Number').trim());
            }
           if(String.isNotBlank(keyValueMap.get('Issue Type Code'))){
               cccExtIds.add(keyValueMap.get('Issue Type Code').trim());
           }
           rows.put(lineItemId, keyValueMap);
       }

       Map<String, Id> lanToAccountIdMap = new Map<String,Id>();
       Map<String, Id> lanToAssetIdMap = new Map<String,Id>();
    //    Map<String, List<String>> cccIdToIssueTypeMap = new Map<String, List<String>>();
       for(Asset assetRec : [Select Id, ContractId__c, AccountId from Asset where ContractId__c IN :lans and Business_Unit__c =: System.label.Wellness_BU WITH SYSTEM_MODE]){
           lanToAccountIdMap.put(assetRec.ContractId__c, assetRec.AccountId);
           lanToAssetIdMap.put(assetRec.ContractId__c, assetRec.Id);
       }

       Set<String> extIdFoundSet = new Set<String>();
       for(ASF_Case_Category_Config__c config : [SELECT Id, CCC_External_Id__c, Allowed_Issue_Types__c  FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c IN :cccExtIds WITH SYSTEM_MODE]){
           extIdFoundSet.add(config.CCC_External_Id__c);
       }

       Set<String> clientIdsFoundSet = new Set<String>();
       for(Account acc : [SELECT Id, Client_Code__c  FROM Account WHERE Client_Code__c IN :clientIds WITH SYSTEM_MODE]){
        clientIdsFoundSet.add(acc.Client_Code__c);
       }

       for(Id lineItemId : rows.keySet()){
           Map<String, String> keyValueMap = rows.get(lineItemId);
           String issueTypeCode = keyValueMap.get('Issue Type Code').trim();
           String lan = keyValueMap.get('Contract Number').trim();
           String clientId = keyValueMap.get('Member Id/Customer Number').trim();
           String source = String.isNotBlank(keyValueMap.get('Source'))?keyValueMap.get('Source').trim():keyValueMap.get('Source');
           String description = String.isNotBlank(keyValueMap.get('Description'))?keyValueMap.get('Description').trim():keyValueMap.get('Description');
           if(lan == null || lan.trim() == ''){
               keyValueMap.put('Result', 'FAILURE');
               keyValueMap.put('Message', 'Contract Number is required');
               resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
               resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
               continue;
           }
           if(clientId == null || clientId.trim() == ''){
               keyValueMap.put('Result', 'FAILURE');
               keyValueMap.put('Message', 'Member Id/Customer Number is required');
               resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
               resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
               continue;
           }
           if(issueTypeCode == null || issueTypeCode.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Issue Type Code is required');
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
            if(!clientIdsFoundSet.contains(clientId)){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Member Id/Customer Number is not valid');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
           if(!lanToAccountIdMap.containsKey(lan)){
               keyValueMap.put('Result', 'FAILURE');
               keyValueMap.put('Message', 'Contract Number is not valid');
               resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
               resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
               continue;
           }
           
        //    WellnessCaseDetail__c caseDetRec = new WellnessCaseDetail__c();
        //    caseDetRec.Source_Request_submitted_by__c = 'Customer';

           Case caseRec = new Case();
           caseRec.AccountId = lanToAccountIdMap.get(lan);
           caseRec.AssetId = lanToAssetIdMap.get(lan);
           caseRec.CCC_External_Id__c = issueTypeCode;
           caseRec.Source__c = source;
        //    caseRec.Issue_Type__c = issueType;
           caseRec.Description = description;
           caseRec.RecordTypeId = ASF_Constants.RT_FRAMEWORK;
           caseRec.Technical_Source__c = 'LWC';
        //    caseRec.Bulk_CaseDetail_JSON__c = JSON.serialize(caseDetRec);
           resultWrapper.resultRecords.put(lineItemId, caseRec);
           resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
       }

       return resultWrapper;
   }
   /**
    * @description This method is called from the ASF_BulkCsvController while performing bulk download of records
    * for create operation
    * @param columnNames
    * @param objectName
    * @param listViewId
    * @param selectedRecordIds
    * @return List<Map<String,String>>
    */
   public List<Map<String,String>> prepareDownloadTemplate(List<String> columnNames, String objectName, Id listViewId, List<String> selectedRecordIds){
       List<Map<String, String>> listOfRecordsAsMap = new List<Map<String, String>>();
       Map<String, String> mapOfFieldApiToColumnName = new Map<String,String>{
           'LAN__c'=>'Contract Number',
           'Client_Code_Text__c'=>'Member Id/Customer Number',
           'CCC_External_Id__c'=>'Issue Type Code',
           'Source__c'=>'Source',
           'Description'=>'Description',
           'No_Auto_Communication__c'=>'Block Customer Communication'
       };
       Map<String, String> mapOfColumnNameToFieldApi = new Map<String,String>{
           'Contract Number'=>'LAN__c',
           'Member Id/Customer Number'=>'Client_Code_Text__c',
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
           strFinalQuery = 'Select '+ String.escapeSingleQuotes(strFields) + ' FROM ' + String.escapeSingleQuotes(objectName) + String.escapeSingleQuotes(strWhereClause);
       }
       else if(listViewId != null){
           String strFields = String.join(fieldNames, ',');
           String listViewQuery = ASF_BulkCsvDownloadHelper.getListViewSOQL(objectName, listViewId);
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

   /**
    * @description This method is called from the ASF_BulkCsvController while performing bulk download of ctst data
    * for create operation
    * @param columnNames
    * @param businessUnit
    * @return List<Map<String,String>>
    */
   public List<Map<String,String>> prepareCtstData(List<String> columnNames, String businessUnit){
       List<Map<String, String>> listOfRecordsAsMap = new List<Map<String, String>>();
       return listOfRecordsAsMap;
   }
}