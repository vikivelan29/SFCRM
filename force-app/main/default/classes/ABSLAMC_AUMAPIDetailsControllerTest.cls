@IsTest
public class ABSLAMC_AUMAPIDetailsControllerTest {
    @IsTest
    static void testFetchAUMDetails_BlankAccId() {
        // Test when accId is blank
        ABSLAMC_AUMAPIDetailsController.ReturnWrapper result = ABSLAMC_AUMAPIDetailsController.fetchAUMDetails('');
        System.assertEquals(false, result.isSuccess, 'The method should fail when accId is blank.');
        System.assertEquals('Case Id cannot be null or blank.', result.errorMessage, 'The error message should indicate a blank case ID.');
    }

    @IsTest
    static void testFetchAUMDetails_NoPAN() {
        // Create an account without PAN
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        ABSLAMC_AUMAPIDetailsController.ReturnWrapper result = ABSLAMC_AUMAPIDetailsController.fetchAUMDetails(acc.Id);
        System.assertEquals(false, result.isSuccess, 'The method should fail when no PAN is found.');
        System.assertEquals('PAN details not found for the specified case.', result.errorMessage, 'The error message should indicate missing PAN.');
    }

    @IsTest
    static void testFetchAUMDetails_APISuccess() {
        // Create an account with PAN
        Account acc = new Account(Name = 'Test Account', PAN__c = 'ABCDE1234F');
        insert acc;

        // Mock the API callout for success
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockIntegrationCallout());

        ABSLAMC_AUMAPIDetailsController.ReturnWrapper result = ABSLAMC_AUMAPIDetailsController.fetchAUMDetails(acc.Id);
        Test.stopTest();

        System.assertEquals(true, result.isSuccess, 'The method should succeed when the API call succeeds.');
       // System.assertNotNull(result.responseBody, 'The response body should not be null.');
        //System.assert(result.responseBody.contains('"response_key":"response_value"'), 'The response body should match the mocked API response.');
    }

    @IsTest
    static void testFetchAUMDetails_APIFailure() {
        // Create an account with PAN
        Account acc = new Account(Name = 'Test Account', PAN__c = 'ABCDE1234F');
        insert acc;

        // Mock the API callout for failure
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockIntegrationCalloutError());

        ABSLAMC_AUMAPIDetailsController.ReturnWrapper result = ABSLAMC_AUMAPIDetailsController.fetchAUMDetails(acc.Id);
        Test.stopTest();

        System.assertEquals(false, result.isSuccess, 'The method should fail when the API call fails.');
        System.assertEquals('{"ReturnCode": "0", "ReturnMessage": "Error retrieving record."}', result.errorMessage, 'The error message should match the mocked API error response.');
    }

    // Mock integration classes for success and error scenarios
    private class MockIntegrationCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String jsonString = '{"statusCode":200,"responseBody":"{\\"response_key\\":\\"response_value\\"}"}';
            res.setBody(jsonString);
            res.setStatusCode(200);
            return res;
        }
    }

    private class MockIntegrationCalloutError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(400);
            res.setBody('{"ReturnCode": "0", "ReturnMessage": "Error retrieving record."}');
            return res;
        }
    }
}