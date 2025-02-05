/**
 * @description       : Class for Branch Address LWC
 * @author            : Viren, dhinesh.t@salesforce.com
 * @group             : 
 * @last modified on  : 07-15-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   06-03-2024   dhinesh.t@salesforce.com   Initial Version
**/
public without sharing class ABSLI_BranchAddressButtonController {
    public static final string STR_METADATA_NAME = 'ABSLI_Branch_Address';
    
    /****************************************************************************************************************
     * @LOB - ABSLI
     * @Function - getBranchDetails  - fetch Branch 
     * @param ranchId 
     * @return Branch_Master__c 
     * @description - Method to get the Branch Address
     *****************************************************************************************************************/
    @AuraEnabled
    public static Branch_Master__c getBranchDetails(String branchId){
        return [SELECT ID,Name,Address__c,Phone__c,City__c,State__c,Pincode__c FROM Branch_Master__c WHERE Id=: branchId WITH SECURITY_ENFORCED LIMIT 1];
    }
    
    /****************************************************************************************************************
     * @LOB - ABSLI
     * @Function - getTemplateBody  - fetch template body 
     * @param whatId 
     * @param branchId 
     * @return String 
     * @description - Method to get the template Body
     *****************************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static String getTemplateBody(String whatId,String branchId){
        Customer_Notification_Config__mdt commMdt= [SELECT ID,SMS_Template_Name__c FROM Customer_Notification_Config__mdt 
                                             WHERE DeveloperName=: STR_METADATA_NAME WITH SECURITY_ENFORCED];
        EMAILTemplate eTemplate = [SELECT ID,HTMLValue FROM EMAILTemplate WHERE DeveloperName =: commMdt.SMS_Template_Name__c WITH SECURITY_ENFORCED];
        String retVal = generateMessageBody(eTemplate.Id,UserInfo.getUserId(), branchId,true);
        return retVal;
    }
    
    /****************************************************************************************************************
     * @LOB - ABSLI
     * @Function - generateMessageBody
     * @param templateID
     * @param whoID
     * @param whatID
     * @param isPlainText
     * @return String
     * @description - Method to generate Message Body
     *****************************************************************************************************************/
    private static String generateMessageBody(String templateID, String whoID, String whatID, Boolean isPlainText){
        Messaging.SingleEmailMessage msg = Messaging.renderStoredEmailTemplate(templateID, whoId, whatID, Messaging.AttachmentRetrievalOption.NONE); 
        String richTextMessage = msg.getHtmlBody(); 
        return isPlainText ? richTextMessage.StripHtmlTags() : richTextMessage;
    }
    
    /****************************************************************************************************************
     * @LOB - ABSLI
     * @Function - sendCommunication
     * @param accountId
     * @param branchId
     * @param unregisteredNumber
     * @description - Method to sendCommunication
     *****************************************************************************************************************/
    @AuraEnabled
    public static void sendCommunication(string accountId,string branchId,string unregisteredNumber){
        Contact c = [SELECT ID,MobilePhone,Name FROM Contact WHERE AccountId = : accountId WITH SECURITY_ENFORCED LIMIT 1];
        Customer_Notification_Config__mdt commMdt= [SELECT ID,SMS_Entity_Id__c,
                                                    SMS_Sender_Id__c,SMS_Template_Name__c,external_templateID__c
                                                    FROM Customer_Notification_Config__mdt 
                                             WHERE DeveloperName=: STR_METADATA_NAME WITH SECURITY_ENFORCED];
        if((c.MobilePhone != null && c.MobilePhone != '') || (unregisteredNumber != null && unregisteredNumber != '')){
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
            
            if (Schema.sObjectType.ASF_Communication_Log__c.isCreateable()) {
    			insert cLog;
			}
            System.debug(LoggingLevel.INFO,'record Inserted...'+cLog.Id);
            
            List<Outbound_Communication__e> eventList = new List<Outbound_Communication__e>();
            eventList.add(createOutboundCommunication(cLog,'SMS'));
            List<Database.SaveResult> results = EventBus.publish(eventList);
            System.debug(LoggingLevel.INFO,results);
        }
        else{
            throw new AuraException('Mobile number is not present for this record.');
        }
        
    }
    
    /****************************************************************************************************************
     * @LOB - ABSLI
     * @Function - sendCommunication
     * @param log
     * @param msgType
     * @return Outbound_Communication__e
     * @description - Method to createOutboundCommunication
     *****************************************************************************************************************/ 
    private static Outbound_Communication__e createOutboundCommunication(ASF_Communication_Log__c log,String msgType){
        System.debug(LoggingLevel.INFO,'***createOutboundCommunication --> ');
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