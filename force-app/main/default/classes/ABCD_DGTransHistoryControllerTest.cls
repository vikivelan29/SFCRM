@isTest
public class ABCD_DGTransHistoryControllerTest {
    
    @testSetup
    static void setupTestData() {
    }

    @isTest
    static void testGetTransactions_Success() {
        Test.startTest();
        
        
        String mockResponse = '{ "code": 200, "status": "Success", "message": "Transactions Retrieved", "dgTransactionInfo": { "dgTransactionDetails": [ { "transactionType": "BUY", "amount": 5001.00, "unit": 0.59, "transactionDate": "2024-12-14T00:00:00.000Z", "transactionStatus": "confirmed" } ] } }';

        
        Test.setMock(HttpCalloutMock.class, new MockIntegrationResponse(200, mockResponse));

        
        ABCD_DGTransactionHistoryController.TransactionHistoryResult result = ABCD_DGTransactionHistoryController.getTransactions(
            '9876543210', 'CUST123', 'test@example.com', Date.today().addMonths(-3), Date.today()
        );

        Test.stopTest();

        
        System.assert(result.isSuccess, 'Transaction retrieval should be successful');
        System.assertEquals(1, result.dgTransactionDetails.size(), 'One transaction should be retrieved');
        System.assertEquals('BUY', result.dgTransactionDetails[0].transactionType, 'Transaction type should be BUY');
        System.assertEquals(5001.00, result.dgTransactionDetails[0].amount, 'Amount should match');
    }

    @isTest
    static void testGetTransactions_Failure() {
        Test.startTest();

        
        String mockResponse = '{ "code": 400, "status": "Failed", "message": "Invalid request" }';

        Test.setMock(HttpCalloutMock.class, new MockIntegrationResponse(400, mockResponse));

        
        ABCD_DGTransactionHistoryController.TransactionHistoryResult result = ABCD_DGTransactionHistoryController.getTransactions(
            '9876543210', 'CUST123', 'test@example.com', Date.today().addMonths(-3), Date.today()
        );

        Test.stopTest();

        System.assert(!result.isSuccess, 'Transaction retrieval should fail');
        System.assertEquals(0, result.dgTransactionDetails.size(), 'No transactions should be retrieved');
        System.assertEquals('Invalid response from the external service', result.errorMessage, 'Error message should match API response');
    }

    
    // Mock class to simulate API responses
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