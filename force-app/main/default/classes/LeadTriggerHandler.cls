/*********************************************************
*Class        :  LeadTriggerHandler
*Author       :  Vishal Gangwar
*Created Date :  27/02/2024
*Description  :  Trigger Handler for Lead 
*********************************************************/

@SuppressWarnings('PMD.ApexDoc')
public with sharing class LeadTriggerHandler extends ASF_VTriggerHandler {
  public static Boolean triggerDisabled = false;
  public override void AfterInsert(map<Id, sObject> newItems) {
    if(!triggerDisabled){
          LeadTriggerHelper.sendLeadToCRM((Map<Id,Lead>)newItems); 
    } 
  }

  @SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
  /*********************************************************
  * @Function - BeforeInsert
  * @param - newItems
  * @return - void
  * @description -  Sending Leads to LeadTriggerHelper Class
  */
  public override void BeforeInsert(List<SObject> newItems){

    if(!triggerDisabled){
      LeadTriggerHelper leadTriggerHelperObj = new LeadTriggerHelper();
      leadTriggerHelperObj.populateLeadFields((List<Lead>) newItems); 
    }
  }
}