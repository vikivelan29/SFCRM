global class EbotBatchClass implements Database.Batchable<String> {
    
    List<String> emailMessageIds;
    global EbotBatchClass(List<String> messageIds) {
        emailMessageIds = messageIds;
    }

    global List<String> start(Database.BatchableContext bc) {
        return emailMessageIds;
    }

    global void execute(Database.BatchableContext bc, List<String> scope) {
        List<EmailMessage> emailMessages = [SELECT Id, ParentId, FromAddress, ToAddress, Subject, TextBody FROM EmailMessage WHERE Id IN :scope];
		String emailMessageID ;
        Set<Id> caseIds = new Set<Id>();
        Map<Id, EmailMessage> emailMessageMap = new Map<Id, EmailMessage>();

        for(EmailMessage message : emailMessages) {
            caseIds.add(message.ParentId);
            emailMessageMap.put(message.Id, message);
            emailMessageID = message.Id;
        }

        Map<Id,EmailMessage> emailMsgMap = new Map<Id,EmailMessage>([Select Contentdocumentids,HasAttachment,CCAddress,FromAddress,ToAddress,BCCAddress,ParentId,Parent.Description,
        Parent.CaseNumber,Parent.Subject,Parent.Origin,Parent.Business_Unit__c from EmailMessage where id in: scope]);

        system.debug('emailMsgMap'+emailMsgMap);

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

            
            if(emailMsgMap.containsKey(emailMessageID)){
                EmailMessage emailMsg = emailMsgMap.get(emailMessageID);
                ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();    
                caseInt.Case__c = emailMsg.ParentId;
                caseInt.Status__c = 'Pending';
                caseInt.Type__c = 'eBOT';
                caseIntegrationList.add(caseInt);
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

                if(emailMsgMap.containsKey(emailMessageID)){
                    EmailMessage emailMsg = emailMsgMap.get(emailMessageID);

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
                    if(String.isNotBlank(emailMsg.ToAddress)){
                        additionalEmails += emailMsg.ToAddress.replace(';',',');
                    }
                    if(String.isNotBlank(emailMsg.CCAddress)){
                        additionalEmails += ',';
                        additionalEmails += emailMsg.CCAddress.replace(';',',');
                    }
                    //Salesforce doesn't capture BCC addresses in incoming mails
                    if(String.isNotBlank(emailMsg.BCCAddress)){
                        additionalEmails += ',';
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
                    string toAddress = emailMsg.ToAddress;
                    system.debug('toAddress'+toAddress);
                    if(emailMsg.Parent.Business_Unit__c == 'ABHFL'){
                        List<ASF_PriorityEmailAddressesByBU__mdt> emailAddressBU = [Select Email2CaseAddress__c from ASF_PriorityEmailAddressesByBU__mdt where Business_Unit__c = 'ABHFL' and Send_To_Ebot__c = true];
                        if(emailAddressBU.size() > 0){
                            toAddress = emailAddressBU[0].Email2CaseAddress__c;
                            system.debug('toAddress--->'+toAddress);
                        }
                    }
                    
                    Map<String, String> fieldsMap = new Map<String, String>();
                    fieldsMap.put('Case_Integration_ID__c',caseIntegrationId);
                    fieldsMap.put('Description__c',emailMsg.Parent.Description);
                    fieldsMap.put('Line_of_Business__c',LOB);
                    fieldsMap.put('Business_Unit__c',LOB);
                    fieldsMap.put('Integration_Name__c','EBOT API');
                    fieldsMap.put('Case_Number__c',emailMsg.Parent.CaseNumber);
                    fieldsMap.put('From_Address__c',emailMsg.FromAddress);
                    fieldsMap.put('To_Address__c',toAddress);
                    fieldsMap.put('Subject__c',emailMsg.Parent.Subject);
                    fieldsMap.put('Additional_Emails__c',additionalEmails);
                    fieldsMap.put('File_Names__c',fileNames); 
                    system.debug('fieldsMap'+fieldsMap);
                    Database.SaveResult eventResult = ABHFL_CasePlatformEventHandler.publishPlatformEvent('CRM_to_EBOT_Event__e', fieldsMap);
                }   
            
        }
        
    }

    global void finish(Database.BatchableContext bc) {
    }
}