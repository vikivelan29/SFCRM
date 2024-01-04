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
    * @Function - validateRCAfields
    * @param  - Case record 
    * @description - invoked from resolved stage to check whether RCA fields are filled.
    *****************************************************************************************************************/
    public class FieldValidationResult {
    	public Boolean result { get; set; }
    	public Set<String> blankFields { get; set; }
        public String message { get; set; }
	}

	public static FieldValidationResult validateRCAfields(Case caseRec){
    	Id caseId = caseRec.Id;
    	FieldValidationResult validation = new FieldValidationResult();
    	validation.result = false;
    	validation.blankFields = new Set<String>();

    	Case caseR = [SELECT Id, ABHFL_Case_Detail__r.Case_Categorization__c,
                         ABHFL_Case_Detail__r.Action_Taken__c, 
                         ABHFL_Case_Detail__r.Voice_of_Customer__c,
                         ABHFL_Case_Detail__r.Gap_IT__c,
                         ABHFL_Case_Detail__r.Gap_People__c, 
                         ABHFL_Case_Detail__r.Gap_Process__c,
                         ABHFL_Case_Detail__r.Gap_Product__c,
                         ABHFL_Case_Detail__r.Regulator_Initiated__c 
                  	  FROM Case 
                  	  WHERE Id = :caseId WITH SECURITY_ENFORCED];

    	Map<String, Schema.SObjectField> caseDetailFields = Schema.SObjectType.ABHFL_Case_Detail__c.fields.getMap();
    	Schema.DescribeFieldResult caseCategorizationField = caseDetailFields.get('Case_Categorization__c').getDescribe();
    	Schema.DescribeFieldResult actionTakenField = caseDetailFields.get('Action_Taken__c').getDescribe();
    	Schema.DescribeFieldResult voiceOfCustomerField = caseDetailFields.get('Voice_of_Customer__c').getDescribe();

    	if(String.isBlank(caseR.ABHFL_Case_Detail__r.Case_Categorization__c)) {
        	validation.blankFields.add(caseCategorizationField.getLabel());
        	validation.result = true;
    	}	
    	if(String.isBlank(caseR.ABHFL_Case_Detail__r.Action_Taken__c)) {
        	validation.blankFields.add(actionTakenField.getLabel());
        	validation.result = true;
    	}
    	if(String.isBlank(caseR.ABHFL_Case_Detail__r.Voice_of_Customer__c)) {
        	validation.blankFields.add(voiceOfCustomerField.getLabel());
        	validation.result = true;
    	}
         if(!caseR.ABHFL_Case_Detail__r.Gap_IT__c && 
       		!caseR.ABHFL_Case_Detail__r.Gap_People__c && 
       		!caseR.ABHFL_Case_Detail__r.Gap_Process__c && 
       		!caseR.ABHFL_Case_Detail__r.Gap_Product__c && 
       		!caseR.ABHFL_Case_Detail__r.Regulator_Initiated__c){
        		validation.result = true;
                validation.blankFields.add('Any one of GAP or Regulator Initiated.');
    	}
    
    	// Set the message within the wrapper
    	if(validation.result && !validation.blankFields.isEmpty()) {
        	String message = 'The following fields are mandatory to complete RCA : ';
        	for(String fieldLabel : validation.blankFields) {
            	message += fieldLabel + ', ';
        	}
        	message = message.removeEnd(', ');
        	validation.message = message;
    	}	
        
     	return validation;
	}	




}