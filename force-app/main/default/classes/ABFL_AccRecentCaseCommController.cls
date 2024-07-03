/**
 * @description : Apex Controller class to handle Aura components related to retrieving recent case comments for an account.
 * This class provides a method to fetch case comments associated with a specified account.
 */
public With Sharing class ABFL_AccRecentCaseCommController{
    /**********************************************************************************************************
     * @AuraEnabled(cacheable=true)
     * @description Fetches recent case comments for a specified account.
     * @param accountId The ID of the account for which case comments are to be retrieved.
     * @param queryRows The maximum number of case comments to retrieve.
     * @return List of CaseComment records associated with the specified account, ordered by last modified date.
     * @throws AuraHandledException if any exception occurs during the process.
     **********************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static List<CaseComment> getAccountCaseComments(Id accountId, Integer queryRows){
        try {
            queryRows =  (queryRows == null ? 10 : queryRows);           
          
            return [SELECT Id, CommentBody,Parent.CaseNumber,ParentId, LastModifiedDate, CreatedBy.Name FROM CaseComment WHERE ParentId IN (SELECT Id FROM Case WHERE AccountId = :accountId) WITH SECURITY_ENFORCED ORDER BY LastModifiedDate DESC LIMIT :queryRows];
        } catch (Exception e) {
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABFL_ReassignProspectsBatch.execute');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
            throw new AuraHandledException(e.getMessage());
            
        }
    }
}