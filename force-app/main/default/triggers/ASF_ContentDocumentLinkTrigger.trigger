trigger ASF_ContentDocumentLinkTrigger on ContentDocumentLink (before insert,before delete,after insert) {
    TriggerDispatcher.Run(new ASF_ContentDocLinkTriggerHandler());    
}