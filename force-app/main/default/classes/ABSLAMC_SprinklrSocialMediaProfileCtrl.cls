public with sharing class ABSLAMC_SprinklrSocialMediaProfileCtrl {
    
    @AuraEnabled
    public static responseWrapper getSocialMediaProfileResponse(String accId) {
        
        responseWrapper resultWrap = new responseWrapper();
        String request = '';
        Account acc = getAccount(accId);

        if(!String.isEmpty(acc.PersonEmail) && !String.isEmpty(acc.PersonMobilePhone)){
            request = '{"customerEmail ":"'+acc.PersonEmail+'","customerMobile ":"'+acc.PersonMobilePhone+'"}'; 
        } else if(!String.isEmpty(acc.PersonEmail)){
            request = '{"customerEmail ":"'+acc.PersonEmail+'"}'; 
        } else if(!String.isEmpty(acc.PersonMobilePhone)){
            request = '{"customerMobile ":"'+acc.PersonMobilePhone+'"}'; 
        }
        System.debug('Request:'+request);
          ABCL_IntegrationCallout.IntegrationResponseWrapper responseWrapper = ABCL_IntegrationCallout.executeCallout('ABAMC_Get_Social_Media_Profile', request, null);
        if(responseWrapper != null && responseWrapper.statusCode == 200){
            resultWrap.responseBody = responseWrapper.responseBody;
            resultWrap.isSuccess = true;
        }else{
            resultWrap.isSuccess = false;
            resultWrap.errorMessage = responseWrapper.responseBody;
        }
        System.debug('resp:'+resultWrap);
        return resultWrap;
        
    }
    
    public static Account getAccount(string accId){
        return [Select Id,PersonEmail,PersonMobilePhone from Account
                Where id =: accId
                AND Business_Unit__c =: ABSLAMC_Constants.ABSLAMCBU LIMIT 1];
    }
    
    public class responseWrapper {
        @AuraEnabled public Boolean isSuccess{get;set;}
        @AuraEnabled public String errorMessage{get;set;}
        @AuraEnabled public String responseBody{get;set;}
    }
}