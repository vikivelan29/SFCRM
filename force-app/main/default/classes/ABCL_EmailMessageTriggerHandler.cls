/*********************************************************
*Class        :  ABHFL_EmailMessageHandler
*Author       :  Siddarth Jaitly
*Created Date :  28/11/2023
*Last Modified:  30/11/2023
*Description  :  Trigger Handler for Email Message 
*********************************************************/
public with sharing class ABCL_EmailMessageTriggerHandler extends ASF_VTriggerHandler {
    
    public override void beforeInsert(List<SObject> newItems){
        ASF_EmailMessageHelper.validateIfGoingFromAuthorizedAddress(newItems);
    }
    
    
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - AfterInsert
    * @param newEmails - map of cases from trigger.newMap()
    * @return - void .
    * @Description - After Insert Handler for Email Message
    *****************************************************************************************************************/        
    public override void AfterInsert(map<Id, sObject> newEmails){
		ABHFL_EmailMessageHelper.ebotHandler(newEmails);
    }
    
    
}