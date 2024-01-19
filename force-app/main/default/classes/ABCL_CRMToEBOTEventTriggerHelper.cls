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
            System.debug('***Event: ' + event);
            eventFailureWrapper efw = new eventFailureWrapper();
            efw.Additional_Emails = event.Additional_Emails__c;
            efw.Business_Unit = event.Business_Unit__c;
            efw.Case_Integration_ID = event.Case_Integration_ID__c;
            efw.Case_Number = event.Case_Number__c;
            efw.Description = event.Description__c;
            efw.File_Names = event.File_Names__c;
            efw.From_Address = event.From_Address__c;
            efw.Integration_Name = event.Integration_Name__c;
            efw.Subject = event.Subject__c;
            efw.To_Address = event.To_Address__c;
            // update Case Integration record
            System.debug('***efw: ' + efw);
            ASF_Case_Integration__c ci = ciMap.get(event.Case_Integration_ID__c);
            System.debug('***ci: ' + ci);
            ci.Request__c = JSON.serialize(efw);
            ciUpdateList.add(ci);
        }
        
        if (ciUpdateList.size() > 0) {
            update ciUpdateList;
        }   
    }
    public class eventFailureWrapper{
        public String Additional_Emails;
        public String Business_Unit;
        public String Case_Integration_ID;
        public String Description;
        public String File_Names;
        public String From_Address;
        public String Integration_Name;
        public String Subject;
        public String To_Address;
        public String Case_Number;
    }
}