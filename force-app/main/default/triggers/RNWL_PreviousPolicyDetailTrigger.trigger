trigger RNWL_PreviousPolicyDetailTrigger on Previous_Policy_Details__c (after Insert) {
    TriggerDispatcher.Run(new RNWL_PreviousPolicyDetailTriggerHandler());
}