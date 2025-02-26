public with sharing class ABCD_Loyalty_Rewards {
     /****************************************************************************************************************
    * @LOB - ABCD
    * @Function - getRoyaltyRewardsDetails
    * @param accountId - accountId
    * payload - request body
    * @return - ResponseLoyaltyRewards
    * @Description - Makes the callout and logs the response in ASF_Case_Integration__c
    *****************************************************************************************************************/ 
    @AuraEnabled
    public static ResponseLoyaltyRewards getRoyaltyRewardsDetails(string accountId,String fromDate,String toDate){
        try{
            ResponseLoyaltyRewards responseWrapper = new ResponseLoyaltyRewards();
            String integrationName = 'ABCD_Loyalty_Rewards';
            Account accRec = [SELECT Id, Name, PersonMobilePhone, PersonEmail, Client_Code__c FROM Account WHERE Id=:accountId LIMIT 1];
            String payload = JSON.serialize(new CustomerInfoRequest(fromDate != null ? fromDate : '',toDate != null ? toDate : '',accRec.Client_Code__c));
            ABCL_IntegrationCallout.accountId=accountId;
            ABCL_IntegrationCallout.IntegrationResponseWrapper royaltyRewardResp = ABCL_IntegrationCallout.executeCallout(integrationName, payload, null);
            system.debug('responsewrap '+royaltyRewardResp);            
            if (royaltyRewardResp != null && royaltyRewardResp.responseBody != null) {
                responseWrapper = (ResponseLoyaltyRewards)JSON.deserialize(royaltyRewardResp.responseBody, ResponseLoyaltyRewards.class);
            }
            return responseWrapper; 
        }catch(exception e){
            throw new AuraHandledException('Error : '+e.getMessage()+' '+e.getLineNumber());
        }
    }
    
        public class CustomerInfoRequest{
        String fromDate;
        String toDate ;
        String customer_id;
        public CustomerInfoRequest(String fromDt, String toDt, String custId){
            this.fromDate = fromDt;
            this.toDate = toDt;
            this.customer_id = custId;
        }
    }
    public class ResponseLoyaltyRewards {
    @AuraEnabled
    public List<ReturnData> ReturnData { get; set; }
    @AuraEnabled
    public Integer StatusCode { get; set; }
}

public class ReturnData {
    @AuraEnabled
    public String CustomerID { get; set; }
    @AuraEnabled
    public String LR_coins_latest_accrual_date { get; set; }
    @AuraEnabled
    public Integer LR_coins_latest_earned_coins { get; set; }
    @AuraEnabled
    public Integer LR_coins_latest_transaction_amount { get; set; }
    @AuraEnabled
    public String OrderDescription { get; set; }
    @AuraEnabled
    public String Productname { get; set; }
    @AuraEnabled
    public Integer RedemptionRequestID { get; set; }
    @AuraEnabled
    public String RequestDate { get; set; }
    @AuraEnabled
    public Integer cash_purchase { get; set; }
    @AuraEnabled
    public String channel { get; set; }
    @AuraEnabled
    public Integer customer_id { get; set; }
    @AuraEnabled
    public String lr_transaction_id { get; set; }
    @AuraEnabled
    public String offer_id { get; set; }
    @AuraEnabled
    public Integer points { get; set; }
    @AuraEnabled
    public Integer points_redeemed { get; set; }
    @AuraEnabled
    public String product { get; set; }
    @AuraEnabled
    public String source { get; set; }
    @AuraEnabled
    public Integer total_amount { get; set; }
    @AuraEnabled
    public Integer transaction_amount { get; set; }
    @AuraEnabled
    public String transaction_date { get; set; }
    @AuraEnabled
    public String transaction_type { get; set; }
    @AuraEnabled
    public String unique_customer_id { get; set; }
}

}