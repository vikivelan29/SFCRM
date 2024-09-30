/*********************************************************
*Class        :  ABHFL_EmailMessageHandler
*Author       :  Siddarth Jaitly
*Created Date :  28/11/2023
*Last Modified:  30/11/2023
*@description  :  Trigger Handler for Email Message 
*********************************************************/
public with sharing class ABCL_EmailMessageTriggerHandler extends ASF_VTriggerHandler {
    
    public override void beforeInsert(List<SObject> newItems){
        //ASF_EmailMessageHelper.validateIfGoingFromAuthorizedAddress(newItems);
        //ABCL_SendEmailValidation.validateUsersTeam(newItems);
        ASF_EmailMessageHelper.checkIsReplyToCloseCase(newItems);
        
        // VIRENDRA - CODE TO SET WINNING EMAIL ADDRESS.
        ASF_Email2CaseHandler.setPriorityEmailAddress(newItems);
        
        ASF_EmailMessageHelper.checkAndReopenClosedCases(newItems);
        
      //  for(EmailMessage em : (List<EmailMessage>)newItems){
            //System.debug('ASF - emailmessage before'+em);
        //}
    }
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - AfterInsert
    * @param newEmails - map of cases from trigger.newMap()
    * @description - After Insert Handler for Email Message
    *****************************************************************************************************************/        
    public override void AfterInsert(map<Id, sObject> newEmails){

        // set of qualified email messages
        Set<Id> sEMIds = new Set<Id>();
        for(EmailMessage mesg: (List<EmailMessage>)newEmails.values()){
            if(mesg.Incoming==true && mesg.ParentId.getSObjectType() == Case.sObjectType){
                sEMIds.add(mesg.Id);
            }
        } 
        //System.debug('***semids:'+sEMIds);
        
        // Check creation rules for ABFL BU - Can't be used in before as we need case details for logic
        ABFL_E2C_CreationRules.checkCreationRules(ABCL_EmailMessageHelper.getEligibles(newEmails.values()));
        
        // VIRENDRA - UPDATEMESSAGEIDENTIFIERONCASE TO AVOID CREATING MULTIPLE CASES WHEN MULTIPLE EMAIL TO CASE ADDRESSES ARE PART OF INCOMING EMAIL.
        ASF_Email2CaseHandler.updateMessageIdentifierOnCase((List<EmailMessage>)newEmails.values());
        
        // IF EVERYTHING IS SUCCESSFUL THEN ONLY TRIGGER EBOT CODE.
        // VIRENDRA - TRIGGER EBOT WHEN EMAIL-TO-CASE ROUTING ADDRESS IS CONFIGURED TO SENDTOEBOT = TRUE
        ABCL_SendEmailValidation.validateUsersTeam(newEmails.values());
        ASF_EmailMessageHelper.validateIfGoingFromAuthorizedAddress(newEmails.values());
        ABCL_EmailMessageHelper.ebotHandler(newEmails);
        // invoke ABFL E2C Case creation checks

        //PR1030924-237 handle cases of customers flagged as handle with care (HWC)
        ABSLAMC_Email2CaseHandler.handleAbslamcHwcEmails(newEmails.values());
        
        // US- PR970457-575(ABWM chat originated cases) WEALTHCHATGENERATED CASES UPDATE SUPPLIED EMAIL WHICH IS ETRACTED FROM EMAIL BODY
        ABFL_WealthChatGeneratedCases.execute(newEmails.values());
        ABSLIG_SendCaseCreationEmail.sendEmailOnCaseCreation(newEmails.values());
        // ABFL_EmailCase_Logic.updateIncomingEmailCount(sEMIds);
        if(sEMIds.size()>0){
            Async_Transaction_Event__e ate = new Async_Transaction_Event__e(
                Payload__c=JSON.serialize(sEMIds),
                ATF_Settings__c='ABFL_IncrementEmailCount',
                Run_By__c=UserInfo.getUserId()
                // UUID__c=UUID.randomUUID()
            );
            EventBus.publish(ate);
        }
    } 
    public override void beforeUpdate(Map<Id, SObject> newItemsCase, Map<Id, SObject> oldItems) {
        ABCL_SendEmailValidation.validateUsersTeam(newItemsCase.values());
        ASF_EmailMessageHelper.validateIfGoingFromAuthorizedAddress(newItemsCase.values());
    }
}