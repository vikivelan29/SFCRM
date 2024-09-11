/*********************************************************
*Class        :  Abhi_ViewClaimDetails_Controller
*Author       :  Anirudh Raturi
*Created Date :  9/09/2024
*Last Modified:  9/09/2024
*@description  :  Class for View Claim Details API 
*********************************************************/

@SuppressWarnings('PMD.ExcessivePublicCount,PMD.ApexDoc')
/******************************************
    API Response Status Code & Message:
    1000: ‘Success’ 
    1001: ‘Claim view Failure’ 
*******************************************/

public with sharing class Abhi_ViewClaimDetails_Controller {

    @AuraEnabled
    public static ResponseWrapper viewClaimDetailsInformationCallout(String policyNo){
        
        Abhi_ViewClaimDetails_Controller abhilClassObj = new Abhi_ViewClaimDetails_Controller();

        String integrationName = 'ABHI_View_Claim_Details_API_Details';
        String requestPayload = JSON.serialize(abhilClassObj.prepareRequestPayload(policyNo));
        ABCL_IntegrationCallout.IntegrationResponseWrapper integrationResponse = ABCL_IntegrationCallout.executeCallout(integrationName, requestPayload, null);
        
        ResponseWrapper respWrapper = new ResponseWrapper();

        if(String.isNotBlank(integrationResponse.responseBody)){        
            respWrapper = (ResponseWrapper) JSON.deserialize(integrationResponse.responseBody, ResponseWrapper.class);
        }
        return respWrapper;
    }

    /**********************************
    * @description - Creating Request Body for View Information Policy API.
    ***********************************/
    public RequestWrapper prepareRequestPayload(String policyNo){      

        RequestWrapper reqWrapper = new RequestWrapper();
        reqWrapper.RequestType   = 'ClaimMasterDetails';
        reqWrapper.policyNumber = policyNo;

        return reqWrapper;
    }

    @SuppressWarnings('PMD.VariableNamingConventions,PMD.PropertyNamingConventions,PMD.ApexDoc')
    /**********************************
    * @description - API Request Wrapper.
    ***********************************/
    public class RequestWrapper {
		@AuraEnabled public String RequestType{get;set;}
		@AuraEnabled public String policyNumber{get;set;}
    }

    @SuppressWarnings('PMD.VariableNamingConventions,PMD.PropertyNamingConventions,PMD.ApexDoc')
    /**
    * @description - API Response Wrapper
    */
    public class ResponseWrapper{
		@AuraEnabled public List<Response> Response{get;set;}
		@AuraEnabled public Integer StatusCode{get;set;}
		@AuraEnabled public String Message{get;set;}
		@AuraEnabled public ResponseObj ResponseObj{get;set;}
    }

    @SuppressWarnings('PMD.VariableNamingConventions,PMD.PropertyNamingConventions,PMD.ApexDoc')
	public class ResponseObj{
		@AuraEnabled public String Message{get;set;}
		@AuraEnabled public String Code{get;set;}
	}
    @SuppressWarnings('PMD.VariableNamingConventions,PMD.PropertyNamingConventions,PMD.ApexDoc')
	public class Response{
		@AuraEnabled public String PaidAmount{get;set;}
		@AuraEnabled public String mnyHealthReturnAmnt{get;set;}
		@AuraEnabled public String Claim_Status{get;set;}
		@AuraEnabled public String ReserveAmount{get;set;}
		@AuraEnabled public String Claim_SubStatus{get;set;}
		@AuraEnabled public String ClaimStatus{get;set;}
		@AuraEnabled public String Claim_Amount{get;set;}
		@AuraEnabled public String ClaimDate{get;set;}
		@AuraEnabled public String ApprovedAmount{get;set;}
		@AuraEnabled public String ClaimType{get;set;}
		@AuraEnabled public String DeductionAmount{get;set;}
		@AuraEnabled public String ClaimNumber{get;set;}
		@AuraEnabled public String MemberName{get;set;}
		@AuraEnabled public String PolicyNumber{get;set;}
	}
}