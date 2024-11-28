trigger ASF_ContentDocumentLinkTrigger on ContentDocumentLink (before delete) {
    TriggerDispatcher.Run(new ASF_ContentDocLinkTriggerHandler());
    
}