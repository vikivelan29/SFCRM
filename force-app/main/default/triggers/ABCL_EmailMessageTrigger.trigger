trigger ABCL_EmailMessageTrigger on EmailMessage (before insert,after insert,before update,after update,before delete,after delete, after undelete) {

    TriggerDispatcher.Run(new ABCL_EmailMessageTriggerHandler());
    
}