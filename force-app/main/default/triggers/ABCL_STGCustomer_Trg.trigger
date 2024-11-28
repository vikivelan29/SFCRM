trigger ABCL_STGCustomer_Trg on STG_Customer__c (before insert,after insert,before update,after update,before delete,after delete, after undelete) {
    
    if(FeatureManagement.checkPermission('By_Pass_Trigger')){
        return;
    }
    
    TriggerDispatcher.Run(new ABCL_STGCustomerTriggerHandler());
    
}