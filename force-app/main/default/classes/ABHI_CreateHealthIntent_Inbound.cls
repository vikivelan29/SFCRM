/*********************************************************
*Class        :  ABHI_CreateHealthIntent_Inbound
*Author       :  Shubham Sinha 
*Created Date :  07/08/2024
*Last Modified:  07/08/2024
*@description  :  This webservice is to create health intent records in SFDC.
*********************************************************/
@RestResource(urlMapping='/CreateHealthIntent/*')
global with sharing class ABHI_CreateHealthIntent_Inbound {
    @HttpPost
    global static String processHealthData() {
        ABHI_CreateHealthIntentRequestWrapper.RequestBody requestBody;
        String accountId;
        Boolean hasError = false;
        ABCL_IntegrationCallout.IntegrationResponseWrapper integrationResponse = new ABCL_IntegrationCallout.IntegrationResponseWrapper();
        ABCL_Integrations__mdt integrationMdt = ABCL_IntegrationCallout.getIntegrationMetadata('ABHI_CreateHealthIntent_Inbound');
        integrationResponse.requestBody = RestContext.request.requestBody.toString();

        try {
            // Parsing the JSON request into the RequestBody class
            requestBody = (ABHI_CreateHealthIntentRequestWrapper.RequestBody)JSON.deserialize(RestContext.request.requestBody.toString(), ABHI_CreateHealthIntentRequestWrapper.RequestBody.class);
            
            // Checking for member id 
            try {
                accountId = [SELECT Id, Client_Code__c FROM Account WHERE Client_Code__c = :requestBody.MemberId].Id;
                ABCL_IntegrationCallout.accountId = accountId;
            } catch (Exception e) {
                integrationResponse.responseBody = JSON.serialize(createFailureResponse('100', 'Failure', Custom_Messages__mdt.getInstance('ABHI_MemberID_Not_Found').Message__c));
                hasError = true;
                return integrationResponse.responseBody; 
            }

            // Preparing to collect Health intent records
            List<Health_Intent__c> lsthealthIntent = new List<Health_Intent__c>();
            for (ABHI_CreateHealthIntentRequestWrapper.CategoryDetail category : requestBody.CategoryDetails) {
                for (ABHI_CreateHealthIntentRequestWrapper.ActivityDetail detail : category.ActivityDetails) {
                    Health_Intent__c healthIntentRecord = new Health_Intent__c();
                    healthIntentRecord.Member_Id__c = accountId;
                    healthIntentRecord.Active_on_Social_Media__c = requestBody.ActiveOnSocialMedia;
                    healthIntentRecord.Health_Return__c = requestBody.HealthReturn;
                    healthIntentRecord.Preferred_Communication_Mode__c = requestBody.PreferredCommunicationMode;
                    healthIntentRecord.Preferred_Language__c = requestBody.PreferredLanguage;
                    healthIntentRecord.Social_Media_Id__c = requestBody.SocialMediaId;
                    healthIntentRecord.Source__c = requestBody.Source;
                    healthIntentRecord.Waiting_Period_Permanent_Exclusion__c = requestBody.WaitingPeriodAndExclusive;
                    healthIntentRecord.Which_phone_are_you_using__c = requestBody.WhichPhone;
                    healthIntentRecord.Category__c = category.Category;
                    healthIntentRecord.Do_you_track_these__c = detail.DoYouTrackThese;
                    healthIntentRecord.Frequency_in_a_month__c = detail.FrequencyInMonth;
                    healthIntentRecord.How_do_you_track_your_activity__c = detail.HowDoYouTrackYourActivity;
                    healthIntentRecord.What_activities_are_you_currently_doing__c = detail.WhatActivitiesCurrentlyDoing;
                    lsthealthIntent.add(healthIntentRecord);
                }
            }

            // Inserting the HealthIntent records
            try {
                if (!lsthealthIntent.isEmpty()) {
                    insert lsthealthIntent;
                }
                integrationResponse.responseBody = JSON.serialize(createSuccessResponse(requestBody.MemberId));
            } catch (DmlException e) {
                integrationResponse.responseBody = JSON.serialize(createFailureResponse('100', 'Failure', 'Error in creating healthintent records: ' + e.getMessage()));
                hasError = true;
            }

        } catch (Exception e) {
            integrationResponse.responseBody = JSON.serialize(createFailureResponse('100', 'Failure', Custom_Messages__mdt.getInstance('ABHI_InvalidJson').Message__c));
            hasError = true;
        } finally {
            // Handling response in a single place
            ABCL_IntegrationCallout.handleResponse(integrationMdt, integrationResponse, hasError);
        }

        return integrationResponse.responseBody;
    }

   
    public static ABHI_ResponseWrapper createSuccessResponse(String memberId) {
        ABHI_ResponseWrapper response = new ABHI_ResponseWrapper(
            '200',
            'Success',
            Custom_Messages__mdt.getInstance('ABHI_SuccessMessage').Message__c
        );
        //response.ProposalNumber = memberId; // Assuming you want to assign the memberId to ProposalNumber
        return response;
    }

    public static ABHI_ResponseWrapper createFailureResponse(String statusCode, String statusMessage, String statusRemarks) {
        return new ABHI_ResponseWrapper(statusCode, statusMessage, statusRemarks);
    }
}