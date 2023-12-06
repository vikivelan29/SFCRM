public without sharing class ASF_CommPETriggerQueryHandler {
    
    
    public static List<PE_Logger__c> getPELoggerRecords(Set<Id> peIds, String status){
        return [SELECT ID,Status__c,Unique_Id__c,Case__c,CustomMetadataName__c,Email_Template_Name__c,AccountId__c,ContactId__c,LOB__c FROM PE_Logger__c WHERE Id =: peIds AND Status__c != :status];
    }
    
    public static List<Customer_Notification_Config__mdt> getCustomMetadataList(Set<String> devName){
        return [select id,developerName,Email_Merge_Fields_CSV__c,Email_Template_Name__c,SMS_Merge_Fields_CSV__c,SMS_Template_Name__c,Whatsapp_Merge_Fields_CSV__c,Whatsapp_Template_Name__c,external_templateID__c   
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
    

}