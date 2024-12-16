/**
* @description       : 
* @author            : Salesforce.com
* @group             : 
* @last modified on  : 12-02-2024
* @last modified by  : Neeraj Kumar
* Modifications Log
* Ver   Date         Author                       Modification
* 1.0   08-12-2024   nkumar6@salesforce.com   Initial Version
**/
public class ABSLAMC_AUMAPIDetailsController {

    @AuraEnabled
    public static ReturnWrapper fetchAUMDetails(String accId) {
        ReturnWrapper wrap = new ReturnWrapper();

        if (String.isBlank(accId)) {
            wrap.isSuccess = false;
            wrap.errorMessage = 'Case Id cannot be null or blank.';
            return wrap;
        }

        Map<String, String> resMap = getAccountWithPAN(accId);

        if (resMap == null || !resMap.containsKey('PAN')) {
            wrap.isSuccess = false;
            wrap.errorMessage = 'PAN details not found for the customer.';
            return wrap;
        }

        // Build the payload
        String payload = '{"PAN":"'+ resMap.get('PAN') +'"}';

        System.debug('Req: ' + payload);

        // Use ABCL_IntegrationUtility class to invoke the API
        ABCL_IntegrationCallout.IntegrationResponseWrapper responseWrapper = ABCL_IntegrationCallout.executeCallout('ABAMC_Get_AUM_Details', payload, null);

        System.debug('resp: ' + responseWrapper);

        if (responseWrapper != null && responseWrapper.statusCode == 200) {
            wrap.responseBody = responseWrapper.responseBody;
            wrap.isSuccess = true;
        } else {
            wrap.isSuccess = false;
            wrap.errorMessage = responseWrapper != null ? responseWrapper.responseBody : 'An error occurred while invoking the API.';
        }

        return wrap;
    }

    public static Map<String, String> getAccountWithPAN(String accId) {
        Map<String, String> result = new Map<String, String>();

        if (String.isBlank(accId)) {
            return result; // Return empty map if caseId is blank
        }

        try {
            Account accRec = [SELECT Id,PAN__c FROM Account WHERE Id = :accId LIMIT 1];
            if (accRec != null && accRec.PAN__c != null) {
                result.put('PAN', accRec.PAN__c);
            }
        } catch (Exception e) {
            System.debug('Error while fetching PAN: ' + e.getMessage());
        }

        return result;
    }

    public class ReturnWrapper {
        @AuraEnabled public Boolean isSuccess { get; set; }
        @AuraEnabled public String errorMessage { get; set; }
        @AuraEnabled public String responseBody { get; set; }
    }
}