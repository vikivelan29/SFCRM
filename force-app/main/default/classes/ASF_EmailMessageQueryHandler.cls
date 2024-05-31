public without sharing class ASF_EmailMessageQueryHandler {
    private static List<Case> queriedCases = null;
    public static List<ASF_Regional_SMS_Email_Template__c> regionalTemplatesList = null;
    
    public static List<Case> getCaseRecords(Set<Id> caseIds){
        if(queriedCases == null){
            queriedCases = [SELECT Id, IsClosed, Is_Reopen_Allowed__c, Reopen_Days__c, ClosedDate, Sent_to_EBOT__c,
            CCC_External_Id__c, AccountId, Channel__c, Origin, Priority, RecordTypeId, SuppliedEmail, SuppliedPhone, SuppliedName, No_Auto_Communication__c,
            Technical_Source__c, Nature__c, ContactId,Business_Unit__c,CaseNumber
            FROM Case 
            WHERE Id IN :caseIds];
        }
        return queriedCases;
    }
    public static List<ASF_Regional_SMS_Email_Template__c> getRegionalTemplatesList(Set<Id> cccIdList, Set<String> queryFields) {
        if(regionalTemplatesList == null){
            regionalTemplatesList = (List<ASF_Regional_SMS_Email_Template__c>) Database.query(
                'SELECT Id, Language__c, Case_Category_Config__c, ' +
                String.join(queryFields, ',') +
                ' FROM ASF_Regional_SMS_Email_Template__c WHERE Case_Category_Config__c IN :cccIdList'
            );

        }
        return regionalTemplatesList;
    }
    

}