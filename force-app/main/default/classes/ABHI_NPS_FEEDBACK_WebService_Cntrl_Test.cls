/*********************************************************
*Class        :  ABHI_NPS_FEEDBACK_WebService_Cntrl_Test
*Author       :  Anirudh Raturi
*Created Date :  29/08/2024
*@description  :  Test Class for NPS ABHI_NPS_FEEDBACK_WebService_Controller 
*********************************************************/

@IsTest
private class ABHI_NPS_FEEDBACK_WebService_Cntrl_Test {

    @TestSetup
    static void setupTestData() {
        // Create custom metadata records
        Account acct = new Account(
            Name = 'Test Account 1',
            LOB_Client_Code__c = '1118038'
        );
        insert acct;
    }
    @IsTest
    static void testCreateSurveyResponse() {

        ABHI_NPS_FEEDBACK_WebService_Controller.NPS_FEEDBACK_REQUEST_WRAPPER reqWrapper = new ABHI_NPS_FEEDBACK_WebService_Controller.NPS_FEEDBACK_REQUEST_WRAPPER();
        reqWrapper.comment = 'This is a test comment';
        reqWrapper.project_name = 'Test Project';
        reqWrapper.utmMedium = 'Test Medium';
        reqWrapper.responded_date = '2023-01-01 00:00:00';
        reqWrapper.tag_private_customer_id = '1118038';
        reqWrapper.tag_claim_status = 'repudiation';
        reqWrapper.primary_rating = '10';
        reqWrapper.ratings = new List<ABHI_NPS_FEEDBACK_WebService_Controller.ratings>();

        ABHI_NPS_FEEDBACK_WebService_Controller.ratings rating = new ABHI_NPS_FEEDBACK_WebService_Controller.ratings();
        rating.field_id = 'primary_rating';
        rating.seq_no = 2;
        rating.actual_rating = 8;
        rating.rating = '8';
        reqWrapper.ratings.add(rating);
        reqWrapper.feed_id = '61383b283539e3cd46886391';

        String requestBody = JSON.serialize(reqWrapper);
        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        // Call the web service method
        Test.startTest();
        ABHI_NPS_FEEDBACK_WebService_Controller.NPS_FEEDBACK_RESPONSE_WRAPPER response = ABHI_NPS_FEEDBACK_WebService_Controller.createSurveyResponse();
        Test.stopTest();

        System.assertEquals('1000', response.StatusCode, '1000');

        Survey_Response__c surveyResponse = [SELECT Id, Customer_Comments__c, Primary_Question_NPS__c FROM Survey_Response__c LIMIT 1];
        System.assertEquals(8, surveyResponse.Primary_Question_NPS__c, '8');
    }

    @IsTest
    static void testCreateSurveyResponseInvalidJson() {

        String invalidJson = '{"invalidField": "Invalid data"}';
        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(invalidJson);

        // Call the web service method
        Test.startTest();
        ABHI_NPS_FEEDBACK_WebService_Controller.NPS_FEEDBACK_RESPONSE_WRAPPER response = ABHI_NPS_FEEDBACK_WebService_Controller.createSurveyResponse();
        Test.stopTest();

        // Assert error response
        System.assertEquals('1001', response.StatusCode, '1001');
    }

    @IsTest
    static void testLogicToPopulateRating() {

        ABHI_NPS_FEEDBACK_WebService_Controller.NPS_FEEDBACK_REQUEST_WRAPPER reqWrapper = new ABHI_NPS_FEEDBACK_WebService_Controller.NPS_FEEDBACK_REQUEST_WRAPPER();
        reqWrapper.tag_claim_status = 'repudiation';
        reqWrapper.tag_earner_type = 'non-earner';
        reqWrapper.ratings = new List<ABHI_NPS_FEEDBACK_WebService_Controller.ratings>();

        ABHI_NPS_FEEDBACK_WebService_Controller.ratings rating1 = new ABHI_NPS_FEEDBACK_WebService_Controller.ratings();
        rating1.field_id = 'primary_rating';
        rating1.actual_rating = 9;
        reqWrapper.ratings.add(rating1);

        ABHI_NPS_FEEDBACK_WebService_Controller.ratings rating2 = new ABHI_NPS_FEEDBACK_WebService_Controller.ratings();
        rating2.question = 'L1 Drivers';
        rating2.actual_rating = 7;
        reqWrapper.ratings.add(rating2);

        // Call the method
        Test.startTest();
        Map<String, Integer> ratingsMap = new ABHI_NPS_FEEDBACK_WebService_Controller().logicToPopulateRating(reqWrapper);
        Test.stopTest();

        System.assertEquals(9, ratingsMap.get('actualRating'), '9');
    }
}