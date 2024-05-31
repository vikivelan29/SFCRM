/*********************************************************
*Class        :  ABCL_AssetTriggerHandler
*Author       :  Shubham Sinha
*Created Date :  16/01/2024
*Description  :  Trigger Handler for Asset 
*********************************************************/
public with sharing class ABCL_AssetTriggerHandler extends ASF_VTriggerHandler {
	public static Boolean TriggerDisabled = false;
    public override void beforeUpdate(map<Id, sObject> newItems,map<Id, sObject> oldItems) {
    	if(!TriggerDisabled){
            ABCL_AssetTriggerHelper.updateRmAssignment((Map<Id,Asset>)oldItems,(Map<Id,Asset>)newItems); 
        } 
    }
}