trigger ASF_ContentDocumentLinkTrigger on ContentDocumentLink (before insert,after insert,before update,after update,before delete,after delete, after undelete) {
    TriggerDispatcher.Run(new ASF_ContentDocLinkTriggerHandler());
    
}