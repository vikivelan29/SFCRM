trigger ABCL_AssetTrigger on Asset (before update) {

    if(FeatureManagement.checkPermission('By_Pass_Trigger')){
        return;
    }

    TriggerDispatcher.Run(new ABCL_AssetTriggerHandler());
}