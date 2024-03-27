public With Sharing class ABFL_AccRecentCaseCommController {

    @AuraEnabled(cacheable=true)
    public static List<CaseComment> getAccountCaseComments(Id accountId, Integer queryRows){
        try {
            queryRows =  (queryRows == null ? 10 : queryRows);           
          
            return [SELECT Id, CommentBody,Parent.CaseNumber,ParentId, LastModifiedDate, CreatedBy.Name FROM CaseComment WHERE ParentId IN (SELECT Id FROM Case WHERE AccountId = :accountId) WITH SECURITY_ENFORCED ORDER BY LastModifiedDate DESC LIMIT :queryRows];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}