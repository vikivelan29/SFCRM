/**************
*Class        :  ABHI_FALevelDetails_Controller
*Author       :  Kuldeep Mishra
*Created Date :  06/08/2024
*Last Modified:  06/08/2024
*@description  :  This class is used as controller for the abhi_FALevelDetails Component and for calling FALevelDetails API
***************/

public with sharing class ABHI_FALevelDetails_Controller {
    
    @AuraEnabled
    Public static IntegrationResponseWrapper GetFALevelDetails(string customerId, string fromDate, string toDate){
        try{
       
        string integrationName = 'ABHI_FALevelDetails';
        string eventCode = 'ED-Fitnes2';
        ABCL_IntegrationCallout.accountId = customerId;
        Account acc = [SELECT Client_Code__c from Account where Id =: customerId];
        
        String scoreType = 'FITNESS_ASSESSMENT';
        Map<String,String> urlParameters = new Map<String,String>();
        urlParameters.put('eventDateFrom',fromDate);
        urlParameters.put('eventDateTo',toDate);
        urlParameters.put('customerNumber', acc.Client_Code__c);
        urlParameters.put('eventCode', eventCode);
        urlParameters.put('scoreType', scoreType);
            system.debug(urlParameters);
       
        ABCL_IntegrationCallout.IntegrationResponseWrapper integrationResp = ABCL_IntegrationCallout.executeCallout(integrationName,null, urlParameters);
        system.debug('integrationResp>>' +integrationResp);
                 IntegrationResponseWrapper deserializedIntResponse = (IntegrationResponseWrapper) JSON.deserialize(integrationResp.responseBody, IntegrationResponseWrapper.class);
                system.debug('deserialized resp' +deserializedIntResponse);
                 return deserializedIntResponse;
        
        }catch(Exception e){
         throw new AuraHandledException('Error : '+e.getMessage()+' '+e.getLineNumber());
        }
            
    }
        
        //Wrapper class for response 
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
           
       
    
   public class urlParams{
        @AuraEnabled public String startDate;
        @AuraEnabled public String endDate;
       
       
        
    }

}