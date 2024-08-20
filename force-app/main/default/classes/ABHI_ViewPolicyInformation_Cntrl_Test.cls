/*********************************************************
*Class        :  ABHI_ViewPolicyInformation_Cntrl_Test
*Author       :  Anirudh Raturi
*Created Date :  02/00/2024
*Last Modified:  02/00/2024
*@description  :  Test Class for ABHI_ViewPolicyInformation_Controller
*********************************************************/

@isTest
public class ABHI_ViewPolicyInformation_Cntrl_Test {

    @testSetup
    static void setup() {
        // Create test data for Account
        Account acc = new Account(
            Name = 'Test Account',
            Client_Code__c = '12345'
        );
        insert acc;
    }

    @isTest
    static void testViewPolicyInformationApiCallout() {
        // Fetch the test account created in test setup
        Account testAccount = [SELECT Id, Client_Code__c FROM Account LIMIT 1];
        
        // Set up a mock response for the callout
        ABCL_IntegrationCalloutMock mock = new ABCL_IntegrationCalloutMock();
        Test.setMock(HttpCalloutMock.class, mock);

        // Call the method and assert the results
        ABCL_IntegrationCallout.IntegrationResponseWrapper response = ABHI_ViewPolicyInformation_Controller.viewPolicyInformationApiCallout(testAccount.Id);
        System.assertNotEquals(null, response, 'null');
    }

    @isTest
    static void testPrepareRequestPayload() {
        // Fetch the test account created in test setup
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Create an instance of the controller class
        ABHI_ViewPolicyInformation_Controller controller = new ABHI_ViewPolicyInformation_Controller();

        // Call the prepareRequestPayload method
        ABHI_ViewPolicyInformation_Controller.RequestWrapper requestPayload = controller.prepareRequestPayload(testAccount.Id);
        
        // Assert the values in the requestPayload
        System.assertEquals('12345', requestPayload.MemberNumber, '12345');
        System.assertNotEquals(null, requestPayload.RequestType, 'null');
        System.assertEquals(1, requestPayload.RequestType.size(), '1');
        System.assertEquals('GetHealthReturn', requestPayload.RequestType[0].HealthReturns, 'GetHealthReturn');
        System.assertEquals('UserInfo', requestPayload.RequestType[0].AppRegDetails, 'UserInfo');
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