@isTest
public class ABCD_GetAccHoldingsControllerTest {
    
    @testSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Account', Client_Code__c = 'CUST12345');
        insert testAccount;
        
        Case testCase = new Case(AccountId = testAccount.Id, Status = 'Open', Subject = 'Test Case');
        insert testCase;
    }

    @isTest
    static void testGetAccountHoldings_Success() {
        Test.startTest();
        
        String mockResponse = '{ "code": 200, "status": "Success", "message": "Holdings Retrieved", "holdingIdsInfo": { "LOB": "Equity", "holdingIDs": ["HOLD123", "HOLD456"] } }';

        Test.setMock(HttpCalloutMock.class, new MockIntegrationResponse(200, mockResponse));

        ABCD_GetAccountHoldingsController.GetAccountHoldingsResult result = ABCD_GetAccountHoldingsController.getAccountHoldings('CUST12345', 'Equity');

        Test.stopTest();

        System.assert(result.isSuccess, 'Holding retrieval should be successful');
        System.assertEquals(2, result.holdingIDs.size(), 'Two holdings should be retrieved');
        System.assertEquals('HOLD123', result.holdingIDs[0], 'First holding ID should match');
    }

    @isTest
    static void testGetAccountHoldings_Failure() {
        Test.startTest();

        String mockResponse = '{ "code": 400, "status": "Failed", "message": "Invalid customer ID" }';

        Test.setMock(HttpCalloutMock.class, new MockIntegrationResponse(400, mockResponse));

        ABCD_GetAccountHoldingsController.GetAccountHoldingsResult result = ABCD_GetAccountHoldingsController.getAccountHoldings('INVALID_CUST', 'Equity');

        Test.stopTest();

        System.assert(!result.isSuccess, 'Holding retrieval should fail');
        System.assertEquals(0, result.holdingIDs.size(), 'No holdings should be retrieved');
        System.assertEquals('Invalid response from the external service', result.errorMessage, 'Error message should match API response');
    }

    
    @isTest
    static void testGetClientCode() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();
        String clientCode = ABCD_GetAccountHoldingsController.getClientCode(testCase.Id);
        Test.stopTest();

        System.assertEquals('CUST12345', clientCode, 'Client code should match the test Account record');
    }

    private class MockIntegrationResponse implements HttpCalloutMock {
        Integer statusCode;
        String responseBody;

        public MockIntegrationResponse(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(statusCode);
            if (responseBody != null) {
                res.setBody(responseBody);
            }
            return res;
        }
    }
}