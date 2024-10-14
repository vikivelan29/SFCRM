/***************************************
*Class        :  ABHI_HealthAssesmentDetails
*Author       :  Kuldeep Mishra
*Created Date :  25/08/2024
*Last Modified:  27/08/2024
*@description :  This class used as a outBound API call and a controller for abhi_HealthAssesmentDetails component.
***************************************/
public with sharing class ABHI_HealthAssesmentDetails {
    
    @AuraEnabled
    public static IntegrationResponseWrapper GetHealthDetails(String assetId){

        String policyNumber;
        String customerId;
        Boolean hasError = false;
         
        try{
            string integrationName = 'ABHI_HealthAssesmentDetails';
            Asset assets = [SELECT Policy_No__c,AccountId from Asset where Id =: assetId];
        if (assets!= null && assets.Policy_No__c != null) {
                policyNumber = assets.Policy_No__c;
                customerId = assets.AccountId;
                System.debug('Policy Number retrieved from Asset: ' + policyNumber);
             }
                ABCL_IntegrationCallout.accountId = customerId;
                String conPayload =  JSON.serialize(new HealthViewRequest(policyNumber));
                ABCL_IntegrationCallout.IntegrationResponseWrapper integrationResp = ABCL_IntegrationCallout.executeCallout(integrationName,conPayload, null);
                IntegrationResponseWrapper deserializedIntResponse = (IntegrationResponseWrapper) JSON.deserialize(integrationResp.responseBody, IntegrationResponseWrapper.class);
                system.debug('deserialized resp' +deserializedIntResponse);
                return deserializedIntResponse;
        }catch(Exception e){
         throw new AuraHandledException('Error : '+e.getMessage()+' '+e.getLineNumber());
        } 
    }
    
    
    
    public class HealthViewRequest {
        public String policyNumber;
        HealthViewRequest(String policyNumber) {
            this.policyNumber = policyNumber;
        }
    }
    
    
    //Response Wrapper class
    public class IntegrationResponseWrapper{
        @AuraEnabled
        public List<requestListWrapper> Response;
        @AuraEnabled
        public Integer StatusCode;
        @AuraEnabled
        public String Message;	
        //public IntegrationResponseWrapper(Integer statusCode, String responseBody){
            //this.StatusCode = statusCode;
            //this.Message = responseBody;
        //}
    }
    public class requestListWrapper{
        @AuraEnabled
        public String AHCdate;
        @AuraEnabled
        public String EligibiltytoearnHRAHC;
        @AuraEnabled
        public String EligibiltytoearnHRDHA;
        @AuraEnabled
        public String EligibiltytoearnHRHA;
        @AuraEnabled
        public String HHSDHA;
        @AuraEnabled
        public String HHSExpiredDateDHA;
        @AuraEnabled
        public String HHSExpiredDateHA;
        @AuraEnabled
        public String HHSHA;
        @AuraEnabled
        public String HealthAssesmentStatusAHC;
        @AuraEnabled
        public String HealthAssesmentStatusDHA;
        @AuraEnabled
        public String HealthAssesmentStatusHA;
        @AuraEnabled
        public String MemberlevelHHS;
        @AuraEnabled
        public String Name;
        @AuraEnabled
        public String vchClientCode;
        @AuraEnabled
        public String vchPolicyNumber;
    }
    
}