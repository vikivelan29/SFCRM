public with sharing class ABCD_AppPageDetails {
     /****************************************************************************************************************
    * @LOB - ABCD
    * @Function - getAppPageDetails
    * @param accountId - accountId
    * payload - request body
    * @return - AppPageResponse
    * @Description - Makes the callout and logs the response in ASF_Case_Integration__c
    *****************************************************************************************************************/ 
    @AuraEnabled
    public static AppPageInfoResponse getAppPageDetails(string accountId){ 
        try{
            AppPageInfoResponse responseWrapper = new AppPageInfoResponse();
            String integrationName = 'ABCD_App_Pages';
            Account accRec = [SELECT Id, Name, PersonMobilePhone, PersonEmail, Client_Code__c FROM Account WHERE Id=:accountId LIMIT 1];
            String payload = JSON.serialize(new CustomerInfoRequest(accRec.Client_Code__c));
            ABCL_IntegrationCallout.accountId=accountId;
            ABCL_IntegrationCallout.IntegrationResponseWrapper appPageResp = ABCL_IntegrationCallout.executeCallout(integrationName, payload, null);
            system.debug('responsewrap '+appPageResp);            
            if (appPageResp != null && appPageResp.responseBody != null) {
                responseWrapper = (AppPageInfoResponse)JSON.deserialize(appPageResp.responseBody, AppPageInfoResponse.class);
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
           // this.mobileNumber = mob;
            //this.emailId = email;
            this.customerId = custId;
        }
    }
public class AppPageInfoResponse {
    @AuraEnabled public Integer code;
    @AuraEnabled public String message;
    @AuraEnabled public AppPageInfo appPageInfo;
    @AuraEnabled public String status;
}

public class AppPageInfo {
    @AuraEnabled public AppPageDetails appPageDetails;
}

public class AppPageDetails {
    @AuraEnabled public String appLastDownLoadDate;
    @AuraEnabled public String appVersionWithCustomer;
    @AuraEnabled public String deviceName;
    @AuraEnabled public String lastOTPDate;
    @AuraEnabled public String lastSIMBindingDate;
    @AuraEnabled public String lastDeviceBindingDate;
    @AuraEnabled public String appUninstalledDate;
}

}