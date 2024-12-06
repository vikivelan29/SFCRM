public with sharing class ABSLAMC_SprinklrSocialMediaProfileCtrl {
    
    @AuraEnabled
    public static responseWrapper getSocialMediaProfileResponse(String accId) {
        
        responseWrapper resultWrap = new responseWrapper();
        String request = '';
        System.debug('@@@accID'+accId);
        Map<String,String>  emailPhoneMap = getAccount(accId);
        String email = emailPhoneMap.get('Email');
        String phone = emailPhoneMap.get('Phone');
        System.debug('Email:'+email+' Phone:'+phone);
        
        // Build the JSON request based on available data
        if (!String.isEmpty(email) && !String.isEmpty(phone)) {
            request = '{"customerEmail":"'+email+'","customerMobile":"'+phone+'"}';
        } else if (!String.isEmpty(email)) {
            request = '{"customerEmail":"'+email+'"}';
        } else if (!String.isEmpty(phone)) {
            request = '{"customerMobile":"'+phone+'"}';
        }
        
        System.debug('Request:' + request);
        
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
    
    public static Map<String, String> getAccount(String accId) {
        Account account = [
            SELECT Id,PersonEmail,PersonMobilePhone,Office_Email__c,Phone,RecordType.DeveloperName,
            (SELECT Id,Phone,Email FROM Contacts LIMIT 1)
            FROM Account
            WHERE Id = :accId
            LIMIT 1
        ];
        System.debug(account);
        System.debug(account.Contacts);
        
        Map<String, String> result = new Map<String, String>();
        if (account.RecordType.DeveloperName == 'ABSLAMC_Non_Individual_Distributor' || 
            account.RecordType.DeveloperName == 'Non_Individual') {
                
                if (!account.Contacts.isEmpty()) {
                    Contact primaryContact = account.Contacts[0];
                    result.put('Email', primaryContact.Email);
                    result.put('Phone', primaryContact.Phone);
                } else {
                    result.put('Email', '');
                    result.put('Phone', ''); 
                }
                
            } else if (account.RecordType.DeveloperName == 'ABSLAMC_Individual_Distributor' || 
                       account.RecordType.DeveloperName == 'Individual') {
                           
                           result.put('Email', account.PersonEmail);
                           result.put('Phone', account.PersonMobilePhone);
                       }
        
        return result;
    }
    
    
    public class responseWrapper {
        @AuraEnabled public Boolean isSuccess{get;set;}
        @AuraEnabled public String errorMessage{get;set;}
        @AuraEnabled public String responseBody{get;set;}
    }
}
