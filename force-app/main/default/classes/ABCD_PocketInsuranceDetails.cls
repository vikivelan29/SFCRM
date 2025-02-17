public with sharing class ABCD_PocketInsuranceDetails {
     /****************************************************************************************************************
    * @LOB - ABCD
    * @Function - getPocketInsuranceDetails
    * @param accountId - accountId
    * payload - request body
    * @return - PocketInsuranceResponse
    * @Description - Makes the callout and logs the response in ASF_Case_Integration__c
    *****************************************************************************************************************/ 
    @AuraEnabled
    public static PocketInsuranceInfoResponse getPocketInsuranceDetails(string accountId){
        try{
            PocketInsuranceInfoResponse responseWrapper = new PocketInsuranceInfoResponse();
            String integrationName = 'ABCD_Pocket_Insurance';
            Account accRec = [SELECT Id, Name, PersonMobilePhone, PersonEmail, Client_Code__c FROM Account WHERE Id=:accountId LIMIT 1];
            String payload = JSON.serialize(new CustomerInfoRequest(accRec.PersonMobilePhone,accRec.PersonEmail,accRec.Client_Code__c));
            ABCL_IntegrationCallout.accountId=accountId;
            ABCL_IntegrationCallout.IntegrationResponseWrapper pocketInsuranceResp = ABCL_IntegrationCallout.executeCallout(integrationName, payload, null);
            system.debug('responsewrap '+pocketInsuranceResp);            
            if (pocketInsuranceResp != null && pocketInsuranceResp.responseBody != null) {
                responseWrapper = (PocketInsuranceInfoResponse)JSON.deserialize(pocketInsuranceResp.responseBody, PocketInsuranceInfoResponse.class);
            }
            return responseWrapper; 
        }catch(exception e){
            throw new AuraHandledException('Error : '+e.getMessage()+' '+e.getLineNumber());
        }
    }
    
        public class CustomerInfoRequest{
        String mobileNumber;
        String emailId ;
        String customerId;
        public CustomerInfoRequest(String mob, String email, String custId){
            this.mobileNumber = mob;
            this.emailId = email;
            this.customerId = custId;
        }
    }
    public class PocketInsuranceInfoResponse {
        @AuraEnabled public Integer code;
        @AuraEnabled public String message;
        @AuraEnabled public PiInfo piInfo;
        @AuraEnabled public String status;
    }
    public class PiInfo {
        @AuraEnabled public List<PiDetails> piDetails;
    }
	public class PiDetails {
        @AuraEnabled public String applicationNumber;
        @AuraEnabled public String policyNumber;
        @AuraEnabled public String policyStatus;
        @AuraEnabled public String policyTerm;
        @AuraEnabled public String policyIssuanceDate;
        @AuraEnabled public String policyMaturityDate;
        @AuraEnabled public String premiumAmount;
        @AuraEnabled public String coverName;
        @AuraEnabled public String insuredAmount;
        @AuraEnabled public String premiumMode;
        @AuraEnabled public String policyType;
        @AuraEnabled public String policyPlanName;
        @AuraEnabled public String policyQuoteNumber;
        @AuraEnabled public String lastPremiumPaymentDate;
	}
}