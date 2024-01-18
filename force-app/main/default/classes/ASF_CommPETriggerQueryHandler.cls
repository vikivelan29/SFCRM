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
public without sharing class ASF_CommPETriggerQueryHandler {
    
    
    public static List<PE_Logger__c> getPELoggerRecords(Set<Id> peIds, String status){
        //Added Is_Attachment__c field 
        return [SELECT ID,Status__c,Is_Attachment__c,Unique_Id__c,Case__c,CustomMetadataName__c,Email_Template_Name__c,AccountId__c,ContactId__c,LOB__c,No_Auto_Communication__c,Lead__c, Send_To_Specific_Emails__c  FROM PE_Logger__c WHERE Id =: peIds AND Status__c != :status];
    }
    
    public static List<Customer_Notification_Config__mdt> getCustomMetadataList(Set<String> devName){
        return [select id,developerName,Email_Merge_Fields_CSV__c,Email_Template_Name__c,
                SMS_Merge_Fields_CSV__c,SMS_Template_Name__c,Whatsapp_Merge_Fields_CSV__c,
                Whatsapp_Template_Name__c,external_templateID__c,SMS_Entity_Id__c, SMS_Sender_Id__c  
                from Customer_Notification_Config__mdt where developerName =: devName];
    }
    
    public static List<Case> getCaseContacts(Set<Id> caseIds){
        return [SELECT ID, Overall_Case_Closure_SLA__c, Stage__c,AccountId,ContactId,Origin  FROM Case WHERE Id=:caseIds];
    }
    
    public static List<Contact> getCustomerContact(Set<Id> accountIds, Set<Id> contactIds){
        if(contactIds.size()>0){
            return [select id,Name,MobilePhone,email,AccountId from contact where (accountId IN: accountIds OR Id IN: contactIds) AND IsEmailBounced = false];
        }
        return [select id,Name,MobilePhone,email,AccountId from contact where accountId IN: accountIds AND IsEmailBounced = false];
        
    }
    
    public static List<EmailTemplate> getEmailTemplates(Set<String> templateName){
        return [SELECT Id,DeveloperName FROM EmailTemplate WHERE DeveloperName IN: templateName];
    }
    
    public static List<Lead> getProspectRecords(Set<Id> prospectIds){
        return [SELECT ID,Email,Name,MobilePhone FROM Lead WHERE Id =: prospectIds];
    }
    

}