trigger ASF_CaseSLAHistoryTrigger on ASF_Case_SLA_History__c (before insert, after insert) {
    
    //By Pass Trigger: If user is having By_Pass_Trigger custom permission trigger will by pass.
    if(FeatureManagement.checkPermission('By_Pass_Trigger')){return;}
    
    TriggerDispatcher.Run(new ASF_CaseSLAHistoryTriggerHandler());
}