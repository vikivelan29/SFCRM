/*********************************************************
*Class        :  ABHI_CreateHealthIntent_Inbound_Test
*Author       :  Shubham Sinha
*Created Date :  12/10/2024
*Last Modified:  12/10/2024
*@description  : Test class for ABHI_CreateHealthIntent_Inbound
***********************************************************/ 
@isTest
public class ABHI_CreateHealthIntent_Inbound_Test {

    private static Account createTestAccount(String clientCode) {
        Account acc = new Account(Name = 'Test Account', Client_Code__c = clientCode);
        insert acc;
        return acc;
    }

    private static ABHI_CreateHealthIntent_Inbound.RequestBody createRequestBody(String memberId) {
        ABHI_CreateHealthIntent_Inbound.RequestBody requestBody = new ABHI_CreateHealthIntent_Inbound.RequestBody();
        requestBody.MemberId = memberId;
        requestBody.ActiveOnSocialMedia = 'true';
        requestBody.HealthReturn = 'Health Return';
        requestBody.PreferredCommunicationMode = 'Email';
        requestBody.PreferredLanguage = 'English';
        requestBody.SocialMediaId = 'SocialMediaID';
        requestBody.Source = 'App';
        requestBody.WaitingPeriodAndExclusive = 'No Waiting Period';
        requestBody.WhichPhone = 'Android';
        
        ABHI_CreateHealthIntent_Inbound.CategoryDetail categoryDetail = new ABHI_CreateHealthIntent_Inbound.CategoryDetail();
        categoryDetail.Category = 'Fitness';
        
        ABHI_CreateHealthIntent_Inbound.ActivityDetail activityDetail = new ABHI_CreateHealthIntent_Inbound.ActivityDetail();
        activityDetail.DoYouTrackThese = 'true';
        activityDetail.FrequencyInMonth = '4';
        activityDetail.HowDoYouTrackYourActivity = 'App';
        activityDetail.WhatActivitiesCurrentlyDoing = 'Running';
        
        categoryDetail.ActivityDetails = new List<ABHI_CreateHealthIntent_Inbound.ActivityDetail>{activityDetail};
        
        requestBody.CategoryDetails = new List<ABHI_CreateHealthIntent_Inbound.CategoryDetail>{categoryDetail};
        
        return requestBody;
    }

    @isTest
    public static void testProcessHealthData_Success() {
        Account testAccount = createTestAccount('12345');
        
        ABHI_CreateHealthIntent_Inbound.RequestBody requestBody = createRequestBody('12345');
        String requestBodyJson = JSON.serialize(requestBody);
        
        Test.startTest();
        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(requestBodyJson);
     
        String response = ABHI_CreateHealthIntent_Inbound.processHealthData();
        Test.stopTest();
        
        ABHI_ResponseWrapper responseWrapper = (ABHI_ResponseWrapper)JSON.deserialize(response, ABHI_ResponseWrapper.class);
        System.assertEquals('200', responseWrapper.StatusCode);
        System.assertEquals('Success', responseWrapper.StatusMessage);
    }

    @isTest
    public static void testProcessHealthData_MemberNotFound() {
        // Create mock data for the request with non-existing MemberId
        ABHI_CreateHealthIntent_Inbound.RequestBody requestBody = createRequestBody('99999');
        String requestBodyJson = JSON.serialize(requestBody);
        
        // Mock the RestContext to simulate HTTP request
        Test.startTest();
        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(requestBodyJson);
        
        // Test the method
        String response = ABHI_CreateHealthIntent_Inbound.processHealthData();
        Test.stopTest();
        try{
            ABHI_ResponseWrapper responseWrapper = (ABHI_ResponseWrapper)JSON.deserialize(response, ABHI_ResponseWrapper.class);
            System.assertEquals('100', responseWrapper.StatusCode);
            System.assertEquals('Failure', responseWrapper.StatusMessage);
        }catch(exception e){}
    }

    @isTest
    public static void testProcessHealthData_DMLException() {
        Account testAccount = createTestAccount('12345');
        
        ABHI_CreateHealthIntent_Inbound.RequestBody requestBody = createRequestBody('12345');
        String requestBodyJson = JSON.serialize(requestBody);
        
        Test.startTest();
        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(requestBodyJson);
        
        String response = ABHI_CreateHealthIntent_Inbound.processHealthData();
        Test.stopTest();
        try{
            ABHI_ResponseWrapper responseWrapper = (ABHI_ResponseWrapper)JSON.deserialize(response, ABHI_ResponseWrapper.class);
            System.assertEquals('Success', responseWrapper.StatusMessage);
        }catch(exception e){}
    }

    @isTest
    public static void testProcessHealthData_InvalidJson() {
        String invalidJson = '{ "MemberId": "12345", "ActiveOnSocialMedia": true, "CategoryDetails": [ }';  // Malformed JSON
        
        Test.startTest();
        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(invalidJson);
        
        String response = ABHI_CreateHealthIntent_Inbound.processHealthData();
        Test.stopTest();
        
        ABHI_ResponseWrapper responseWrapper = (ABHI_ResponseWrapper)JSON.deserialize(response, ABHI_ResponseWrapper.class);
        System.assertEquals('100', responseWrapper.StatusCode);
        System.assertEquals('Failure', responseWrapper.StatusMessage);
        System.assert(responseWrapper.StatusRemarks.contains('Invalid JSON'));
    }
    
    class ABCL_IntegrationCalloutMock implements HttpCalloutMock {
        Boolean throwDmlException = false;
        
        public ABCL_IntegrationCalloutMock(Boolean throwDmlException) {
            this.throwDmlException = throwDmlException;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            res.setBody('{"StatusCode":"200","StatusMessage":"Success"}');
            return res;
        }
    }
}