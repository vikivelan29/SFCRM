@isTest
public class ABHI_ViewPrintandDispatchDetails_Test {
    @isTest
    static void testGetViewPrintDetails() {
        // Set up test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Asset testAsset = new Asset(
            Name = 'Test Asset',
            AccountId = testAccount.Id,
            Policy_No__c = 'POLICY123'
        );
        insert testAsset;

        // Mock the IntegrationCallout
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ABCL_IntegrationCalloutMock());
        
        ABHI_ViewPrintandDispatchDetails.IntegrationResponseWrapper response = ABHI_ViewPrintandDispatchDetails.GetViewPrintDetails(testAsset.Id);
        System.debug('Response: ' + response);
        
        // Assert the expected results
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals('200', response.response.responseCode, 'Response code should be 200');
        System.assertEquals('Result fetched successfully.', response.response.responseMessage, 'Response message mismatch');
        
        // Validate vendorPrintDispatchDetails responseBody
        System.assertNotEquals(null, response.vendorPrintDispatchDetails, 'VendorPrintDispatchDetails should not be null');
        System.assertEquals(null, response.vendorPrintDispatchDetails.flag, 'Flag mismatch');
        System.assertEquals('7200', response.vendorPrintDispatchDetails.productCode, 'Product code mismatch');
        Test.stopTest();
    }
    
    // Mock class for the integration callout
    private class ABCL_IntegrationCalloutMock implements HttpCalloutMock {
        // Create a mock HTTP response
        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200); // Simulating a successful HTTP response
            
            // Serialize the mock response
            String jsonResponse = '{"vendorPrintDispatchDetails":{"flag":null,"productCode":"7200 ","basicdetailAttribute":[{"name": "Go Green","value": "No","multisetAttribute": null}]},"response": {"responseCode": "200","responseMessage": "Result fetched successfully.","messages": null}}';
            res.setBody(jsonResponse);
            
            return res;
        }
    }
}