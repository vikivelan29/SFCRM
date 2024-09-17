/**
 * @description       : Class to handle EOD API integration
 * @author            : udit.singhal@salesforce.com
 * @group             : ABFL
 * @last modified on  : 21-03-2024
 * @last modified by  : udit.singhal@salesforce.com
 * Modifications Log
 * Ver      Date           Author                            Modification
 * 1.0      21-03-2024     udit.singhal@salesforce.com      Initial Version
 **/
@SuppressWarnings('PMD.CognitiveComplexity')
public without sharing class ABFL_EODController{
    /****************************************************************************************************************
     * @LOB - ABFL
     * @Function - invokeAPI
     * @param apiName - apiName of the EOD API
     * @param assetId - Id of the asset record
     * @return String - response wrapper for the LWC component
     * @description - Method to get the response for the Last EOD Details UI component
     *****************************************************************************************************************/
    @AuraEnabled(Cacheable = false)
    public static ResponseWrapper invokeAPI(String apiName, Id assetId){
        // prepare payload to pass
        String requestPayload = generateRequestPayload(apiName, assetId);

        ABCL_IntegrationCallout.IntegrationResponseWrapper intResponseWrapper = new ABCL_IntegrationCallout.IntegrationResponseWrapper();

        switch  on apiName{
            when 'EOD_Account_Balance'{
                intResponseWrapper = (ABCL_IntegrationCallout.executeCallout(ABFL_Constants.EOD_ACCOUNT_BALANCE_INTEGRATION_METADATA, requestPayload, null));
            }
            when 'EOD_Application_Details'{
                intResponseWrapper = (ABCL_IntegrationCallout.executeCallout(ABFL_Constants.EOD_APPLICATION_DETAILS_INTEGRATION_METADATA, requestPayload, null));
            }
            when 'EOD_Repayment_Details'{
                intResponseWrapper = (ABCL_IntegrationCallout.executeCallout(ABFL_Constants.EOD_REPAYMENT_DETAILS_INTEGRATION_METADATA, requestPayload, null));
            }
            when 'EOD_Disbursement_Details'{
                intResponseWrapper = (ABCL_IntegrationCallout.executeCallout(ABFL_Constants.EOD_DISBURSEMENT_DETAILS_INTEGRATION_METADATA, requestPayload, null));
            }
        }
        
        return new ResponseWrapper(intResponseWrapper.statusCode, intResponseWrapper.responseBody);
    }

    /****************************************************************************************************************
     * @LOB - ABFL
     * @Function - generateRequestPayload
     * @param apiName - apiName of the EOD API
     * @param assetId - Id of the asset record
     * @return String - request payload for the EOD API
     * @description - Method to generate requestPayload based on apiName and assetId
     *****************************************************************************************************************/
    private static String generateRequestPayload(String apiName, Id assetId){
        Map<String, Object> requestPayload = new Map<String, Object>();

        Asset assetRecord = ABFL_SOQL_Util.getAssetInfo(assetid);

        if (assetRecord != null){
            // Generate request payload based on apiName
            if (apiName == 'EOD_Account_Balance' && String.isNotBlank(assetRecord.LAN__c)){
                requestPayload.put('loanAccountNumber', assetRecord.LAN__c);
                requestPayload.put('type', 1);
            } else if (apiName == 'EOD_Application_Details' && String.isNotBlank(assetRecord.LAN__c)){
                requestPayload.put('applicationNo', assetRecord.Application_Number__c);
                requestPayload.put('type', 2);
            } else if (apiName == 'EOD_Disbursement_Details' && String.isNotBlank(assetRecord.LAN__c)){
                requestPayload.put('loanAccountNumber', assetRecord.LAN__c);
                requestPayload.put('type', 3);
            } else if (apiName == 'EOD_Repayment_Details' && String.isNotBlank(assetRecord.LAN__c)){
                requestPayload.put('loanAccountNumber', assetRecord.LAN__c);
                requestPayload.put('type', 4);
            }
        }
        return JSON.serialize(requestPayload);
    }

    /****************************************************************************************************************
    * @description Wrapper class to send the response to LWC
    *****************************************************************************************************************/
    public Class ResponseWrapper{
        @AuraEnabled
        public Integer statusCode;
        @AuraEnabled
        public String payload;

        /****************************************************************************************************************
        * @description Custom constructor of ResponseWrapper class
        * @param statusCode
        * @param res
        *****************************************************************************************************************/
        public ResponseWrapper(Integer statusCode, String res){
            this.statusCode = statusCode;
            this.payload = res;
        }
    }
}