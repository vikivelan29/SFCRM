/*********************************************************
*Class        :  ABHI_ActiveDaysDashboardController
*Author       :  Shubham Sinha 
*Created Date :  01/08/2024
*Last Modified:  01/08/2024
*@description  :  This class is used for calling ActiveDays DashboardAPI
*********************************************************/
public with sharing class ABHI_ActiveDaysDashboardController {
    /****************************************************************************************************************
    * @LOB - ABHIL
    * @Function - getActiveDaysDashboard
    * @param customerID - Name of Integration Metadata Record, protocol - Specified the Http Action,
    * payload - request body, urlParameters - Map of URL parameters
    * @return - ActiveDaysResponseWrapper
    * @Description - Makes the callout and logs the response in ASF_Case_Integration__c
    *****************************************************************************************************************/ 
    @AuraEnabled
    public static ActiveDaysResponseWrapper getActiveDaysDashboard(String customerID,String accountId, String fromDate, String toDate){
        try{
            String integrationName = 'ABHI_ActivedaysDashboard';
            ActiveDaysResponseWrapper responseWrapper = new ActiveDaysResponseWrapper();
            Map <String,String> mapUrlParam = new Map <String,String>();
           	mapUrlParam= buildParametersMap(customerID,fromDate,toDate,integrationName);
            ABCL_IntegrationCallout.accountId=accountId;
            ABCL_IntegrationCallout.IntegrationResponseWrapper activeDaysResponseDashResp = ABCL_IntegrationCallout.executeCallout(integrationName, null, mapUrlParam);
            system.debug('responsewrap '+activeDaysResponseDashResp);            
            if (activeDaysResponseDashResp != null && activeDaysResponseDashResp.responseBody != null) {
                responseWrapper = (ActiveDaysResponseWrapper)JSON.deserialize(activeDaysResponseDashResp.responseBody, ActiveDaysResponseWrapper.class);
            }
            return responseWrapper; 
        }catch(exception e){
            throw new AuraHandledException('Error : '+e.getMessage()+' '+e.getLineNumber());
        }
    }

   public class ActiveDaysResponseWrapper {
    @AuraEnabled
    public String operationStatus;
    @AuraEnabled
    public List<ServiceMessage> serviceMessages;
    @AuraEnabled
    public ResponseMap responseMap;
    @AuraEnabled
    public Integer StatusCode;
    @AuraEnabled
    public String message;
}

    public class ResponseMap {
        @AuraEnabled
        public ResultsList resultsList;
    }

    public class ResultsList {
        @AuraEnabled
        public String transformedEntityId;
        @AuraEnabled
        public Double totalScoreForPeriod;
        @AuraEnabled
        public Double totalScoreForGym;
        @AuraEnabled
        public Double totalScoreForSteps;
        @AuraEnabled
        public Double totalScoreForCalories;
        @AuraEnabled
        public Double totalScoreForEvents;
        @AuraEnabled
        public List<Score> scores;
    }

    public class Score {
        @AuraEnabled
        public String activeDate;
        @AuraEnabled
        public String isScored;
        @AuraEnabled
        public List<Activity> activities;
    }

    public class Activity {
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String value;
        @AuraEnabled
        public Double score;
        @AuraEnabled
        public String eventDate;
    }

    public class ServiceMessage {
        @AuraEnabled
        public String systemCode;
        @AuraEnabled
        public String businessCode;
        @AuraEnabled
        public String businessDesc;
        @AuraEnabled
        public String serviceMessageType;
        @AuraEnabled
        public String messageTime;
    }
    // Method to fetch static parameters from custom metadata and combine with dynamic parameters
    public static Map<String, String> buildParametersMap(String customerId, String fromDate, String toDate,String customMetadata) {
        // Initialized the map for parameters
        Map<String, String> parametersMap = new Map<String, String>();
        
        // Fetching static parameters from custom metadata
        ABCL_Integrations__mdt urlParamRecord = [SELECT URL_Parameters__c  FROM ABCL_Integrations__mdt WHERE DeveloperName =: customMetadata LIMIT 1];
        String staticParameters = urlParamRecord.URL_Parameters__c ;
        
         // Replace placeholders with actual values
        String parametersString = staticParameters
            .replace('{customerId}', customerId != null ? EncodingUtil.urlEncode(customerId, 'UTF-8') : 'null')
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
        system.debug('asparametersMap '+parametersMap);
        return parametersMap;
    }
}