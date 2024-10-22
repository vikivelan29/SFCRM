/*********************************************************
*Class        :  ABSLAMC_BulkCAMSCaseUpdateConvrtrUtility
*Author       :  Santosh Vyavhare
*Created Date :  01/10/2024
*Last Modified:  24/09/2024
*Description  :  Class for bulk CAMS case field update
*********************************************************/
@SuppressWarnings('PMD.ApexSOQLInjection')

public with sharing class ABSLAMC_BulkCAMSCaseUpdateConvrtrUtility implements ASF_BulkCSVToRecordConverter {
    public ASF_BulkCaseProcessorUtility.ConvertionResult convertJSONRows(Map<Id, String> jsonRows){
        //Each row will be
        //{'Case Number':'00005150','CAMS SEBI Reportable Flag':'yes', 'CAMS SEBI Reportable Category':'some category'}
        ASF_BulkCaseProcessorUtility.ConvertionResult resultWrapper = new ASF_BulkCaseProcessorUtility.ConvertionResult();
        resultWrapper.resultJSONMapRows = new Map<Id, Map<String, String>>();
        resultWrapper.resultJSONRows = new Map<Id, String>();
        resultWrapper.resultRecords = new Map<Id, SObject>();

        Set<String> caseNumbers = new Set<String>();
        Map<Id, Map<String, String>> rows = new Map<Id, Map<String, String>>();

        for(Id lineItemId : jsonRows.keySet()){
            String eachJSON = jsonRows.get(lineItemId);
            Map<String, String> keyValueMap = (Map<String, String>)JSON.deserialize(eachJSON, Map<String, String>.class);
            
            if(String.isNotBlank(keyValueMap.get('Case Number'))){
                caseNumbers.add(keyValueMap.get('Case Number').trim());
            }
            rows.put(lineItemId, keyValueMap);
        }
        Map<String, Case> caseNumberToCaseMap = new Map<String,Case>();
        for(Case caseRec : [Select Id, CaseNumber, Bulk_CaseDetail_JSON__c from Case where CaseNumber IN :caseNumbers]){
            caseNumberToCaseMap.put(caseRec.CaseNumber, caseRec);
            
        }

        for(Id lineItemId : rows.keySet()){
            Map<String, String> keyValueMap = rows.get(lineItemId);
            String caseNumber = String.isNotBlank(keyValueMap.get('Case Number'))?keyValueMap.get('Case Number').trim(): '';
            String sebiReportedFlag = String.isNotBlank(keyValueMap.get('CAMS SEBI Reportable Flag'))?keyValueMap.get('CAMS SEBI Reportable Flag').trim(): '';
            String sebiReportedCategory = String.isNotBlank(keyValueMap.get('CAMS SEBI Reportable Category'))?keyValueMap.get('CAMS SEBI Reportable Category').trim(): '';

            if(String.isBlank(caseNumber)){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Case number is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(String.isBlank(sebiReportedFlag) ){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'CAMS SEBI Reportable Flag is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(String.isBlank(sebiReportedCategory) ){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'CAMS SEBI Reportable Category is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }

            if( !(sebiReportedFlag.equalsIgnoreCase('yes') || sebiReportedFlag.equalsIgnoreCase('no')) ){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'CAMS SEBI Reportable flag should be yes or no');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }

            Case caseRec = caseNumberToCaseMap.get(caseNumber);
            ABSLAMC_Case_Detail__c casedetails = new ABSLAMC_Case_Detail__c();
            casedetails.CAMS_SEBI_Reportable_Category__c= sebiReportedCategory;
            casedetails.CAMS_SEBI_Reportable_Flag__c = sebiReportedFlag.equalsIgnoreCase('yes')? true : false ;
            caseRec.Bulk_CaseDetail_JSON__c = JSON.serialize(casedetails);
            resultWrapper.resultRecords.put(lineItemId, caseRec);
            resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
        }

        return resultWrapper;
    }

    public List<Map<String,String>> prepareDownloadTemplate(List<String> columnNames, String objectName, Id listViewId, List<String> selectedRecordIds){
        List<Map<String, String>> listOfRecordsAsMap = new List<Map<String, String>>();
        Map<String, String> mapOfFieldApiToColumnName = new Map<String,String>{
            'CaseNumber'=>'Case Number',
            'ABSLAMC_Case_Detail__r.CAMS_SEBI_Reportable_Flag__c'=>'CAMS SEBI Reportable Flag',
            'ABSLAMC_Case_Detail__r.CAMS_SEBI_Reportable_Category__c'=> 'CAMS SEBI Reportable Category'                
        };
        Map<String, String> mapOfColumnNameToFieldApi = new Map<String,String>{
            'Case Number'=>'CaseNumber',
            'CAMS SEBI Reportable Flag'=>'ABSLAMC_Case_Detail__r.CAMS_SEBI_Reportable_Flag__c',
            'CAMS SEBI Reportable Category' =>'ABSLAMC_Case_Detail__r.CAMS_SEBI_Reportable_Category__c' 
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
            String strWhereClause = ' WHERE ID IN:selectedRecordIds ';
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
                    String fieldValue; //= (String)obj.get(fieldName);
                    fieldValue = fieldValue==null?' ':fieldValue;
                    if(fieldName.contains('.') && obj.getSobject((fieldName.split('\\.'))[0]) != null){
                        fieldValue = String.valueOf(obj.getSobject(fieldName.split('\\.')[0]).get(fieldName.split('\\.')[1]));
                        if(fieldName.contains('CAMS_SEBI_Reportable_Flag__c')){
                            if(fieldValue == null || fieldValue==' '){
                                fieldValue = 'false';
                            }
                            fieldValue = fieldValue.equalsIgnoreCase('true') ? 'Yes' : 'No';
                        }
                    }else if(!fieldName.contains('.')){
                        fieldValue = (String)obj.get(fieldName);
                    }else if(fieldName.contains('.') && obj.getSobject((fieldName.split('\\.'))[0]) == null){ // added this check to add the No in the blank/null value for reportable flag field.
                        System.debug('field fieldName ==> '+fieldName);
                        if(fieldName.contains('CAMS_SEBI_Reportable_Flag__c')){
                            fieldValue = 'false';
                            fieldValue = fieldValue.equalsIgnoreCase('true') ? 'Yes' : 'No';
                        }
                    }
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