trigger RNWL_AccountTrigger on Account (before insert,after insert, before update, After update) {
	
    TriggerDispatcher.Run(new RNWL_AccountTriggerHandler());
    
}