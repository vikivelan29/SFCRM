trigger ASF_ContentDocumentLinkTrigger on ContentDocumentLink (before insert,before delete) {
    TriggerDispatcher.Run(new ASF_ContentDocLinkTriggerHandler());
    
}