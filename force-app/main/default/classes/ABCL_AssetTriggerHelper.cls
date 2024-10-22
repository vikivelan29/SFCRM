/*********************************************************
*Class        :  ABCL_AssetTriggerHelper
*Author       :  Shubham Sinha
*Created Date :  16/01/2024
*@description  :  Trigger helper for Asset 
*********************************************************/
public class ABCL_AssetTriggerHelper {
/****************************************************************************************************************
* @LOB - Abfl
* @function - updateRmAssignment
* @param newAssetMap - new asset map values.
* @param oldAssetMpa - old asset map values.
* @return - void.
* @description - Update RM_Assignment__c field to Pending if RM_Code__c is updated.
*****************************************************************************************************************/
	public static void updateRmAssignment(Map<Id,Asset> oldAssetMpa,Map<Id,Asset> newAssetMap){ 
        for(Asset  objAsset: newAssetMap.values()){
            if((oldAssetMpa.get(objAsset.Id).RM_Code__c  != objAsset.RM_Code__c && objAsset.Business_Unit__c == 'ABFL' && objAsset.RM_Assignment__c == 'Processed')||oldAssetMpa.get(objAsset.Id).RM_Assignment__c  ==null && objAsset.Business_Unit__c == 'ABFL'){
            	objAsset.RM_Assignment__c = 'Pending';
        	}    
    	}
	}
    
/****************************************************************************************************************
* @LOB - ABSLI
* @function - updateProccessingState
* @param newAssetMap - new asset map values.
* @param oldAssetMpa - old asset map values.
* @return - void.
* @description - Update Processing_State__c field to Pending if VRM Conditions are satisfied.
*****************************************************************************************************************/
    public static void updateProccessingState(Map<Id,Asset> oldAssetMap,Map<Id,Asset> newAssetMap){ 
        for(Asset  objAsset: newAssetMap.values()){
            if(objAsset.Business_Unit__c == 'ABSLI' && (oldAssetMap.get(objAsset.Id).Assign_to_DM__c != objAsset.Assign_to_DM__c || oldAssetMap.get(objAsset.Id).Channel__c  != objAsset.Channel__c || oldAssetMap.get(objAsset.Id).Loyalty_Service_Agent_Name__c   != objAsset.Loyalty_Service_Agent_Name__c)){
            	objAsset.Processing_State__c = 'Pending';
        	}    
    	}
	}
/****************************************************************************************************************
* @LOB - ABSLI
* @function - updateProccessingStateduringInsert
* @param newAssetMap - new asset map values.
* @return - void.
* @description - Update Processing_State__c field to Pending if VRM Conditions are satisfied.
*****************************************************************************************************************/
    public static void updateProccessingStateduringInsert(List<Asset> newItems){ 
        for(Asset objAsset: newItems){
            if(objAsset.Business_Unit__c == 'ABSLI' && (objAsset.Assign_to_DM__c == 'Yes' || objAsset.Channel__c == 'DM' || objAsset.Loyalty_Service_Agent_Name__c != null)){
            	objAsset.Processing_State__c = 'Pending';
        	}    
    	}
	}
}