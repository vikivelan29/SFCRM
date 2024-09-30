/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 09-23-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   09-16-2024   rsinghnagar@salesforce.com   Initial Version
**/
public with sharing class MCRM_APIController {
    /****************************************************************************************************************
     * @LOB - Wellness
     * @Function - invokeAPI
     * @param apiName - apiName of Integration
     * @param assetId - Id of the asset record
     * @return String - response wrapper for the LWC component
     * @description - Method to get the response for the Last EOD Details UI component
     *****************************************************************************************************************/
    @AuraEnabled(Cacheable = false)
    public static ResponseWrapper invokeAPI(String recId ,String intName){
        // prepare payload to pass
        // String requestPayload = generateRequestPayload(apiName, assetId);
        String requestPayload = 'Dummy';

        ABCL_IntegrationCallout.IntegrationResponseWrapper intResponseWrapper = new ABCL_IntegrationCallout.IntegrationResponseWrapper();

        intResponseWrapper = (ABCL_IntegrationCallout.executeCallout(intName, requestPayload, null));
        
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
    
    @AuraEnabled(Cacheable = false)
    public static ResponseWrapper invokeAPIwithDate(String recId ,String intName,Map<String, Object> dates){
        // prepare payload to pass
        // String requestPayload = generateRequestPayload(apiName, assetId);
        if(dates.size()>0){
        	Date startDate = Date.valueOf((String)dates.get('startDate'));
    		Date endDate = Date.valueOf((String)dates.get('endDate'));
    	}
         
        
        String requestPayload = 'Dummy';

        ABCL_IntegrationCallout.IntegrationResponseWrapper intResponseWrapper = new ABCL_IntegrationCallout.IntegrationResponseWrapper();

        intResponseWrapper = (ABCL_IntegrationCallout.executeCallout(intName, requestPayload, null));
        
        return new ResponseWrapper(intResponseWrapper.statusCode, intResponseWrapper.responseBody);
    }

    @AuraEnabled(Cacheable = false)
    public static ResponseWrapper invokeAPIwithParams(String recId ,String intName,Map<String, Object> params){
        // prepare payload to pass
        // String requestPayload = generateRequestPayload(apiName, assetId);
        String param1;
         if(params.size()>0){
        	param1 = (String)params.get('param1');
    	}
        
        String requestPayload = 'Dummy';

        ABCL_IntegrationCallout.IntegrationResponseWrapper intResponseWrapper = new ABCL_IntegrationCallout.IntegrationResponseWrapper();

        intResponseWrapper = (ABCL_IntegrationCallout.executeCallout(intName, requestPayload, null));
        
        return new ResponseWrapper(intResponseWrapper.statusCode, intResponseWrapper.responseBody);
    }

    @AuraEnabled(cacheable=true)
    public static List<Asf_Dynamic_Datatable_Child__mdt> fetchTableMetadata(String configName) {
        return [
            SELECT MasterLabel,Order__c, DeveloperName ,Asf_Dynamic_Datatable_Parent__c , Api_Name__c, Data_Type__c,
            Asf_Dynamic_Datatable_Parent__r.Page_Size__c
            FROM Asf_Dynamic_Datatable_Child__mdt
            WHERE Asf_Dynamic_Datatable_Parent__r.DeveloperName = :configName WITH SYSTEM_MODE
            ORDER BY Order__c ASC
        ]; 
    }
}