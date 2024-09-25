@isTest
public class ABHI_PolicyDetails_Test {
    
    @isTest
    static void testGetPolicyDetails() {
        //Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Asset testAsset = new Asset(
            Name = 'Asset Name',
            Policy_No__c = 'POL123456',
            SerialNumber = 'SER123456',
            AccountId = testAccount.Id
        );
        insert testAsset;

        //Set up mock for the integration callout
        Test.setMock(HttpCalloutMock.class, new ABCL_IntegrationCalloutMockSuccess());

        //Call the method to test
        ABHI_PolicyDetails.IntegrationResponseWrapper response = ABHI_PolicyDetails.GetPolicyDetails(testAsset.Id);

        //Assert the response
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(1, response.ResponseObj.size(), 'ResponseObj size should be 1');
        System.assertEquals(01, response.ResponseObj[0].Code, 'Response Code should be 200');
        System.assertEquals('Success', response.ResponseObj[0].Message, 'Response Message should be "Success"');
        System.assertNotEquals(null, response.Response, 'Response should not be null');
    }
    
    @isTest
    static void testResponseObjWrapperConstructor() {
        // Testing the constructor of ResponseObjWrapper directly
        ABHI_PolicyDetails.ResponseObjWrapper responseObj = new ABHI_PolicyDetails.ResponseObjWrapper(01, 'Test Message');
        System.assertNotEquals(null, responseObj, 'ResponseObjWrapper should be instantiated');
        System.assertEquals(01, responseObj.Code, 'Code should be 1');
        System.assertEquals('Test Message', responseObj.Message, 'Message should be "Test Message"');
    }
      
    
    // Mock class for the integration callout
    private class ABCL_IntegrationCalloutMockSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a mock response
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            res.setStatus('OK');
            
            // Mock response body
            String jsonResponse = '{"ResponseObj":[{"Code":01,"Message":"Success"}],"Response":[{"ReceiptNumber":"REC123","ReceiptDate":"2024-09-23","PayerName":"John Doe","CollectionMode":"Online","InstrumentNumber":"INST123","InstrumentDate":"2024-09-22","Status":"Completed","ReceiptAmount":"100.00"}]}';
            res.setBody(jsonResponse);
            return res;
        }
    }
}