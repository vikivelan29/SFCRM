/***************************************************************************
*Class          :  RNWL_PreviousPolicyDetailTriggerHandler
*Author         :  Gaurav Sharma
*Created Date   :  07/10/2024
*Last Modified  :  07/10/2024
*@description   :  Trigger Handler for Previous_Policy_Details__c object
****************************************************************************/

public with sharing class RNWL_PreviousPolicyDetailTriggerHandler extends ASF_VTriggerHandler {
    private Boolean isTriggerDisabled(){
        return isDisabled('Prev_Policy_Detail');
    }
    
    public override void afterInsert(Map<Id, SObject> newRecordsMap) {
        if(isTriggerDisabled()){return;}
        RNWL_PreviousPolicyDetailTriggerHelper.updateRelatedOpportunities(newRecordsMap.values());
    }  
}