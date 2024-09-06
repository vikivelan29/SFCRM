/**
 * @description       : Class for ABSLI_IssueType LWC
 * @author            : dhinesh.t@salesforce.com
 * @group             : 
 * @last modified on  : 09-04-2024
 * @last modified by  : dhinesh.t@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   06-03-2024   dhinesh.t@salesforce.com   Initial Version
**/
public with sharing class ABSLI_IssueTypeController {
	/****************************************************************************************************************
     * @LOB - ABSLI
     * @Function - getIssueTypeforCCC
     * @param whatId
     * @return String.
     * @description - Method to get the Issue Types of CCc 
     *****************************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static List<String> getIssueTypeforCCC(String recordID){
        Case caseRec = [SELECT ID,CCC_External_Id__c FROM Case WHERE Id = : recordID WITH SECURITY_ENFORCED LIMIT 1];
        ASF_Case_Category_Config__c config = [SELECT ID,Allowed_Issue_Types__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c =: caseRec.CCC_External_Id__c WITH SECURITY_ENFORCED LIMIT 1];
        if (config != null && config.Allowed_Issue_Types__c != null) {
            return config.Allowed_Issue_Types__c.split(';');
        } else {
            return new List<String>();
    	}
    }    
    /****************************************************************************************************************
     * @LOB - ABSLI
     * @Function - updateIssueType
     * @param whatId
     * @return String.
     * @description - Method to get the Issue Types of CCc 
     *****************************************************************************************************************/
    @AuraEnabled
    public static void updateIssueType(String recordID, String issueType) {
        Case caseRec = [SELECT ID, CCC_External_Id__c, Issue_Type__c 
                        FROM Case 
                        WHERE Id = :recordID WITH SECURITY_ENFORCED LIMIT 1];
    
        if (caseRec != null && Case.Issue_Type__c.getDescribe().isUpdateable()) {
            caseRec.Issue_Type__c = issueType; 
            update caseRec; 
        } else {
            throw new AuraHandledException('The Issue Type field is not updatable for the current user.');
        }
    }
}