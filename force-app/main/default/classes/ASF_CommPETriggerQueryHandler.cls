/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 06-25-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   01-17-2024   rsinghnagar@salesforce.com   Initial Version
**/
public without sharing class ASF_CommPETriggerQueryHandler {
    
    /**
     * @description  Retrieves PE Logger records based on provided IDs and status.
     * @param peIds The set of PE Logger record IDs to retrieve.
     * @param status The status to exclude from the query results.
     * @return List of PE Logger records matching the criteria.
     */
    public static List<PE_Logger__c> getPELoggerRecords(Set<Id> peIds, String status){
        //Added Is_Attachment__c field 
        return [SELECT ID,Status__c,RecordID__c,TakeBodyFromContentDoc__c,HTMLBody_Con_Doc_Id__c ,Is_Attachment__c,Unique_Id__c,Case__c,CustomMetadataName__c,Email_Template_Name__c,AccountId__c,ContactId__c,LOB__c,No_Auto_Communication__c,Lead__c, 
                Send_To_Specific_Emails__c, Specific_To_Address__c,Send_To_Specific_Mobile__c, Specific_Cc_Addresses__c,Specific_To_MobilePhone__c,Subject__c,Content_Version_Ids__c FROM PE_Logger__c WHERE Id =: peIds AND Status__c != :status];
    }

    /**
     * @description Retrieves custom metadata records based on provided developer names.
     * @param devName The set of developer names of custom metadata records to retrieve.
     * @return List of custom metadata records matching the criteria.
     */
    public static List<Customer_Notification_Config__mdt> getCustomMetadataList(Set<String> devName){
        return [select id,developerName,Email_Merge_Fields_CSV__c,Email_Template_Name__c,
                SMS_Merge_Fields_CSV__c,SMS_Template_Name__c,Whatsapp_Merge_Fields_CSV__c,
                Whatsapp_Template_Name__c,external_templateID__c,SMS_Entity_Id__c, SMS_Sender_Id__c  
                from Customer_Notification_Config__mdt where developerName =: devName];
    }
    
    /**
     * @description Retrieves case records based on provided case IDs.
     * @param caseIds The set of case record IDs to retrieve.
     * @return List of case records matching the criteria.
     */
    public static List<Case> getCaseContacts(Set<Id> caseIds){
        return [SELECT ID, Overall_Case_Closure_SLA__c, Stage__c,AccountId,ContactId,Origin  FROM Case WHERE Id=:caseIds];
    }
    
    /**
     * @description Retrieves customer contact records based on provided account IDs and contact IDs.
     * @param accountIds The set of account record IDs to filter contacts.
     * @param contactIds The set of contact record IDs to retrieve.
     * @return List of contact records matching the criteria.
     */
    public static List<Contact> getCustomerContact(Set<Id> accountIds, Set<Id> contactIds){
        if(contactIds.size()>0){
            return [select id,Name,MobilePhone,email,AccountId from contact where (accountId IN: accountIds OR Id IN: contactIds) AND IsEmailBounced = false];
        }
        return [select id,Name,MobilePhone,email,AccountId from contact where accountId IN: accountIds AND IsEmailBounced = false];
        
    }
    
    /**
     * @description Retrieves email templates based on provided template names.
     * @param templateName The set of template names to retrieve.
     * @return List of email templates matching the criteria.
     */
    public static List<EmailTemplate> getEmailTemplates(Set<String> templateName){
        return [SELECT Id,DeveloperName FROM EmailTemplate WHERE DeveloperName IN: templateName];
    }
    
    /**
     * @description Retrieves prospect records based on provided prospect IDs.
     * @param prospectIds The set of prospect record IDs to retrieve.
     * @return List of prospect records matching the criteria.
     */
    public static List<Lead> getProspectRecords(Set<Id> prospectIds){
        return [SELECT ID,Email,Name,MobilePhone FROM Lead WHERE Id =: prospectIds];
    }
    

}