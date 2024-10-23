@IsTest
public class ABSLAMC_HoldingsByFolioControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Insert test Asset record
        Asset testAsset = new Asset(
            Name = 'Test Asset',
            LAN__c = '123456789',
            Business_Unit__c = ABSLAMC_Constants.ABSLAMCBU
        );
        insert testAsset;
    }
    
    // Mock for the callout response
    private class MockIntegrationCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"statusCode":200,"responseBody":"{\\"response_key\\":\\"response_value\\"}"}');
            return res;
        }
    }
    // Mock for error response
    private class MockErrorIntegrationCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"statusCode":400,"responseBody":"Error occurred"}');
            return res;
        }
    }
    
    @IsTest
    static void testGetSIPResponseSuccess() {
        // Mock callout
        Test.setMock(HttpCalloutMock.class, new MockIntegrationCallout());
        
        // Retrieve the test asset's ID
        Asset testAsset = [SELECT Id FROM Asset LIMIT 1];
        
        // Call the method
        ABSLAMC_HoldingsByFolioController.resultWrapper result = ABSLAMC_HoldingsByFolioController.getSIPResponse(testAsset.Id);
        
        // Assert the results
        System.assert(result != null, 'Expected result to be not null');
        System.assert(result.isSuccess, 'Expected success to be true');
    }
    
    @IsTest
    static void testGetHoldingsResponseSuccess() {
        // Mock callout
        Test.setMock(HttpCalloutMock.class, new MockIntegrationCallout());
        
        // Retrieve the test asset's ID
        Asset testAsset = [SELECT Id FROM Asset LIMIT 1];
        
        // Call the method
        ABSLAMC_HoldingsByFolioController.resultWrapper result = ABSLAMC_HoldingsByFolioController.getHoldingsResponse(testAsset.Id);
        
        // Assert the results
        System.assert(result != null, 'Expected result to be not null');
        System.assert(result.isSuccess, 'Expected success to be true');
    }   
}