public with sharing class ABHI_ActiveDayEventsController {
     /****************************************************************************************************************
    * @LOB - ABHIL
    * @Function - getActiveDaysDashboard
    * @param customerID - Name of Integration Metadata Record, protocol - Specified the Http Action,
    * payload - request body, urlParameters - Map of URL parameters
    * @return - ActiveDaysResponseWrapper
    * @Description - Makes the callout and logs the response in ASF_Case_Integration__c
    *****************************************************************************************************************/ 
    @AuraEnabled
    public static ActiveDaysEventsResponseWrapper getActiveDayEventsDetail(String customerID,String accountId){
        try{
            ActiveDaysEventsResponseWrapper responseWrapper = new ActiveDaysEventsResponseWrapper();
            String integrationName = 'ABHI_ActivedayEvents';
            Map <String,String> mapUrlParam = new Map <String,String>();
           	mapUrlParam= ABHI_ActiveDaysDashboardController.buildParametersMap(customerID,null,null,integrationName);
            ABCL_IntegrationCallout.accountId=accountId;
            ABCL_IntegrationCallout.IntegrationResponseWrapper activeDayEventsResp = ABCL_IntegrationCallout.executeCallout(integrationName, null, mapUrlParam);
            system.debug('responsewrap '+activeDayEventsResp);            
            if (activeDayEventsResp != null && activeDayEventsResp.responseBody != null) {
                responseWrapper = (ActiveDaysEventsResponseWrapper)JSON.deserialize(activeDayEventsResp.responseBody, ActiveDaysEventsResponseWrapper.class);
            }
            return responseWrapper; 
        }catch(exception e){
            throw new AuraHandledException('Error : '+e.getMessage()+' '+e.getLineNumber());
        }
    }

    public class ActiveDaysEventsResponseWrapper {
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

    public class ResponseMap {
        @AuraEnabled
        public ResultsList resultsList;
    }

    public class ResultsList {
        @AuraEnabled
        public List<AssessmentDetail> assessmentDetails;
    }

    public class AssessmentDetail {
        @AuraEnabled
        public Decimal avgCal;
        @AuraEnabled
        public Decimal avgSteps;
        @AuraEnabled
        public Decimal avgGymVisits;
        @AuraEnabled
        public Decimal totalCal;
        @AuraEnabled
        public Decimal totalSteps;
        @AuraEnabled
        public Decimal totalGymVisits;
        @AuraEnabled
        public Decimal totalActiveDayz;
        @AuraEnabled
        public String isActiveToday;
        @AuraEnabled
        public Decimal totalADForPolicyDates;
    }
}