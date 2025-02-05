/*********************************************************
*Class        :  ABSLAMC_CaseDetailTriggerHandler
*Author       :  Neeraj Kumar
*Created Date :  02-09-2024
*@description  :  Handler class for ABSLAMC_Case_Detail__c Trigger
*********************************************************/
public class ABSLAMC_CaseDetailTriggerHandler extends ASF_VTriggerHandler{
    
    public override void afterUpdate(Map<Id,SObject> newItems, Map<Id,SObject> oldItems) {
        ABSLAMC_CaseDetailTriggerHelper.createCaseComments((Map<Id,ABSLAMC_Case_Detail__c>)newItems,(Map<Id,ABSLAMC_Case_Detail__c>)oldItems);
    }
}