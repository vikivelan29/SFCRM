/*********************************************************
*Class        :  ABCL_EbotTriggerHandler
*Author       :  Siddarth Jaitly
*Created Date :  06/12/2023
*Last Modified:  06/12/2023
*@description  :  Trigger Handler for EBOT Internal Event
*********************************************************/
public class ABCL_EbotTriggerHandler extends ASF_VTriggerHandler{
    /****************************************************************************************************************
    * @LOB - Common
    * @Function - AfterInsert
    * @param newEvent - map of event from trigger.newMap()
    * @description - After Insert Handler for EBOT Internal Event
    *****************************************************************************************************************/     
    public override void AfterInsert(map<Id, sObject> newEvent){
        ABHFL_EbotTriggerHelper.createExtEbotEvent(newEvent);
    }
}