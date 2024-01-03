/*********************************************************
*Class        :  ABCL_EbotTriggerHandler
*Author       :  Siddarth Jaitly
*Created Date :  06/12/2023
*Last Modified:  06/12/2023
*Description  :  Trigger Handler for EBOT Internal Event
*********************************************************/
public class ABCL_EbotTriggerHandler extends ASF_VTriggerHandler{
    /****************************************************************************************************************
    * @LOB - Common
    * @Function - AfterInsert
    * @param newEmails - map of event from trigger.newMap()
    * @return - void .
    * @Description - After Insert Handler for EBOT Internal Event
    *****************************************************************************************************************/     
    public override void AfterInsert(map<Id, sObject> newEvent){
        ABCL_EbotTriggerHelper.createExtEbotEvent(newEvent);
    }
}