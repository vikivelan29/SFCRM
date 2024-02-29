/*********************************************************
*@Class        :  ABHFL_ComplaintCTSTHelper
*@Author       :  Dhinesh Kumar T
*@Created Date :  12/25/2023
*@Last Modified:  01/11/2024
*@description  :  Class for complaints stage movement helper. 
*********************************************************/
public with sharing class ABHFL_ComplaintCTSTHelper {
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - sendAcknowledgement
    * @param  - Case record 
    * @description - invoked from in progress stage to send acknowledgement mail.
    *****************************************************************************************************************/
    public static void sendAcknowledgement(List<Case> caseRecs){
    	//Id caseId = caseRec.Id; 
    	//Case caseRecord = [SELECT Id, Source__c, AccountId, CCC_External_Id__c, ContactId, OwnerId, CreatedById, Asset.LAN__c, Asset.Account_Status__c,No_Auto_Communication__c,Short_URL__c
        //               FROM Case WHERE Id = :caseId];

        Map<String, Id> externalIdToCase = new Map<String, Id>();
        for(Case caseRec : caseRecs){
            externalIdToCase.add(caseRec.CCC_External_Id__c, caseRec.Id);
        }
        Map<Id, ASF_Case_Category_Config__c> caseIdToCCCMap = new Map<Id,ASF_Case_Category_Config__c>();
    	for(ASF_Case_Category_Config__c ccc : [SELECT Id, New_Case_Email_Template__c,New_Case_SMS_Metadata__c, CCC_External_Id__c FROM ASF_Case_Category_Config__c 
                                           WHERE CCC_External_Id__c IN :externalIdToCase.keySet() WITH SECURITY_ENFORCED])
        {
            caseIdToCCCMap.put(externalIdToCase.get(ccc.CCC_External_Id__c), ccc);
        }
        

        Map<Id, String> emailTemplateMap = new Map<Id, String>();
        Map<Id, String> smsMetadataMap = new Map<Id, String>();
        Map<Id, Boolean> isTransferredMap = new Map<Id, Boolean>();
        List<Case> typeOneCases = new List<Case>();
        List<Case> typeTwoCases = new List<Case>();
        for(Case caseRec : caseRecs){
            List<String> emailTemplates = new List<String>();
            List<String> smsMetadata = new List<String>();
            ASF_Case_Category_Config__c ccc = caseIdToCCCMap.get(caseRec.Id);
            if(String.isNotBlank(ccc.New_Case_Email_Template__c)){
                emailTemplates = (ccc.New_Case_Email_Template__c).split(',');            
            }
            if(String.isNotBlank(ccc.New_Case_SMS_Metadata__c)){
                smsMetadata = (ccc.New_Case_SMS_Metadata__c).split(',');            
            }
            if(caseRec.Short_URL__c == NULL){
                typeOneCases.add(caseRec);
                emailTemplateMap.put(caseRec.Id, emailTemplates[1]);
                smsMetadataMap.put(caseRec.Id, smsMetadata[1]);
                isTransferredMap.put(caseRec.Id, false);
            }else{
                typeTwoCases.add(caseRec);
                emailTemplateMap.put(caseRec.Id, emailTemplates[0]);
                smsMetadataMap.put(caseRec.Id, smsMetadata[0]);
                isTransferredMap.put(caseRec.Id, false);
            }
        }
        if(!typeOneCases.isEmpty()){
            ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(typeOneCases, emailTemplateMap, smsMetadataMap, isTransferredMap);
        }
        if(!typeTwoCases.isEmpty()){
            ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(typeTwoCases, emailTemplateMap, smsMetadataMap, isTransferredMap);
        }
        
	}
     /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - isInGrievanceTeam
    * @param  - Case record 
    * @description - invoked from resolved stage to check whether case owner belongs to grievance team
    *****************************************************************************************************************/
    public static Map<Id, Boolean> isInGrievanceTeam(List<Case> caseRecs){
       	//Id caseId = caseRec.Id; 
    	//Case caseRecord = [SELECT Id,OwnerId FROM Case WHERE Id = :caseId WITH SECURITY_ENFORCED];
        
        Map<Id, List<Id>> ownerIdToCases = new Map<Id, List<Id>>();
        Map<Id, Boolean> caseIdToResult = new Map<Id, Boolean>();
        for(Case caseRec : caseRecs){
            if(!ownerIdToCases.containsKey(caseRec.OwnerId)){
                ownerIdToCases.put(caseRec.OwnerId, new List<Id>());
            }
            ownerIdToCases.get(caseRec.OwnerId).add(caseRec.Id);
            caseIdToResult.put(caseRec.Id, false);//default no membership
        }
        
        for(GroupMember gm : [SELECT Id FROM GroupMember WHERE UserOrGroupId IN :ownerIdToCases.keySet() 
            AND (
                group.DeveloperName='ABHFL_CEO_Desk_G' 
                OR group.DeveloperName='ABHFL_Express_Resolution_G' 
                OR group.DeveloperName='ABHFL_Grievance_G' 
                OR group.DeveloperName='ABHFL_Grievance_Head_G'
            ) WITH SECURITY_ENFORCED
        ])
        {
            for(Id caseId : ownerIdToCases.get(gm.UserOrGroupId)){
                caseIdToResult.put(caseId, true);//if found, overwrite with true
            }
        }
        return caseIdToResult;
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

	public static Map<Id, FieldValidationResult> validateRCAfields(List<Case> caseRecs){
    	//Id caseId = caseRec.Id;
        Map<Id, FieldValidationResult> resultsMap = new Map<Id, FieldValidationResult>();
        for(Case caseRec : caseRecs){
            FieldValidationResult validation = new FieldValidationResult();
            validation.result = false;
            validation.blankFields = new Set<String>();
            resultsMap.put(caseRec.Id, validation);
        }

    	// Case caseR = [SELECT Id, ABHFL_Case_Detail__r.Case_Categorization__c,
        //                  ABHFL_Case_Detail__r.Action_Taken__c, 
        //                  ABHFL_Case_Detail__r.Voice_of_Customer__c,
        //                  ABHFL_Case_Detail__r.Gap_IT__c,
        //                  ABHFL_Case_Detail__r.Gap_People__c, 
        //                  ABHFL_Case_Detail__r.Gap_Process__c,
        //                  ABHFL_Case_Detail__r.Gap_Product__c,
        //                  ABHFL_Case_Detail__r.Regulator_Initiated__c,
		// 				 ABHFL_Case_Detail__r.Final_resolution__c,
		// 				 ABHFL_Case_Detail__r.Repeat_interaction__c 
        //           	  FROM Case 
        //           	  WHERE Id = :caseId WITH SECURITY_ENFORCED];

    	Map<String, Schema.SObjectField> caseDetailFields = Schema.SObjectType.ABHFL_Case_Detail__c.fields.getMap();
    	Schema.DescribeFieldResult caseCategorizationField = caseDetailFields.get('Case_Categorization__c').getDescribe();
    	Schema.DescribeFieldResult actionTakenField = caseDetailFields.get('Action_Taken__c').getDescribe();
    	Schema.DescribeFieldResult voiceOfCustomerField = caseDetailFields.get('Voice_of_Customer__c').getDescribe();
        Schema.DescribeFieldResult finalResolutionField = caseDetailFields.get('Final_resolution__c').getDescribe();
        Schema.DescribeFieldResult repeatInterationField = caseDetailFields.get('Repeat_interaction__c').getDescribe();
        for(Case caseR : caseRecs){
            FieldValidationResult validation = resultsMap.get(caseRec.Id);
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
            if(String.isBlank(caseR.ABHFL_Case_Detail__r.Final_resolution__c)) {
                validation.blankFields.add(finalResolutionField.getLabel());
                validation.result = true;
            }
            if(String.isBlank(caseR.ABHFL_Case_Detail__r.Repeat_interaction__c)) {
                validation.blankFields.add(repeatInterationField.getLabel());
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
            resultsMap.put(caseR.Id, validation);
        }
        
     	return resultsMap;
	}	




}