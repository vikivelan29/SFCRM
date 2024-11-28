trigger ABCL_AssetTrigger on Asset (before update, before insert) {

    TriggerDispatcher.Run(new ABCL_AssetTriggerHandler());
}