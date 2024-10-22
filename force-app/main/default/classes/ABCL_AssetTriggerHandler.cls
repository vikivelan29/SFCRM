/*********************************************************
*Class        :  ABCL_AssetTriggerHandler
*Author       :  Shubham Sinha
*Created Date :  16/01/2024
*@description  :  Trigger Handler for Asset 
*********************************************************/
public with sharing class ABCL_AssetTriggerHandler extends ASF_VTriggerHandler {
	public static Boolean TriggerDisabled = false;
    public override void beforeUpdate(map<Id, sObject> newItems,map<Id, sObject> oldItems) {
    	if(!TriggerDisabled){
            ABCL_AssetTriggerHelper.updateRmAssignment((Map<Id,Asset>)oldItems,(Map<Id,Asset>)newItems);
            ABCL_AssetTriggerHelper.updateProccessingState((Map<Id,Asset>)oldItems,(Map<Id,Asset>)newItems);
        } 
    }
    public override void beforeInsert(List<SObject> newItems) {
    	if(!TriggerDisabled){
            ABCL_AssetTriggerHelper.updateProccessingStateduringInsert(newItems);
        } 
    }
}