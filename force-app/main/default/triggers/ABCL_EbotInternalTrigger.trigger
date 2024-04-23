trigger ABCL_EbotInternalTrigger on EBOT_Internal_Event__e (after insert) {
    
    TriggerDispatcher.Run(new ABCL_EbotTriggerHandler());
    
}