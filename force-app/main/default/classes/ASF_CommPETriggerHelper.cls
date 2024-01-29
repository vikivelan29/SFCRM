/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 01-17-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   01-17-2024   rsinghnagar@salesforce.com   Initial Version
**/
public class ASF_CommPETriggerHelper {
    
    public static Set<String> customMetadataName = new Set<String>();
    public static Map<String,Customer_Notification_Config__mdt> mCommConfigMetaName = new Map<String,Customer_Notification_Config__mdt>();
    public static Set<String> setTemplates = new Set<String>();
    public static List<String> channelFieldNamesSMS = new List<String>();
    public static List<String> channelFieldNamesEmail = new List<String>();
    public static List<String> channelFieldNamesWA = new List<String>();
    public static Map<Id,responseWrapper> peLogIdVsSuccessResult = new Map<Id,responseWrapper>();
    public static List<EmailTemplate> emailTemplates = new List<EmailTemplate>();
    public static Map<String,Id> templateIDMap = new Map<String,Id>();
    public static set<String> setCaseFields = new Set<String>();
    public static Set<Id> caseIds = new Set<Id>();
    public static Map<String, Schema.SObjectField> casefieldInfo;
    public static List<ASF_Communication_log__c> logs = new List<ASF_Communication_log__c>();
    public static Set<Id> caseAccountIds = new Set<Id>();
    public static Set<Id> caseConIds = new Set<Id>();
    public static Map<Id,Set<Contact>> mAccountIdContactId = new Map<Id,Set<Contact>>();
    public static Map<Id,Id> mLogIdVsCaseId = new Map<Id,Id>();
    public static Id defaultContactId;
    public static Map<Id,Messaging.SingleEmailMessage> emailLogMap = new Map<Id,Messaging.SingleEmailMessage>();
    public static Map<Id,Case> mCases = new Map<Id,Case>();
    public static Map<integer,Id> mIdxVsPELoggerId = new Map<integer,Id>();
    public static integer iCounter = 0;
    public static Set<Id> markForDeletion = new Set<Id>();
    public static Set<Id> caseProspectIds = new Set<Id>();
    public static Map<Id,Lead> mLeads = new Map<Id,Lead>();
    
    
    
    public static Map<Id,responseWrapper> executeContructor(List<PE_Logger__c> peLogs){
        system.debug('PE logs at entry:'+peLogs);
        // 1. Find out Custom Metadata - Done
        // 2. Find out SMS Template and WhatsApp Template - Done
        // 3. Query on SMS Template Field and WhatsApp Template Field. - Done
        // 4. Create Communication Logger Record.
        // 5. Publish Platform Event for the same.
        // 6. Send Email from Lightning Email Template - The same can be used for VF Email Template.
        // 7. Go back and update the PE Logger Record, in case of Success --> Completed, in Case of Error --> Error with Error Message
        // 8. Set retry flag to true, if the error is because of the resources unavailability like email limit reached, Platform Events Publisher limit reached etc.
        
        
        channelFieldNamesSMS = ASF_CommPEMergeFieldHandler.getMergefieldNames(ASF_CommPEMergeFieldHandler.Channel.SMS);
        channelFieldNamesEmail = ASF_CommPEMergeFieldHandler.getMergefieldNames(ASF_CommPEMergeFieldHandler.Channel.Email);
        channelFieldNamesWA = ASF_CommPEMergeFieldHandler.getMergefieldNames(ASF_CommPEMergeFieldHandler.Channel.WhatsApp);
        
        
        casefieldInfo = Schema.SObjectType.Case.fields.getMap();
        
        /* Account Contact Related Operations */
        getAccountAndContactIdsAndLeadIds(peLogs);
        List<contact> contactList = ASF_CommPETriggerQueryHandler.getCustomerContact(caseAccountIds,caseConIds);
        mLeads = new Map<Id,Lead>(ASF_CommPETriggerQueryHandler.getProspectRecords(caseProspectIds));
        System.debug(contactList);
        for(Contact c : contactList){
            //Build AccountId to Set of ContactId map.
            if(!mAccountIdContactId.containsKey(c.AccountId)){
                mAccountIdContactId.put(c.AccountId,new Set<Contact>());
            }
            mAccountIdContactId.get(c.AccountId).add(c);
        }
        defaultContactId = [select id from contact limit 1].Id;
        /* Account Contact Related Operations */
        
        
        List<Customer_Notification_Config__mdt> custMetaList = ASF_CommPETriggerQueryHandler.getCustomMetadataList(customMetadataName);
        
        for(Customer_Notification_Config__mdt custMeta : custMetaList){
            if(!mCommConfigMetaName.containsKey(custMeta.developerName))
                mCommConfigMetaName.put(custMeta.developerName, custMeta);
        }
        
        /* SMS And WhatsApp Related Template Information from Custom Metadata Related Operations */
        for(PE_Logger__c pLog : peLogs){
            try{
                String strMetadataName = pLog.CustomMetadataName__c;
                if(strMetadataName != null){
                    getTemplateNamesFromConfig(strMetadataName); 
                }
                if(pLog.Email_Template_Name__c != null){
                    setTemplates.add(pLog.Email_Template_Name__c);
                }
                
            }
            catch(exception e){
                responseWrapper cls = new responseWrapper(pLog.Id,'Error','No template found in Customer_Notification_Config__mdt');
                peLogIdVsSuccessResult.put(pLog.Id,cls);
            }
        }
        
        if(setTemplates.size()>0){
            emailTemplates = ASF_CommPETriggerQueryHandler.getEmailTemplates(setTemplates); 
            getEmailTempDevNameVsId();
        }
        /* SMS And WhatsApp Related Template Information from Custom Metadata Related Operations */
        
        
        createLogs(peLogs,null);
        sendEmailCommunication(peLogs);
        sendCommunications(false,peLogs);
        updateLog();
        
        return peLogIdVsSuccessResult;
    }
    
    public static void updateLog(){
        List<ASF_Communication_Log__c> updLogs = new List<ASF_Communication_Log__c>();
        for(ASF_Communication_Log__c log : logs){
            if(log.Id != null){
                // Do some data setup here and then update.
                log.Status__c = 'In Progress';
                updLogs.add(log);
            }
        }
        if(updLogs.size()>0){
            update updLogs;
        } 
    }
    
    private static Messaging.SingleEmailMessage getMessageGenerated(Contact con, Case cRec, Id eTempId, Id OWDId, Boolean IsAttachment, Lead prospect){
        Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
        if(con != null){
            msg.setTargetObjectId(con.Id);
            msg.setTreatTargetObjectAsRecipient(true);	
            msg.setToAddresses(new String[]{con.Email});
        }
        else if(prospect != null){
            msg.setTargetObjectId(defaultContactId);
            msg.setTreatTargetObjectAsRecipient(false);	
            msg.setToAddresses(new String[]{prospect.Email});
        }
        else{
            msg.setTargetObjectId(defaultContactId);
            msg.setTreatTargetObjectAsRecipient(false);
            msg.setToAddresses(new String[]{cRec.SuppliedEmail});
        }
        //Start - Calling the function to add files to the email as attachments - Aditya Mehrotra
        if(isAttachment){
            List<Messaging.Emailfileattachment> emailFileAttachments = getCaseFilesAsEmailAttachments(cRec.Id);
            if(emailFileAttachments.size()>0){
                msg.setFileAttachments(emailFileAttachments);
            }
        }
        
        //End
        msg.setTemplateId(eTempId);
        msg.setWhatId(cRec.Id);
        msg.setSaveAsActivity(true);
        msg.setOrgWideEmailAddressId(OWDId);        
        return msg;
    }
    
    //Function to get all the case files(if present) to attach to the email communication - Aditya Mehrotra
    private static List<Messaging.Emailfileattachment> getCaseFilesAsEmailAttachments(String caseId){
        List<Id> ContentDocumentIds = new List<Id>();
        List<Messaging.Emailfileattachment> emailFileAttachments = new List<Messaging.Emailfileattachment>();
        for(ContentDocumentLink cdLink : [SELECT LinkedEntityId, ContentDocumentId 
                                          FROM ContentDocumentLink WHERE LinkedEntityId=:caseId])
        {
            ContentDocumentIds.add(cdLink.ContentDocumentId);
        }
        for (ContentVersion cversion : [SELECT title,PathOnClient,FileType,versiondata 
                                        FROM contentversion 
                                        WHERE ContentDocumentId IN :ContentDocumentIds
                                        AND isSTP__c = TRUE])
        {
            blob fileBody = cversion.versiondata;
            Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
            efa.setFileName(cversion.title+'.'+cversion.FileType);
            efa.setBody(fileBody);
            emailFileAttachments.add(efa); 
        }
        system.debug('File attachments:'+emailFileAttachments);
        
        return emailFileAttachments;
    }
    
    private static void sendEmailCommunication(List<PE_Logger__c> peLogs){
        System.debug('Coming here....'+peLogs);
        List<Messaging.SingleEmailMessage> emails =  new List<Messaging.SingleEmailMessage>();
        //OrgWideEmailAddress owAddress = [select Id,Purpose from OrgWideEmailAddress WHERE Purpose = 'DefaultNoreply' order by lastmodifiedDate desc  limit 1];
        OrgWideEmailAddress owAddress = [select Id,Purpose from OrgWideEmailAddress WHERE DisplayName=:System.Label.ASF_default_no_reply_email_address limit 1];
        
        for(PE_Logger__c pLog : peLogs){
            //Bypass sending Email when user manually blocks it during case creation
            if(mCases.containsKey(pLog.Case__c) &&
               (pLog.No_Auto_Communication__c == null || 
                (pLog.No_Auto_Communication__c != null && !pLog.No_Auto_Communication__c.contains('Email')))){
                    
                    Case cRec = mCases.get(pLog.Case__c);
                    if(templateIDMap.containsKey(pLog.Email_Template_Name__c)){
                        if(templateIDMap.get(pLog.Email_Template_Name__c) == null){
                            continue;
                        }
                    }
                    
                    if(templateIDMap.containsKey(pLog.Email_Template_Name__c)){
                        Id emailtempid = templateIDMap.get(pLog.Email_Template_Name__c);
                        
                        // VIRENDRA - ADDED ANOTHER LOGIC TO SEND EMAIL TO SPECIFIC EMAIL ADDRESS - 
                        if(pLog.Send_To_Specific_Emails__c){
                            System.debug('I am here --> '+pLog.Send_To_Specific_Emails__c);
                            if(pLog.Specific_To_Address__c != null){
                                List<String> toSpecificAddresses = pLog.Specific_To_Address__c.deleteWhitespace().split(';');
                                Messaging.SingleEmailMessage msg = getMessageGenerated(null,cRec, emailtempid, owAddress.Id, pLog.Is_Attachment__c,null);                                
                                msg.setToAddresses(toSpecificAddresses);
                                emails.add(msg); 
                                mIdxVsPELoggerId.put(iCounter,pLog.Id);
                                iCounter++;
                            }
                        }
                        
                        else if(mAccountIdContactId.containsKey(cRec.AccountId)){
                            
                            for(Contact con : mAccountIdContactId.get(cRec.AccountId)){
                                if(con.Email != null){
                                    //Added another parameter pLog.Is_Attachment__c to check if attachment needs to be sent or not
                                    Messaging.SingleEmailMessage msg = getMessageGenerated(con, cRec, emailtempid, owAddress.Id, pLog.Is_Attachment__c,null);                                
                                    emails.add(msg); 
                                    mIdxVsPELoggerId.put(iCounter,pLog.Id);
                                    iCounter++;
                                }
                            }
                        }
                        else if(mLeads.containsKey(cRec.Lead__c)){
                            Lead prospect = mLeads.get(cRec.Lead__c);
                            Messaging.SingleEmailMessage msg = getMessageGenerated(null, cRec, emailtempid, owAddress.Id, pLog.Is_Attachment__c,prospect);                                
                            emails.add(msg); 
                            mIdxVsPELoggerId.put(iCounter,pLog.Id);
                            iCounter++;
                        }
                        else{
                            //Added another parameter pLog.Is_Attachment__c to check if attachment needs to be sent or not
                            Messaging.SingleEmailMessage msg = getMessageGenerated(null,cRec, emailtempid, owAddress.Id, pLog.Is_Attachment__c,null);                                
                            emails.add(msg); 
                            mIdxVsPELoggerId.put(iCounter,pLog.Id);
                            iCounter++;
                        }
                    }
                    
                }
        }
        
        /// Send email Logic moved to first.
        if(emails.size()>0){
            Messaging.SendEmailResult[] msgResults= Messaging.sendEmail(emails,false);
            List<Messaging.SingleEmailMessage> retryEmailSend = new List<Messaging.SingleEmailMessage>();
            
            for(integer i=0;i<msgResults.size();i++){
                if(!msgResults[i].IsSuccess()){
                    retryEmailSend.add(emails[i]);
                }
            }
            if(retryEmailSend.size()>0){
                
                Messaging.SendEmailResult[] msgRetryResults= Messaging.sendEmail(retryEmailSend,false);
                
                for(integer i=0;i<msgRetryResults.size();i++){
                    if(!msgRetryResults[i].IsSuccess()){
                        String errMsg = msgRetryResults[i].getErrors().get(0).getMessage();
                        System.debug('Check here for retry email error --> '+errMsg);
                        
                    }
                    else{
                        System.debug('Email sent successfully in retry...');
                    }
                }
            }
            
            
            for(integer i=0;i<msgResults.size();i++){
                if(!msgResults[i].IsSuccess()){
                    String errMsg = msgResults[i].getErrors().get(0).getMessage();
                    if(mIdxVsPELoggerId.containsKey(i)){
                        responseWrapper cls = new responseWrapper(mIdxVsPELoggerId.get(i) ,'Error','Error Sending Email ' + errMsg);
                        peLogIdVsSuccessResult.put(mIdxVsPELoggerId.get(i) ,cls);
                    }
                }
                else{
                    if(mIdxVsPELoggerId.containsKey(i)){
                        responseWrapper cls = new responseWrapper(mIdxVsPELoggerId.get(i) ,'Success','' );
                        peLogIdVsSuccessResult.put(mIdxVsPELoggerId.get(i) ,cls);
                    }
                }
            }
        }
    }
    
    public static void sendCommunications(Boolean skipPE,List<PE_Logger__c> peLogs){
        
        List<Outbound_Communication__e> eventList = new List<Outbound_Communication__e>();
        
        
        // For SMS and WhatsApp
        for(ASF_Communication_Log__c log : logs){
            if(log.Id != null){
                if(!String.isEmpty(log.SMS_LT_Name__c) && log.Phone__c != null){
                    
                    String smsTemplateId = templateIDMap.get(log.SMS_LT_Name__c);
                    
                    if(smsTemplateId == null){
                        responseWrapper cls = new responseWrapper(log.PE_Logger_Id__c ,'Error','SMS template not found for name ' + log.SMS_LT_Name__c);
                        peLogIdVsSuccessResult.put(log.PE_Logger_Id__c ,cls);
                        //throw new commException('SMS template not found for name ' + log.SMS_LT_Name__c);
                    }
                    else{
                        if(log.Contact__c != null){ 
                            log.SMS_Msg_Body__c = generateMessageBody(smsTemplateId,log.Contact__c,log.id, true); 
                        }
                        else if(log.Lead__c != null){
                            log.SMS_Msg_Body__c = generateMessageBody(smsTemplateId,log.Lead__c,log.id, true); 
                        }
                        
                        responseWrapper cls = new responseWrapper(log.PE_Logger_Id__c,'Success','',log.id,log.SMS_Msg_Body__c);
                        peLogIdVsSuccessResult.put(log.PE_Logger_Id__c,cls);
                        eventList.add(createOutboundCommunication(log,'SMS'));
                    }
                }
                
                if(!String.isEmpty(log.WhatsApp_LT_Name__c)){
                    
                    String waTemplateId = templateIDMap.get(log.WhatsApp_LT_Name__c);
                    
                    if(waTemplateId == null){
                        responseWrapper cls = new responseWrapper(log.PE_Logger_Id__c,'Error','WhatsApp template not found for name ' + log.WhatsApp_LT_Name__c);
                        peLogIdVsSuccessResult.put(log.PE_Logger_Id__c,cls);
                    }
                    else{
                        log.Whatsappp_Msg_Body__c = generateMessageBody(waTemplateId,log.Contact__c, log.id, true);
                        responseWrapper cls = new responseWrapper(log.PE_Logger_Id__c,'Success','',log.id,log.Whatsappp_Msg_Body__c);
                        peLogIdVsSuccessResult.put(log.PE_Logger_Id__c,cls);
                        Outbound_Communication__e comm = createOutboundCommunication(log,'WhatsApp');
                        eventList.add(comm);
                    }
                }
            }
        }
        
        if(!skipPE){
            List<Database.SaveResult> results = EventBus.publish(eventList);
        }
    }
    
    private static String generateMessageBody(String templateID, String whoID, STring whatID, Boolean isPlainText){
        Messaging.SingleEmailMessage msg = Messaging.renderStoredEmailTemplate(templateID, whoId, whatID, Messaging.AttachmentRetrievalOption.NONE); 
        String richTextMessage = msg.getHtmlBody(); 
        System.debug('richTextMessage ---> '+richTextMessage);
        return isPlainText ? richTextMessage.StripHtmlTags() : richTextMessage;
    }
    
    private static Outbound_Communication__e createOutboundCommunication(ASF_Communication_Log__c log,String msgType){
        Outbound_Communication__e event = new Outbound_Communication__e(LogID__c  =log.id,
                                                                        Case__c = log.Case__c,
                                                                        Template_ID__c  = log.External_Template_ID__c ,
                                                                        Phone__c  =log.Phone__c,
                                                                        Txt_Msg__c = log.SMS_Msg_Body__c,
                                                                        LOB__c = log.LOB__c,
                                                                        Type__c = msgType,
                                                                        SMS_Entity_Id__c = log.SMS_Entity_Id__c,
                                                                        SMS_Sender_Id__c = log.SMS_Sender_Id__c
                                                                        );
        
        return event;
    }
    
    private static void createLogs(List<PE_Logger__c> peLogs,Contact selectedCon){
        List<ASF_Communication_Log__c> masterLogs = new List<ASF_Communication_Log__c>();
        
        for(PE_Logger__c pLog : peLogs){
            system.debug('channelFieldNamesSMS::'+channelFieldNamesSMS);
            system.debug('PE logger record:'+pLog);
            system.debug('pLog.CustomMetadataName__c:'+pLog.CustomMetadataName__c);
            system.debug('pLog.No_Auto_Communication__c:'+pLog.No_Auto_Communication__c);
            system.debug('mCommConfigMetaName:'+mCommConfigMetaName);
            //Bypass sending SMS when user manually blocks it during case creation
            if(pLog.CustomMetadataName__c != null &&
               (pLog.No_Auto_Communication__c == null || 
                (pLog.No_Auto_Communication__c != null && !pLog.No_Auto_Communication__c.contains('SMS')))){
                    if(mCommConfigMetaName.containsKey(pLog.CustomMetadataName__c)){
                        String strMetadataName = pLog.CustomMetadataName__c;
                        Customer_Notification_Config__mdt comm_config = mCommConfigMetaName.get(strMetadataName);
                        
                        // SMS Related
                        if(comm_config != null && comm_config.SMS_Template_Name__c != null){
                            setCaseFields(comm_config,channelFieldNamesSMS[0]);
                        }
                        
                        // WhatsApp Related
                        if(comm_config != null && comm_config.Whatsapp_Template_Name__c !=null){
                            setCaseFields(comm_config,channelFieldNamesWA[0]);
                        }
                    }
                }
        }
        String query = 'SELECT ID,Lead__c,AccountId,CCC_External_Id__c ,ContactEmail,contact.Name,ContactMobile,ContactId,SuppliedEmail,origin';
        query += ' FROM CASE WHERE ID IN :caseIds FOR UPDATE';
        if(setCaseFields !=null && setCaseFields.size()>0){
            List<string> temp = new List<String>();
            temp.addAll(setCaseFields);
            Set<Id> temp_cIds = caseIds;
            query = 'SELECT ID,AccountId,Lead__c,CCC_External_Id__c ,ContactEmail,contact.Name,ContactMobile,ContactId,SuppliedEmail,origin,'+String.join(temp, ',');
            query = query.removeEnd(',');
            query += ' FROM CASE WHERE ID IN :temp_cIds FOR UPDATE';
        }
        List<Case> cases = (List<case>)Database.query(query);
        mCases = new Map<Id,Case>(cases);
        
        Map<Id,ASF_Communication_Log__c> mPeLogIdCommunicationLog = new Map<Id,ASF_Communication_Log__c>();
        System.debug('peLogs --> '+peLogs);
        for(PE_Logger__c pLog : peLogs){
            //Bypass sending SMS when user manually blocks it during case creation
            if(pLog.CustomMetadataName__c != null &&
               (pLog.No_Auto_Communication__c == null || 
                (pLog.No_Auto_Communication__c != null && !pLog.No_Auto_Communication__c.contains('SMS')))){
                    String strMetadataName = pLog.CustomMetadataName__c;
                    Case cRec = mCases.get(pLog.Case__c);
                    ASF_Communication_Log__c masterlog = new ASF_Communication_Log__c();
                    Customer_Notification_Config__mdt comm_config = mCommConfigMetaName.get(strMetadataName);
                    System.debug('comm_config --> '+comm_config);
                    
                    if(comm_config != null){
                        if(comm_config.SMS_Template_Name__c != null){
                            if(comm_config.get(channelFieldNamesSMS[3]) != null){
                                System.debug('setCaseFields --> '+setCaseFields);
                                ASF_CommPEMergeFieldHandler.populateMergeFields(channelFieldNamesSMS,comm_config,cRec,masterlog,mPeLogIdCommunicationLog,casefieldInfo,pLog.Id);
                            }
                        } 
                        /* Populate Merge field for WhatsApp Template */
                        if(comm_config.Whatsapp_Template_Name__c != null){
                            if(comm_config.get(channelFieldNamesWA[3]) != null){
                                ASF_CommPEMergeFieldHandler.populateMergeFields(channelFieldNamesWA,comm_config,cRec,masterlog,mPeLogIdCommunicationLog,casefieldInfo,pLog.Id);
                            }
                        }
                    }
                    /* Populate Merge field for SMS Template */
                    
                }
            
        }
        for(PE_Logger__c pLog : peLogs){
            if(mPeLogIdCommunicationLog.containsKey(pLog.Id)){
                ASF_Communication_Log__c cLog = mPeLogIdCommunicationLog.get(pLog.Id);
                ASF_Communication_Log__c log = cLog.clone(false, true,false, false);
                Case cRec = mCases.get(pLog.Case__c);
                
                if(selectedCon!=null && selectedCon.MobilePhone != null){
                    log = createCommunincationLogRecord(log,selectedCon.AccountId,selectedCon.Id,cRec.Id,selectedCon.Name,selectedCon.MobilePhone,null);
                    log.put('Contact_Email__c', selectedCon.email);
                    log.put('PE_Logger_Id__c',pLog.Id);
                    log.LOB__c = pLog.LOB__c;
                    
                    if( selectedCon.MobilePhone != ''){
                        log.put('Status__c','In Progress');
                    }
                    logs.add(log);
                    
                }else if(mAccountIdContactId.containsKey(cRec.AccountId)){// preference 3 : else send it to all contacts
                    
                    for(Contact con : mAccountIdContactId.get(cRec.AccountId)){
                        
                        if(mPeLogIdCommunicationLog.containsKey(pLog.Id) && con.MobilePhone != null){
                            
                            log = cLog.clone(false, true,false, false);
                            log = createCommunincationLogRecord(log,cRec.AccountId,con.Id,cRec.Id,con.Name,con.MobilePhone,null);
                            
                            if(con.MobilePhone != null &&  !String.isEmpty(log.SMS_LT_Name__c))
                                log.put('Status__c','In Progress');
                            
                            log.put('Contact_Email__c', con.email);
                            log.put('PE_Logger_Id__c',pLog.Id);
                            log.LOB__c = pLog.LOB__c;
                            logs.add(log);
                        }
                    }
                }else if(cRec.Lead__c != null){
                    log = cLog.clone(false, true,false, false);
                    lead prospect = mLeads.get(cRec.Lead__c);
                    log = createCommunincationLogRecord(log,null,null,cRec.Id,prospect.Name,prospect.MobilePhone,prospect.Id);
                    
                    if(prospect.MobilePhone != null &&  !String.isEmpty(log.SMS_LT_Name__c))
                        log.put('Status__c','In Progress');
                    
                    log.put('Contact_Email__c', prospect.email);
                    log.put('PE_Logger_Id__c',pLog.Id);
                    log.LOB__c = pLog.LOB__c;
                    logs.add(log);
                    // IN case of Prospect Communication...
                    
                }
                else if(!String.isEmpty(cRec.SuppliedEmail)){// preference 2 : if case contact id is blank then send to case supplied email
                    if(mPeLogIdCommunicationLog.containsKey(pLog.Id)){ 
                        // Don't do anything
                    }
                } 
                else{
                    responseWrapper cls = new responseWrapper(pLog.Id,'Error','AccountId is missing on Case');
                    peLogIdVsSuccessResult.put(pLog.Id,cls);
                }
            }
            
        }
        if(logs.size()>0){
            Database.SaveResult[] results = Database.insert(logs,false);
            for(integer i =0;i<logs.size();i++){
                if(results[i].isSuccess()){
                    System.debug('here....');
                    responseWrapper cls = new responseWrapper(logs[i].PE_Logger_Id__c ,'Completed','');
                    peLogIdVsSuccessResult.put(logs[i].PE_Logger_Id__c ,cls);
                    mLogIdVsCaseId.put(logs[i].Id,logs[i].Case__c);
                }
                else{
                    System.debug('here....');
                    responseWrapper cls = new responseWrapper(logs[i].PE_Logger_Id__c ,'Error',results[i].getErrors().get(0).getMessage());
                    peLogIdVsSuccessResult.put(logs[i].PE_Logger_Id__c ,cls);
                    
                }
            }
        }
        
        
    }
    private static void getEmailTempDevNameVsId(){
        for(EmailTemplate template : emailTemplates){
            templateIDMap.put(template.DeveloperName,template.Id);
        }
    }
    private static void getTemplateNamesFromConfig(String strMetadataName){
        Customer_Notification_Config__mdt comm_config = mCommConfigMetaName.get(strMetadataName);
        
        Object SMStemplateName = comm_config.get(channelFieldNamesSMS[3]); 
        if(SMStemplateName != null)
            setTemplates.add(SMStemplateName.tostring());
        
        Object waTemplateName = comm_config.get(channelFieldNamesWA[3]);
        if(waTemplateName != null)
            setTemplates.add(waTemplateName.tostring());
    }
    
    public class responseWrapper{
        public string logId{get;set;}
        public string status{get;set;}
        public string message{get;set;}
        public string template{get;set;}
        public string communicationId{get;set;}
        
        public responseWrapper(string lId,string st,string msg){
            this.logId = lId;
            this.status = st;
            this.message = msg;
        }
        public responseWrapper(string lId,string st,string msg, String comId, String body){
            this.logId = lId;
            this.status = st;
            this.message = msg;
            this.template = body;
            this.communicationId = comId;
        }
    }
    
    private static void getAccountAndContactIdsAndLeadIds(List<PE_Logger__c> peLogs){
        for(PE_Logger__c pLog : peLogs){
            customMetadataName.add(pLog.CustomMetadataName__c);
            caseIds.add(pLog.Case__c);
            if(pLog.AccountId__c != null){
                caseAccountIds.add(pLog.AccountId__c);
            }
            if(pLog.ContactId__c != null){
                caseConIds.add(pLog.ContactId__c);
            }
            if(pLog.Lead__c != null){
                caseProspectIds.add(pLog.Lead__c);
            }
        }
    }
    private static void setCaseFields(Customer_Notification_Config__mdt comm_config, String developerName){
        String mergeFieldCSV = (String) comm_config.get(developerName);
        if(mergeFieldCSV !=null && String.IsNotBlank(mergeFieldCSV)){
            setCaseFields.addAll(mergeFieldCSV.split(','));
        }
    }
    private static ASF_Communication_Log__c createCommunincationLogRecord(ASF_Communication_Log__c log,
                                                                          Id accountId,
                                                                          Id contactId,
                                                                          Id caseId,
                                                                          String contactName,
                                                                          String mobNo,
                                                                          Id leadId)
    {
        log.put('Account__c',accountId);
        log.put('Case__c', caseId);  
        log.put('Contact__c',contactId);
        log.put('Lead__c',leadId);
        log.put('Contact_Name__c',contactName);
        log.put('Phone__c', mobNo);
        return log;
    }
}