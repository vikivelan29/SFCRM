public without sharing class ASF_EmailMessageQueryHandler {
    private static List<Case> queriedCases = null;
    
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

}