/*********************************************************
*Class        :  ABHI_CreateHealthProvider_Inbound
*Author       :  Amrit Preet Singh 
*Created Date :  12/08/2024
*Last Modified:  12/08/2024
*@description  :  This webservice is to create health provider records in SFDC.
 * Modifications Log
 * Ver   Date         Author                            Modification
 * 1.0   12-08-2024   amritpreet.singh@salesforce.com   Initial Version
*********************************************************/
@RestResource(urlMapping='/CreateHealthProvider')
global with sharing class ABHI_CreateHealthProvider_Inbound {

     /**********************************************************************************************************
    * @Function - createRecords
    * @return - String - Stringified JSON list of HealthProvider objects
    * @description - httpPost method used tocreate Health_Provider records in SFDC
    ***********************************************************************************************************/
    @HttpPost
    global static String createRecords(){
        ABCL_IntegrationCallout.IntegrationResponseWrapper integrationResponse = new ABCL_IntegrationCallout.IntegrationResponseWrapper();
        String accountId;
        Boolean hasError = false;
        ABCL_Integrations__mdt integrationMdt = ABCL_IntegrationCallout.getIntegrationMetadata('ABHI_CreateHealthIntent_Inbound');
        integrationResponse.requestBody = RestContext.request.requestBody.toString();
        RequestWrapper requestBody = new RequestWrapper();
        try{
            requestBody = (RequestWrapper) JSON.deserialize(RestContext.request.requestBody.toString(), RequestWrapper.class);
            System.debug('body>>>'+ requestBody);
        
            try {
                upsert requestBody.HealthProvider Provider_Code__c;
                integrationResponse.responseBody = JSON.serialize(new ABHI_ResponseWrapper('200', 'Success', Custom_Messages__mdt.getInstance('ABHI_SuccessMessage').Message__c));
            } catch (DmlException e) {
                integrationResponse.responseBody = logError(e.getMessage(), requestBody);
                hasError = true;
            }
        }
        catch(Exception e){ 
            integrationResponse.responseBody = logError(Custom_Messages__mdt.getInstance('ABHI_InvalidJson').Message__c, requestBody);
            hasError = true;
        }
        finally {
            // Handling response in a single place
            ABCL_IntegrationCallout.handleResponse(integrationMdt, integrationResponse, hasError);
        }
        return integrationResponse.responseBody;

    }

    /*********************************************************
    *Class        :  RequestWrapper
    *Author       :  Amrit Preet Singh
    *Created Date :  05/08/2024
    *Last Modified:  05/08/2024
    *@description  : wrapper class to hold the request details
    *********************************************************/
    public class RequestWrapper{
        public List<Health_Provider__c> HealthProvider;
    }

    /****************************************************************************************************
    * @Function - logError
    * @param errorMsg - String Message to be logged
    * @param requestBody - RequestWrapper(Body) that caused the error
    * @return - String - Stringified JSON response to be retruned as a response of the request
    * @description - This method is used to log the error if any occurs during the request.
    *****************************************************************************************************/
    private static String logError(String errorMsg, RequestWrapper requestBody){
        ASF_Case_Integration__c integrationLog = new ASF_Case_Integration__c();
        ABCL_IntegrationCallout.IntegrationResponseWrapper integrationResponse = new ABCL_IntegrationCallout.IntegrationResponseWrapper();
        Boolean hasError = true;
        ABCL_Integrations__mdt  integrationMdt = ABCL_IntegrationCallout.getIntegrationMetadata('ABHI_CreateHealthIntent_Inbound');
        ABHI_ResponseWrapper abhiResponse = new ABHI_ResponseWrapper('100', 'Failure', errorMsg);
        //abhiResponse.responseBody = JSON.serialize(requestBody).substring(0,100000);
        integrationResponse.responseBody = JSON.serialize(abhiResponse) + JSON.serialize(requestBody);
        hasError = true;
        // ABHI_ResponseWrapper.createLog(integrationLog,integrationMdt, integrationResponse, hasError);
        return JSON.serialize(abhiResponse);
    }
}