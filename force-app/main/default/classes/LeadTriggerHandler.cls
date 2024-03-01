/*********************************************************
*Class        :  LeadTriggerHandler
*Author       :  Vishal Gangwar
*Created Date :  27/02/2024
*Description  :  Trigger Handler for Lead 
*********************************************************/
public with sharing class LeadTriggerHandler extends ASF_VTriggerHandler {
  public static Boolean TriggerDisabled = false;
    public override void AfterInsert(map<Id, sObject> newItems) {
      if(!TriggerDisabled){
            LeadTriggerHelper.sendLeadToCRM((Map<Id,Lead>)newItems); 
        } 
    }
}