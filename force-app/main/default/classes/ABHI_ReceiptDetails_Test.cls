/***************************************
*Class        :  ABHI_ReceiptDetails_Test
*Author       :  Kuldeep Mishra
*Created Date :  09/09/2024
*Last Modified:  09/09/2024
*@description :  This class used as Test class for ABHI_ReceiptDetails.
***************************************/
@isTest
public with sharing class ABHI_ReceiptDetails_Test {
    
    @isTest
    static void testGetReceiptDetails() {
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
        Test.startTest();
        ABHI_ReceiptDetails.IntegrationResponseWrapper response = ABHI_ReceiptDetails.GetReceiptDetails(testAsset.Id);
        Test.stopTest();

        //Assert the response
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(1, response.ResponseObj.size(), 'ResponseObj size should be 1');
        System.assertEquals(1, response.ResponseObj[0].Code, 'Response Code should be 01');
        System.assertEquals('Success', response.ResponseObj[0].Message, 'Response Message should be "Success"');
        System.assertNotEquals(null, response.Response, 'Response should not be null');
    }
     @isTest
    static void testResponseObjWrapperConstructor() {
        // Testing the constructor of ResponseObjWrapper directly
        ABHI_ReceiptDetails.ResponseObjWrapper responseObj = new ABHI_ReceiptDetails.ResponseObjWrapper(01, 'Test Message');
        System.assertNotEquals(null, responseObj, 'ResponseObjWrapper should be instantiated');
        System.assertEquals(01, responseObj.Code, 'Code should be 1');
        System.assertEquals('Test Message', responseObj.Message, 'Message should be "Test Message"');
    }
      
    
     /*************
     @Class -     : ABCL_IntegrationCalloutMockSuccess
     @description : Mock class for the integration Success callout and returns http response.
     **************/
    private class ABCL_IntegrationCalloutMockSuccess implements HttpCalloutMock {
            /***********
            * @Description  HTTP response mocking
            * @ Set all param req 
            ** @return HTTPResponse
            ************/
        public HTTPResponse respond(HTTPRequest req) {
            // Create a mock response
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            res.setStatus('OK');
            // Mock response body
            String jsonResponse = '{"ResponseObj":[{"Code":1,"Message":"Success"}],"Response":[{"ReceiptNumber":"REC123","ReceiptDate":"2024-09-23","PayerName":"John Doe","CollectionMode":"Online","InstrumentNumber":"INST123","InstrumentDate":"2024-09-22","Status":"Completed","ReceiptAmount":"100.00"}]}';
            res.setBody(jsonResponse);
            return res;
        }
    }
}