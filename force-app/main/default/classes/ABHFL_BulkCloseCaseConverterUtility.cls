public with sharing class ABHFL_BulkCloseCaseConverterUtility  implements ASF_BulkCSVToRecordConverter{
    public ASF_BulkCaseProcessorUtility.ConvertionResult convertJSONRows(Map<Id, String> jsonRows){
        //Each row will be
        //{'Case number':'00005150','Resolution Comments':'', 'Stage':'Unresolved', 'Close Unresolved Reason':'Others', 'Close Unresolved Details':'Sample text'}

        ASF_BulkCaseProcessorUtility.ConvertionResult resultWrapper = new ASF_BulkCaseProcessorUtility.ConvertionResult();
        resultWrapper.resultJSONMapRows = new Map<Id, Map<String, String>>();
        resultWrapper.resultJSONRows = new Map<Id, String>();
        resultWrapper.resultRecords = new Map<Id, SObject>();

        Set<String> caseNumbers = new Set<String>();
        Map<Id, Map<String, String>> rows = new Map<Id, Map<String, String>>();
        for(Id lineItemId : jsonRows.keySet()){
            String eachJSON = jsonRows.get(lineItemId);
            Map<String, String> keyValueMap = (Map<String, String>)JSON.deserializeUntyped(eachJSON);
            caseNumbers.add(keyValueMap.get('Case number'));
            rows.put(lineItemId, keyValueMap);
        }

        Map<String, Case> caseNumberToCaseMap = new Map<String,Case>();
        for(Case caseRec : [Select Id, CaseNumber, IsClosed, Stage__c from Case where CaseNumber IN :caseNumbers]){
            caseNumberToCaseMap.put(caseRec.CaseNumber, caseRec);
        }

        for(Id lineItemId : rows.keySet()){
            Map<String, String> keyValueMap = rows.get(lineItemId);
            if(!caseNumberToCaseMap.containsKey(keyValueMap.get('Case number'))){
                keyValueMap.put('Result', 'FALSE');
                keyValueMap.put('Message', 'Invalid Case Number');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                continue;
            }
            if(caseNumberToCaseMap.get(keyValueMap.get('Case number')).IsClosed == true){
                keyValueMap.put('Result', 'FALSE');
                keyValueMap.put('Message', 'Case is already '+caseNumberToCaseMap.get(keyValueMap.get('Case number')).Stage__c);
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                continue;
            }
            Case caseRec = caseNumberToCaseMap.get(keyValueMap.get('Case number'));
            if(keyValueMap.get('Stage') == 'Resolved'){
                caseRec.Stage__c = keyValueMap.get('Stage');
                caseRec.Pending_Clarification__c = false;
                caseRec.moved_back__c = false;
                caseRec.Is_Manual_Moved__c = true;
                caseRec.Resolution_Comments__c = keyValueMap.get('Resolution Comments');
            }else if(keyValueMap.get('Stage') == 'Unresolved'){
                caseRec.Stage__c = keyValueMap.get('Stage');
                caseRec.Reject_Case__c = true;
                caseRec.Rejected_Reason__c = keyValueMap.get('Close Unresolved Details');
                caseRec.Rejection_Reason__c = keyValueMap.get('Close Unresolved Reason');
            }else{
                keyValueMap.put('Result', 'FALSE');
                keyValueMap.put('Message', 'Invalid Stage');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                continue;
            }
            //Any other BU specific checks - add here
            resultWrapper.resultRecords.put(lineItemId, caseRec);
            resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
        }

        return resultWrapper;
    }
}