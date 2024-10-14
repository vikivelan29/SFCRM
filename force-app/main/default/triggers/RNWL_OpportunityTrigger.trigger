trigger RNWL_OpportunityTrigger on Opportunity (before insert,after insert, before update, After update) {
    
    TriggerDispatcher.Run(new RNWL_OpportunityTriggerHandler());

}