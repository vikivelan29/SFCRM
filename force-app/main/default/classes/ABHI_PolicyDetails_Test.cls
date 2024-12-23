/***************************************
*Class        :  ABHI_PolicyDetails_Test
*Author       :  Kuldeep Mishra
*Created Date :  09/09/2024
*Last Modified:  09/09/2024
*@description :  This class used as Test class for ABHI_PolicyDetails.
***************************************/
@isTest
public with sharing class ABHI_PolicyDetails_Test {
    
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
        Test.startTest();
        ABHI_PolicyDetails.IntegrationResponseWrapper response = ABHI_PolicyDetails.GetPolicyDetails(testAsset.Id);
        Test.stoptest();

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
        ABHI_PolicyDetails.ResponseObjWrapper responseObj = new ABHI_PolicyDetails.ResponseObjWrapper(01, 'Test Message');
        System.assertNotEquals(null, responseObj, 'ResponseObjWrapper should be instantiated');
        System.assertEquals(1, responseObj.Code, 'Code should be 1');
        System.assertEquals('Test Message', responseObj.Message, 'Message should be "Test Message"');
    }
      
     /*******************
     @Class -     : ABCL_IntegrationCalloutMockSuccess
     @description : Mock class for the integration Success callout and returns http response.
     ********************/
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
            String jsonResponse = '{"ResponseObj":[{"Code":1,"Message":"Success"}],"Response":[{"vchPolicyNumber":"GHI-AX-22-2000742","vchStatus":"IF","BranchName":"10MHMUM01","PolicyType":"Family Floater","BusinessType":"Renewal","ChronicType":"NO","PolicyOwnerID":"0005423679034","PolicyOwnerName":"Nitush Das","NoofMembers":"3","ProposalNumber":"8100079988/00742","ProposalIssueDate":"08/09/2022","ProposalType":"RUG","Product":"5211","Scheme":" ","Suminssured":"500000","PolicyStartDate":"08/09/2022","dtPolicyEndDate":"07/09/2023","PolicyTenure":"1","PolicyVarian":"Family Floater","FamilyType":"FLOATER",\"NextPremiumDate\":\"07/09/2023\",\"PolicySource\":\"\",\"PolicyZone\":\"Zone - III\",\"ServicingBranchName\":\"10MHMUM01\",\"PolicyTPA\":\"\",\"PolicyCancelRemark\":\"\",\"CounterOfferReason\":\"\",\"BasicPremium\":\"\",\"NetPremium\":\"12119.49\"}]}';
            res.setBody(jsonResponse);
            return res;
        }
    }
}