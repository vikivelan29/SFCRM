trigger ASF_CaseTrigger on Case (before insert,after insert,before update,after update,before delete,after delete, after undelete) {

    if(FeatureManagement.checkPermission('By_Pass_Trigger')){
        return;
    }
    
    TriggerDispatcher.Run(new ASF_CaseTriggerHandler2());
    
}