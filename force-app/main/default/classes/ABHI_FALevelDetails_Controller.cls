/**************
*Class        :  ABHI_FALevelDetails_Controller
*Author       :  Kuldeep Mishra
*Created Date :  06/08/2024
*Last Modified:  06/08/2024
*@description  :  This class is used as controller for the abhi_FALevelDetails Component and for calling FALevelDetails API
***************/
public with sharing class ABHI_FALevelDetails_Controller {
    /**********
     Method Name - GetFALevelDetails
     @description :  Method returns IntegrationResponse, when customerId is passed on the customers page.
     ***********/
    @SuppressWarnings('PMD.MethodNamingConventions')
    @AuraEnabled
    Public static IntegrationResponseWrapper GetFALevelDetails(string customerId, string fromDate, string toDate){
        try{
       
        string integrationName = 'ABHI_FALevelDetails';
        string eventCode = 'ED-Fitnes2';
        ABCL_IntegrationCallout.accountId = customerId;
        Account acc = [SELECT Client_Code__c from Account where Id =: customerId WITH SYSTEM_MODE];
        
        String scoreType = 'FITNESS_ASSESSMENT';
        Map<String,String> urlParameters = new Map<String,String>();
        urlParameters.put('startDate',fromDate);
        urlParameters.put('endDate',toDate);
        urlParameters.put('customerId', acc.Client_Code__c);
        //urlParameters.put('customerNumber', '12345');
       
        ABCL_IntegrationCallout.IntegrationResponseWrapper integrationResp = ABCL_IntegrationCallout.executeCallout(integrationName,null, urlParameters);
        system.debug('integrationResp>>' +integrationResp.statusCode);
                   IntegrationResponseWrapper deserializedIntResponse = (IntegrationResponseWrapper) JSON.deserialize(integrationResp.responseBody, IntegrationResponseWrapper.class);
                system.debug('deserialized resp' +deserializedIntResponse);
            return deserializedIntResponse;

        
        }catch(Exception e){
         throw new AuraHandledException('Error : '+e.getMessage()+' '+e.getLineNumber());
        }
            
    }
         @SuppressWarnings('PMD.FieldNamingConventions')
        //Wrapper class for response
        /**********
        @Class : IntegrationResponseWrapper
        @description :  Wrapper class for API response.
        ***********/
        public class IntegrationResponseWrapper {
            
       @AuraEnabled public String eventTxnId;
       @AuraEnabled public String eventCode;
       @AuraEnabled public String eventDate;
       @AuraEnabled public String customerNumber;
       @AuraEnabled public String eventValue;
       @AuraEnabled public String receivedDate;
       @AuraEnabled public String totalScore;
       @AuraEnabled public String totalCount;
       @AuraEnabled public String effectiveToDate;
       @AuraEnabled public Integer StatusCode;
       @AuraEnabled public String Message;
     
        public IntegrationResponseWrapper(Integer statusCode, String responseBody){
            this.StatusCode = statusCode;
            this.Message = responseBody;
        
    }
        }
           
       
   @SuppressWarnings('PMD.ClassNamingConventions')
        /**********
        @Class : urlParams
        @description :  Wrapper class for API response.
        ***********/
   public class urlParams{
        @AuraEnabled public String startDate;
        @AuraEnabled public String endDate;
       
       
        
    }

}