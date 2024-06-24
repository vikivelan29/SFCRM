public with sharing class ABSLI_FetchPolicyDetails {
    @AuraEnabled(cacheable=true)
    public static fetchPolicyResponseWrapper getPolicyDetailsFromDWH(String policyId){
        Asset policy = [SELECT ID,Policy_No__c FROM Asset WHERE Id =:policyId LIMIT 1];
        
        fetchPolicyRequestWrapper policyRequestWrapper = new fetchPolicyRequestWrapper(policy.Policy_No__c);
        string policyRequestBody = JSON.serialize(policyRequestWrapper);
        ABCL_IntegrationCallout.IntegrationResponseWrapper policyResponse = ABCL_IntegrationCallout.executeCallout(ABSLI_Constants.FETCHPOLICY_ESB_INTEGRATION_METADATA,policyRequestBody,null);
        if(policyResponse.statusCode == 200 && String.isNotBlank(policyResponse.responseBody)){
            fetchPolicyResponseWrapper policyResp = (fetchPolicyResponseWrapper) JSON.deserialize(policyResponse.responseBody, fetchPolicyResponseWrapper.class);
            return policyResp;
        }
        return null;
        
    }
    public class fetchPolicyRequestWrapper{
        public String POLICY_NO{get;set;}
        public fetchPolicyRequestWrapper(String val){
            this.POLICY_NO = val;
        }
    }
    public class fetchPolicyResponseWrapper{
        @AuraEnabled
        public String ReturnMessage{get;set;}
        @AuraEnabled
        public String ReturnCode{get;set;}
        @AuraEnabled
        public details lstDetails{get;set;}
                 
    }
    public class details{
        @AuraEnabled
        public String POLICY_NO{get;set;}
        @AuraEnabled
        public String FUND_ID{get;set;}
        @AuraEnabled
        public String FUND_VALUE{get;set;}
        @AuraEnabled
        public String NAV{get;set;}
        @AuraEnabled
        public String NAV_DATE{get;set;}   
        @AuraEnabled
        public String FUND_NAME{get;set;}   
        @AuraEnabled
        public String ALLOCATION_RATIO{get;set;}   
        @AuraEnabled
        public String UNITS{get;set;}  
    }

}