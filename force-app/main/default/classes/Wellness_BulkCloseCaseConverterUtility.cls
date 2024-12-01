/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 11-13-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   10-25-2024   rsinghnagar@salesforce.com   Initial Version
**/
@SuppressWarnings('PMD.ApexSOQLInjection, PMD.CyclomaticComplexity, PMD.CognitiveComplexity, PMD.StdCyclomaticComplexity, PMD.ExcessiveParameterList, PMD.NcssMethodCount')
public with sharing class Wellness_BulkCloseCaseConverterUtility implements ASF_BulkCSVToRecordConverter{
    /****************************************************************************************************************
    * @LOB - Wellness
    * @Function - convertJSONRows
    * @param jsonRows
    * @return - ASF_BulkCaseProcessorUtility.ConvertionResult
    * @description - Invoked from the Mcrm_getPolicyDetails Lwc components to send asset policy details.
    */
    public ASF_BulkCaseProcessorUtility.ConvertionResult convertJSONRows(Map<Id, String> jsonRows){
        //Each row will be
        //{'Case number':'00005150','Resolution Comment':'', 'Description':'Unresolved'}

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
        for(Case caseRec : [SELECT Id, CaseNumber, IsClosed, Stage__c, RecordTypeId, CCC_External_Id__c, AccountId FROM Case WHERE CaseNumber IN :caseNumbers WITH SECURITY_ENFORCED]){
            caseNumberToCaseMap.put(caseRec.CaseNumber, caseRec);
        }

        for(Id lineItemId : rows.keySet()){
            Map<String, String> keyValueMap = rows.get(lineItemId);
            String caseNumber = String.isNotBlank(keyValueMap.get('Case number'))?keyValueMap.get('Case number').trim():keyValueMap.get('Case number');
            String resolutionComments = String.isNotBlank(keyValueMap.get('Resolution Comments'))?keyValueMap.get('Resolution Comments').trim():keyValueMap.get('Resolution Comments');
            String resolutionReason = String.isNotBlank(keyValueMap.get('Resolution Reason'))?keyValueMap.get('Resolution Reason').trim():keyValueMap.get('Resolution Reason');
            String description = String.isNotBlank(keyValueMap.get('Description'))?keyValueMap.get('Description').trim():keyValueMap.get('Description');
            if(caseNumber == null || caseNumber.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Case number is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(resolutionComments == null || resolutionComments.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Resolution Comments is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(resolutionReason == null || resolutionReason.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Resolution Reason is required');
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
            Case caseRec = caseNumberToCaseMap.get(caseNumber);
            
            caseRec.Stage__c = 'Resolved';
            caseRec.Status = 'Resolved';
            caseRec.Pending_Clarification__c = false;
            caseRec.moved_back__c = false;
            caseRec.Is_Manual_Moved__c = true;
            caseRec.Description = description;
            
            WellnessCaseDetail__c caseDetRec = new WellnessCaseDetail__c();
            caseDetRec.Resolution_Comments__c = resolutionComments;
            caseDetRec.Resolution_Reason__c = resolutionReason;
            caseRec.Bulk_CaseDetail_JSON__c = JSON.serialize(caseDetRec);
            
            //Any other BU specific checks - add here
            resultWrapper.resultRecords.put(lineItemId, caseRec);
            resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
        }

        return resultWrapper;
    }

    /****************************************************************************************************************
    * @LOB - Wellness
    * @Function - prepareDownloadTemplate
    * @param columnNames - List of Column Names
    * @param objectName - Object Name
    * @param listViewId - List View Id
    * @param selectedRecordIds - List of Selected Record Ids
    * @return - List<Map<String,String>>    
    * @description - Method to prepare Download Template
    */
    public List<Map<String,String>> prepareDownloadTemplate(List<String> columnNames, String objectName, Id listViewId, List<String> selectedRecordIds){
        System.debug('***columnNames:'+columnNames);
        List<Map<String, String>> listOfRecordsAsMap = new List<Map<String, String>>();
        Map<String, String> mapOfFieldApiToColumnName = new Map<String,String>{
            'CaseNumber'=>'Case number',
            'Resolution_Comments__c'=>'Resolution Comments',
            'WellnessCaseDetail__r.Resolution_Reason__c'=>'Resolution Reason',
            'Description'=>'Description'
        };
        Map<String, String> mapOfColumnNameToFieldApi = new Map<String,String>{
            'Case number'=>'CaseNumber',
            'Resolution Comments'=>'Resolution_Comments__c',
            'Resolution Reason'=>'WellnessCaseDetail__r.Resolution_Reason__c',
            'Description'=>'Description'
        };
        List<String> fieldNames = new List<String>();
        for(String columnName : columnNames){
            if(mapOfColumnNameToFieldApi.containsKey(columnName)){
                fieldNames.add(mapOfColumnNameToFieldApi.get(columnName));
            }
        }
        System.debug('***fieldNames:'+fieldNames);
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
            System.debug('strFinalQuery'+strFinalQuery);
            List<SObject> recordsList = Database.query(strFinalQuery);
            for(SObject obj : recordsList){
                Map<String,String> fieldMap = new Map<String,String>();
                String fieldValue = '';
                for(String fieldName : mapOfFieldApiToColumnName.keySet()){
                    if(fieldName.contains('.') && obj.getSobject((fieldName.split('\\.'))[0]) != null){
                        fieldValue = (String)obj.getSobject(fieldName.split('\\.')[0]).get(fieldName.split('\\.')[1]);
                    }else if(!fieldName.contains('.')){
                        fieldValue = (String)obj.get(fieldName);
                    }
                    fieldValue = fieldValue==null?' ':fieldValue;
                    fieldMap.put(mapOfFieldApiToColumnName.get(fieldName), fieldValue);
                }
                listOfRecordsAsMap.add(fieldMap);
            }
        } 

        return listOfRecordsAsMap;
    }
    /****************************************************************************************************************
    * @LOB - Wellness
    * @Function - prepareCtstData
    * @param columnNames - List of Column Names
    * @param businessUnit - BU Name
    * @return - List<Map<String,String>>    
    * @description - Method to prepare download template
    */
    public List<Map<String,String>> prepareCtstData(List<String> columnNames, String businessUnit){
        return new List<Map<String,String>>();
    }
}