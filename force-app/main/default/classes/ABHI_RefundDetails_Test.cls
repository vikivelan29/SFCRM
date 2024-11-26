/***************************************
*Class        :  ABHI_RefundDetails_Test
*Author       :  Kuldeep Mishra
*Created Date :  09/09/2024
*Last Modified:  09/09/2024
*@description :  This class used as Test class for ABHI_RefundDetails.
***************************************/
@isTest
public class ABHI_RefundDetails_Test {
    @isTest
    static void testGetRefundDetails() {
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
        ABHI_RefundDetails.IntegrationResponseWrapper response = ABHI_RefundDetails.GetRefunds(testAsset.Id);
        Test.stopTest();

        //Assert the response
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(01, response.ResponseObj.Code, 'Response Code should be 200');
        System.assertEquals('SUCCESS', response.ResponseObj.Message, 'Response Message should be "SUCCESS"');
        System.assertNotEquals('123', response.ReceiptObj[0].RefundDetails[0].RefundNumber, 'RefundNumber available ');
        System.assertNotEquals(null, response.ReceiptObj[0].RefundDetails[0].BeneficiaryName, 'BeneficiaryName available');
    }
    
     @isTest
    static void testResponseObjWrapperConstructor() {
        // Testing the constructor of ResponseObjWrapper directly
        ABHI_RefundDetails.ResponseObjWrapper responseObj = new ABHI_RefundDetails.ResponseObjWrapper(01, 'Test Message');
        System.assertNotEquals(null, responseObj, 'ResponseObjWrapper should be instantiated');
        //System.assertEquals(01, responseObj.Code, 'Code should be 1');
       
    }

    /*********************
     @Class -     : ABCL_IntegrationCalloutMockSuccess
     @description : Mock class for the integration Success callout and returns http response.
     *********************/
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
            String jsonResponse = '{"ResponseObj": {"Code": "01","Message": "SUCCESS"},"ReceiptObj": [{"ReceiptNumber": "SR-21-22-697832","RefundDetails": [{"RefundNumber": "SR-21-22-697832","RefundType": "","PaymentDate": "08-08-2023","PaymentRefNo": "","Status": "","RefundTo": "","PaymentMode": "","BeneficiaryName": "TUSHAR", "RefundAmount": "0","ProposerMobile": "6789805137","ProposerEmail": "rrhcahdsh@gmail.com", "BankName": "","AccountNumber": "","Collection_mode": "","premium_for_optional_cover": "","registration_status": "PEN","auto_debit_flag": "N","IVRStatus": "refund processed" }]}]}';
            system.debug('Response body---' +jsonResponse);
            res.setBody(jsonResponse);
            return res;
        }
    }
    

}