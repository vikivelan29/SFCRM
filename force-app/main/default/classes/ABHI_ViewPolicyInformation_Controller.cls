/*********************************************************
*Class        :  ABHIL_ViewPolicyInformation_Controller
*Author       :  Anirudh Raturi
*Created Date :  10/08/2024
*Last Modified:  10/08/2024
*@description  :  Class for View Policy Information API 
*********************************************************/

@SuppressWarnings('PMD.ExcessivePublicCount,PMD.ApexDoc')
/******************************************
    API Response Status Code & Message:
    1001: ‘AppRegDetails Failure’ 
    1002: ‘HealthReturns Failure’
    1003: ‘Failure’  // On both the API failure

    Success Code & Message:
    1000: ‘Success’ 
*******************************************/

public with sharing class ABHI_ViewPolicyInformation_Controller {

    @AuraEnabled
    public static ABCL_IntegrationCallout.IntegrationResponseWrapper viewPolicyInformationApiCallout(String accRecId){
        
        ABHI_ViewPolicyInformation_Controller abhilClassObj = new ABHI_ViewPolicyInformation_Controller();

        String integrationName = 'ABHI_View_Policy_Information_API_Details';
        String requestPayload = JSON.serialize(abhilClassObj.prepareRequestPayload(accRecId));
        ABCL_IntegrationCallout.accountId = accRecId;
        ABCL_IntegrationCallout.IntegrationResponseWrapper integrationResponse = ABCL_IntegrationCallout.executeCallout(integrationName, requestPayload, null);
        return integrationResponse;
    }

    /**********************************
    * @description - Creating Request Body for View Information Policy API.
    ***********************************/
    public RequestWrapper prepareRequestPayload(String accRecordId){
        
        Account accRecord = [Select id, Client_Code__c FROM Account WHERE Id =:accRecordId WITH USER_MODE];

        String clientCode = accRecord?.Client_Code__c;

        RequestWrapper reqWrapper = new RequestWrapper();
        reqWrapper.MemberNumber   = clientCode;
        reqWrapper.RequestType = new List<RequestType>();
        RequestType reqType = new RequestType();
        reqType.HealthReturns = 'GetHealthReturn';
        reqType.AppRegDetails = 'UserInfo';
        reqWrapper.RequestType.add(reqType);

        return reqWrapper;
    }

    @SuppressWarnings('PMD.VariableNamingConventions,PMD.PropertyNamingConventions,PMD.ApexDoc')
    /**********************************
    * @description - API Request Wrapper.
    ***********************************/
    public class RequestWrapper {
		public String MemberNumber{get;set;}
		public list<RequestType> RequestType{get;set;}
    }
    @SuppressWarnings('PMD.VariableNamingConventions,PMD.PropertyNamingConventions,PMD.ApexDoc')
	public class RequestType {
		public String AppRegDetails{get;set;}
		public String HealthReturns{get;set;}
	}
}