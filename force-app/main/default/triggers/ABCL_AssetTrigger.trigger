trigger ABCL_AssetTrigger on Asset (before update) {

    TriggerDispatcher.Run(new ABCL_AssetTriggerHandler());
}