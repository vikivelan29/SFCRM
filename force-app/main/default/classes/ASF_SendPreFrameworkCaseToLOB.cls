public with sharing class ASF_SendPreFrameworkCaseToLOB {
    @AuraEnabled(cacheable = true)
    public static List<ASF_PriorityEmailAddressesByBU__mdt> getPriorityEmailList(){
        List<ASF_PriorityEmailAddressesByBU__mdt> priorityEmails = [SELECT Id, 
                                                                    DeveloperName, MasterLabel, Label,Active__c, Business_Unit__c, Default_Queue_Dev_Name__c, Email2CaseAddress__c, 
                                                                    Priority_Index__c, Send_to_EBOT__c, Case_Origin__c, Case_Business_Unit__c 
                                                                    FROM ASF_PriorityEmailAddressesByBU__mdt WHERE Active__c = TRUE];
        return priorityEmails;
    }
    @AuraEnabled
    public static void updateCase(Id recId,Id priorityCMId){
        Id newOwnerId;
        ASF_PriorityEmailAddressesByBU__mdt priorityEmail = [SELECT Id, 
                                                             DeveloperName, MasterLabel, Label,Active__c, Business_Unit__c, Default_Queue_Dev_Name__c, Email2CaseAddress__c, 
                                                             Priority_Index__c, Send_to_EBOT__c, Case_Origin__c, Case_Business_Unit__c 
                                                             FROM ASF_PriorityEmailAddressesByBU__mdt WHERE Id =: priorityCMId];
        if(priorityEmail.Default_Queue_Dev_Name__c != null){
            Group grp = [SELECT ID FROM Group WHERE DeveloperName =: priorityEmail.Default_Queue_Dev_Name__c LIMIT 1];
            newOwnerId = grp.Id;
        }
        Case c = new Case(Id=recId);
        c.Business_Unit__c = priorityEmail.Case_Business_Unit__c;
        c.Winning_Email__c = priorityEmail.Email2CaseAddress__c;
        c.Sent_to_EBOT__c = priorityEmail.Send_to_EBOT__c;
        c.Origin = priorityEmail.Case_Origin__c;
        c.OwnerId = newOwnerId;
        try{
            update c;
            
            List<EmailMessage> emails = [SELECT ID FROM EmailMessage WHERE ParentId =: c.Id AND Incoming = TRUE LIMIT 1];
            if(emails.size()>0){
                Map<String, String> fieldsMap = new Map<String, String>();
                fieldsMap.put('Email_Message_ID__c', emails[0].Id);
                Database.SaveResult eventResult = ABCL_CasePlatformEventHandler.publishPlatformEvent('EBOT_Internal_Event__e', fieldsMap);
            }
            
        }
        catch(exception ex){
          throw new AuraException('Error Occured while forwarding email to LOB');
        }
        
    }
    
}