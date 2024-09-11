/**
 * @description       : 
 * @author            : Salesforce.com
 * @group             : 
 * @last modified on  : 08-12-2024
 * @last modified by  : santanu.halder
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   08-12-2024   santanu.halder@salesforce.com   Initial Version
**/

public without sharing class ABAMC_DisplayDigitalErrorsController {
    @AuraEnabled
    public static ReturnWrapper fetchDigitalErrors(String input){
        ReturnWrapper wrap = new ReturnWrapper();
        //input is account id
        //get the pan of the customer
        Account custAcc = [Select Id, PAN__c from Account where Id = :input and Business_Unit__c = 'ABSLAMC' LIMIT 1];

        //Build the payload
        String payload = '{"panValue":"'+custAcc.PAN__c+'","channelId":"CHA1005"}';
        
        //use ABCL_IntegrationUtility class to invoke the api
        ABCL_IntegrationCallout.IntegrationResponseWrapper responseWrapper = ABCL_IntegrationCallout.executeCallout('ABAMC_Get_DIgital_Asset_Errors', payload, null);
        
        //process the response
        if(responseWrapper != null && responseWrapper.statusCode == 200){
            //returning the response body as string to LWC as its easier & less resource consuming to parse it in JS than in apex.
            wrap.responseBody = responseWrapper.responseBody;
            wrap.isSuccess = true;
        }else{
            //handle errors, return meaningful error to LWC
            wrap.isSuccess = false;
            wrap.errorMessage = responseWrapper.responseBody;
        }
        //return
        return wrap;
    }


    public class ReturnWrapper {
        @AuraEnabled public Boolean isSuccess{get;set;}
        @AuraEnabled public String errorMessage{get;set;}
        @AuraEnabled public String responseBody{get;set;}
    }


}