trigger LeadTrigger on Lead (after insert) {
    if(FeatureManagement.checkPermission('By_Pass_Trigger')){
        return;
    }

    TriggerDispatcher.Run(new LeadTriggerHandler());
}