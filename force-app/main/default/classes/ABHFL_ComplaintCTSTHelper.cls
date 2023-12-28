/*********************************************************
*@Class        :  ABHFL_AmortizationIntegration
*@Author       :  Dhinesh Kumar T
*@Created Date :  12/25/2023
*@Last Modified:  12/27/2023
*@description  :  Class for complaints stage movement helper. 
*********************************************************/
public with sharing class ABHFL_ComplaintCTSTHelper {
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - sendAcknowledgement
    * @param  - Case record 
    * @description - invoked from in progress stage to send acknowledgement mail.
    *****************************************************************************************************************/
    public static void sendAcknowledgement(Case caseRec){
    	Id caseId = caseRec.Id; 
    	Case caseRecord = [SELECT Id, Source__c, AccountId, CCC_External_Id__c, ContactId, OwnerId, CreatedById, Asset.LAN__c, Asset.Account_Status__c
                       FROM Case WHERE Id = :caseId WITH SECURITY_ENFORCED];

    	ASF_Case_Category_Config__c ccc = [SELECT Id, New_Case_Email_Template__c FROM ASF_Case_Category_Config__c 
                                           WHERE CCC_External_Id__c = :caseRecord.CCC_External_Id__c WITH SECURITY_ENFORCED LIMIT 1];

    	ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRecord, 
                                                                  ccc.New_Case_Email_Template__c, 
                                                                  null, 
                                                                  false);
	}
     /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - isInGrievanceTeam
    * @param  - Case record 
    * @description - invoked from resolved stage to check whether case owner belongs to grievance team
    *****************************************************************************************************************/
    public static boolean isInGrievanceTeam(Case caseRec){
       	Id caseId = caseRec.Id; 
    	Case caseRecord = [SELECT Id,OwnerId FROM Case WHERE Id = :caseId WITH SECURITY_ENFORCED];
        List<GroupMember> queueMemberships = [SELECT Id 
    										  FROM GroupMember 
    										  WHERE UserOrGroupId =: caseRecord.OwnerId 
        									     AND (
            									     group.DeveloperName='ABHFL_CEO_Desk_G' 
            									     OR group.DeveloperName='ABHFL_Express_Resolution_G' 
            									     OR group.DeveloperName='ABHFL_Grievance_G' 
            									     OR group.DeveloperName='ABHFL_Grievance_Head_G'
        										 ) WITH SECURITY_ENFORCED
											  ];
        return !queueMemberships.isEmpty();

    }
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - validateGAPfields
    * @param  - Case record 
    * @description - invoked from resolved stage to check whether any one of GAP fields are selected.
    *****************************************************************************************************************/
    public static boolean validateGAPfields(Case caseRec){
        Id caseId = caseRec.Id;
        boolean result = false;
        Case caseR = [SELECT Id,ABHFL_Case_Detail__r.Gap_IT__c,
                        	   ABHFL_Case_Detail__r.Gap_People__c, 
              				   ABHFL_Case_Detail__r.Gap_Process__c,
                               ABHFL_Case_Detail__r.Gap_Product__c,
                               ABHFL_Case_Detail__r.Regulator_Initiated__c FROM Case WHERE Id = :caseId WITH SECURITY_ENFORCED];
        if(!caseR.ABHFL_Case_Detail__r.Gap_IT__c && 
           !caseR.ABHFL_Case_Detail__r.Gap_People__c && 
           !caseR.ABHFL_Case_Detail__r.Gap_Process__c && 
           !caseR.ABHFL_Case_Detail__r.Gap_Product__c && 
           !caseR.ABHFL_Case_Detail__r.Regulator_Initiated__c){
            result = true;
        }
        return result;
    }


}