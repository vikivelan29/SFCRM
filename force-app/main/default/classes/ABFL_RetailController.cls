/**
 * @description       : Class to handle Real Time API integration
 * @author            : rsinghnagar@salesforce.com
 * @group             : ABFL
 * @last modified on  : 03-14-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver      Date           Author                            Modification
 * 1.0      28-12-2023     rsinghnagar@salesforce.com      Initial Version
 * 2.0      28-02-2024     udit.singhal@salesforce.com     updated logic for the real time API
 **/
@SuppressWarnings('PMD.CognitiveComplexity')
public without sharing class ABFL_RetailController{
    /****************************************************************************************************************
     * @LOB - ABFL
     * @Function - getDynamicScreen
     * @param String apiName - apiName of the Real Time API
     * @param Id assetId - Id of the asset record
     * @return String - response wrapper for the LWC component
     * @Description - Method to get the response for the Real Time Details UI component
     *****************************************************************************************************************/
    @AuraEnabled(Cacheable = false)
    public static ResponseWrapper invokeAPI(String apiName, Id assetId){
        // prepare payload to pass
        String requestPayload = generateRequestPayload(apiName, assetId);
        System.debug('requestPayload: '+requestPayload);

        ABCL_IntegrationCallout.IntegrationResponseWrapper intResponseWrapper = new ABCL_IntegrationCallout.IntegrationResponseWrapper();

        switch  on apiName{
            when 'RTL_RealTime_LoanDetails'{
                intResponseWrapper = (ABCL_IntegrationCallout.executeCallout(ABFL_Constants.RTL_LOANDETAILS_INTEGRATION_METADATA, requestPayload, null));
            }
            when 'RTL_RealTime_BasicCustInfo'{
                intResponseWrapper = (ABCL_IntegrationCallout.executeCallout(ABFL_Constants.RTL_BASICCUSTINFO_INTEGRATION_METADATA, requestPayload, null));
            }
            when 'RTL_RealTIme_GCCPropertyDetails'{
                intResponseWrapper = (ABCL_IntegrationCallout.executeCallout(ABFL_Constants.RTL_GCCPROPERTYDETAILS_INTEGRATION_METADATA, requestPayload, null));
            }
            when 'RTL_RealTime_LoanMIS'{
                intResponseWrapper = (ABCL_IntegrationCallout.executeCallout(ABFL_Constants.RTL_LOANMIS_INTEGRATION_METADATA, requestPayload, null));
            }
            when 'RTL_RealTime_InstallPmntDtls'{
                intResponseWrapper = (ABCL_IntegrationCallout.executeCallout(ABFL_Constants.RTL_INSTALLPMNTDTLS_INTEGRATION_METADATA, requestPayload, null));
            }
        }

        System.debug('status code: '+intResponseWrapper.statusCode);
        System.debug('response body: '+intResponseWrapper.responseBody);
        
        return new ResponseWrapper(intResponseWrapper.statusCode, intResponseWrapper.responseBody);
    }

    /****************************************************************************************************************
     * @LOB - ABFL
     * @Function - generateRequestPayload
     * @param String apiName - apiName of the Real Time API
     * @param Id assetId - Id of the asset record
     * @return String - request payload for the Real Time API
     * @Description - Method to generate requestPayload based on apiName and assetId
     *****************************************************************************************************************/
    private static String generateRequestPayload(String apiName, Id assetId){
        Map<String, String> requestPayload = new Map<String, String>();

        Asset assetRecord = ABFL_SOQL_Util.getAssetInfo(assetid);

        if (assetRecord != null){
            List<String> validValues = new List<String>{'RTL_RealTIme_GCCPropertyDetails', 'RTL_RealTime_LoanMIS', 'RTL_RealTime_InstallPmntDtls'};
            // Generate request payload based on apiName
            if (apiName == 'RTL_RealTime_LoanDetails' && String.isNotBlank(assetRecord.LAN__c)){
                requestPayload.put('CCC', '');
                requestPayload.put('LAN', assetRecord.LAN__c);
            } else if (apiName == 'RTL_RealTime_BasicCustInfo' && String.isNotBlank(assetRecord.Account.PAN__c)){
                requestPayload.put('PAN', assetRecord.Account.PAN__c);
            } else if (validValues.contains(apiName) && String.isNotBlank(assetRecord.LAN__c)){
                requestPayload.put('LoanAccountNo', assetRecord.LAN__c);
            } else if (apiName == 'RTL_RealTime_GetCRMDetails' && String.isNotBlank(assetRecord.LAN__c)){
                requestPayload.put('loanNo', assetRecord.LAN__c);
            }
        }
        return JSON.serialize(requestPayload);
    }

    public Class ResponseWrapper{
        @AuraEnabled
        public Integer statusCode;
        @AuraEnabled
        public String payload;
        public ResponseWrapper(Integer statusCode, String res){
            this.statusCode = statusCode;
            this.payload = res;
        }
    }
}