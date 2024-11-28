/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 05-13-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   03-27-2024   rsinghnagar@salesforce.com   Initial Version
**/
public without sharing class ABCL_CRMToEBOTEventTriggerHelper {
    /**
    * @description : after insert hander
    * @author rsinghnagar@salesforce.com | 05-11-2024 
    * @param newRecords
    **/
    public static void afterInsertMethod(List<CRM_to_EBOT_Event__e> newRecords){
        // Fetch case integration records
        Set<String> ciNameSet = new Set<String>();
        for (CRM_to_EBOT_Event__e event : newRecords) {
            ciNameSet.add(event.Case_Integration_ID__c);
        }
        Map<String, ASF_Case_Integration__c> ciMap = new Map<String, ASF_Case_Integration__c>();
        for(ASF_Case_Integration__c rec: [Select Id,Name, Request__c from ASF_Case_Integration__c where Name IN :ciNameSet with SYSTEM_MODE]){
            ciMap.put(rec.Name, rec);
        }
        
        // Prepare records to update
        List<ASF_Case_Integration__c> ciUpdateList = new List<ASF_Case_Integration__c>();
        for (CRM_to_EBOT_Event__e event : newRecords) {
            ASF_Case_Integration__c ci = ciMap.get(event.Case_Integration_ID__c);
            ci.Request__c = JSON.serialize(event);
            ciUpdateList.add(ci);
        }
        
        if (Schema.sObjectType.ASF_Case_Integration__c.isCreateable() && ciUpdateList.size() > 0){
            update ciUpdateList;
        }   
    }
}