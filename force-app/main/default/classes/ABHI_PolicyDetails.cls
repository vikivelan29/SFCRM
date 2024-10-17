/***************************************
*Class        :  ABHI_PolicyDetails
*Author       :  Kuldeep Mishra
*Created Date :  09/09/2024
*Last Modified:  09/09/2024
*@description :  This class used as a outBound API call and a controller for abhi_PolicyDetails component.
***************************************/
public with sharing class ABHI_PolicyDetails {
    
    @AuraEnabled
    public static IntegrationResponseWrapper GetPolicyDetails(String assetId){
        
        String customerId;
        Boolean hasError = false;
        String policyNumber;
        String ProposalNumber;
        String RequestType = 'PolicyDetails';
        String MemberNumber;
        String ClaimNumber;
        String ProviderCode;
        String TestType;
        
        try{
            String integrationName = 'ABHI_PolicyDetails';
            Asset assets = [SELECT Policy_No__c,SerialNumber,AccountId from Asset where Id=: assetId];
            system.debug('values ---' +assets);
             if (assets!= null && assets.Policy_No__c != null){
                 policyNumber = assets.Policy_No__c;
                 ProposalNumber = assets.SerialNumber;
                 customerId = assets.AccountId;
                System.debug('Policy Number retrieved from Asset: ' + policyNumber);
                }
            ABCL_IntegrationCallout.accountId = customerId;
            RequestPayLoadWrapper requestPayload = new RequestPayLoadWrapper();
                requestPayload.RequestType = RequestType; 
                requestPayload.PolicyNumber = policyNumber;
                requestPayload.ProposalNumber = ProposalNumber;
                requestPayload.MemberNumber = '';
                requestPayload.ClaimNumber = '';
                requestPayload.ProviderCode = '';
                requestPayload.TestType = '';
            
            // Serialize RequestPayLoadWrapper to JSON
            String requestPayloadJson = JSON.serialize(requestPayload);
            system.debug('requestBody-->' +requestPayloadJson);
                ABCL_IntegrationCallout.IntegrationResponseWrapper integrationResp = ABCL_IntegrationCallout.executeCallout(integrationName,requestPayloadJson, null);
            system.debug('integrationResp>>' +integrationResp);
                IntegrationResponseWrapper deserializedIntResponse = (IntegrationResponseWrapper) JSON.deserialize(integrationResp.responseBody, IntegrationResponseWrapper.class);
            system.debug('deserialized resp' +deserializedIntResponse);
                return deserializedIntResponse;
            
            
        }catch(Exception e){
         throw new AuraHandledException('Error : '+e.getMessage());
        }
        
        
    }
    
    //Request Wrapper class
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
    public class IntegrationResponseWrapper{
        @AuraEnabled
        public List<ResponseObjWrapper> ResponseObj;
        @AuraEnabled
        public List<ResponseWrapper> Response;
       
    }
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