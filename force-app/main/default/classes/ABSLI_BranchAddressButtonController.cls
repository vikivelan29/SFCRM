public without sharing class ABSLI_BranchAddressButtonController {
    public static final string strMetadataName = 'ABSLI_Branch_Address';
    @AuraEnabled
    public static Branch_Master__c getBranchDetails(String branchId){
        return [SELECT ID,Name,Address__c,Phone__c,City__c,State__c,Pincode__c FROM Branch_Master__c WHERE Id=: branchId LIMIT 1];
    }
    @AuraEnabled(cacheable=true)
    public static String getTemplateBody(String whatId,String branchId){
        Customer_Notification_Config__mdt commMdt= [SELECT ID,SMS_Template_Name__c FROM Customer_Notification_Config__mdt 
                                             WHERE DeveloperName=: strMetadataName ];
        EMAILTemplate eTemplate = [SELECT ID,HTMLValue FROM EMAILTemplate WHERE DeveloperName =: commMdt.SMS_Template_Name__c];
        String retVal = generateMessageBody(eTemplate.Id,UserInfo.getUserId(), branchId,true);
        return retVal;
    }
    private static String generateMessageBody(String templateID, String whoID, String whatID, Boolean isPlainText){
        Messaging.SingleEmailMessage msg = Messaging.renderStoredEmailTemplate(templateID, whoId, whatID, Messaging.AttachmentRetrievalOption.NONE); 
        String richTextMessage = msg.getHtmlBody(); 
        return isPlainText ? richTextMessage.StripHtmlTags() : richTextMessage;
    }
    @AuraEnabled
    public static void sendCommunication(string accountId,string branchId,string unregisteredNumber){
        Contact c = [SELECT ID,MobilePhone,Name FROM Contact WHERE AccountId = : accountId LIMIT 1];
        Customer_Notification_Config__mdt commMdt= [SELECT ID,SMS_Entity_Id__c,
                                                    SMS_Sender_Id__c,SMS_Template_Name__c,external_templateID__c
                                                    FROM Customer_Notification_Config__mdt 
                                             WHERE DeveloperName=: strMetadataName ];
        if(c.MobilePhone != null && c.MobilePhone != ''){
            List<ASF_Communication_Log__c> masterLogs = new List<ASF_Communication_Log__c>();
            String templateBody = getTemplateBody(accountId,branchId);
            ASF_Communication_Log__c cLog = new ASF_Communication_Log__c();
            cLog.Account__c = accountId;
            cLog.Contact__c = c.Id;
            cLog.Contact_Name__c = c.Name;
            cLog.SMS_Entity_Id__c = commMdt.SMS_Entity_Id__c;
            cLog.SMS_Sender_Id__c = commMdt.SMS_Sender_Id__c;
            cLog.SMS_LT_Name__c = commMdt.SMS_Template_Name__c;
            cLog.External_Template_ID__c = commMdt.external_templateID__c;
            cLog.Status__c = 'In Progress';
            cLog.SMS_Msg_Body__c = templateBody;
            cLog.Phone__c = c.MobilePhone;
            if(unregisteredNumber != null && unregisteredNumber != ''){
                cLog.Phone__c = unregisteredNumber;
            }
            
            cLog.LOB__c = 'ABSLI';
            insert cLog;
            System.debug('record Inserted...'+cLog.Id);
            
            List<Outbound_Communication__e> eventList = new List<Outbound_Communication__e>();
            eventList.add(createOutboundCommunication(cLog,'SMS'));
            List<Database.SaveResult> results = EventBus.publish(eventList);
            System.debug(results);
        }
        
        
    }
    private static Outbound_Communication__e createOutboundCommunication(ASF_Communication_Log__c log,String msgType){
        System.debug('***createOutboundCommunication --> ');
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

}