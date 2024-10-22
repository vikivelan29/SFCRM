trigger RNWL_CollectionTrigger on Collections__c (after Insert) {
    TriggerDispatcher.Run(new RNWL_CollectionTriggerHandler());
}