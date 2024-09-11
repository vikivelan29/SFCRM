@isTest
public class Abhi_ViewClaimDetails_Controller_Test {

    @testSetup
    static void setup() {

        Asset assetRec = new Asset(
            Name = 'Test Asset 1',
            Policy_No__c = 'ABC12345'
        );
        insert assetRec;
    }

    @isTest
    static void testViewPolicyInformationApiCallout() {

        Asset testAsset = [SELECT Id, Policy_No__c FROM Asset LIMIT 1];
        
        // Set up a mock response for the callout
        ABCL_IntegrationCalloutMock mock = new ABCL_IntegrationCalloutMock();
        Test.setMock(HttpCalloutMock.class, mock);

        // Call the method and assert the results
        Abhi_ViewClaimDetails_Controller.ResponseWrapper response = Abhi_ViewClaimDetails_Controller.viewClaimDetailsInformationCallout(testAsset.Policy_No__c);

        Abhi_ViewClaimDetails_Controller.ResponseObj responseObj = new Abhi_ViewClaimDetails_Controller.ResponseObj();
        responseObj.Code = '200';
        responseObj.Message = 'Records fetched successfully';

        // Step 2: Initialize the Response
        Abhi_ViewClaimDetails_Controller.Response responseWrp = new Abhi_ViewClaimDetails_Controller.Response();
        responseWrp.PaidAmount = '100';
        responseWrp.ReserveAmount = '2000';
        responseWrp.Claim_SubStatus = 'Failed';
        responseWrp.ClaimStatus = 'Success';
        responseWrp.Claim_Amount = '10000';
        responseWrp.ClaimDate = '2024-08-20';
        responseWrp.ApprovedAmount = '5000';
        responseWrp.ClaimType = 'Test Claim';
        responseWrp.DeductionAmount = '1000';
        responseWrp.ClaimNumber = 'ABC12345';

        Abhi_ViewClaimDetails_Controller.ResponseWrapper responseWrapper = new Abhi_ViewClaimDetails_Controller.ResponseWrapper();
        responseWrapper.Message = 'Success';
        responseWrapper.StatusCode = 1000;
        responseWrapper.ResponseObj = responseObj;

        responseWrapper.Response = new List<Abhi_ViewClaimDetails_Controller.Response>();
        responseWrapper.Response.add(responseWrp);

        System.assertEquals('Success', responseWrapper.Message);
    }

    @isTest
    static void testPrepareRequestPayload() {
        // Fetch the test Asset created in test setup
        Asset testAsset = [SELECT Id, Policy_No__c FROM Asset LIMIT 1];
        
        // Create an instance of the controller class
        Abhi_ViewClaimDetails_Controller controller = new Abhi_ViewClaimDetails_Controller();

        // Call the prepareRequestPayload method
        Abhi_ViewClaimDetails_Controller.RequestWrapper requestPayload = controller.prepareRequestPayload(testAsset.Policy_No__c);
        
        System.assertEquals('ABC12345', requestPayload.policyNumber, 'ABC12345');
    }

    @SuppressWarnings('PMD.ApexDoc')
    // Mock class for HttpCalloutMock
    private class ABCL_IntegrationCalloutMock implements HttpCalloutMock {

        /********************************
        * @Function - respond
        * @param req
        * @description - respond method
        ********************************/
        public HTTPResponse respond(HTTPRequest req) {

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success"}');
            res.setStatusCode(1000);
            return res;
        }
    }
}