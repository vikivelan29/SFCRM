/*********************************************************
* Class        : ABCL_EmailMessageHelper
* Author       : Aditya Mehrotra
* Created Date : 11/29/2023
* Last Modified: 12/04/2023
* Description  : Class for EBOT API call.
*********************************************************/
public with sharing class ABCL_EmailMessageHelper {
    
    public static Set<String> originSet = new Set<String>{'ABHFL Email', 'ABFL Email'}; //PR970457-91 Added 'ABFL Email' to execute the logic for ABFL
        
        /****************************************************************************************************************
* @LOB - ABHFL
* @Function - ebotHandler
* @param newEmails - map of cases from trigger.newMap.
* @return - void.
* @Description - Invoked from AfterInsert method, this method calls EBOT to send details of cases created from emails.
*****************************************************************************************************************/
        public static void ebotHandler(Map<Id, sObject> newEmails) {
            // Find eligible records
            Map<Id, EmailMessage> caseEmailsMap = new Map<Id, EmailMessage>();
            Set<Id> caseIds = new Set<Id>();
            
            for (EmailMessage email : (List<EmailMessage>) newEmails.values()) {
                if (String.isNotBlank(email.ParentId) && (String.isBlank(email.Headers) ||( email.Headers != null && 
                    !email.Headers.contains('In-Reply-To:')))
                    && email.ParentId.getSObjectType() == Case.getSObjectType()
                    && email.Incoming == true && email.Send_To_Ebot__c == true){ 
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
            
            for (Case c : [SELECT Id, CaseNumber, Origin, CCC_External_Id__c,SuppliedEmail, Technical_Source__c, Business_Unit__c FROM Case WHERE ID IN :caseIds]) 
            {
                /*
* * 1. Condition to check first Email Message for a case
* * 2. ASF_CasePreFrameworkTriggerHelper - Pre-framework logic sets Technical_Source__c as 'Email'
*/
                if (String.isBlank(c.CCC_External_Id__c) && c.Technical_Source__c == 'Email' 
                    && originSet.contains(c.Origin) && c.Business_Unit__c != null) 
                {
                    EmailMessage email = caseEmailsMap.get(c.Id);
                    
                    // VIRENDRA - SEND TO EBOT IF THE EMAIL ADDRESS IS MARKED FOR EBOT INTEGRATION ONLY.
                    if(ASF_Email2CaseHandler.mEbotTriggerMap.containsKey(email.MessageIdentifier)){
                        boolean sendToEbot = ASF_Email2CaseHandler.mEbotTriggerMap.get(email.MessageIdentifier);
                        System.debug('sendToEbot ---> '+sendToEbot);
                        if(!sendToEbot){ 
                            continue;
                        }
                    }
                    // VIRENDRA - ENDS HERE.
                    
                    Map<String, String> fieldsMap = new Map<String, String>();
                    fieldsMap.put('Email_Message_ID__c', email.Id);
                    // Invoke Internal PE - This is required as content documents information is not persisted in initial transaction
                    Database.SaveResult eventResult = ABCL_CasePlatformEventHandler.publishPlatformEvent('EBOT_Internal_Event__e', fieldsMap);
                }
            }
        }
    
    
}