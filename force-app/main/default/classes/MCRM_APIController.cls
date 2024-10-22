/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 09-28-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   09-16-2024   rsinghnagar@salesforce.com   Initial Version
**/
public with sharing class MCRM_APIController {

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
    public static ResponseWrapper invokeAPIwithParams(String recId ,String intName,Map<String, Object> params){
        // recId = '1187714';
        //recId = '2907103';// for gym voucher

        String objectName = Id.valueOf(recId).getSObjectType().getDescribe().getName();
        if(objectName == 'Account'){
            recId = [SELECT Id, Client_Code__c FROM Account WHERE Id =: recId]?.Client_Code__c;
        }else if(objectName == 'Asset'){
            recId = [SELECT Id, contractId__c FROM Asset WHERE Id =: recId]?.contractId__c;
        }
        // prepare payload to pass
        // String requestPayload = generateRequestPayload(apiName, assetId);
        String contractId, param1, param2, startDate, endDate;
         if(params.size()>0){
        	param1 = (String)params.get('param1');
        	param2 = (String)params.get('param2');
        	startDate = (String)params.get('startDate');
    		endDate = (String)params.get('endDate');
    	}
        
        Map <String,String> mapUrlParam = buildParametersMap(recId, param1, param2, startDate, endDate, intName);
        ABCL_IntegrationCallout.IntegrationResponseWrapper intResponseWrapper = ABCL_IntegrationCallout.executeCallout(intName, null, mapUrlParam);
        
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

    // Method to fetch static parameters from custom metadata and combine with dynamic parameters
    public static Map<String, String> buildParametersMap(String recId, String param1, String param2, String fromDate, String toDate,String customMetadata) {
        // Initialized the map for parameters
        Map<String, String> parametersMap = new Map<String, String>();
        
        // Fetching static parameters from custom metadata
        ABCL_Integrations__mdt urlParamRecord = [SELECT URL_Parameters__c  FROM ABCL_Integrations__mdt WHERE DeveloperName =: customMetadata LIMIT 1];
        String staticParameters = urlParamRecord.URL_Parameters__c ;
        if(staticParameters != null){
            // Replace placeholders with actual values
            String parametersString = staticParameters
                .replace('{customerId}', recId != null ? EncodingUtil.urlEncode(recId, 'UTF-8') : 'null')
                .replace('{contractId}', recId != null ? EncodingUtil.urlEncode(recId, 'UTF-8') : 'null')
                .replace('{param1}', param1 != null ? EncodingUtil.urlEncode(param1, 'UTF-8') : 'null')
                .replace('{param2}', param2 != null ? EncodingUtil.urlEncode(param2, 'UTF-8') : 'null')
                .replace('{fromDate}', fromDate != null ? EncodingUtil.urlEncode(fromDate, 'UTF-8') : 'null')
                .replace('{toDate}', toDate != null ? EncodingUtil.urlEncode(toDate, 'UTF-8') : 'null');

            // Split the parameters string into individual key-value pairs
            String[] paramPairs = parametersString.split('&');
            for (String pair : paramPairs) {
                String[] keyValue = pair.split('=');
                if (keyValue.size() == 2) {
                    // Add key-value pairs to the map
                    parametersMap.put(keyValue[0].trim(), keyValue[1].trim());
                }
            }
        }
        return parametersMap;
    }
}