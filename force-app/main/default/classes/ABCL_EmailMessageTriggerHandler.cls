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
        //ABCL_SendEmailValidation.validateUsersTeam(newItems);
        //ASF_EmailMessageHelper.checkAndReopenClosedCases(newItems);
        
        // VIRENDRA - CODE TO SET WINNING EMAIL ADDRESS.
        ASF_Email2CaseHandler.setPriorityEmailAddress(newItems);
        
        for(EmailMessage em : (List<EmailMessage>)newItems){
            System.debug('ASF - emailmessage before'+em);
        }
    }
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - AfterInsert
    * @param newEmails - map of cases from trigger.newMap()
    * @return - void .
    * @Description - After Insert Handler for Email Message
    *****************************************************************************************************************/        
    public override void AfterInsert(map<Id, sObject> newEmails){
        
        
        // VIRENDRA - UPDATEMESSAGEIDENTIFIERONCASE TO AVOID CREATING MULTIPLE CASES WHEN MULTIPLE EMAIL TO CASE ADDRESSES ARE PART OF INCOMING EMAIL.
        ASF_Email2CaseHandler.updateMessageIdentifierOnCase((List<EmailMessage>)newEmails.values());
        // ABFL_E2C_CreationRules.checkCreationRules(newEmails.values());
        
        // IF EVERYTHING IS SUCCESSFUL THEN ONLY TRIGGER EBOT CODE.
        // VIRENDRA - TRIGGER EBOT WHEN EMAIL-TO-CASE ROUTING ADDRESS IS CONFIGURED TO SENDTOEBOT = TRUE
        
        ABCL_EmailMessageHelper.ebotHandler(newEmails);
        // invoke ABFL E2C Case creation checks
        
    }
    
    
}