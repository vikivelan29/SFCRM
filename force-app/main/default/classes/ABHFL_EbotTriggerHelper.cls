/*********************************************************
*Class        :  ABHFL_EbotTriggerHelper
*Author       :  Siddarth Jaitly
*Created Date :  06/12/2023
*Last Modified:  06/12/2023
*Description  :  Trigger Helper for EBOT Internal Event
*********************************************************/
public with sharing class ABHFL_EbotTriggerHelper {
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - createExtEbotEvent
    * @param newEmails - map of event from trigger.newMap()
    * @return - void .
    * @Description - Create CRM to EBOT Event 
    *****************************************************************************************************************/     
    public static void createExtEbotEvent(map<Id, sObject> newEvent){
        Set<Id> emailMsgIds = new Set<Id>();
        for(EBOT_Internal_Event__e request : (List<EBOT_Internal_Event__e>)newEvent.values()){
            emailMsgIds.add(request.Email_Message_ID__c);
        }

        Map<Id,EmailMessage> emailMsgMap = new Map<Id,EmailMessage>([Select Contentdocumentids,HasAttachment,CCAddress,FromAddress,ToAddress,BCCAddress,ParentId,Parent.Description,
        Parent.CaseNumber,Parent.Subject,Parent.Origin from EmailMessage where id in: emailMsgIds]);

        List<Id> emailMsgContentDocumentIds = new List<Id>();
        for(EmailMessage eMsg : emailMsgMap.values()){
            if(eMsg.HasAttachment){
                emailMsgContentDocumentIds.addAll(eMsg.ContentDocumentids);
            }
        }

        Map<Id,ContentDocument> contentDocumentMap = new Map<Id,ContentDocument>();
        if(emailMsgContentDocumentIds.size() > 0){
            contentDocumentMap = new Map<Id,ContentDocument>([Select Title,FileExtension from ContentDocument where id in: emailMsgContentDocumentIds]);
        }

        List<ASF_Case_Integration__c> caseIntegrationList = new List<ASF_Case_Integration__c>();

        for(EBOT_Internal_Event__e request : (List<EBOT_Internal_Event__e>)newEvent.values()){
            
            if(emailMsgMap.containsKey(request.Email_Message_ID__c)){
                EmailMessage emailMsg = emailMsgMap.get(request.Email_Message_ID__c);
                ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();    
                caseInt.Case__c = emailMsg.ParentId;
                caseInt.Status__c = 'Pending';
                caseInt.Type__c = 'eBOT';
                caseIntegrationList.add(caseInt);
            }
        }

        if(caseIntegrationList.size() > 0){
            insert caseIntegrationList;   
            Set<Id> caseIntegrationIds = new Set<Id>();
            for(ASF_Case_Integration__c caseInt : caseIntegrationList){
                caseIntegrationIds.add(caseInt.Id);
            }
            List<ASF_Case_Integration__c> caseIntegrationInsertedList = [Select Id,Name,Case__c from ASF_Case_Integration__c where id =:caseIntegrationIds];
            Map<Id,ASF_Case_Integration__c> caseIdCaseIntegrationMap = new Map<Id,ASF_Case_Integration__c>();
            for(ASF_Case_Integration__c caseInt : caseIntegrationInsertedList){
                caseIdCaseIntegrationMap.put(caseInt.Case__c,caseInt);
            }

            for(EBOT_Internal_Event__e request : (List<EBOT_Internal_Event__e>)newEvent.values()){
                if(emailMsgMap.containsKey(request.Email_Message_ID__c)){
                    EmailMessage emailMsg = emailMsgMap.get(request.Email_Message_ID__c);

                    List<String> fileNamesList = new List<String>();
                    if(emailMsg.HasAttachment){
                        for(Id doc : emailMsg.ContentDocumentids){
                            if(contentDocumentMap.containsKey(doc)){
                                ContentDocument content = contentDocumentMap.get(doc);
                                fileNamesList.add(content.Title+'.'+content.FileExtension);
                            }
                        }   
                    }
                    
                    String fileNames = String.join(fileNamesList,',');

                    String additionalEmails='';
                    if(String.isNotBlank(emailMsg.CCAddress)){
                        additionalEmails += emailMsg.CCAddress.replace(';',',');
                    }
                    //Salesforce doesn't capture BCC addresses in incoming mails
                    if(String.isNotBlank(emailMsg.BCCAddress)){
                        additionalEmails += emailMsg.BCCAddress.replace(';',',');
                    }
                    
                    string LOB = '';
                    if(String.isNotBlank(emailMsg.Parent.Origin)){
                        LOB = emailMsg.Parent.Origin.split(' ')[0];
                    }

                    string caseIntegrationId;
                    if(caseIdCaseIntegrationMap.containsKey(emailMsg.ParentId)){
                        caseIntegrationId = caseIdCaseIntegrationMap.get(emailMsg.ParentId).Name;
                    }
                    
                    Map<String, String> fieldsMap = new Map<String, String>();
                    fieldsMap.put('Case_Integration_ID__c',caseIntegrationId);
                    fieldsMap.put('Description__c',emailMsg.Parent.Description);
                    fieldsMap.put('Line_of_Business__c',LOB);
                    fieldsMap.put('Business_Unit__c',LOB);
                    fieldsMap.put('Integration_Name__c','EBOT API');
                    fieldsMap.put('Case_Number__c',emailMsg.Parent.CaseNumber);
                    fieldsMap.put('From_Address__c',emailMsg.FromAddress);
                    fieldsMap.put('To_Address__c',emailMsg.ToAddress);
                    fieldsMap.put('Subject__c',emailMsg.Parent.Subject);
                    fieldsMap.put('Additional_Emails__c',additionalEmails);
                    fieldsMap.put('File_Names__c',fileNames); 
                    Database.SaveResult eventResult = ABHFL_CasePlatformEventHandler.publishPlatformEvent('CRM_to_EBOT_Event__e', fieldsMap);
                }   
            }
        }
    }
}