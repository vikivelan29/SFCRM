@SuppressWarnings('PMD.ClassNamingConventions,PMD.FormalParameterNamingConventions,PMD.ApexSOQLInjection')
public without sharing class ASF_AccountCommPETriggerHelper {
    
    public static Set<String> customMetadataName = new Set<String>();
    public static Map<String,Customer_Notification_Config__mdt> mCommConfigMetaName = new Map<String,Customer_Notification_Config__mdt>();
    public static Set<String> setTemplates = new Set<String>();
    public static Map<Id,responseWrapper> peLogIdVsSuccessResult = new Map<Id,responseWrapper>();
    public static List<EmailTemplate> emailTemplates = new List<EmailTemplate>();
    public static Map<String,Id> templateIDMap = new Map<String,Id>();
    
    public static Map<Id,Set<Contact>> mAccountIdContactId = new Map<Id,Set<Contact>>();
    public static Id defaultContactId;
    public static Map<integer,Id> mIdxVsPELoggerId = new Map<integer,Id>();
    public static integer iCounter = 0;
    
    public static Set<Id> accountIds = new Set<Id>();
    public static Set<Id> accountContactIds = new Set<Id>();
    
    public static Map<Id,responseWrapper> executeContructor(List<PE_Logger__c> peLogs){
        /* Account Contact Related Operations */
        getAccountIdsFromPELogger(peLogs);
        List<contact> contactList = ASF_CommPETriggerQueryHandler.getCustomerContact(accountIds,accountContactIds);
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
            System.debug('***setTemplates>'+setTemplates);
            emailTemplates = ASF_CommPETriggerQueryHandler.getEmailTemplates(setTemplates); 
            getEmailTempDevNameVsId();
        }
        /* SMS And WhatsApp Related Template Information from Custom Metadata Related Operations */
        
        sendEmailCommunication(peLogs);
        return peLogIdVsSuccessResult;
    }
    
    private static Messaging.SingleEmailMessage getMessageGenerated(Contact con, PE_Logger__c peLogRec, Id eTempId, Id OWDId, Boolean IsAttachment){
        Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
        if(con != null){
            msg.setTargetObjectId(con.Id);
            msg.setTreatTargetObjectAsRecipient(true);	
            msg.setToAddresses(new String[]{con.Email});
        }
        
        //End
        msg.setTemplateId(eTempId);
        Messaging.SingleEmailMessage renderedHTMLMsg = generateMessageBody(eTempId, con.Id, peLogRec.RecordId__c, false);
        String htmlbody  = renderedHTMLMsg.getHtmlBody();
        String msgSubject = renderedHTMLMsg.getSubject();
        msg.setHTMLBody(htmlbody);
        msg.setSubject(msgSubject);
        msg.setWhatId(peLogRec.AccountId__c);
        msg.setSaveAsActivity(true);
        msg.setOrgWideEmailAddressId(OWDId);  
        return msg;
    }
    
    private static void sendEmailCommunication(List<PE_Logger__c> peLogs){
        List<Messaging.SingleEmailMessage> emails =  new List<Messaging.SingleEmailMessage>();
        OrgWideEmailAddress owAddress = [select Id,Purpose from OrgWideEmailAddress WHERE DisplayName=:System.Label.ASF_default_no_reply_email_address limit 1];
        
        for(PE_Logger__c pLog : peLogs){
            if(pLog.AccountId__c != null && pLog.AccountId__c != ''){
                // CHECK IF ACCOUNTID__C IS NOT NULL.
                
                if(templateIDMap.containsKey(pLog.Email_Template_Name__c)){
                    if(templateIDMap.get(pLog.Email_Template_Name__c) == null){
                        continue;
                    }
                }
                
                if(templateIDMap.containsKey(pLog.Email_Template_Name__c)){
                    Id emailtempid = templateIDMap.get(pLog.Email_Template_Name__c);
                    
                    // VIRENDRA - ADDED ANOTHER LOGIC TO SEND EMAIL TO SPECIFIC EMAIL ADDRESS - 
                    if(mAccountIdContactId.containsKey(pLog.AccountId__c)){
                        
                        for(Contact con : mAccountIdContactId.get(pLog.AccountId__c)){
                            if(con.Email != null){
                                //Added another parameter pLog.Is_Attachment__c to check if attachment needs to be sent or not
                                Messaging.SingleEmailMessage msg = getMessageGenerated(con, pLog, emailtempid, owAddress.Id, pLog.Is_Attachment__c);                                
                                emails.add(msg); 
                                mIdxVsPELoggerId.put(iCounter,pLog.Id);
                                iCounter++;
                            }
                        }
                    }
                    else{
                        //Added another parameter pLog.Is_Attachment__c to check if attachment needs to be sent or not
                        Messaging.SingleEmailMessage msg = getMessageGenerated(null,pLog, emailtempid, owAddress.Id, pLog.Is_Attachment__c);                                
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
    private static Messaging.SingleEmailMessage generateMessageBody(String templateID, String whoID, STring whatID, Boolean isPlainText){
        Messaging.SingleEmailMessage msg = Messaging.renderStoredEmailTemplate(templateID, whoId, whatID, Messaging.AttachmentRetrievalOption.NONE); 
        String richTextMessage = msg.getHtmlBody(); 
        return msg;
    }
    
    private static void getEmailTempDevNameVsId(){
        for(EmailTemplate template : emailTemplates){
            templateIDMap.put(template.DeveloperName,template.Id);
        }
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
    
    private static void getAccountIdsFromPELogger(List<PE_Logger__c> peLogs){
        for(PE_Logger__c pLog : peLogs){
            customMetadataName.add(pLog.CustomMetadataName__c);
            if(pLog.AccountId__c != null){
                accountIds.add(pLog.AccountId__c);
            }
            if(pLog.ContactId__c != null){
                accountContactIds.add(pLog.ContactId__c);
            }
        }
    }
}