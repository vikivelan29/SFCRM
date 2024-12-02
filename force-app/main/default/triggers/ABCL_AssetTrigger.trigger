/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-23-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger ABCL_AssetTrigger on Asset (before update, before insert) {

    TriggerDispatcher.Run(new ABCL_AssetTriggerHandler());
}