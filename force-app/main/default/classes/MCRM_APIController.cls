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
@SuppressWarnings('PMD.CyclomaticComplexity, PMD.CognitiveComplexity, PMD.StdCyclomaticComplexity, PMD.ExcessiveParameterList, PMD.NcssMethodCount')
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

    /****************************************************************************************************************
    * @LOB - Wellness
    * @function - invokeAPIwithParams
    * @param recId - Id of the record
    * @param intName - apiName of the Real Time API
    * @param params - Map of parameters for the api
    * @return ResponseWrapper - response wrapper for the LWC component
    * @description - Method to get api response for the Real Time Details UI component
    *****************************************************************************************************************/
    @AuraEnabled(Cacheable = false)
    public static ResponseWrapper invokeAPIwithParams(String recId ,String intName, Map<String, Object> params){
        try{
            String objectName = Id.valueOf(recId).getSObjectType().getDescribe().getName();
            if(objectName == 'Account'){
                recId = [SELECT Id, Client_Code__c FROM Account WHERE Id =: recId WITH SECURITY_ENFORCED]?.Client_Code__c;
            }else if(objectName == 'Asset'){
                recId = [SELECT Id, contractId__c FROM Asset WHERE Id =: recId WITH SECURITY_ENFORCED]?.contractId__c;
            }
            // prepare payload to pass
            String param1;
            String param2;
            String startDate;
            String endDate;
            if(params.size()>0){
                param1 = (String)params.get('param1');
                param2 = (String)params.get('param2');
                startDate = (String)params.get('startDate');
                endDate = (String)params.get('endDate');
            }

            // Create requestString for Post requests
            String requestString;
            if(intName=='MCRM_Lifestyle_Voucher' || intName=='MCRM_Wallet_Transaction'){
                requestString = '{"customerId":"'+recId+'"}';
            }else if(intName == 'MCRM_Devices'){
                requestString = '{"MemberID":"'+recId+'","OS": "android","PolicyStartDate": ""}';
            }
            
            Map <String,String> mapUrlParam = buildParametersMap(recId, param1, param2, startDate, endDate, intName);
            ABCL_IntegrationCallout.IntegrationResponseWrapper intResponseWrapper = ABCL_IntegrationCallout.executeCallout(intName, requestString, mapUrlParam);
            if(intName == 'MCRM_Devices'){
                EncryptedResponseWrapper encryptedResponse = (EncryptedResponseWrapper) JSON.deserialize(intResponseWrapper.responseBody, EncryptedResponseWrapper.class);
                if(encryptedResponse.content == null || encryptedResponse.content == ''){
                    String returnMessage = encryptedResponse.message != null ? intResponseWrapper.responseBody : '';
                    return new ResponseWrapper(intResponseWrapper.statusCode, returnMessage);
                }
                String decryptedResponse = ABHI_Encryption.decrypt(encryptedResponse.content, intName);
                if(intResponseWrapper.StatusCode == 200 && encryptedResponse.statusCode == '1000'){
                    String responseDecryptedBody = (String) JSON.deserializeUntyped(decryptedResponse);
                    // deserilaizedResponse deserializedIntResponse = (deserilaizedResponse) JSON.deserialize(responseDecryptedBody, deserilaizedResponse.class);
                    ResponseWrapper returnResponse = new ResponseWrapper(intResponseWrapper.StatusCode, responseDecryptedBody);
                    return returnResponse;
                }
                
                else{
                    String returnMessage = decryptedResponse != '' ? '{"message":"'+(String)encryptedResponse.Message+'"}' : '';
                    ResponseWrapper returnResponse = new ResponseWrapper(intResponseWrapper.StatusCode, returnMessage);
                    return returnResponse;
                }
            }
            return new ResponseWrapper(intResponseWrapper.statusCode, intResponseWrapper.responseBody);
        }catch(Exception ex){
            ABCL_Logger.logException('MCRM_APIController.invokeAPIwithParams',ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /****************************************************************************************************************
    * @function - fetchTableMetadata
    * @param configName
    * @return List<Asf_Dynamic_Datatable_Child__mdt>
    * @description - Method to fetch table metadata for the Real Time Details UI component
    *****************************************************************************************************************/
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
    /****************************************************************************************************************
    * @function - buildParametersMap
    * @param recId - Id of the record
    * @param param1
    * @param param2
    * @param fromDate
    * @param toDate
    * @param customMetadata
    * @return Map<String, String>
    * @description - Method to fetch static parameters from custom metadata and combine with dynamic parameters
    *****************************************************************************************************************/
    public static Map<String, String> buildParametersMap(String recId, String param1, String param2, String fromDate, String toDate,String customMetadata) {
        // Initialized the map for parameters
        Map<String, String> parametersMap = new Map<String, String>();
        
        // Fetching static parameters from custom metadata
        ABCL_Integrations__mdt urlParamRecord = [
            SELECT URL_Parameters__c  
            FROM ABCL_Integrations__mdt 
            WHERE DeveloperName =: customMetadata 
            WITH SECURITY_ENFORCED
        ];
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

    /*********************************************************
    *Class        :  EncryptedResponseWrapper
    *Author       :  Rohan Kosandal
    *Created Date :  23/08/2024
    *Last Modified:  23/08/2024
    *@description  :  EncryptedResponseWrapper is wrapper class to hold encrypted response
    *********************************************************/
    public class EncryptedResponseWrapper{
        public String content;
        public String statusCode;
        public String message;
    }

   
}