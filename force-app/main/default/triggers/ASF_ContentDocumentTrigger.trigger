trigger ASF_ContentDocumentTrigger on ContentDocument (before insert,before update,before delete) {
    TriggerDispatcher.Run(new ASF_ContentDocumentTriggerHandler());
    
}