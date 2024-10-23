/*********************************************************
*Class        :  ABCL_IntegrationCallout
*Author       :  Siddarth Jaitly
*Created Date :  30/11/2023
*Last Modified:  01/12/2023
*Description  :  Outbound Callout Logger
*********************************************************/
public with sharing class ABCL_IntegrationCallout {
    public static string caseId;
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - executeCallout
    * @param integrationName - Name of Integration Metadata Record, protocol - Specified the Http Action,
    * payload - request body, urlParameters - Map of URL parameters
    * @return - IntegrationResponseWrapper
    * @Description - Makes the callout and logs the response in ASF_Case_Integration__c
    *****************************************************************************************************************/       
    public static IntegrationResponseWrapper executeCallout( String integrationName, 
                                                          string payload, 
                                                          Map<String,String> urlParameters){
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        IntegrationResponseWrapper integrationResponse = new IntegrationResponseWrapper();
        Boolean hasError = false;
        
        //Fetch Integration Metadata Record
        ABCL_Integrations__mdt  integrationMdt = getIntegrationMetadata(integrationName);
        
        //Build Endpoint URL using provided parameters
        string endPointURL = integrationMdt.EndPoint__c;
        if(urlParameters != null){
            buildURLParameters(urlParameters,integrationMdt.EndPoint__c);                                                  
        }                                              
        
        // Build HttpRequest
        request.setMethod(integrationMdt.Protocol__c);
        request.setEndPoint(endPointURL);
	if(integrationMdt.Timeout__c != null){
            request.setTimeout(Integer.valueof(integrationMdt.Timeout__c));
        }
        
        //Check for Payload
        if(!String.isBlank(payload)){
            request.setBody(payload);
            integrationResponse.requestBody = payload;
        }
                                                      
        //Prepare Header present in Integration Metadata
        if(String.isNotBlank(integrationMdt.HTTP_Headers__c)){
            Map<String,String> headerMap = prepareHeaders(integrationMdt.HTTP_Headers__c);
            for(String key : headerMap.keySet()){
                request.setHeader(key,headerMap.get(key));
            }
        }                                                      
        
        system.debug(request);
        //Execute the callout
        try{
            if(!integrationMdt.EnableMockResponse__c){
                response = new Http().send(request);    
            }
        }catch(Exception e){
            hasError = true;   
        }finally{
            string responseStr = '';
            integer statusCode;
            integrationResponse.responseBody = response != null ? response.getBody() : ''; 
            integrationResponse.StatusCode = response != null ? response.getStatusCode() : 0;
			integrationResponse = handleResponse(integrationMdt,integrationResponse,hasError);
        }
        
        return integrationResponse;
    }
    public IntegrationResponseWrapper executeCaseCallout( String integrationName,string payload,Map<String,String> urlParameters){
        return executeCallout( integrationName, payload, urlParameters);
    }
    public static ABCL_Integrations__mdt  getIntegrationMetadata(string integrationName){
        List<ABCL_Integrations__mdt> integrationMetadata = [Select  EndPoint__c,HTTP_Headers__c,EnableMockResponse__c,
                                                                    Mock_Status_Code__c,Timeout__c,Mock_Response_Resource__c,
                                                                    Full_Log__c,Exception_Log__c,StoreAsAttachment__c,Protocol__c 
                                                                    from ABCL_Integrations__mdt where DeveloperName =: integrationName];
        return integrationMetadata[0];
    }
    
    public static String buildURLParameters(Map<String,String> urlParameters,string endPoint){
        List<String> paramList = new List<String>();
        for(string key : urlParameters.keySet()){
            paramList.add(key + '=' + urlParameters.get(key));
        }
        if(paramList.size() > 0){
            endPoint += '?';
            endPoint += String.join(paramList,'&');
        }
        return endPoint;
    }
    
    public static Map<String,String> prepareHeaders(string headerStr){
        Map<String,String> headerMap;
        try{
            headerMap = (Map<String,String>)JSON.deserialize(headerStr,Map<String,String>.class);
        } catch(Exception e){
            headerMap = new Map<String,String>();
        }
        return headerMap;
    }
    
    public static IntegrationResponseWrapper handleResponse(ABCL_Integrations__mdt  integrationMdt,IntegrationResponseWrapper integrationResponse, Boolean hasError){
        ASF_Case_Integration__c integrationLog = new ASF_Case_Integration__c();
        integrationLog.Type__c = 'Log';
        
        if(!hasError){
            integrationLog.Status__c = 'Success';
            integrationResponse = getStaticResource(integrationMdt,integrationResponse);
        } else {
            integrationLog.Status__c = 'Failure';
        }

        if(!integrationMdt.StoreAsAttachment__c){
            integrationLog.Response__c = integrationResponse.responseBody;
        }
        
        if(integrationMdt.Full_Log__c || (integrationMdt.Exception_Log__c && hasError)){
            if(String.isNotBlank(caseId)){
                integrationLog.Case__c = caseId;
            }
            if(String.isnotBlank(integrationResponse.requestBody)){
                integrationLog.Request__c = integrationResponse.requestBody;
            }
            system.debug('integrationLog:'+integrationLog);
            if(Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
                insert integrationLog;
                storeResponseAttachment(integrationMdt,integrationResponse,integrationLog.Id);
            }
        }
        
        return integrationResponse;
    }

    public static IntegrationResponseWrapper getStaticResource(ABCL_Integrations__mdt  integrationMdt,IntegrationResponseWrapper integrationResponse){
        if(integrationMdt.EnableMockResponse__c){
            if(String.isNotBlank(integrationMdt.Mock_Response_Resource__c)){
                List<StaticResource> mockResponseList = [Select Body from StaticResource 
                                                            where Name =: integrationMdt.Mock_Response_Resource__c WITH SECURITY_ENFORCED];
                if(mockResponseList.size() > 0){
                    integrationResponse.responseBody = mockResponseList[0].Body.toString();
                    integrationResponse.StatusCode = Integer.valueof(integrationMdt.Mock_Status_Code__c);
                }
            }
        }
        return integrationResponse;
    }

    public static void storeResponseAttachment(ABCL_Integrations__mdt  integrationMdt,IntegrationResponseWrapper integrationResponse, string integrationLogId){
        if(integrationMdt.StoreAsAttachment__c && String.isNotBlank(integrationResponse.responseBody)){
            ContentVersion content = new ContentVersion();
            content.PathOnClient = 'Response.txt';
            content.Title = 'Response';
            content.VersionData = Blob.valueof(integrationResponse.responseBody);
            if(Schema.sObjectType.ContentVersion.isCreateable()){
                insert content;
            }
            ContentVersion conVersion = [Select ContentDocumentId from ContentVersion where id =: content.Id WITH SECURITY_ENFORCED];
            ContentDocumentLink docLink = new ContentDocumentLink();
            docLink.LinkedEntityId = integrationLogId;
            docLink.ContentDocumentId = conVersion.ContentDocumentId;
            docLink.ShareType = 'V';
            if(Schema.sObjectType.ContentDocumentLink.isCreateable()){
                insert docLink;
            }
        }
    }
    
    public class IntegrationResponseWrapper{
        public string responseBody;
        public integer statusCode;
        public string requestBody;
    }
}
