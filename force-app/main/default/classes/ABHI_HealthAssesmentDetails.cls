public with sharing class ABHI_HealthAssesmentDetails {
    
    @AuraEnabled
    public static IntegrationResponseWrapper GetHealthDetails(String assetId){   //String customerId, String policyNumbe
        string integrationName = 'ABHI_HealthAssesmentDetails';
        //String request = policyNumber;
        String policyNumber = '';
        String accountId;
        Boolean hasError = false;
        //ABCL_IntegrationCallout.accountId = customerId;
         Asset assets = [SELECT Policy_No__c from Asset where Id =: assetId];
        //policyNumber = assets[0].Policy_No__c;
        system.debug('policyNumber--->' +policyNumber);
        //system.debug('assets.size()' +assets.size());
        if (assets!= null && assets.Policy_No__c != null) {
                policyNumber = assets.Policy_No__c;
                System.debug('Policy Number retrieved from Asset: ' + policyNumber);
        }
       
        try{
       
         ABCL_IntegrationCallout.IntegrationResponseWrapper integrationResp = ABCL_IntegrationCallout.executeCallout(integrationName,policyNumber, null);
        system.debug('integrationResp>>' +integrationResp);
                        System.debug('Raw Response Body: ' + integrationResp.responseBody);
        IntegrationResponseWrapper deserializedIntResponse = (IntegrationResponseWrapper) JSON.deserialize(integrationResp.responseBody, IntegrationResponseWrapper.class);
                system.debug('deserialized resp' +deserializedIntResponse);
                 return deserializedIntResponse;
        }catch(Exception e){
         throw new AuraHandledException('Error : '+e.getMessage()+' '+e.getLineNumber());
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