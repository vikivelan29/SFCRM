/*********************************************************
*Class        :  Abhi_HealthReturnController
*Author       :  Anirudh Raturi
*Created Date :  23/09/2024
*Last Modified:  23/09/2024
*@description  :  Class for Health Return Details API 
*********************************************************/

public with sharing class Abhi_HealthReturnController {

    /**
    * Jira Story  - PR1030924-3
    * @param policyNo 
    * @param proposalNo 
    * @return - ResponseWrapper
    * @description - Method to call the Health Return API
    */
    @AuraEnabled
    public static ResponseWrapper healthReturnCallout(String policyNo, String proposalNo){
        
      Abhi_HealthReturnController abhilClassObj = new Abhi_HealthReturnController();

      String integrationName = 'ABHI_HealthReturn_API_Details';
      String requestPayload = JSON.serialize(abhilClassObj.prepareRequestPayload(policyNo, proposalNo));
      ABCL_IntegrationCallout.IntegrationResponseWrapper integrationResponse = ABCL_IntegrationCallout.executeCallout(integrationName, requestPayload, null);
      
      ResponseWrapper respWrapper = new ResponseWrapper();

      if(integrationResponse.statusCode == 200){        
        respWrapper = (ResponseWrapper) JSON.deserialize(integrationResponse.responseBody, ResponseWrapper.class);
      }
      else if(integrationResponse.statusCode == 400) {
        Custom_Messages__mdt cm = Custom_Messages__mdt.getInstance('ABHI_No_Response_Received');
        respWrapper.Message = cm.Message__c;
        respWrapper.StatusCode = integrationResponse.statusCode;
      }
      return respWrapper;
    }

    /**
    * @param policyNumber
    * @param proposalNumber
    * @return RequestWrapper
    * @description - Method to prepare request body
    */
    public RequestWrapper prepareRequestPayload(String policyNumber, String proposalNumber){      

        RequestWrapper reqWrapper = new RequestWrapper();
        reqWrapper.RequestType   = 'HealthReturn';
        reqWrapper.PolicyNumber = policyNumber;
        reqWrapper.ProposalNumber = proposalNumber;

        return reqWrapper;
    }

    @SuppressWarnings('PMD.PropertyNamingConventions,PMD.ApexDoc')
    /**
    * @description - API Request Wrapper.
    */
    public class RequestWrapper{
		public String MemberNumber{get;set;}
		public String ClaimNumber{get;set;}
		public String ProposalNumber{get;set;}
		public String ProviderCode{get;set;}
		public String PolicyNumber{get;set;}
		public String TestType{get;set;}
		public String RequestType{get;set;}
    }

    @SuppressWarnings('PMD.PropertyNamingConventions,PMD.ApexDoc')
    /**
    * @description - API Response Wrapper.
    */
    public class ResponseWrapper{
		@AuraEnabled public List<Response> Response{get;set;}
		@AuraEnabled public Integer StatusCode{get;set;}
		@AuraEnabled public String Message{get;set;}
    }

    @SuppressWarnings('PMD.PropertyNamingConventions,PMD.ApexDoc')
    public class Response{
		@AuraEnabled public String HealthReturnsforrespectivemonth{get;set;}
		@AuraEnabled public String ChronicMgmtProgramCompliance{get;set;}
		@AuraEnabled public String ActiveDays{get;set;}
		@AuraEnabled public String HealthReturnsTMthroughBenefitforHospitalRoomchoice{get;set;}
		@AuraEnabled public String FitnessAssessment{get;set;}
		@AuraEnabled public String HealthReturnsTMthroughCarriedforwardOPDexpensesandBonus{get;set;}
		@AuraEnabled public String HealthyHeartScore{get;set;}
		@AuraEnabled public String TotalHealthReturnsTMEarned{get;set;}
		@AuraEnabled public String HealthAssessment{get;set;}
		@AuraEnabled public String TotalHealthReturnsTMBurnt{get;set;}
		@AuraEnabled public String Month{get;set;}
		@AuraEnabled public String TotalHealthReturnsTM{get;set;}
		@AuraEnabled public String Year{get;set;}
		@AuraEnabled public String HealthQuestionnaire{get;set;}
		@AuraEnabled public String Name{get;set;}
		@AuraEnabled public String HRPercentage{get;set;}
		@AuraEnabled public String vchClientCode{get;set;}
		@AuraEnabled public String vchPolicyNumber{get;set;}
	}
}