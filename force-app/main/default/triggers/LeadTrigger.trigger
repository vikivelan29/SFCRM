trigger LeadTrigger on Lead (before insert, after insert) {
    if(FeatureManagement.checkPermission('By_Pass_Trigger')){
        return;
    }

    TriggerDispatcher.Run(new LeadTriggerHandler());
}