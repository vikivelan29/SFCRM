/*********************************************************
*Class        :  ABCL_CaseIntegratnOutEventTriggerHelper
*Author       :  Udit Singhal
*Created Date :  19/01/2024
*Last Modified:
*Test Class   :  ABCL_CaseIntegratnOutEvntTriggerHelpTest
*Description  :  ABCL_CaseIntegratnOutEventTrigger helper class
*********************************************************/
public without sharing class ABCL_CaseIntegratnOutEventTriggerHelper{
    
    /****************************************************************************************************************
* @LOB - ABFL
* @Function - afterInsertMethod
* @param List<Case_Integration_Outbound__e> List of new reords from trigger
* @return - void
* @Description - Function to store payload after publishing of Case_Integration_Outbound__e event
*****************************************************************************************************************/
    public static void afterInsertMethod(List<Case_Integration_Outbound__e> newRecords){
        try {
            // Fetch case integration records
            Set<String> ciNameSet = new Set<String>();
            
            for (Case_Integration_Outbound__e event : newRecords){
                ciNameSet.add(event.Case_Integration_ID__c);
            }
            
            Map<String, ASF_Case_Integration__c> ciMap = new Map<String, ASF_Case_Integration__c>();
            
            for (ASF_Case_Integration__c rec : [SELECT Id, Name, Request__c
                                                FROM ASF_Case_Integration__c
                                                WHERE Name IN :ciNameSet
                                                WITH SYSTEM_MODE]){
                                                    ciMap.put(rec.Name, rec);
                                                }
            
            // Prepare records to update
            List<ASF_Case_Integration__c> ciToUpdateList = new List<ASF_Case_Integration__c>();
            for (Case_Integration_Outbound__e event : newRecords){
                EventFailureWrapper evntFailureWrapper = new EventFailureWrapper(event);
                
                // update Case Integration record
                ASF_Case_Integration__c caseIntegrationRecord = ciMap.get(event.Case_Integration_ID__c);
                caseIntegrationRecord.Request__c = JSON.serialize(evntFailureWrapper);
                ciToUpdateList.add(caseIntegrationRecord);
            }
            
            if (ciToUpdateList.size() > 0 && Schema.sObjectType.ASF_Case_Integration__c.isUpdateable()){
                update ciToUpdateList;
            }
        } catch(Exception e) {
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABCL_CaseIntegratnOutEventTriggerHelper.afterInsertMethod');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
        }
    }
    
    public class EventFailureWrapper{
        public String businessUnit;
        public String caseIntegrationID;
        public String integrationName;
        public String requestPayload;
        public String serviceName;
        
        public EventFailureWrapper(Case_Integration_Outbound__e event){
            this.businessUnit = event.Business_Unit__c;
            this.caseIntegrationID = event.Case_Integration_ID__c;
            this.integrationName = event.Integration_Name__c;
            this.requestPayload = event.Request_Payload__c;
            this.serviceName = event.ServiceName__c;
        }
        
    }
    
}