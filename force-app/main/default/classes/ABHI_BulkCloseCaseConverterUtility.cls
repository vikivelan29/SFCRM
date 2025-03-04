/**
* @File Name : ABHI_BulkCloseCaseConverterUtility.cls
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
public with sharing class ABHI_BulkCloseCaseConverterUtility implements ASF_BulkCSVToRecordConverter{
    
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - convertJSONRows
    * @param - jsonRows 
    * @return -  ASF_BulkCaseProcessorUtility.ConvertionResult
    * @description - This method will be used to create JSON format of the case records to be closed
    *****************************************************************************************************************/
    public ASF_BulkCaseProcessorUtility.ConvertionResult convertJSONRows(Map<Id, String> jsonRows){
        //Each row will be
        //{'Case number':'00005150','Case Resolved Comments':'','Stage':'Unresolved', 'Close Unresolved Reason':'Others', 'Close Unresolved Details':'Sample text','Stop Communication':'TRUE'}

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
        for(Case caseRec : [Select Id, CaseNumber, IsClosed, Stage__c, RecordTypeId, CCC_External_Id__c, AccountId from Case where CaseNumber IN :caseNumbers WITH SYSTEM_MODE]){
            caseNumberToCaseMap.put(caseRec.CaseNumber, caseRec);
        }

        for(Id lineItemId : rows.keySet()){
            Map<String, String> keyValueMap = rows.get(lineItemId);
            Boolean blockCommunicationFlag = false;
            
            String caseNumber = String.isNotBlank(keyValueMap.get('Case number'))?keyValueMap.get('Case number').trim():keyValueMap.get('Case number');
            String resolutionComments = String.isNotBlank(keyValueMap.get('Case Resolved Comments'))?keyValueMap.get('Case Resolved Comments').trim():keyValueMap.get('Case Resolved Comments');
            String unresolvedDetails = String.isNotBlank(keyValueMap.get('Close Unresolved Details'))?keyValueMap.get('Close Unresolved Details').trim():keyValueMap.get('Close Unresolved Details');
            String unresolvedReason = String.isNotBlank(keyValueMap.get('Close Unresolved Reason'))?keyValueMap.get('Close Unresolved Reason').trim():keyValueMap.get('Close Unresolved Reason');
            String stage = String.isNotBlank(keyValueMap.get('Stage'))?keyValueMap.get('Stage').trim():keyValueMap.get('Stage');
            String blockCommString = String.isNotBlank(keyValueMap.get('Stop Communication'))?keyValueMap.get('Stop Communication').trim():keyValueMap.get('Stop Communication');
            if(caseNumber == null || caseNumber.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Case number is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(stage == null || stage.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Stage is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(stage.toLowerCase() == 'resolved' && (resolutionComments == null || resolutionComments.trim() == '')){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Case Resolved Comments is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(stage.toLowerCase() == 'unresolved' && (unresolvedDetails == null || unresolvedDetails.trim() == '')){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Close Unresolved Details is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(stage.toLowerCase() == 'unresolved' && (unresolvedReason == null || unresolvedReason.trim() == '')){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Close Unresolved Reason is required');
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
            Case caseRec = caseNumberToCaseMap.get(caseNumber);
            if(stage == 'Resolved'){
                caseRec.Stage__c = stage;
                caseRec.Status = stage;
                caseRec.Pending_Clarification__c = false;
                caseRec.moved_back__c = false;
                caseRec.Is_Manual_Moved__c = true;
                caseRec.No_Auto_Communication__c = blockCommunicationFlag?'Email;SMS':null;
                ABHI_Case_Detail__c caseDetRec = new ABHI_Case_Detail__c();
                caseDetRec.Resolution_Comments__c = resolutionComments;
                caseRec.Bulk_CaseDetail_JSON__c = JSON.serialize(caseDetRec);
            }else if(stage == 'Unresolved'){
                caseRec.Stage__c = stage;
                caseRec.Status = stage;
                caseRec.Reject_Case__c = true;
                caseRec.No_Auto_Communication__c = blockCommunicationFlag?'Email;SMS':null;
                caseRec.Rejected_Reason__c = unresolvedDetails;
                caseRec.Rejection_Reason__c = unresolvedReason;
            }else{ 
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Invalid Stage');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            //Any other BU specific checks - add here
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
            'CaseNumber'=>'Case number',
            'Resolution_Comments__c'=>'Case Resolved Comments',
            'Stage__c'=>'Stage',
            'Rejection_Reason__c'=>'Close Unresolved Reason',
            'Rejected_Reason__c'=>'Close Unresolved Details',
            'No_Auto_Communication__c'=>'Stop Communication'
        };
        Map<String, String> mapOfColumnNameToFieldApi = new Map<String,String>{
            'Case number'=>'CaseNumber',
            'Case Resolved Comments'=>'Resolution_Comments__c',
            'Stage'=>'Stage__c',
            'Close Unresolved Reason'=>'Rejection_Reason__c',
            'Close Unresolved Details'=>'Rejected_Reason__c',
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