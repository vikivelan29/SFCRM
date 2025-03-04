/***************************************
*Class        :  ABHI_HealthAssesmentDetails
*Author       :  Kuldeep Mishra
*Created Date :  25/08/2024
*Last Modified:  11/10/2024 // update by Raj Raghuwanshi added HHS_End_Date, HHS_Start_Date,HR_Expiry_Date in wrapper as part of renewal requirment 
*@description :  This class used as a outBound API call and a controller for abhi_HealthAssesmentDetails component.
***************************************/
@SuppressWarnings('PMD.ExcessivePublicCount')
public with sharing class ABHI_HealthAssesmentDetails {
    
     /**********
     Method Name - GetHealthDetails
     @description :  Method returns IntegrationResponse, when assetId is passed on the Asset page.
     ***********/
    @SuppressWarnings('PMD.MethodNamingConventions')
    @AuraEnabled
    public static IntegrationResponseWrapper GetHealthDetails(String assetId){
        
        String policyNumber;
        String customerId;
        //Boolean hasError = false;
        
        try{
            string integrationName = 'ABHI_HealthAssesmentDetails';
            Asset assets = [SELECT Policy_No__c,AccountId from Asset where Id =: assetId WITH SYSTEM_MODE];
            if (assets!= null && assets.Policy_No__c != null) {
                policyNumber = assets.Policy_No__c;
                customerId = assets.AccountId;
            }
            ABCL_IntegrationCallout.accountId = customerId;
            String conPayload =  JSON.serialize(new HealthViewRequest(policyNumber));
            ABCL_IntegrationCallout.IntegrationResponseWrapper integrationResp = ABCL_IntegrationCallout.executeCallout(integrationName,conPayload, null);
            IntegrationResponseWrapper deserializedIntResponse = (IntegrationResponseWrapper) JSON.deserialize(integrationResp.responseBody, IntegrationResponseWrapper.class);
            return deserializedIntResponse;
        }catch(Exception e){
            throw new AuraHandledException('Error : '+e.getMessage()+' '+e.getLineNumber());
        } 
    }
    
    
      /**********
     @Class - HealthViewRequest
     @description :  Request wrapper
     ***********/
       @SuppressWarnings('PMD.FieldNamingConventions,PMD.ClassNamingConventions,PMD.VariableNamingConventions')
    public class HealthViewRequest {
        public String policyNumber;
        HealthViewRequest(String policyNumber) {
            this.policyNumber = policyNumber;
        }
    }
    
     /**********
     @Class - IntegrationResponseWrapper
     @description :  Response Wrapper class
     ***********/
       @SuppressWarnings('PMD.FieldNamingConventions,PMD.ClassNamingConventions,PMD.VariableNamingConventions')
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
    
     /**********
     @Class - requestListWrapper
     @description :  Response Wrapper class
     ***********/
       @SuppressWarnings('PMD.FieldNamingConventions,PMD.ClassNamingConventions,PMD.VariableNamingConventions,PMD.TooManyFields')
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
        @AuraEnabled
        public String HR_Expiry_Date; // Added as part of Renewal requirement 
        @AuraEnabled
        public String HHS_Start_Date; // Added as part of Renewal requirement
        @AuraEnabled
        public String HHS_End_Date; // Added as part of Renewal requirement
    }
    
}