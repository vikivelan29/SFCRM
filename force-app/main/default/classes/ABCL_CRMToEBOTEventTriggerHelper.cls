public class ABCL_CRMToEBOTEventTriggerHelper {
    public static void afterInsertMethod(List<CRM_to_EBOT_Event__e> newRecords){
        // Fetch case integration records
        Set<String> ciNameSet = new Set<String>();
        for (CRM_to_EBOT_Event__e event : newRecords) {
            System.debug('Event: ' + event);
            ciNameSet.add(event.Case_Integration_ID__c);
        }
        Map<String, ASF_Case_Integration__c> ciMap = new Map<String, ASF_Case_Integration__c>();
        for(ASF_Case_Integration__c rec: [Select Id,Name, Request__c from ASF_Case_Integration__c where Name IN :ciNameSet]){
            ciMap.put(rec.Name, rec);
        }
        
        // Prepare records to update
        List<ASF_Case_Integration__c> ciUpdateList = new List<ASF_Case_Integration__c>();
        for (CRM_to_EBOT_Event__e event : newRecords) {
            ASF_Case_Integration__c ci = ciMap.get(event.Case_Integration_ID__c);
            ci.Request__c = JSON.serialize(event);
            ciUpdateList.add(ci);
        }
        
        if (ciUpdateList.size() > 0) {
            update ciUpdateList;
        }   
    }
}