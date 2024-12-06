/**
 * @description       : 
 * @author            : jpalla@salesforce.com
 * @group             :
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   17-10-2024   jpalla@salesforce.com        Initial Version
**/
@SuppressWarnings('PMD.ClassNamingConventions,PMD.FormalParameterNamingConventions,PMD.ApexSOQLInjection')
public without sharing class ASF_OppCommPETriggerHelper {
    public static Set<String> customMetadataName = new Set<String>();
    public static Map<String,Customer_Notification_Config__mdt> mCommConfigMetaName = new Map<String,Customer_Notification_Config__mdt>();
    public static Set<String> setTemplates = new Set<String>();
    public static List<String> channelFieldNamesSMS = new List<String>();
    public static List<String> channelFieldNamesEmail = new List<String>();
    public static List<String> channelFieldNamesWA = new List<String>();
    public static Map<Id,responseWrapper> peLogIdVsSuccessResult = new Map<Id,responseWrapper>();
    public static List<EmailTemplate> emailTemplates = new List<EmailTemplate>();
    public static Map<String, EmailTemplate> templateIDMap = new Map<String, EmailTemplate>();
    public static set<String> setOpportunityFields = new Set<String>();
    public static Set<Id> opportunityIds = new Set<Id>();
    public static Map<String, Schema.SObjectField> oppFieldInfo;
    public static List<ASF_Communication_log__c> logs = new List<ASF_Communication_log__c>();
    public static Set<Id> caseAccountIds = new Set<Id>();
    public static Map<Id, Account> accountMap = new Map<Id, Account>();
    public static Set<Id> caseConIds = new Set<Id>();
    public static Map<Id,Set<Contact>> mAccountIdContactId = new Map<Id,Set<Contact>>();
    public static Map<Id,Id> mLogIdVsCaseId = new Map<Id,Id>();
    public static Id defaultContactId;
    public static Map<Id,Messaging.SingleEmailMessage> emailLogMap = new Map<Id,Messaging.SingleEmailMessage>();
    public static Map<Id,Case> mCases = new Map<Id,Case>();
    public static Map<Id,Opportunity> mOpps = new Map<Id,Opportunity>();
    public static Map<integer,Id> mIdxVsPELoggerId = new Map<integer,Id>();
    public static integer iCounter = 0;
     // this is currently set to ABHI-RNWL. When RNWL is extended in future, replace this with a field on opp that will identify the BU
    public static String subLob = 'ABHI-RNWL';

    // VIRENDRA - 12 APRIL 2024 - ADDED FOR INFOSEC AND PRODUCTION REQUIREMENT OF ABHFL.
    public static Map<String,Set<String>> mBusUnitVsDefaultFromAddress = new Map<String,Set<String>>();
    public static Map<String,Id> mBusinessUnitVsSpecificOWA = new Map<String,Id>();
    public static Map<String,String> mBusUnitVsReplyToAddress = new Map<String,String>();

    /**
     * @description Executes the constructor to handle communication log creation based on PE logger records.
     * @param peLogs List of PE_Logger__c records.
     * @return Map containing PE logger ID to responseWrapper mapping.
     */
    public static Map<Id,responseWrapper> executeContructor(List<PE_Logger__c> peLogs){
        channelFieldNamesSMS = ASF_CommPEMergeFieldHandler.getMergefieldNames(ASF_CommPEMergeFieldHandler.Channel.SMS);
        channelFieldNamesEmail = ASF_CommPEMergeFieldHandler.getMergefieldNames(ASF_CommPEMergeFieldHandler.Channel.Email);
        channelFieldNamesWA = ASF_CommPEMergeFieldHandler.getMergefieldNames(ASF_CommPEMergeFieldHandler.Channel.WhatsApp);

        /******* VIRENDRA - ADDED on 12 APRIL 2024 FOR INFOSEC REQUIREMENT *********/
        for(BUSpecificAutoEmailMapping__mdt buSpecificAutoEmail : [SELECT ID, Business_Unit__c ,Default_Automated_Email_From_Address__c, Reply_To_Address__c  FROM BUSpecificAutoEmailMapping__mdt]){
            if(!mBusUnitVsDefaultFromAddress.containsKey(buSpecificAutoEmail.Default_Automated_Email_From_Address__c)){
                mBusUnitVsDefaultFromAddress.put(buSpecificAutoEmail.Default_Automated_Email_From_Address__c, new Set<String>());
            }
            mBusUnitVsDefaultFromAddress.get(buSpecificAutoEmail.Default_Automated_Email_From_Address__c).add(buSpecificAutoEmail.Business_Unit__c);

            if(!mBusUnitVsReplyToAddress.containsKey(buSpecificAutoEmail.Business_Unit__c)){
                mBusUnitVsReplyToAddress.put(buSpecificAutoEmail.Business_Unit__c,buSpecificAutoEmail.Reply_To_Address__c);
            }
        }
        for(OrgWideEmailAddress OWA : [select Id,Address,Purpose from OrgWideEmailAddress WHERE Address=:mBusUnitVsDefaultFromAddress.keySet()]){
            if(mBusUnitVsDefaultFromAddress.containsKey(OWA.Address)){
                for(String strBusUnit : mBusUnitVsDefaultFromAddress.get(OWA.Address)){
                    mBusinessUnitVsSpecificOWA.put(strBusUnit,OWA.Id);
                }
            }
        }
        /******* VIRENDRA - ADDED on 12 APRIL 2024 FOR INFOSEC REQUIREMENT *********/

        /* Account Contact Related Operations */
        getAccountAndContactIdsAndLeadIds(peLogs);
        List<Contact> contactList = ASF_CommPETriggerQueryHandler.getCustomerContact(caseAccountIds, caseConIds);
        for(Contact c : contactList){
            //Build AccountId to Set of ContactId map.
            if(!mAccountIdContactId.containsKey(c.AccountId)){
                mAccountIdContactId.put(c.AccountId,new Set<Contact>());
            }
            mAccountIdContactId.get(c.AccountId).add(c);
        }
        accountMap = new Map<Id, Account>([SELECT Id, Phone FROM Account WHERE Id IN :caseAccountIds]);
        defaultContactId = [select id, Account.Phone from contact limit 1].Id;
        oppFieldInfo = Schema.SObjectType.Opportunity.fields.getMap();
        /* Account Contact Related Operations */

        List<Customer_Notification_Config__mdt> custMetaList = ASF_CommPETriggerQueryHandler.getCustomMetadataList(customMetadataName);
        
        for(Customer_Notification_Config__mdt custMeta : custMetaList){
            if(!mCommConfigMetaName.containsKey(custMeta.developerName)){
                mCommConfigMetaName.put(custMeta.developerName, custMeta);
            }
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
            catch(exception e) {
                responseWrapper cls = new responseWrapper(pLog.Id, 'Error', 'No template found in Customer_Notification_Config__mdt');
                peLogIdVsSuccessResult.put(pLog.Id,cls);
            }
        }

        if(setTemplates.size() > 0) {
            emailTemplates = ASF_CommPETriggerQueryHandler.getEmailTemplates(setTemplates); 
            getEmailTempDevNameVsId();
        }
        /* SMS And WhatsApp Related Template Information from Custom Metadata Related Operations */
        
        createLogs(peLogs, null);
        sendEmailCommunication(peLogs);
        sendCommunications(false,peLogs);
        updateLog();

        return peLogIdVsSuccessResult;
    }

    /**
     * @description Updates the communication log records.
     */
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
    
    private static Messaging.SingleEmailMessage getMessageCommonVariables(Contact con, Opportunity opp, Id owdID){
        Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
        msg.setOrgWideEmailAddressId(owdID);
        if(con != null){
            msg.setTargetObjectId(con.Id);
            msg.setTreatTargetObjectAsRecipient(true);  
            msg.setToAddresses(new String[]{con.Email});
        }
        else{
            msg.setTargetObjectId(defaultContactId);
            msg.setTreatTargetObjectAsRecipient(false);
            //msg.setToAddresses(new String[]{con.SuppliedEmail});
        }

        /******* VIRENDRA - ADDED on 12 APRIL 2024 FOR INFOSEC REQUIREMENT *********/
        if(mBusinessUnitVsSpecificOWA.containsKey(subLob)){
            OWDId = mBusinessUnitVsSpecificOWA.get(subLob);
            msg.setOrgWideEmailAddressId(OWDId);
        }
        if(mBusUnitVsReplyToAddress.containsKey(subLob)){
            String replyAddr = mBusUnitVsReplyToAddress.get(subLob);
            msg.setReplyTo(replyAddr);
        }
        /******* VIRENDRA - ENDS HERE on 12 APRIL 2024 FOR INFOSEC REQUIREMENT *********/

        return msg;
    }

    /**
     * @description Generates a single email message based on provided parameters.
     * 
     * @param con The contact associated with the email.
     * @param cRec The case record associated with the email.
     * @param eTempId The email template ID.
     * @param owdID The organization-wide email address ID.
     * @param isAttachment Indicates if attachments need to be included.
     * @param prospect The lead associated with the email.
     * @return Messaging.SingleEmailMessage The generated email message.
     */
    private static Messaging.SingleEmailMessage getMessageGenerated(Contact con, Id eTempId, Id owdID, Opportunity opp, String ccAddresses) {
        Messaging.SingleEmailMessage msg = getMessageCommonVariables(con, opp, owdID);

        msg.setTemplateId(eTempId);
        msg.setWhatId(opp.Id);
        msg.setSaveAsActivity(true);
        if (msg.getOrgWideEmailAddressId() == null){
            msg.setOrgWideEmailAddressId(owdID);
        }

        if (ccAddresses != null) {
            List<String> ccAddressList = ccAddresses.deleteWhitespace().split(';');
            msg.setCCAddresses(ccAddressList);
        }
        return msg;
    }

    /**
     * @description Sends email communication based on the provided PE Logger records.
     * @param peLogs A list of PE Logger records.
     */
    private static void sendEmailCommunication(List<PE_Logger__c> peLogs){
        List<Messaging.SingleEmailMessage> emails =  new List<Messaging.SingleEmailMessage>();
        OrgWideEmailAddress owAddress = [select Id,Purpose from OrgWideEmailAddress WHERE DisplayName = :System.Label.ASF_default_no_reply_email_address limit 1];
        
        for(PE_Logger__c pLog : peLogs){
            if(!mOpps.containsKey(pLog.Opportunity_ID__c)){
                continue;
            }
            Opportunity oppRec = mOpps.get(pLog.Opportunity_ID__c);
            if(templateIDMap.containsKey(pLog.Email_Template_Name__c)){
                if(templateIDMap.get(pLog.Email_Template_Name__c) == null){
                    continue;
                }
            }
                
            if(templateIDMap.containsKey(pLog.Email_Template_Name__c)){
                Id emailtempid = templateIDMap.get(pLog.Email_Template_Name__c).Id;

                if(pLog.Send_To_Specific_Emails__c){
                    if(pLog.Specific_To_Address__c != null){
                        List<String> toSpecificAddresses = pLog.Specific_To_Address__c.deleteWhitespace().split(';');
                        Contact contactRec;
                        if (mAccountIdContactId.containsKey(oppRec.AccountId)) {
                            for(Contact con : mAccountIdContactId.get(oppRec.AccountId)) {
                                contactRec = con;
                                break;
                            }
                        }
                        Messaging.SingleEmailMessage msg = getMessageGenerated(contactRec, emailtempid, owAddress.Id, oppRec, pLog.CC_Addresses__c);
                        msg.setToAddresses(toSpecificAddresses);
                        emails.add(msg); 
                        mIdxVsPELoggerId.put(iCounter,pLog.Id);
                        iCounter++;
                    }
                } else if(mAccountIdContactId.containsKey(oppRec.AccountId)){ // though this is a loop, there's only one contact for ABHI Accounts, so this loops only once
                    for(Contact con : mAccountIdContactId.get(oppRec.AccountId)){
                        if(con.Email != null){
                            Messaging.SingleEmailMessage msg = getMessageGenerated(con, emailtempid, owAddress.Id, oppRec, pLog.CC_Addresses__c);                                
                            emails.add(msg); 
                            mIdxVsPELoggerId.put(iCounter,pLog.Id);
                            iCounter++;
                        }
                    }
                }
            }
        }
        
        // Send email logic moved to first.
        if(emails.size()>0){
            Messaging.SendEmailResult[] msgResults= Messaging.sendEmail(emails,false);
            List<Messaging.SingleEmailMessage> retryEmailSend = new List<Messaging.SingleEmailMessage>();
            
            for(integer i=0;i<msgResults.size();i++){
                if(!msgResults[i].IsSuccess()){
                    retryEmailSend.add(emails[i]);
                }
            }
            if(retryEmailSend.size()>0) {
                Messaging.SendEmailResult[] msgRetryResults= Messaging.sendEmail(retryEmailSend,false);
                for(integer i=0;i<msgRetryResults.size();i++){
                    if(!msgRetryResults[i].IsSuccess()){
                        String errMsg = msgRetryResults[i].getErrors().get(0).getMessage();                        
                    }
                }
            }
            
            for (Integer i=0;i<msgResults.size();i++){
                if (!msgResults[i].isSuccess()){
                    String errMsg = msgResults[i].getErrors().get(0).getMessage();
                    if(mIdxVsPELoggerId.containsKey(i)){
                        responseWrapper cls = new responseWrapper(mIdxVsPELoggerId.get(i) ,'Error','Error Sending Email ' + errMsg);
                        peLogIdVsSuccessResult.put(mIdxVsPELoggerId.get(i) ,cls);
                    }
                } else {
                    if(mIdxVsPELoggerId.containsKey(i)){
                        responseWrapper cls = new responseWrapper(mIdxVsPELoggerId.get(i) ,'Success','' );
                        peLogIdVsSuccessResult.put(mIdxVsPELoggerId.get(i) ,cls);
                    }
                }
            }
        }
    }

    /**
     * @description Sends communications via SMS and WhatsApp based on the provided PE Logger records.
     * @param skipPE A boolean flag to skip publishing Platform Events.
     * @param peLogs A list of PE Logger records.
     */
    public static void sendCommunications(Boolean skipPE, List<PE_Logger__c> peLogs){
        List<Outbound_Communication__e> smsEventList = new List<Outbound_Communication__e>();
        List<ABCL_Integration_Event__e> whatsAppEventList = new List<ABCL_Integration_Event__e>();

        // For SMS and WhatsApp
        for(ASF_Communication_Log__c log : logs){
            if(log.Id == null){
                continue;
            }
            if (!String.isEmpty(log.SMS_LT_Name__c) && log.Phone__c != null) {
                String smsTemplateId = templateIDMap.get(log.SMS_LT_Name__c).Id;
                
                if(smsTemplateId == null){
                    responseWrapper cls = new responseWrapper(log.PE_Logger_Id__c ,'Error','SMS template not found for name ' + log.SMS_LT_Name__c);
                    peLogIdVsSuccessResult.put(log.PE_Logger_Id__c ,cls);
                } else{
                    if (log.Contact__c != null) {
                        log.SMS_Msg_Body__c = generateMessageBody(smsTemplateId, log.Contact__c, log.Renewal_Request__c, true); 
                    } else if(log.Send_To_Specific_Mobile__c){
                        log.SMS_Msg_Body__c = generateMessageBody(smsTemplateId, defaultContactId, log.Renewal_Request__c, true); 
                    }

                    responseWrapper cls = new responseWrapper(log.PE_Logger_Id__c,'Success','',log.id,log.SMS_Msg_Body__c);
                    peLogIdVsSuccessResult.put(log.PE_Logger_Id__c,cls);
                    smsEventList.add(createOutboundCommunication(log, 'SMS'));
                }
            }
            
            if (!String.isEmpty(log.WhatsApp_LT_Name__c)) {
                responseWrapper cls = new responseWrapper(log.PE_Logger_Id__c, 'Success','', log.id, '');
                peLogIdVsSuccessResult.put(log.PE_Logger_Id__c,cls);
                ABCL_Integration_Event__e comm = createWhatsAppCommunicationEvent(log);
                whatsAppEventList.add(comm);
            }
        }
        
        if(!skipPE){
            system.debug('*******smsEventList: ' + smsEventList + '*****whatsAppEventList: ' + whatsAppEventList);
            List<Database.SaveResult> resultsSMS = EventBus.publish(smsEventList);
            List<Database.SaveResult> resultsWhatsApp = EventBus.publish(whatsAppEventList);
        }
    }
    
    /**
     * @description Generates the message body based on the provided email template ID, recipient ID, and related record ID.
     * @param templateID The ID of the email template.
     * @param whoID The ID of the recipient.
     * @param whatID The ID of the related record.
     * @param isPlainText A boolean value indicating whether to return plain text message or HTML message.
     * @return The generated message body.
     */
    private static String generateMessageBody(String templateID, String whoID, String whatID, Boolean isPlainText){
        Messaging.SingleEmailMessage msg = Messaging.renderStoredEmailTemplate(templateID, whoId, whatID, Messaging.AttachmentRetrievalOption.NONE); 
        String richTextMessage = msg.getHtmlBody(); 
        return isPlainText ? richTextMessage.StripHtmlTags() : richTextMessage;
    }

    /**
     * @description Creates an Outbound_Communication__e event based on the provided ASF_Communication_Log__c object and message type.
     * @param log The ASF_Communication_Log__c object containing communication log details.
     * @param msgType The type of message (e.g., "SMS", "WhatsApp").
     * @return The created Outbound_Communication__e event.
     */
    private static Outbound_Communication__e createOutboundCommunication(ASF_Communication_Log__c log, String msgType){
        Outbound_Communication__e event = new Outbound_Communication__e(LogID__c = log.id, Template_ID__c = log.External_Template_ID__c,
            Phone__c = log.Phone__c, Txt_Msg__c = log.SMS_Msg_Body__c, LOB__c = log.LOB__c, Type__c = msgType, SMS_Entity_Id__c = log.SMS_Entity_Id__c,
            SMS_Sender_Id__c = log.SMS_Sender_Id__c);
        return event;
    }

    private static ABCL_Integration_Event__e createWhatsAppCommunicationEvent(ASF_Communication_Log__c log) {
        Opportunity oppRec = mOpps.get(log.Renewal_Request__c);
        ABCL_Integration_Event__e event = new ABCL_Integration_Event__e(Business_Unit__c = 'ABHI-RNWL', ObjectApiName__c = 'ASF_Communication_Log__c',
            Record_Id__c = log.Id, ServiceName__c = 'ClickPSSCommunication');
        WhatsAppAPIRequestWrapper requestWrap = new WhatsAppAPIRequestWrapper();
        requestWrap.AlertID = log.External_Template_ID__c;
        requestWrap.Mobileno = log.Phone__c;
        requestWrap.AppNo = oppRec.Proposal_Number__c;
        requestWrap.ReqId = oppRec.Policy_Number__c;
        requestWrap.PolicyID = oppRec.Policy_Number__c;
        String serializedRequest = JSON.serialize(requestWrap);
        Map<String,Object> untypedObj =  (Map<String,Object>) JSON.deserializeUntyped(serializedRequest);

        // currently only 5 merge fields exist at most, increase this as per need
        for (Integer i = 1; i < 6; i++) {
            Object mergeValue = log.get(channelFieldNamesWA[1] + i + '__c');
            untypedObj.put('AlertV' + i, mergeValue);
        }
        event.Request__c = JSON.serialize(untypedObj);
        return event;
    }

    /**
     * @description Creates ASF_Communication_Log__c records based on the provided PE_Logger__c records and selected contact.
     * @param peLogs The list of PE_Logger__c records.
     * @param selectedCon The selected contact.
     */
    private static void createLogs(List<PE_Logger__c> peLogs, Contact selectedCon) {
        List<ASF_Communication_Log__c> masterLogs = new List<ASF_Communication_Log__c>();

        for(PE_Logger__c pLog : peLogs){
            //Bypass sending SMS when user manually blocks it during case creation
            if(pLog.CustomMetadataName__c != null && mCommConfigMetaName.containsKey(pLog.CustomMetadataName__c)){
                String strMetadataName = pLog.CustomMetadataName__c;
                Customer_Notification_Config__mdt commConfig = mCommConfigMetaName.get(strMetadataName);
                
                // SMS Related
                if(commConfig != null && commConfig.SMS_Template_Name__c != null){
                    setOpportunityFields(commConfig,channelFieldNamesSMS[0]);
                }
                
                // WhatsApp Related
                if(commConfig != null && commConfig.Whatsapp_Template_Name__c !=null){
                    setOpportunityFields(commConfig,channelFieldNamesWA[0]);
                }
            }
        }
        setOpportunityFields.add('AccountId');
        setOpportunityFields.add('Policy_Number__c');
        setOpportunityFields.add('Name');
        setOpportunityFields.add('Proposal_Number__c');
        String query = 'SELECT ID, AccountId, Policy_Number__c, Name, Proposal_Number__c';
        query += ' FROM OPPORTUNITY WHERE ID IN :opportunityIds';
        if (setOpportunityFields !=null && setOpportunityFields.size() > 0) {
            List<string> temp = new List<String>();
            temp.addAll(setOpportunityFields);
            query = 'SELECT ID, ' + String.escapeSingleQuotes(String.join(temp, ','));
            query = query.removeEnd(',');
            query += ' FROM OPPORTUNITY WHERE ID IN :opportunityIds';
        }
        List<Opportunity> opportunityRecs = (List<Opportunity>) Database.query(query);
        mOpps = new Map<Id, Opportunity>(opportunityRecs);

        Map<Id, ASF_Communication_Log__c> mPeLogIdCommunicationLog = new Map<Id, ASF_Communication_Log__c>();
        for(PE_Logger__c pLog : peLogs){
            //Bypass sending SMS when user manually blocks it during case creation
            if(pLog.CustomMetadataName__c == null) {
                continue;
            }
            String strMetadataName = pLog.CustomMetadataName__c;
            Opportunity opp = mOpps.get(pLog.Opportunity_ID__c);
            ASF_Communication_Log__c masterlog = new ASF_Communication_Log__c();
            Customer_Notification_Config__mdt commConfig = mCommConfigMetaName.get(strMetadataName);

            if (commConfig != null) {
                if (commConfig.SMS_Template_Name__c != null) {
                    if (commConfig.get(channelFieldNamesSMS[3]) != null) {
                        populateMergeFields(channelFieldNamesSMS, commConfig, opp, masterlog, mPeLogIdCommunicationLog, oppFieldInfo, pLog.Id);
                    }
                } 
                if (commConfig.Whatsapp_Template_Name__c != null) {
                    if (commConfig.get(channelFieldNamesWA[3]) != null) {
                        populateMergeFields(channelFieldNamesWA, commConfig, opp, masterlog, mPeLogIdCommunicationLog, oppFieldInfo, pLog.Id);
                    }
                }
            }
        }
        for(PE_Logger__c pLog : peLogs){
            if(!mPeLogIdCommunicationLog.containsKey(pLog.Id)){
                continue;
            }
            ASF_Communication_Log__c cLog = mPeLogIdCommunicationLog.get(pLog.Id);
            ASF_Communication_Log__c log = cLog.clone(false, true,false, false);
            Opportunity oppRec = mOpps.get(pLog.Opportunity_ID__c);

            if(pLog.Send_To_Specific_Mobile__c){
                if(pLog.Specific_To_MobilePhone__c != null){
                    log = createCommunicationLogRecord(log, null, null, oppRec.Id, 'Customer', pLog.Specific_To_MobilePhone__c, pLog);
                    log.put('PE_Logger_Id__c',pLog.Id);
                    log.LOB__c = pLog.LOB__c;
                    log.put('Status__c','In Progress');
                    log.put('Send_To_Specific_Mobile__c',pLog.Send_To_Specific_Mobile__c);
                    logs.add(log);
                }
            // send it to the person account/contact. Though there is a loop, this only runs once as ABHI Accounts have only one contact
            } else if(mAccountIdContactId.containsKey(oppRec.AccountId)) {
                for (Contact con : mAccountIdContactId.get(oppRec.AccountId)){
                    if (mPeLogIdCommunicationLog.containsKey(pLog.Id) && con.Account.Phone != null) {
                        log = cLog.clone(false, true,false, false);
                        log = createCommunicationLogRecord(log, oppRec.AccountId, con.Id, oppRec.Id, con.Name, con.Account.Phone, pLog);
                        
                        if(con.Account.Phone != null &&  !String.isEmpty(log.SMS_LT_Name__c)){
                            log.put('Status__c','In Progress');
                        }

                        log.put('Contact_Email__c', con.email);
                        log.put('PE_Logger_Id__c',pLog.Id);
                        log.LOB__c = pLog.LOB__c;
                        logs.add(log);
                    }
                }
            } else if (accountMap.containsKey(oppRec.AccountId) && accountMap.get(oppRec.AccountId).Phone != null) {
                log = createCommunicationLogRecord(log, null, null, oppRec.Id, 'Customer', accountMap.get(oppRec.AccountId).Phone, pLog);
                log.put('PE_Logger_Id__c', pLog.Id);
                log.LOB__c = pLog.LOB__c;
                log.put('Status__c','In Progress');
                log.put('Send_To_Specific_Mobile__c', true);
                log.put('Phone__c', accountMap.get(oppRec.AccountId).Phone);
                logs.add(log);
            } else{
                responseWrapper cls = new responseWrapper(pLog.Id,'Error', 'Phone number is missing on Account');
                peLogIdVsSuccessResult.put(pLog.Id,cls);
            }
        }
        if(logs.size()>0){
            Database.SaveResult[] results = Database.insert(logs,false);
            for(integer i =0;i<logs.size();i++){
                if(results[i].isSuccess()){
                    responseWrapper cls = new responseWrapper(logs[i].PE_Logger_Id__c ,'Completed','');
                    peLogIdVsSuccessResult.put(logs[i].PE_Logger_Id__c ,cls);
                    mLogIdVsCaseId.put(logs[i].Id,logs[i].Case__c);
                }
                else{
                    responseWrapper cls = new responseWrapper(logs[i].PE_Logger_Id__c ,'Error',results[i].getErrors().get(0).getMessage());
                    peLogIdVsSuccessResult.put(logs[i].PE_Logger_Id__c ,cls);
                    
                }
            }
        }
    }

    /**
     * @description Retrieves the developer name and ID mapping of email templates and stores them in the templateIDMap.
     */
    private static void getEmailTempDevNameVsId(){
        for(EmailTemplate template : emailTemplates){
            templateIDMap.put(template.DeveloperName,template);
        }
    }
    /**
     * @description Retrieves the template names from the provided custom metadata name and adds them to the setTemplates collection. 
     * @param strMetadataName The name of the custom metadata.
     */
    private static void getTemplateNamesFromConfig(String strMetadataName){
        Customer_Notification_Config__mdt commConfig = mCommConfigMetaName.get(strMetadataName);
        
        Object smsTemplateName = commConfig.get(channelFieldNamesSMS[3]); 
        if(smsTemplateName != null){
            setTemplates.add(smsTemplateName.tostring());
        }
        
        Object waTemplateName = commConfig.get(channelFieldNamesWA[3]);
        if(waTemplateName != null){
            setTemplates.add(waTemplateName.tostring());
        }
    }
    /**
     * @description Wrapper class to encapsulate response information.
     */
    public class responseWrapper{
        /**
         * @description The ID associated with the log.
         */
        public string logId{get;set;} 
        /**
         * @description The status of the response.
         */
        public string status{get;set;} 
        /**
         * @description The message content of the response.
         */
        public string message{get;set;}
        /**
         * @description The template content of the response.
         */
        public string template{get;set;}
        /**
         * @description The ID associated with the communication.
         */
        public string communicationId{get;set;}
        /**
         * @description Constructs a response wrapper object with the provided parameters.
         * @param lId The ID associated with the log.
         * @param st The status of the response.
         * @param msg The message content of the response.
         */
        public responseWrapper(string lId,string st,string msg){
            this.logId = lId;
            this.status = st;
            this.message = msg;
        }
        /**
         * @description Constructs a response wrapper object with the provided parameters.
         * @param lId The ID associated with the log.
         * @param st The status of the response.
         * @param msg The message content of the response.
         * @param comId The ID associated with the communication.
         * @param body The template body.
         */
        public responseWrapper(string lId,string st,string msg, String comId, String body){
            this.logId = lId;
            this.status = st;
            this.message = msg;
            this.template = body;
            this.communicationId = comId;
        }
    }
    /**
     * @description Populates sets of relevant Ids from PE_Logger__c records.
     * @param peLogs List of PE_Logger__c records.
     */
    private static void getAccountAndContactIdsAndLeadIds(List<PE_Logger__c> peLogs){
        for(PE_Logger__c pLog : peLogs){
            customMetadataName.add(pLog.CustomMetadataName__c);
            opportunityIds.add(pLog.Opportunity_ID__c);
            if(pLog.AccountId__c != null){
                caseAccountIds.add(pLog.AccountId__c);
            }
            if(pLog.ContactId__c != null){
                caseConIds.add(pLog.ContactId__c);
            }
        }
    }
    /**
     * @description Sets case fields based on the provided Customer_Notification_Config__mdt record and developer name.
     * @param commConfig The Customer_Notification_Config__mdt record.
     * @param developerName The developer name of the field.
     */
    private static void setOpportunityFields(Customer_Notification_Config__mdt commConfig, String developerName){
        String mergeFieldCSV = (String) commConfig.get(developerName);
        if(mergeFieldCSV !=null && String.IsNotBlank(mergeFieldCSV)){
            setOpportunityFields.addAll(mergeFieldCSV.split(','));
        }
    }

    /**
     * @description Creates an ASF_Communication_Log__c record with the provided details.
     * @param log The ASF_Communication_Log__c record to populate.
     * @param accountId The ID of the account.
     * @param contactId The ID of the contact.
     * @param caseId The ID of the case.
     * @param contactName The name of the contact.
     * @param mobNo The mobile number associated with the communication.
     * @param leadId The ID of the lead.
     * @return The populated ASF_Communication_Log__c record.
     */
    private static ASF_Communication_Log__c createCommunicationLogRecord(ASF_Communication_Log__c log, Id accountId, Id contactId, Id opportunityId, String contactName, String mobNo, PE_Logger__c pLog) {
        log.put('Account__c',accountId);
        log.put('Renewal_Request__c', opportunityId);  
        log.put('Contact__c',contactId);
        log.put('Contact_Name__c',contactName);
        log.put('Phone__c', mobNo);
        log.put('Created_On__c', pLog.CreatedDate);
        log.put('Created_By__c', pLog.CreatedById);
        return log;
    }

    public static void populateMergeFields(String[] channelFieldNames, Customer_Notification_Config__mdt comm_config, Opportunity oppRecord, ASF_Communication_Log__c masterlog,
        Map<Id,ASF_Communication_Log__c> mPeLogIdCommunicationLog, Map<String, Schema.SObjectField> oppFieldInfo, Id pLogId) {
        Object mergeCSVField = comm_config.get(channelFieldNames[0]);

        if (mergeCSVField != null) {
            List<String> mergeFields = mergeCSVField.tostring().split(',');
            String mergeField, fieldName, fieldValue;
            
            for (Integer counter = 1; counter <= mergeFields.size(); counter++) {
                mergeField = mergeFields[counter-1].trim();
                // currently none of the merge fields are parent object fields so limiting the code to object specific fields only. 
                // in future if templates need parent fields, update this to use getSobject method similar to other communication helpers
                Schema.DisplayType FldType = oppFieldInfo.get(mergeField).getDescribe().getType();
                if(FldType == Schema.DisplayType.DateTime){
                    Datetime dt = (Datetime) oppRecord.get(mergeField);
                    if (dt!=null) {
                        fieldValue = dt.format();
                    }  
                } else if(FldType == Schema.DisplayType.Date){
                    Date dt = (Date) oppRecord.get(mergeField);
                    if(dt!=null)
                        fieldValue = dt.format();
                } else{
                    fieldValue = String.valueOf(oppRecord.get(mergeField));
                }
                fieldName = channelFieldNames[1] + counter + '__c';
                masterlog.put(fieldName, fieldValue);
            }
        }
        
        String tempFieldAPIName = channelFieldNames[2];

        masterlog.put(tempFieldAPIName, comm_config.get(channelFieldNames[3]).tostring()); //have same field name on both objects
        masterlog.put('External_Template_ID__c', comm_config.external_templateID__c);
        masterlog.put('SMS_Sender_Id__c', comm_config.SMS_Sender_Id__c );
        masterlog.put('SMS_Entity_Id__c', comm_config.SMS_Entity_Id__c );
        if (comm_config.get(channelFieldNames[3]) != null && templateIDMap.containsKey(comm_config.get(channelFieldNames[3]).tostring())) {
            masterlog.put('Template_Name__c', templateIDMap.get(comm_config.get(channelFieldNames[3]).tostring()).Name);
        }

        mPeLogIdCommunicationLog.put(pLogId, masterlog);   
    }

    public class WhatsAppAPIRequestWrapper {
        public String AlertMode = '4'; // set to 4 as this is only used for WhatsApp now
        public String AlertID;
        public String ChannelID = 'SFCRM';
        public String AppNo;
        public String Field1 = 'NA'; // hardcoded - unused tags
        public String Field2 = 'NA'; // hardcoded - unused tags
        public String Field3 = 'NA'; // hardcoded - unused tags
        public String ReqId;
        public String PolicyID;
        public String Mobileno;
    }
}