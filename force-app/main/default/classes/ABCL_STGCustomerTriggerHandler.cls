public class ABCL_STGCustomerTriggerHandler extends ASF_VTriggerHandler {
    
    public override void AfterInsert(map<Id, sObject> newSTGCustomer) {
        ABCL_STGCustomerTriggerHelper.executePlatformEvent((Map<Id,STG_Customer__c>) newSTGCustomer);
    }
    

}