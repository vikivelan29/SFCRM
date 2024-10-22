/************************************************************
*Class          :  RNWL_CollectionTriggerHandler
*Author         :  Gaurav Sharma
*Created Date   :  21/10/2024
*Last Modified  :  21/10/024
*@description   :  Trigger handler for Collections__c Object
*************************************************************/
public with sharing class RNWL_CollectionTriggerHandler extends ASF_VTriggerHandler{
    
    private Boolean isTriggerDisabled(){
        return isDisabled('Collection');
    }


    public override void afterInsert(Map<Id,SObject> newCollectionMap) {
        if(isTriggerDisabled()){return;}
        RNWL_CollectionTriggerHelper.updateRenewalRequest(newCollectionMap.values());
    }
}