public with sharing class ABSLI_FetchPolicyDetails {
    @AuraEnabled(cacheable=true)
    public static fetchPolicyResponseWrapper getPolicyDetailsFromDWH(String policyId){
        if(policyId == null)
            return null;
        System.debug('policyId --> '+policyId);
        Asset policy = [SELECT ID,Policy_No__c FROM Asset WHERE Id =:policyId LIMIT 1];
        
        fetchPolicyRequestWrapper policyRequestWrapper = new fetchPolicyRequestWrapper(policy.Policy_No__c);
        string policyRequestBody = JSON.serialize(policyRequestWrapper);
        System.debug('policyRequestBody --> '+policyRequestBody);
        ABCL_IntegrationCallout.IntegrationResponseWrapper policyResponse = ABCL_IntegrationCallout.executeCallout(ABSLI_Constants.FUND_VALUE_API_METADATA,policyRequestBody,null);
        if(policyResponse.statusCode == 200 && String.isNotBlank(policyResponse.responseBody)){
            fetchPolicyResponseWrapper policyResp = (fetchPolicyResponseWrapper) JSON.deserialize(policyResponse.responseBody, fetchPolicyResponseWrapper.class);
            policyResp.statusCode = String.ValueOf(policyResponse.statusCode);
            policyResp.message = '';
            System.debug('policyResp --> '+policyResp); 
            return policyResp;
        }
        else{
            fetchPolicyResponseWrapper policyResp = new fetchPolicyResponseWrapper();
            policyResp.statusCode = String.ValueOf(policyResponse.statusCode);
            policyResp.message = 'No Response from Get Fund Detail API.';
        }
        return null;
        
    }
    
    public class fetchPolicyResponseWrapper{
        @AuraEnabled
        public root BFID_RESPONSE;
        @AuraEnabled
        public List<detail> FUND_DETAILS;
        @AuraEnabled
        public String statusCode{get;set;}
        @AuraEnabled
        public String message{get;set;}
    }
    public class root{
        @AuraEnabled
        public String TOTAL_FUND_VALUE{get;set;}
        @AuraEnabled
        public String navdate{get;set;}
    }
    public class detail{
		@AuraEnabled
        public String FND_ID{get;set;}
        @AuraEnabled
        public decimal TOT_UNITS{get;set;}
        @AuraEnabled
        public decimal NAV{get;set;}
        @AuraEnabled
        public String POL_CSTAT_CD{get;set;}
        @AuraEnabled
        public String FUND_NAME{get;set;}
        @AuraEnabled
        public decimal FUND_VALUE{get;set;} 
        @AuraEnabled
        public String POL_ID{get;set;}
    }
     
    public class fetchPolicyRequestWrapper{ 
        public String policy_id{get;set;}
        public String effective_date{get;set;}
        public String source{get;set;}
        public fetchPolicyRequestWrapper(String val){
            this.policy_id = val;
            this.effective_date = ABCL_IntegrationCommonUtility.dateFormat(System.today(), 'dd-MM-YYYY');
            this.source = ABSLI_Constants.ESB_SOURCE_ID;
        }
    }

}