trigger RNWL_DispositionsTrigger on Dispositions__c (before insert,after insert) {
    TriggerDispatcher.Run(new RNWL_DispositionsTriggerHandler());
}