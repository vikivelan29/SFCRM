/**
 * @description - EmailMessage query class
 */
public without sharing class ASF_EmailMessageQueryHandler {
    private static List<Case> queriedCases = null;
    public static List<ASF_Case_Email_Config__c> regionalTemplatesList = null;
    
    /**
     * @description - case records from the email message
     * @param caseIds 
     * @return list<Case> cases with the passed ids
     */
    public static List<Case> getCaseRecords(Set<Id> caseIds){
        if(queriedCases == null){
            queriedCases = [SELECT Id, IsClosed, Is_Reopen_Allowed__c, Reopen_Days__c, ClosedDate, Sent_to_EBOT__c,
            CCC_External_Id__c, AccountId, Channel__c, Origin, Priority, RecordTypeId, SuppliedEmail, SuppliedPhone, SuppliedName, No_Auto_Communication__c,
            Technical_Source__c, Nature__c, ContactId,Business_Unit__c,CaseNumber
            FROM Case 
            WHERE Id IN :caseIds WITH SYSTEM_MODE];
        }
        return queriedCases;
    }
    public static List<ASF_Case_Email_Config__c> getRegionalTemplatesList(Set<Id> cccIdList, Set<String> queryFields) {
        if(regionalTemplatesList == null){
            regionalTemplatesList = (List<ASF_Case_Email_Config__c>) Database.query(
                'SELECT Id, Language__c, Case_Category_Config__c, ' +
                String.join(queryFields, ',') +
                ' FROM ASF_Case_Email_Config__c WHERE Case_Category_Config__c IN :cccIdList AND Type__c = \'Regional Template\''
            );

        }
        return regionalTemplatesList;
    }
    

}