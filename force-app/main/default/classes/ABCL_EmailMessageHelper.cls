/*********************************************************
* Class        : ABCL_EmailMessageHelper
* Author       : Aditya Mehrotra
* Created Date : 11/29/2023
* Last Modified: 12/04/2023
* @description  : Class for EBOT API call.
*********************************************************/
public with sharing class ABCL_EmailMessageHelper {
    
    public static Set<String> originSet = new Set<String>{'ABHFL Email', 'ABFL Email','Payments Email','ABWM Email','ABFL WM CHAT','ABSLI Email','ABSLIG Email'}; //PR970457-91 Added 'ABFL Email' to execute the logic for ABFL        
        /****************************************************************************************************************
* @LOB - ABHFL
* @Function - ebotHandler
* @param newEmails - map of cases from trigger.newMap.
* @description - Invoked from AfterInsert method, this method calls EBOT to send details of cases created from emails.
*****************************************************************************************************************/
        public static void ebotHandler(Map<Id, sObject> newEmails) {
            // Find eligible records
            Map<Id, EmailMessage> caseEmailsMap = new Map<Id, EmailMessage>();
            Set<Id> caseIds = new Set<Id>();
            List<Case> csList  = new List<Case>();
            
            for (EmailMessage email : (List<EmailMessage>) newEmails.values()) {
                boolean bReplyOnClosedCase = false;
                //System.debug('ASF_EmailMessageHelper.bNewCaseByReplyToCloseCase --> '+ASF_EmailMessageHelper.bNewCaseByReplyToCloseCase);
                if(ASF_EmailMessageHelper.bNewCaseByReplyToCloseCase){
                    bReplyOnClosedCase = ASF_EmailMessageHelper.bNewCaseByReplyToCloseCase;
                }
                 if (String.isNotBlank(email.ParentId) && email.ParentId.getSObjectType() == Case.getSObjectType() && 
                     email.Incoming == true && email.Send_To_Ebot__c == true && 
                    ((String.isBlank(email.Headers)|| !email.Headers.contains('In-Reply-To:') || bReplyOnClosedCase ) ||
                    (email.Headers != null && email.Headers.contains('In-Reply-To:') && email.ReplyToEmailMessageId == null ))){
                        caseIds.add(email.ParentId);
                        caseEmailsMap.put(email.ParentId, email);
                }
            }
            
            // Map<Id, List<EmailMessage>> caseEmailsMap = new Map<Id, List<EmailMessage>>();
            // for (EmailMessage email : [SELECT Id, ParentId FROM EmailMessage WHERE ParentId IN :caseIds]) {
            //     if (caseEmailsMap.containsKey(email.ParentId)) {
            //         caseEmailsMap.get(email.ParentId).add(email);
            //     } else {
            //         caseEmailsMap.put(email.ParentId, new List<EmailMessage>{email});
            //     }
            // }
            
            for (Case c : [SELECT Id, CaseNumber, Origin, CCC_External_Id__c,SuppliedEmail, Technical_Source__c, Business_Unit__c FROM Case WHERE ID IN :caseIds WITH SYSTEM_MODE ]) 
            {
                /*
* * 1. Condition to check first Email Message for a case
* * 2. ASF_CasePreFrameworkTriggerHelper - Pre-framework logic sets Technical_Source__c as 'Email'
*/
                if (String.isBlank(c.CCC_External_Id__c) && c.Technical_Source__c == 'Email' 
                    && originSet.contains(c.Origin) && c.Business_Unit__c != null) 
                {
                    EmailMessage email = caseEmailsMap.get(c.Id);
                    
                    Map<String, String> fieldsMap = new Map<String, String>();
                    fieldsMap.put('Email_Message_ID__c', email.Id);
                    // Invoke Internal PE - This is required as content documents information is not persisted in initial transaction
                    Database.SaveResult eventResult = ABCL_CasePlatformEventHandler.publishPlatformEvent('EBOT_Internal_Event__e', fieldsMap);
                    c.Sent_to_EBOT__c = true;
                    csList.add(c);
                }
            }
            
            if(csList.size() > 0 && Schema.sObjectType.Case.isUpdateable()){
                ASF_TriggerSkipperUtility.markTriggerRun('Case');
                update csList;
            }
        }
      /****************************************************************************************************************
* @Function - getEligibles
* @param emails 
* @return  List<EmailMessage>
* @description - getEligibles 
*****************************************************************************************************************/
    public static List<EmailMessage> getEligibles(List<EmailMessage> emails){
        List<EmailMessage> lEMessages = new List<EmailMessage>();
        for (EmailMessage email : emails) {
            if (String.isNotBlank(email.ParentId) && email.ParentId.getSObjectType() == Case.getSObjectType() && 
            email.Incoming == true && ((String.isBlank(email.Headers)|| !email.Headers.contains('In-Reply-To:')) ||
           (email.Headers != null && email.Headers.contains('In-Reply-To:') && email.ReplyToEmailMessageId == null ))){
                lEMessages.add(email);
            }
        }
        return lEMessages;
    }
}