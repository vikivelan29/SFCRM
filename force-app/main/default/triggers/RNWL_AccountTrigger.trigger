trigger RNWL_AccountTrigger on Account (After update) {
	
    TriggerDispatcher.Run(new RNWL_AccountTriggerHandler());
    
}