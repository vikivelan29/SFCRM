/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-Jul-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class ABSLI_BulkCreateCaseConverterUtility implements ASF_BulkCSVToRecordConverter{
     /**
     * @description This method is called from the ASF_BulkCaseProcessorUtility while performing bulk create via csv upload
     * @param jsonRows
     * @param allOutputs - outputWrapper with updated values
     */
	public ASF_BulkCaseProcessorUtility.ConvertionResult convertJSONRows(Map<Id, String> jsonRows){
        //Each row will be
        //{'Policy Number':'LAN1234','Issue Code':'BSLI1234', 'Issue Type Dropdown':'Issue Type', 'Source':'Email', 'Description':'DescriptionXYZ'}

        ASF_BulkCaseProcessorUtility.ConvertionResult resultWrapper = new ASF_BulkCaseProcessorUtility.ConvertionResult();
        resultWrapper.resultJSONMapRows = new Map<Id, Map<String, String>>();
        resultWrapper.resultJSONRows = new Map<Id, String>();
        resultWrapper.resultRecords = new Map<Id, SObject>();

        Set<String> lans = new Set<String>();
        Set<String> cccExtIds = new Set<String>();
        Map<Id, Map<String, String>> rows = new Map<Id, Map<String, String>>();
        for(Id lineItemId : jsonRows.keySet()){
            String eachJSON = jsonRows.get(lineItemId);
            Map<String, String> keyValueMap = (Map<String, String>)JSON.deserialize(eachJSON, Map<String, String>.class);
            if(String.isNotBlank(keyValueMap.get('Policy Number'))){
                lans.add(keyValueMap.get('Policy Number').trim());
            }
            if(String.isNotBlank(keyValueMap.get('Issue Code'))){
                cccExtIds.add(keyValueMap.get('Issue Code').trim());
            }
            rows.put(lineItemId, keyValueMap);
        }

        Map<String, Id> lanToAccountIdMap = new Map<String,Id>();
        Map<String, Id> lanToAssetIdMap = new Map<String,Id>();
        Map<String, List<String>> cccIdToIssueTypeMap = new Map<String, List<String>>();
        for(Asset assetRec : [Select Id, Policy_No__c, AccountId from Asset where Policy_No__c IN :lans and Business_Unit__c =: ASF_Constants.ABSLI_BU WITH SYSTEM_MODE]){
            lanToAccountIdMap.put(assetRec.Policy_No__c, assetRec.AccountId);
            lanToAssetIdMap.put(assetRec.Policy_No__c, assetRec.Id);
        }

        Set<String> extIdFoundSet = new Set<String>();
        for(ASF_Case_Category_Config__c config : [SELECT Id, CCC_External_Id__c, Allowed_Issue_Types__c  FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c IN :cccExtIds WITH SYSTEM_MODE]){
            extIdFoundSet.add(config.CCC_External_Id__c);
            if(String.isNotBlank(config.Allowed_Issue_Types__c)){
                cccIdToIssueTypeMap.put(config.CCC_External_Id__c, config.Allowed_Issue_Types__c.split(';'));
            }
        }

        for(Id lineItemId : rows.keySet()){
            Map<String, String> keyValueMap = rows.get(lineItemId);
            String issueTypeCode = keyValueMap.get('Issue Code').trim();
            String lan = keyValueMap.get('Policy Number').trim();
            String source = String.isNotBlank(keyValueMap.get('Source'))?keyValueMap.get('Source').trim():keyValueMap.get('Source');
            String issueType = String.isNotBlank(keyValueMap.get('Issue Type Dropdown'))?keyValueMap.get('Issue Type Dropdown').trim():keyValueMap.get('Issue Type Dropdown');
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
                keyValueMap.put('Message', 'Policy Number is required');
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
            if(cccIdToIssueTypeMap.containsKey(issueTypeCode) && (issueType == null || issueType.trim() == '')){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Issue Type Dropdown is required for selected Issue Type Code');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(cccIdToIssueTypeMap.containsKey(issueTypeCode) && !(cccIdToIssueTypeMap.get(issueTypeCode).contains(issueType))){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Issue Type Dropdown is not valid for selected Issue Type Code');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(!cccIdToIssueTypeMap.containsKey(issueTypeCode) && issueType != null && issueType.trim() != ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Selected Issue Type Code does not have an Issue Type');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(!lanToAccountIdMap.containsKey(lan)){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Policy Number is not found');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            
            ABSLI_Case_Detail__c caseDetRec = new ABSLI_Case_Detail__c();
            caseDetRec.Source_Request_submitted_by__c = 'Customer';

            Case caseRec = new Case();
            caseRec.AccountId = lanToAccountIdMap.get(lan);
            caseRec.AssetId = lanToAssetIdMap.get(lan);
            caseRec.CCC_External_Id__c = issueTypeCode;
            caseRec.Source__c = source;
            caseRec.Issue_Type__c = issueType;
            caseRec.Description = description;
            caseRec.RecordTypeId = ASF_Constants.RT_FRAMEWORK;
            caseRec.Technical_Source__c = 'LWC';
            caseRec.Bulk_CaseDetail_JSON__c = JSON.serialize(caseDetRec);
            resultWrapper.resultRecords.put(lineItemId, caseRec);
            resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
        }

        return resultWrapper;
    }
	/**
     * @description This method is called from the ASF_BulkCsvController while performing bulk download of records
     * for create operation
     * @param jsonRows
     * @param allOutputs - outputMap with key as field and value as the record value
     */
    public List<Map<String,String>> prepareDownloadTemplate(List<String> columnNames, String objectName, Id listViewId, List<String> selectedRecordIds){
        List<Map<String, String>> listOfRecordsAsMap = new List<Map<String, String>>();
        Map<String, String> mapOfFieldApiToColumnName = new Map<String,String>{
            'LAN__c'=>'Policy Number',
            'CCC_External_Id__c'=>'Issue Code',
            'Issue_Type__c'=>'Issue Type Dropdown',
            'Source__c'=>'Source',
            'Description'=>'Description'
        };
        Map<String, String> mapOfColumnNameToFieldApi = new Map<String,String>{
            'Policy Number'=>'LAN__c',
            'Issue Code'=>'CCC_External_Id__c',
            'Issue Type Dropdown'=>'Issue_Type__c',
            'Source'=>'Source__c',
            'Description'=>'Description'
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
     * @param jsonRows
     * @param allOutputs - outputMap with key as field and value as the record value
     */
    public List<Map<String,String>> prepareCtstData(List<String> columnNames, String businessUnit){
        List<Map<String, String>> listOfRecordsAsMap = new List<Map<String, String>>();
        Map<String, String> mapOfFieldApiToColumnName = new Map<String,String>{
            'CCC_External_Id__c'=>'Issue Code',
            'Type__c'=>'Case Type',
            'Sub_Type__c'=>'Sub Type',
            'Nature__c'=>'Nature',
            'Allowed_Issue_Types__c'=>'Issue Type'
        };
        Map<String, String> mapOfColumnNameToFieldApi = new Map<String,String>{
            'Issue Code'=>'CCC_External_Id__c',
            'Case Type'=>'Type__c',
            'Sub Type'=>'Sub_Type__c',
            'Nature'=>'Nature__c',
            'Issue Type'=>'Allowed_Issue_Types__c'
        };
        List<String> fieldNames = new List<String>();
        for(String columnName : columnNames){
            if(mapOfColumnNameToFieldApi.containsKey(columnName)){
                fieldNames.add(mapOfColumnNameToFieldApi.get(columnName));
            }
        }

        String strFinalQuery;
        String strFields = String.join(fieldNames, ',');
        String strWhereClause = ' WHERE Business_Unit__c =: businessUnit';
        strFinalQuery = 'Select '+ String.escapeSingleQuotes(strFields) + ' FROM ASF_Case_Category_Config__c'+ String.escapeSingleQuotes(strWhereClause);
        
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