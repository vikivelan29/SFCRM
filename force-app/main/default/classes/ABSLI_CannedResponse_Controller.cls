/**
 *Class        :  ABSLI_CannedResponse_Controller
 *Author       :  Anirudh Raturi
 *Created Date :  04/06/2024
 *Last Modified:  04/06/2024
 *@description  :  Class for Canned Response
*/

public with sharing class ABSLI_CannedResponse_Controller {
    
    /****************************************************************************************************************
    * @LOB - ABSLI
    * @Function - sendEmailForCannedResponse
    * @param recordId - Case record Id.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @description - Invoked from the ASF_IntegrationsController class, this method evaluates whether Interest Certificate Or Provisional Interest Certificate Integration should be fired or not.
    *****************************************************************************************************************/
    @AuraEnabled
    public static CannedResponseWrapper sendEmailForCannedResponse(Id recordId) {
        
        CannedResponseWrapper cannedResponseWrapp = new CannedResponseWrapper();
        String cccExternalId = '';
        String issueType     = '';
        String cannedResponseEmailTemplate = '';

        Case cs       = [SELECT Id, AccountId,ContactId, CCC_External_Id__c, Issue_Type__c, No_Auto_Communication__c, Business_Unit__c,
                                Lead__c
                         FROM Case WHERE Id =: recordId WITH SECURITY_ENFORCED];

        cccExternalId = cs.CCC_External_Id__c ?? cs.CCC_External_Id__c;
        issueType     = cs.Issue_Type__c ?? cs.Issue_Type__c;

        List<ASF_Case_Email_Config__c> cannedEmailTemplateList = [SELECT Canned_Response_Email_Template__c 
                                                                  FROM ASF_Case_Email_Config__c 
                                                                  WHERE Case_Category_Config__r.CCC_External_Id__c =:cccExternalId AND 
                                                                        Type__c = 'Canned Response'  AND Issue_Type__c =:issueType WITH SECURITY_ENFORCED];
        
        if(cannedEmailTemplateList.size() > 0) {

            cannedResponseEmailTemplate = cannedEmailTemplateList[0].Canned_Response_Email_Template__c;
            Database.SaveResult platformEventResult = ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(cs, cannedResponseEmailTemplate, '',false); 
            cannedResponseWrapp.isSuccess = false;

            if(platformEventResult.isSuccess()) {
                cannedResponseWrapp.successMessage = System.Label.ABSLI_Canned_Response_Success_Message;
                cannedResponseWrapp.isSuccess = true;
            }
            else {
                cannedResponseWrapp.errorMessage = 'Communication Failed';
            }  
        } else {
            cannedResponseWrapp.errorMessage = System.Label.ABSLI_Canned_Response_Error_Message;
        }

        return cannedResponseWrapp;
    }

    public class CannedResponseWrapper {
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String successMessage;
        @AuraEnabled public Boolean isSuccess;
    }
}