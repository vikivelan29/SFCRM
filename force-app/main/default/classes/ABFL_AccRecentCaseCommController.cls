public With Sharing class ABFL_AccRecentCaseCommController {

    @AuraEnabled(cacheable=true)
    public static List<CaseComment> getAccountCaseComments(Id accountId, Integer queryRows){
        
            queryRows =  (queryRows == null ? 10 : queryRows);           
            return [SELECT Id, CommentBody,Parent.CaseNumber,ParentId, CreatedDate, CreatedBy.Name FROM CaseComment WHERE ParentId IN (SELECT Id FROM Case WHERE AccountId = :accountId) WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC LIMIT :queryRows];
        
    }
  
}