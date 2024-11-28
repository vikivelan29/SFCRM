trigger ASF_CaseCommentTrigger on CaseComment (before insert,after insert,before update,after update,before delete,after delete, after undelete) {
    TriggerDispatcher.Run(new ASF_CaseCommentTriggerHandler());
    
}