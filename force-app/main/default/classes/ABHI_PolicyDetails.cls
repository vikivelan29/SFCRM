/***************************************
*Class        :  ABHI_PolicyDetails
*Author       :  Kuldeep Mishra
*Created Date :  09/09/2024
*Last Modified:  09/09/2024
*@description :  This class used as a outBound API call and a controller for abhi_PolicyDetails component.
***************************************/
@SuppressWarnings('PMD.ExcessivePublicCount')
public with sharing class ABHI_PolicyDetails {
    
     /**********
     @Method     : GetPolicyDetails
     @description: Method to return IntegrationResponse when assetId passed.
     ***********/
    @SuppressWarnings('PMD.MethodNamingConventions')
    @AuraEnabled
    public static IntegrationResponseWrapper GetPolicyDetails(String assetId){
        
        String customerId;
        //Boolean hasError = false;
        String policyNumber;
        String proposalNumber;
        String requestType = 'PolicyDetails';
        String memberNumber;
        String claimNumber;
        String providerCode;
        String testType;
        
        try{
            String integrationName = 'ABHI_PolicyDetails';
            Asset assets = [SELECT Policy_No__c,SerialNumber,AccountId from Asset where Id=: assetId WITH SYSTEM_MODE];

             if (assets!= null && assets.Policy_No__c != null){
                 policyNumber = assets.Policy_No__c;
                 proposalNumber = assets.SerialNumber;
                 customerId = assets.AccountId;
                }
            ABCL_IntegrationCallout.accountId = customerId;
            RequestPayLoadWrapper requestPayload = new RequestPayLoadWrapper();
                requestPayload.RequestType = requestType; 
                requestPayload.PolicyNumber = policyNumber;
                requestPayload.ProposalNumber = proposalNumber;
                requestPayload.MemberNumber = '';
                requestPayload.ClaimNumber = '';
                requestPayload.ProviderCode = '';
                requestPayload.TestType = '';
            
            // Serialize RequestPayLoadWrapper to JSON
            String requestPayloadJson = JSON.serialize(requestPayload);
                ABCL_IntegrationCallout.IntegrationResponseWrapper integrationResp = ABCL_IntegrationCallout.executeCallout(integrationName,requestPayloadJson, null);
                IntegrationResponseWrapper deserializedIntResponse = (IntegrationResponseWrapper) JSON.deserialize(integrationResp.responseBody, IntegrationResponseWrapper.class);
                return deserializedIntResponse; 
            
        }catch(Exception e){
         throw new AuraHandledException('Error : '+e.getMessage());
        }
        
        
    }
    
    //Request Wrapper class
    @SuppressWarnings('PMD.FieldNamingConventions,PMD.VariableNamingConventions')
    /**********
        @Class : RequestPayLoadWrapper
        @description :  Wrapper class for API request payload.
        ***********/
    public class RequestPayLoadWrapper{
        public String RequestType;
        public String PolicyNumber;
        public String ProposalNumber;
        public String MemberNumber;
        public String ClaimNumber;
        public String ProviderCode;
        public String TestType;
       
    }
    //Response Wrapper class
    @SuppressWarnings('PMD.FieldNamingConventions,PMD.VariableNamingConventions')
      /**********
        @Class : IntegrationResponseWrapper
        @description :  Wrapper class for API response.
        ***********/
    public class IntegrationResponseWrapper{
        @AuraEnabled
        public List<ResponseObjWrapper> ResponseObj;
        @AuraEnabled
        public List<ResponseWrapper> Response;
       
    }
    @SuppressWarnings('PMD.FieldNamingConventions,PMD.FormalParameterNamingConventions,PMD.VariableNamingConventions')
    /**********
        @Class : ResponseObjWrapper
        @description :  Wrapper class for API response.
        ***********/
    public class ResponseObjWrapper{ 
        @AuraEnabled
        public Integer Code;
        @AuraEnabled
        public String Message;	
        public ResponseObjWrapper(Integer Code, String responseBody){
            this.Code = Code;
            this.Message = responseBody;
        }
    }
    @SuppressWarnings('PMD.FieldNamingConventions,PMD.VariableNamingConventions')
    /**********
        @Class : ResponseWrapper
        @description :  Wrapper class for API response.
        ***********/
    public class ResponseWrapper{
        @AuraEnabled
        public String BasicPremium;
        @AuraEnabled
        public String LoadingDiscount;
        @AuraEnabled
        public String auto_debit_flag;
        @AuraEnabled
        public String ServiceTax;
        @AuraEnabled
        public String collection_mode;
        @AuraEnabled
        public String GrossPremium;
        @AuraEnabled
        public String NetPremium;
        @AuraEnabled
        public String registration_status;
        @AuraEnabled
        public String premium_for_optional_cover;
        @AuraEnabled
        public String EMIApplicability;
        @AuraEnabled
        public String PaymentStatus;
        
    }
        

}