/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-Jul-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class ABSLI_BulkCloseCaseConverterUtility implements ASF_BulkCSVToRecordConverter{
    
    public static Boolean requestFromBulkClose = false;
    /**
     * @description This method is called from the ASF_BulkCaseProcessorUtility while performing bulk close via csv upload
     * @param jsonRows
     * @param allOutputs - outputWrapper with updated values
     */
	public ASF_BulkCaseProcessorUtility.ConvertionResult convertJSONRows(Map<Id, String> jsonRows){
        //Each row will be
        //{'Case number':'00005150','Team Resolution Status':'', 'Resolution Comments':'Unresolved', 'Reason for Delay':'Others', 'RCA Comments If any':'Sample text'}
        ASF_BulkCaseProcessorUtility.ConvertionResult resultWrapper = new ASF_BulkCaseProcessorUtility.ConvertionResult();
        resultWrapper.resultJSONMapRows = new Map<Id, Map<String, String>>();
        resultWrapper.resultJSONRows = new Map<Id, String>();
        resultWrapper.resultRecords = new Map<Id, SObject>();

        Set<String> caseNumbers = new Set<String>();
        Map<Id, Map<String, String>> rows = new Map<Id, Map<String, String>>();
        for(Id lineItemId : jsonRows.keySet()){
            String eachJSON = jsonRows.get(lineItemId);
            System.debug('eachJSON'+eachJSON);
            Map<String, String> keyValueMap = (Map<String, String>)JSON.deserialize(eachJSON, Map<String, String>.class);
            if(String.isNotBlank(keyValueMap.get('Case number'))){
                caseNumbers.add(keyValueMap.get('Case number').trim());
            }
            rows.put(lineItemId, keyValueMap);
        }

        Map<String, Case> caseNumberToCaseMap = new Map<String,Case>();
        for(Case caseRec : [Select Id, CaseNumber, IsClosed, Stage__c, Nature__c, RecordTypeId, CCC_External_Id__c, AccountId from Case where CaseNumber IN :caseNumbers WITH SYSTEM_MODE]){
            caseNumberToCaseMap.put(caseRec.CaseNumber, caseRec);
        }

        for(Id lineItemId : rows.keySet()){
            Map<String, String> keyValueMap = rows.get(lineItemId);
            String caseNumber = String.isNotBlank(keyValueMap.get('Case number'))?keyValueMap.get('Case number').trim():keyValueMap.get('Case number');
            String teamResolutionStatus = String.isNotBlank(keyValueMap.get('Team Resolution Status'))?keyValueMap.get('Team Resolution Status').trim():keyValueMap.get('Team Resolution Status');
            String resolutionComments = String.isNotBlank(keyValueMap.get('Resolution Comments'))?keyValueMap.get('Resolution Comments').trim():keyValueMap.get('Resolution Comments');
            String reasonForDelay = String.isNotBlank(keyValueMap.get('Reason for Delay'))?keyValueMap.get('Reason for Delay').trim():keyValueMap.get('Reason for Delay');
            String rcaComments = String.isNotBlank(keyValueMap.get('RCA Comments If any'))?keyValueMap.get('RCA Comments If any').trim():keyValueMap.get('RCA Comments If any');
            
            if(caseNumber == null || caseNumber.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Case number is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(teamResolutionStatus == null || teamResolutionStatus.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Team Resolution Status is required');
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
            if(caseNumberToCaseMap.get(caseNumber).Nature__c == 'Request' && (resolutionComments == null || resolutionComments.trim() == '')){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Resolution Comments is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            Case caseRec = caseNumberToCaseMap.get(caseNumber);
            ABSLI_Case_Detail__c caseDetRec = new ABSLI_Case_Detail__c();
            caseDetRec.Outcome__c = teamResolutionStatus;
            caseDetRec.Resolution__c = resolutionComments;
            caseDetRec.Reason_for_Delay__c = reasonForDelay;
            caseDetRec.RCA_Comments__c = rcaComments;
            system.debug('json rel object--'+JSON.serialize(caseDetRec));
            
            if(teamResolutionStatus == 'Resolved'){
                caseRec.Stage__c = teamResolutionStatus;
                caseRec.Status = teamResolutionStatus;
                caseRec.Pending_Clarification__c = false;
                caseRec.moved_back__c = false;
                caseRec.Is_Manual_Moved__c = true;
                ABSLI_BulkCloseCaseConverterUtility.requestFromBulkClose = true;
                caseRec.Bulk_CaseDetail_JSON__c = JSON.serialize(caseDetRec);
                
            }else if(teamResolutionStatus == 'Unresolved'){
                caseRec.Stage__c = teamResolutionStatus;
                caseRec.Status = teamResolutionStatus;
                caseRec.Reject_Case__c = true;
                ABSLI_BulkCloseCaseConverterUtility.requestFromBulkClose = true;
                caseRec.Bulk_CaseDetail_JSON__c = JSON.serialize(caseDetRec);
            }else{
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Invalid Team Resolution Status');
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
	/**
     * @description This method is called from the ASF_BulkCsvController while performing bulk download of records
     * for close operation
     * @param jsonRows
     * @param allOutputs - outputMap with key as field and value as the record value
     */
    public List<Map<String,String>> prepareDownloadTemplate(List<String> columnNames, String objectName, Id listViewId, List<String> selectedRecordIds){
        List<Map<String, String>> listOfRecordsAsMap = new List<Map<String, String>>();
        Map<String, String> mapOfFieldApiToColumnName = new Map<String,String>{
            'CaseNumber'=>'Case number',
            'ABSLI_Case_Detail__r.Outcome__c'=>'Team Resolution Status',
            'ABSLI_Case_Detail__r.Resolution__c'=>'Resolution Comments',
            'ABSLI_Case_Detail__r.Reason_for_Delay__c'=>'Reason for Delay',
            'ABSLI_Case_Detail__r.RCA_Comments__c'=>'RCA Comments If any'
        };
        Map<String, String> mapOfColumnNameToFieldApi = new Map<String,String>{
            'Case number'=>'CaseNumber',
            'Team Resolution Status'=>'ABSLI_Case_Detail__r.Outcome__c',
            'Resolution Comments'=>'ABSLI_Case_Detail__r.Resolution__c',
            'Reason for Delay'=>'ABSLI_Case_Detail__r.Reason_for_Delay__c',
            'RCA Comments If any'=>'ABSLI_Case_Detail__r.RCA_Comments__c'
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
    public List<Map<String,String>> prepareCtstData(List<String> columnNames, String businessUnit){
        return new List<Map<String,String>>();
    }
}