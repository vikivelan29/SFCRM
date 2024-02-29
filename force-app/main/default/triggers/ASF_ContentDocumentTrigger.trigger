trigger ASF_ContentDocumentTrigger on ContentDocument (before insert,after insert,before update,after update,before delete,after delete, after undelete) {
    TriggerDispatcher.Run(new ASF_ContentDocumentTriggerHandler());
    
}