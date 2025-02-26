public with sharing class ABCD_GoldLoanDetails {
     /****************************************************************************************************************
    * @LOB - ABCD
    * @Function - getGoldLoanDetails
    * @param accountId - accountId
    * payload - request body, urlParameters - Map of URL parameters
    * @return - GoldLoanResponse
    * @Description - Makes the callout and logs the response in ASF_Case_Integration__c
    *****************************************************************************************************************/ 
    @AuraEnabled
    public static GoldLoanResponse getGoldLoanDetails(string accountId){
        try{
            GoldLoanResponse responseWrapper = new GoldLoanResponse();
            String integrationName = 'ABCD_Gold_Loan';
            Account accRec = [SELECT Id, Name, PersonMobilePhone, PersonEmail, Client_Code__c FROM Account WHERE Id=:accountId LIMIT 1];
            String payload = JSON.serialize(new CustomerInfoRequest(accRec.Client_Code__c));
           // Map <String,String> mapUrlParam = new Map <String,String>(); 
             //mapUrlParam= ABHI_ActiveDaysDashboardController.buildParametersMap(customerID,null,null,integrationName);
            ABCL_IntegrationCallout.accountId=accountId;
            ABCL_IntegrationCallout.IntegrationResponseWrapper goldLoanResp = ABCL_IntegrationCallout.executeCallout(integrationName, payload, null);
            system.debug('responsewrap '+goldLoanResp);            
            if (goldLoanResp != null && goldLoanResp.responseBody != null) {
                responseWrapper = (GoldLoanResponse)JSON.deserialize(goldLoanResp.responseBody, GoldLoanResponse.class);
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
        public CustomerInfoRequest( String custId){
            //this.mobileNumber = mob;
            //this.emailId = email;
            this.customerId = custId;
        }
    }
   public class GoldLoanResponse {
        @AuraEnabled
        public GoldLoanInfo goldLoanInfo;
        @AuraEnabled
        public Integer code; 
        @AuraEnabled
        public String message;
        @AuraEnabled
        public String status;
	}
    public class GoldLoanInfo {
        @AuraEnabled
        public List<GoldLoanDetails> goldLoanDetails;
    }
	public class GoldLoanDetails {   
        @AuraEnabled
        public String loanAccountNumber;
        @AuraEnabled
        public String loanStartDate;
        @AuraEnabled
        public String loanEndDate;
        @AuraEnabled
        public String tenor;
        @AuraEnabled
        public String lastDisbursedDate;
        @AuraEnabled
        public String nextInstallmentDate;
        @AuraEnabled
        public String loanType;   
        @AuraEnabled
        public String businessLOB;
        @AuraEnabled
        public String disbursementDate;
        @AuraEnabled
        public String sanctionDate;
        @AuraEnabled
        public String sanctionAmount;
        @AuraEnabled
        public String rateOfInterest;
        @AuraEnabled
        public String emi;
	}    
}