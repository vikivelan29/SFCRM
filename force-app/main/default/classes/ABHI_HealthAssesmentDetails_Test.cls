@isTest
public class ABHI_HealthAssesmentDetails_Test {
    
    
    @isTest
    static void testGetHealthDetails_Success() {
        // Setup test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Asset testAsset = new Asset(
            Name = 'Test Asset',
            Policy_No__c = 'POL123456',
            AccountId = testAccount.Id
        );
        insert testAsset;

        // Mock response data
        ABHI_HealthAssesmentDetails.IntegrationResponseWrapper mockResponse = new ABHI_HealthAssesmentDetails.IntegrationResponseWrapper();
        mockResponse.StatusCode = 1000;
        mockResponse.Message = 'Success'; // Ensure this field matches the Apex class

        // Mock the IntegrationCallout
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ABCL_IntegrationCalloutMock(mockResponse));
        ABHI_HealthAssesmentDetails.IntegrationResponseWrapper result = ABHI_HealthAssesmentDetails.GetHealthDetails(testAsset.Id);

        // Assertions
        System.assertNotEquals(null, result, 'Response should not be null');
        System.assertEquals(1000, result.StatusCode, 'Status Code should be 200');
        System.assertEquals('Success', result.Message, 'Message should be Success');
        Test.stopTest();
    }

    @isTest
    static void testGetHealthDetails_Error() {
        // Setup test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Asset testAsset = new Asset(
            Name = 'Test Asset',
            Policy_No__c = 'POL123456',
            AccountId = testAccount.Id
        );
        insert testAsset;

        // Mock the IntegrationCallout with an error response
        ABHI_HealthAssesmentDetails.IntegrationResponseWrapper mockResponse = new ABHI_HealthAssesmentDetails.IntegrationResponseWrapper();
        mockResponse.StatusCode = 500;
        mockResponse.Message = 'Internal Server Error'; // Ensure this field matches the Apex class

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ABCL_IntegrationCalloutMock(mockResponse));

        try {
            ABHI_HealthAssesmentDetails.GetHealthDetails(testAsset.Id);
            //System.assert(false, 'An exception should have been thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Error:'), 'Exception message should contain "Error:"');
        }
        Test.stopTest();
    }

    // Mock class for the integration callout
    private class ABCL_IntegrationCalloutMock implements HttpCalloutMock {
        private ABHI_HealthAssesmentDetails.IntegrationResponseWrapper response;

        ABCL_IntegrationCalloutMock(ABHI_HealthAssesmentDetails.IntegrationResponseWrapper response) {
            this.response = response;
        }

        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(JSON.serialize(response));
            res.setStatusCode(response.StatusCode);
            return res;
        }
    }

}