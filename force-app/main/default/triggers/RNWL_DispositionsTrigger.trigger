trigger RNWL_DispositionsTrigger on Dispositions__c (before insert,after insert, after Update) {
    TriggerDispatcher.Run(new RNWL_DispositionsTriggerHandler());
}