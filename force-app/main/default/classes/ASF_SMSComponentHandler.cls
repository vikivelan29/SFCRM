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
public without sharing class ASF_SMSComponentHandler {
    public enum Channel {SMS, Whatsapp, Email}
    public static List<ASF_Communication_log__c> logs = new List<ASF_Communication_log__c>();
    public static set<String> setCaseFields = new Set<String>();
    public static List<Customer_Notification_Config__mdt>  comm_configs; 
    public static Map<String, Schema.SObjectField> casefieldInfo;
    
    public static Map<String,Id> templateIDMap = new Map<String,Id>();
    
    public static Map<Id,String> mCaseIdMetadataName = new Map<Id,String>();
    
    public static Map<String,Customer_Notification_Config__mdt> mCommConfigMetaName = new Map<String,Customer_Notification_Config__mdt>();
    public static Map<Id,Boolean> mCaseHasTemplate = new Map<Id,Boolean>();
    public static Map<Id,responseWrapper> caseIdVsSuccessResult = new Map<Id,responseWrapper>();
    
    @AuraEnabled
    public static String getTemplate(Id caseId,String templateMetaData, Boolean isGenerateOnlyTemplate, Id conId,Boolean finalSend){
        Contact selectedCon = null;
        Lead selectedProspect = null;
        if(conId.getsObjectType() == Contact.sObjectType){
            selectedCon = [SELECT Id, Name, Email, AccountId, MobilePhone FROM contact WHERE Id =: conId];
        }
        if(conId.getsObjectType() == Lead.sObjectType){
            selectedProspect = [SELECT ID, Name, Email, MobilePhone FROM Lead WHERE Id =: conId];
        }
        
        if(!isGenerateOnlyTemplate && !finalSend){
            //&& !ASF_WhatsappCommunicationParser.checkEnrolmentStatus(conId)){
            AuraHandledException auraEx = new AuraHandledException('');
            throw auraEx;  
        }
        Set<Id> caseIds = new Set<Id>();
        caseIds.add(caseId);
        Map<Id,String> mCaseVsMetadata = new Map<Id,String>();
        mCaseVsMetadata.put(caseId,templateMetaData);
        Map<Id,responseWrapper> responseMap =  executeContructor(caseIds,mCaseVsMetadata,isGenerateOnlyTemplate, selectedCon,selectedProspect);
        if(responseMap.values()[0].status.toUpperCase()=='ERROR'){
            AuraHandledException auraEx = new AuraHandledException(responseMap.values()[0].message);
            throw auraEx; 
        }
        if(isGenerateOnlyTemplate){
            List<responseWrapper> resp = responseMap.values();
            List<ASF_Communication_Log__c> logLst = new List<ASF_Communication_Log__c>();
            List<Id> logIdLst = new List<Id>();
            for(responseWrapper res: resp){
                logIdLst.add(res.communicationId);
            }
            for(ASF_Communication_Log__c log: [SELECT Id FROM ASF_Communication_Log__c where Id IN :logIdLst]){
                logLst.add(log);
            }
            if(logLst.size()>0){
                delete logLst;
            }
        }
        // System.debug('>>>>> WA MSG BODY\n'+responseMap);
        return JSON.serialize(responseMap.values());
    }
    
    public static Map<Id,responseWrapper> executeContructor(Set<Id> caseIds,Map<Id,String> mCaseVsMetadata){
        return executeContructor(caseIds,mCaseVsMetadata,false,null,null);
    }
    
    public static Map<Id,responseWrapper> executeContructor(Set<Id> caseIds,Map<Id,String> mCaseVsMetadata, Boolean skipPE, Contact selectedCon, Lead selectedProspect){
        
        
        casefieldInfo = Schema.SObjectType.Case.fields.getMap();
        Map<Id,Set<String>> mCaseIdTemplates = new Map<Id,Set<String>>();
        Set<String> templateName = new Set<String>();
        mCaseIdMetadataName = mCaseVsMetadata;
        
        comm_configs = [select id,developerName,Email_Merge_Fields_CSV__c,Email_Template_Name__c,SMS_Merge_Fields_CSV__c,SMS_Template_Name__c,Whatsapp_Merge_Fields_CSV__c,Whatsapp_Template_Name__c,external_templateID__c,
                        SMS_Sender_Id__c,SMS_Entity_Id__c
                        from Customer_Notification_Config__mdt where developerName =: mCaseVsMetadata.values()];
        for(Customer_Notification_Config__mdt cncmdt : comm_configs){
            //Build CustomMetadata Developer Name Vs CustomMetadata map.
            if(!mCommConfigMetaName.containsKey(cncmdt.developerName)){
                mCommConfigMetaName.put(cncmdt.developerName,cncmdt);
            }                
            
        }
        
        
        String[] channelFieldNames = getMergefieldNames(Channel.SMS);
        
        
        for(Id caseId : mCaseIdMetadataName.keySet()){
            //SMS
            try{
                Set<String> setTemplates = new Set<string>();
                
                String strMetadataName = mCaseIdMetadataName.get(caseId);
                Customer_Notification_Config__mdt comm_config = mCommConfigMetaName.get(strMetadataName);
                Object SMStemplateName = comm_config.get(channelFieldNames[3]); 
                if(SMStemplateName != null)
                    setTemplates.add(SMStemplateName.tostring());
                
                channelFieldNames = getMergefieldNames(Channel.Email);
                Object emailTemplateName = comm_config.get(channelFieldNames[3]);
                if(emailTemplateName != null)
                    setTemplates.add(emailTemplateName.tostring());
                
                channelFieldNames = getMergefieldNames(Channel.WhatsApp);
                Object waTemplateName = comm_config.get(channelFieldNames[3]);
                if(waTemplateName != null)
                    setTemplates.add(waTemplateName.tostring());
                
                if(!mCaseIdTemplates.containsKey(caseId)){
                    if(setTemplates.size()>0){
                        mCaseIdTemplates.put(caseId,setTemplates);
                        mCaseHasTemplate.put(caseId,true);
                    }
                    else{
                        mCaseHasTemplate.put(caseId,false);
                    }
                    
                }
                templateName.addAll(setTemplates);
            }
            catch(exception e){
                responseWrapper cls = new responseWrapper(caseId,'Error','No template found in Customer_Notification_Config__mdt');
                caseIdVsSuccessResult.put(caseId,cls);
            }
        }
        
        for(EmailTemplate template : [SELECT Id,DeveloperName FROM EmailTemplate WHERE DeveloperName IN: templateName ]){
            // Build Template DeveloperName vs Id map.
            templateIDMap.put(template.DeveloperName,template.Id);
        }
        
        
        
        System.debug('/// CREATE LOGS START HERE ///');
        createLogs(selectedCon,selectedProspect);
        sendCommunications(skipPE);
        updateLog();
        
        return caseIdVsSuccessResult;
        
    }
    public static void createLogs(Contact selectedCon, Lead selectedProspect){
        List<ASF_Communication_Log__c> masterLogs = new List<ASF_Communication_Log__c>();
        
        for(Id caseId : mCaseIdMetadataName.keySet()){
            if(!mCaseHasTemplate.containsKey(caseId)){
                continue;
                // Process next Case if No Template for Current Case.
            }
            String strMetadataName = mCaseIdMetadataName.get(caseId);
            Customer_Notification_Config__mdt comm_config = mCommConfigMetaName.get(strMetadataName);
            
            if(comm_config != null && comm_config.SMS_Template_Name__c != null){
                String[] channelFieldNames = getMergefieldNames(Channel.SMS);
                String mergeFieldCSV = (String) comm_config.get(channelFieldNames[0]);
                if(mergeFieldCSV !=null && String.IsNotBlank(mergeFieldCSV)){
                    setCaseFields.addAll(mergeFieldCSV.split(','));
                }
                
            }
        }
        if(setCaseFields !=null && setCaseFields.size()>0){
            List<string> temp = new List<String>();
            temp.addAll(setCaseFields);
            System.debug(mCaseIdMetadataName);
            Set<Id> temp_cIds = mCaseIdMetadataName.keySet();
            String query = 'SELECT ID,Business_Unit__c,AccountId,ContactEmail,contact.Name,ContactMobile,ContactId,SuppliedEmail,origin,'+String.join(temp, ',');
            query = query.removeEnd(',');
            query += ' FROM CASE WHERE ID IN :temp_cIds';
            List<Case> cases = (List<case>)Database.query(query);
            System.debug(cases);
            Map<Id,ASF_Communication_Log__c> mCaseIdCommunicationLog = new Map<Id,ASF_Communication_Log__c>();
            for(Case cRec : cases){
                
                if(!mCaseHasTemplate.containsKey(cRec.Id)){
                    continue;
                    // Process next Case if No Template for Current Case.
                }
                ASF_Communication_Log__c masterlog = new ASF_Communication_Log__c();
                String strMetadataName = mCaseIdMetadataName.get(cRec.Id);
                Customer_Notification_Config__mdt comm_config = mCommConfigMetaName.get(strMetadataName);
                
                if(comm_config.SMS_Template_Name__c != null){
                    String[] channelFieldNames = getMergefieldNames(Channel.SMS);
                    if(comm_config.get(channelFieldNames[3]) != null){
                        populateMergeFields(channelFieldNames,comm_config,cRec,masterlog,mCaseIdCommunicationLog);
                    }
                }
            }
            for(Case cRec : cases){
                if(!mCaseHasTemplate.containsKey(cRec.Id)){
                    continue;
                }
                ASF_Communication_Log__c cLog = mCaseIdCommunicationLog.get(cRec.Id);
                ASF_Communication_Log__c log = cLog.clone(false, true,false, false);
                
                
                if(selectedCon!=null || selectedProspect != null){
                    if(selectedProspect != null){
                        log.put('Lead__c',selectedProspect.Id);
                        log.put('Phone__c', selectedProspect.MobilePhone);
                        log.put('Contact_Email__c', selectedProspect.email);
                        log.put('Contact_Name__c',selectedProspect.Name);
                        if( selectedProspect.MobilePhone != ''){
                            log.put('Status__c','In Progress');
                        }
                    }
                    else{
                        log.put('Account__c',selectedCon.AccountId);
                        log.put('Contact__c',selectedCon.Id);
                        log.put('Phone__c', selectedCon.MobilePhone);
                        log.put('Contact_Email__c', selectedCon.email);
                        log.put('Contact_Name__c',selectedCon.Name);
                        if( selectedCon.MobilePhone !=''){
                            log.put('Status__c','In Progress');
                        }
                    }
                    log.put('Case__c', cRec.Id);  
                    log.LOB__c = cRec.Business_Unit__c;
                    
                    
                    logs.add(log);
                }else{
                    responseWrapper cls = new responseWrapper(cRec.Id,'Error','Contact/Prospect is not selected');
                    caseIdVsSuccessResult.put(cRec.Id,cls);
                }
                
            }
            
            if(logs.size()>0){
                Database.SaveResult[] results = Database.insert(logs,false);
                for(integer i =0;i<logs.size();i++){
                    if(results[i].isSuccess()){
                        responseWrapper cls = new responseWrapper(logs[i].Case__c,'Completed','');
                        caseIdVsSuccessResult.put(logs[i].Case__c,cls);
                    }
                    else{
                        responseWrapper cls = new responseWrapper(logs[i].Case__c,'Error',results[i].getErrors().get(0).getMessage());
                        caseIdVsSuccessResult.put(logs[i].Case__c,cls);
                    }
                }
            }
        }
        
        
        
    }
    public static void populateMergeFields(String[] channelFieldNames,Customer_Notification_Config__mdt comm_config,case caseRecord,ASF_Communication_Log__c masterlog,Map<Id,ASF_Communication_Log__c> mCaseIdCommunicationLog){
        Object MergeCSVField = comm_config.get(channelFieldNames[0]);
        
        if(MergeCSVField == null)
            return;
        
        List<string> mergeFields = MergeCSVField.tostring().split(',');
        
        string mergeField, fieldName, fieldValue;
        
        for(integer counter = 1; counter<=mergeFields.size(); counter++){
            mergeField = mergeFields[counter-1];
            
            if(mergeField.contains('.')){
                String[] arr = mergeField.split('\\.');
                fieldValue = (String) caseRecord.getSobject(arr[0])?.get(arr[1]);
            }else{
                
                Schema.DisplayType FldType = casefieldInfo.get(mergeField).getDescribe().getType();
                
                if(FldType == Schema.DisplayType.DateTime){
                    Datetime dt = (Datetime) caseRecord.get(mergeField);
                    if(dt!=null){
                        if(mergeField =='CreatedDate')
                            fieldValue = dt.format();
                        else
                            fieldValue = dt.date().format();
                    }
                    
                }else if(FldType == Schema.DisplayType.Date){
                    Date dt = (Date) caseRecord.get(mergeField);
                    if(dt!=null)
                        fieldValue = dt.format();
                }
                else{
                    fieldValue = (String) caseRecord.get(mergeField);
                }
            }
            
            fieldName = channelFieldNames[1] + counter + '__c';
            
            masterlog.put(fieldName,fieldValue);
        }
        
        string tempFieldAPIName = channelFieldNames[2];
        
        masterlog.put(tempFieldAPIName,comm_config.get(channelFieldNames[3]).tostring()); //have same field name on both objects
        masterlog.put('External_Template_ID__c',comm_config.external_templateID__c);
        masterlog.put('SMS_Sender_Id__c',comm_config.SMS_Sender_Id__c );
        masterlog.put('SMS_Entity_Id__c',comm_config.SMS_Entity_Id__c );
        
        
        mCaseIdCommunicationLog.put(caseRecord.Id, masterlog);
        
        
    }
    public static String[] getMergefieldNames(Channel ChannelType){
        
        String mergeFieldCSVName;
        String mergefieldHolderName;
        String templateName;
        String templateFieldName;
        
        switch on ChannelType {
            when SMS {
                mergeFieldCSVName = 'SMS_Merge_Fields_CSV__c';
                mergefieldHolderName = 'SMS_Merge_Field';
                templateName = 'SMS_LT_Name__c';
                templateFieldName = 'SMS_Template_Name__c';
            }   
            when Whatsapp {
                mergeFieldCSVName = 'Whatsapp_Merge_Fields_CSV__c';
                mergefieldHolderName = 'Whatsapp_Merge_Field';
                templateName = 'WhatsApp_LT_Name__c';
                templateFieldName = 'Whatsapp_Template_Name__c';
            }
            when Email {
                mergeFieldCSVName = 'Email_Merge_Fields_CSV__c';
                mergefieldHolderName = 'Email_Merge_Field';
                templateName = 'Email_template_Name__c'; 
                templateFieldName = 'Email_Template_Name__c';
            }
        }
        
        return new string[]{mergeFieldCSVName, mergefieldHolderName, templateName,templateFieldName};
            }
    public static void sendCommunications(Boolean skipPE){
        
        List<Outbound_Communication__e> eventList = new List<Outbound_Communication__e>();
        
        // For SMS and WhatsApp
        for(ASF_Communication_Log__c log : logs){
            if(log.Id != null){
                if(!String.isEmpty(log.SMS_LT_Name__c) && log.Phone__c != null){
                    String smsTemplateId = templateIDMap.get(log.SMS_LT_Name__c);
                    if(smsTemplateId == null){
                        responseWrapper cls = new responseWrapper(log.Case__c,'Error','SMS template not found for name ' + log.SMS_LT_Name__c);
                        caseIdVsSuccessResult.put(log.Case__c,cls);
                    }
                    else{
                        log.SMS_Msg_Body__c = generateMessageBody(smsTemplateId,log.Contact__c,log.id, true);
                        responseWrapper cls = new responseWrapper(log.Case__c,'Success','',log.id,log.SMS_Msg_Body__c);
                        caseIdVsSuccessResult.put(log.Case__c,cls);
                        eventList.add(createOutboundCommunication(log,'SMS'));
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
    public static void updateLog(){
        List<ASF_Communication_Log__c> updLogs = new List<ASF_Communication_Log__c>();
        for(ASF_Communication_Log__c log : logs){
            if(log.Id != null){
                updLogs.add(log);
            }
        }
        
        if(updLogs.size()>0){
            update updLogs;
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
    
}