/**
 * @description       : 
 * @author            : nikhil.patewar@in.ey.com
 * @group             : 
 * @last modified on  : 28-11-2024
 * @last modified by  : nikhil.patewar@in.ey.com
 * Modifications Log
 * Ver   Date(DD-MM)  Author                    Modification
 * 1.0   28-11-2024   nikhil.patewar@in.ey.com   Initial Version
**/
public class ABFL_CRMToUNFYDFeedbackTriggerHelper {
	public static void afterInsertMethod(List<CRM_to_UNFYD_Feedback_Event__e> newRecords){
        // Fetch case integration records
        Set<String> ciNameSet = new Set<String>();
        for (CRM_to_UNFYD_Feedback_Event__e event : newRecords) {
            ciNameSet.add(event.Case_Integration_ID__c);
        }
        
        Map<String, ASF_Case_Integration__c> ciMap = new Map<String, ASF_Case_Integration__c>();
        for(ASF_Case_Integration__c rec: [Select Id,Name, Request__c from ASF_Case_Integration__c where Name IN :ciNameSet with SYSTEM_MODE]){
            ciMap.put(rec.Name, rec);
        }
        
        // Prepare records to update
        List<ASF_Case_Integration__c> ciUpdateList = new List<ASF_Case_Integration__c>();
        for (CRM_to_UNFYD_Feedback_Event__e event : newRecords) {
            ASF_Case_Integration__c ci = ciMap.get(event.Case_Integration_ID__c);
            ci.Request__c = JSON.serialize(event);
            ciUpdateList.add(ci);
        }
        
        if (Schema.sObjectType.ASF_Case_Integration__c.isCreateable() && ciUpdateList.size() > 0){
            update ciUpdateList;
        }   
    }
}