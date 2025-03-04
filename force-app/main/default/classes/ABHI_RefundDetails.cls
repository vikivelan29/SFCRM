/***************************************
*Class        :  ABHI_RefundDetails
*Author       :  Kuldeep Mishra
*Created Date :  09/09/2024
*Last Modified:  09/09/2024
*@description :  This class used as a outBound API call and a controller for abhi_RefundDetails component.
***************************************/
@SuppressWarnings('PMD.ExcessivePublicCount')
public with sharing class ABHI_RefundDetails {
    
     /******************************
     @Method     : GetReceiptDetails
     @description: Method to return IntegrationResponse when assetId passed.
     ******************************/
    @SuppressWarnings('PMD.MethodNamingConventions')
    @AuraEnabled
    public static IntegrationResponseWrapper GetRefunds(String assetId){
        
        String customerId;
        Boolean hasError = false;
        String policyNumber;
        String proposalNumber;
        String requestType = 'RefundDetails';
        String memberNumber;
        String claimNumber;
        String providerCode;
        String testType;
        
        try{
            String integrationName = 'ABHI_RefundDetails';
            Asset assets = [SELECT Policy_No__c,SerialNumber,AccountId from Asset where Id=: assetId WITH SYSTEM_MODE];
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
                ABCL_IntegrationCallout.IntegrationResponseWrapper integrationResp = ABCL_IntegrationCallout.executeCallout(integrationName,requestPayloadJson, null);
                IntegrationResponseWrapper deserializedIntResponse = (IntegrationResponseWrapper) JSON.deserialize(integrationResp.responseBody, IntegrationResponseWrapper.class);
            system.debug('deserialized resp' +deserializedIntResponse);
                return deserializedIntResponse;
               
        }catch(Exception e){
            System.debug('Deserialization error: ' + e.getMessage());
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
        public ResponseObjWrapper ResponseObj;
        @AuraEnabled
        public List<ReceiptObjWrapper> ReceiptObj;
       
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
        @Class : ReceiptObjWrapper
        @description :  Wrapper class for API response.
        ***********/
    public class ReceiptObjWrapper{
        @AuraEnabled
        public String ReceiptNumber;
        @AuraEnabled
        public List<RefundDetailsWrapper> RefundDetails;
        
    }
    @SuppressWarnings('PMD.FieldNamingConventions,PMD.VariableNamingConventions')
     /**********
        @Class : RefundDetailsWrapper
        @description :  Wrapper class for API response.
        ***********/
    public class RefundDetailsWrapper{
        @AuraEnabled
        public String RefundNumber;
        @AuraEnabled
        public String RefundType;
        @AuraEnabled
        public String PaymentDate;
        @AuraEnabled
        public String PaymentRefNo;
        @AuraEnabled
        public String Status;
        @AuraEnabled
        public String RefundTo;
        @AuraEnabled
        public String PaymentMode;
        @AuraEnabled
        public String BeneficiaryName;
        @AuraEnabled
        public String RefundAmount;
        @AuraEnabled
        public String ProposerMobile;
        @AuraEnabled
        public String ProposerEmail;
        @AuraEnabled
        public String BankName;
        @AuraEnabled
        public String AccountNumber;
        @AuraEnabled
        public String IVRStatus;
        @AuraEnabled
        public String PaymentReason;
        @AuraEnabled
        public String PaymentSubReason;
        @AuraEnabled
        public String IFSCCode;
        
    }
    
}