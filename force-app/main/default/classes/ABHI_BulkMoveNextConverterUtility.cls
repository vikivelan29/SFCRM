/**
* @File Name : ABHI_BulkMoveNextConverterUtility.cls
* @Description : Class for bulk case upload
* @Author : Salesforce
* @Last Modified By : Aditya Jawadekar
* @Last Modified On : October 12, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 12, 2024 | Aditya Jawadekar  | Initial Version
**/
@SuppressWarnings('PMD.ApexSOQLInjection,PMD.CyclomaticComplexity,PMD.StdCyclomaticComplexity,PMD.CognitiveComplexity,PMD.ExcessivePublicCount,PMD.IfStmtsMustUseBraces,PMD.IfElseStmtsMustUseBraces,PMD.AvoidDeeplyNestedIfStmts,PMD.ExcessiveParameterList,PMD.NcssMethodCount,PMD.ClassNamingConventions,PMD.FieldNamingConventions,PMD.VariableNamingConventions')
public with sharing class ABHI_BulkMoveNextConverterUtility implements ASF_BulkCSVToRecordConverter{
    
    public static boolean boolSkipChklstAbhiBulk = false;
    
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - convertJSONRows
    * @param - jsonRows 
    * @return -  ASF_BulkCaseProcessorUtility.ConvertionResult
    * @description - This method will be used to create JSON format of the case records to be closed
    *****************************************************************************************************************/
    public ASF_BulkCaseProcessorUtility.ConvertionResult convertJSONRows(Map<Id, String> jsonRows){
        //Each row will be
        //{'Case number':'00005150'}

        ASF_BulkCaseProcessorUtility.ConvertionResult resultWrapper = new ASF_BulkCaseProcessorUtility.ConvertionResult();
        resultWrapper.resultJSONMapRows = new Map<Id, Map<String, String>>();
        resultWrapper.resultJSONRows = new Map<Id, String>();
        resultWrapper.resultRecords = new Map<Id, SObject>();

        Set<String> caseNumbers = new Set<String>();
        Map<Id, Map<String, String>> rows = new Map<Id, Map<String, String>>();
        for(Id lineItemId : jsonRows.keySet()){
            String eachJSON = jsonRows.get(lineItemId);
            Map<String, String> keyValueMap = (Map<String, String>)JSON.deserialize(eachJSON, Map<String, String>.class);
            if(String.isNotBlank(keyValueMap.get('Case number'))){
                caseNumbers.add(keyValueMap.get('Case number').trim());
            }
            rows.put(lineItemId, keyValueMap);
        }

        Map<String, Case> caseNumberToCaseMap = new Map<String,Case>();
        Set<String> configIds = new Set<String>();
        Set<String> caseStages = new Set<String>();
        Map<String, Boolean> stageConfigMap = new Map<String, Boolean>();
        Map<Id, Set<String>> recIdToSkipperFlag = new Map<Id, Set<String>>();
        for(Case caseRec : [Select Id, CaseNumber, IsClosed, Stage__c, RecordTypeId, CCC_External_Id__c, AccountId from Case where CaseNumber IN :caseNumbers WITH SYSTEM_MODE]){
            caseNumberToCaseMap.put(caseRec.CaseNumber, caseRec);
            configIds.add(caseRec.CCC_External_Id__c);
            caseStages.add(caseRec.Stage__c);
            recIdToSkipperFlag.put(caseRec.Id, new Set<String>{ASF_Constants.SKIP_VALIDATE_CHECKLISTS});
        }
        if(!configIds.isEmpty()){
            for(ASF_Case_Stage_Config__c stageConfig : [Select Id, Enable_Bulk_Move_to_Next_Stage__c, StageName__c, Case_Category_Config__r.CCC_External_Id__c from ASF_Case_Stage_Config__c where Case_Category_Config__r.CCC_External_Id__c IN : configIds AND StageName__c IN :caseStages WITH SYSTEM_MODE]){
                String key = stageConfig.Case_Category_Config__r.CCC_External_Id__c +''+ stageConfig.StageName__c;
                stageConfigMap.put(key, stageConfig.Enable_Bulk_Move_to_Next_Stage__c);
            }
        }

        for(Id lineItemId : rows.keySet()){
            Map<String, String> keyValueMap = rows.get(lineItemId);
            String caseNumber = String.isNotBlank(keyValueMap.get('Case number'))?keyValueMap.get('Case number').trim():keyValueMap.get('Case number');
            
            if(caseNumber == null || caseNumber.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Case number is required');
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
            if(caseNumberToCaseMap.get(caseNumber).RecordTypeId == ASF_Constants.RT_INTERACTION 
            && (caseNumberToCaseMap.get(caseNumber).AccountId == null || caseNumberToCaseMap.get(caseNumber).CCC_External_Id__c == null)){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Case does not have Account tagged or Issue Type Code tagged');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            String caseKey = caseNumberToCaseMap.get(caseNumber).CCC_External_Id__c + ''+ caseNumberToCaseMap.get(caseNumber).Stage__c;
            if(!stageConfigMap.containsKey(caseKey) || !stageConfigMap.get(caseKey)){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Case current stage is not enabled for stage movement in bulk');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            //Any other BU specific checks - add here
            Case caseRec = caseNumberToCaseMap.get(caseNumber);
            caseRec.MoveToNext__c = true;
            boolSkipChklstAbhiBulk = true;
            //ASF_CaseTriggerModularHelper.setManualSkipperFlags(recIdToSkipperFlag, null);
            resultWrapper.resultRecords.put(lineItemId, caseRec);
            resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
        }

        return resultWrapper;
    }
	
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - prepareDownloadTemplate
    * @param - columnNames, objectName, listViewId, selectedRecordIds
    * @return -  List<Map<String,String>>
    * @description - This method will be used to prepare download template for users to add cases in sheet
    *****************************************************************************************************************/
    public List<Map<String,String>> prepareDownloadTemplate(List<String> columnNames, String objectName, Id listViewId, List<String> selectedRecordIds){
        List<Map<String, String>> listOfRecordsAsMap = new List<Map<String, String>>();
        Map<String, String> mapOfFieldApiToColumnName = new Map<String,String>{
            'CaseNumber'=>'Case number'
        };
        Map<String, String> mapOfColumnNameToFieldApi = new Map<String,String>{
            'Case number'=>'CaseNumber'
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
    
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - prepareCtstData
    * @param - columnNames, businessUnit
    * @return -  List<Map<String,String>>
    * @description - This method will be used to prepare CTST data
    *****************************************************************************************************************/
    public List<Map<String,String>> prepareCtstData(List<String> columnNames, String businessUnit){
        return new List<Map<String,String>>();
    }
}