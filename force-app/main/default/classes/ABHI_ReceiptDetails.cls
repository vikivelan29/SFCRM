/***************************************
*Class        :  ABHI_ReceiptDetails
*Author       :  Kuldeep Mishra
*Created Date :  09/09/2024
*Last Modified:  09/09/2024
*@description :  This class used as a outBound API call and a controller for abhi_ReceiptDetails component.
***************************************/
@SuppressWarnings('PMD.ExcessivePublicCount')
public with sharing class ABHI_ReceiptDetails {
    
    /**********
     @Method     : GetReceiptDetails
     @description: Method to return IntegrationResponse when assetId passed.
     ***********/
     @SuppressWarnings('PMD.MethodNamingConventions')
     @AuraEnabled
    public static IntegrationResponseWrapper GetReceiptDetails(String assetId){
        
        String customerId;
        //Boolean hasError = false;
        String policyNumber;
        String proposalNumber;
        String requestType = 'ReceiptDetails';
        String memberNumber;
        String claimNumber;
        String providerCode;
        String testType;
        
        try{
            String integrationName = 'ABHI_ReceiptDetails';
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
        public String ReceiptNumber;
        @AuraEnabled
        public String ReceiptDate;
        @AuraEnabled
        public String PayerName;
        @AuraEnabled
        public String CollectionMode;
        @AuraEnabled
        public String InstrumentNumber;
        @AuraEnabled
        public String InstrumentDate;
        @AuraEnabled
        public String Status;
        @AuraEnabled
        public String ReceiptAmount;
        
    }    
        
        
        
    }