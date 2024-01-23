/*********************************************************
*Class        :  ABCL_AssetTriggerHelper
*Author       :  Shubham Sinha
*Created Date :  16/01/2024
*Description  :  Trigger helper for Asset 
*********************************************************/
public class ABCL_AssetTriggerHelper {
/****************************************************************************************************************
* @LOB - Abfl
* @Function - updateRmAssignment
* @return - void.
* @Description - Update RM_Assignment__c field to Pending if RM_Code__c is updated.
*****************************************************************************************************************/
	public static void updateRmAssignment(Map<Id,Asset> oldAssetMpa,Map<Id,Asset> newAssetMap){ 
        for(Asset  objAsset: newAssetMap.values()){
            if(oldAssetMpa.get(objAsset.Id).RM_Code__c  != objAsset.RM_Code__c && objAsset.Business_Unit__c == 'ABFL' && objAsset.RM_Assignment__c == 'Processed'){
            	objAsset.RM_Assignment__c = 'Pending';
        	}    
    	}
	}
}