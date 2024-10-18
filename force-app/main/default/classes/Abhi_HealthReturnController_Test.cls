@isTest
public class Abhi_HealthReturnController_Test {

    @isTest
    static void testHealthReturnCalloutSuccess() {
        // Set up mock response for a successful callout
        ABCL_IntegrationCalloutMock mock = new ABCL_IntegrationCalloutMock();
        mock.setResponseBody('{"Response":[{"vchPolicyNumber":"31-24-0098014-00","vchClientCode":"PT87552250","Name":"PRADIP  BHUIN","Year":"2024","Month":"8","HealthAssessment":"0","HealthyHeartScore":"G","FitnessAssessment":"0","ActiveDays":"10","HealthReturnsforrespectivemonth":"0.0","ChronicMgmtProgramCompliance":"","HealthReturnsTMthroughBenefitforHospitalRoomchoice":"0.0","HealthReturnsTMthroughCarriedforwardOPDexpensesandBonus":"0.0","TotalHealthReturnsTMEarned":"0.0","TotalHealthReturnsTMBurnt":"0.0","TotalHealthReturnsTM":"0.0","HealthQuestionnaire":"","HRPercentage":"0.0"}],"StatusCode":1000,"message":"Success"}');
        mock.setStatusCode(1000);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        // Call the method with sample inputs
        Abhi_HealthReturnController.ResponseWrapper response = Abhi_HealthReturnController.healthReturnCallout('POL123', 'PROP123');
        Test.stopTest();

        // Assertions for success scenario
        System.assertEquals(1000, response.StatusCode, 'StatusCode should be 1000 for a successfull response');
    }

    @isTest
    static void testHealthReturnCalloutErrorResponse() {
        // Set up mock response for error case
        ABCL_IntegrationCalloutMock mock = new ABCL_IntegrationCalloutMock();
        mock.setResponseBody('');
        mock.setStatusCode(400); // Simulate a bad request
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        // Call the method with sample inputs
        Abhi_HealthReturnController.ResponseWrapper response = Abhi_HealthReturnController.healthReturnCallout('POL123', 'PROP123');
        Test.stopTest();

        // Assertions for error scenario
        Custom_Messages__mdt errorMessage = Custom_Messages__mdt.getInstance('ABHI_No_Response_Received');
        System.assertEquals(400, response.StatusCode, 'StatusCode should be 400');
        System.assertEquals(errorMessage.Message__c, response.Message, 'Message should match the custom metadata message');
    }

    @isTest
    static void testPrepareRequestPayload() {
        // Test the prepareRequestPayload method
        Abhi_HealthReturnController controller = new Abhi_HealthReturnController();
        Abhi_HealthReturnController.RequestWrapper reqWrapper = new Abhi_HealthReturnController.RequestWrapper();
        reqWrapper.MemberNumber = 'POL123';
        reqWrapper.ClaimNumber = 'PROP123';
        reqWrapper.ProviderCode = 'PROP123';
        reqWrapper.TestType = 'PROP123';

        Abhi_HealthReturnController.RequestWrapper request = controller.prepareRequestPayload('POL123', 'PROP123');
        
        // Assertions
        System.assertEquals('POL123', request.PolicyNumber, 'PolicyNumber should be POL123');
        System.assertEquals('PROP123', request.ProposalNumber, 'ProposalNumber should be PROP123');
        System.assertEquals('HealthReturn', request.RequestType, 'RequestType should be HealthReturn');
    }
    
    // Mock class to simulate the HTTP callout behavior
    @SuppressWarnings('PMD.ApexDoc')
    private class ABCL_IntegrationCalloutMock implements HttpCalloutMock {
        private String responseBody;
        private Integer statusCode;
        
        public void setResponseBody(String responseBody) {
            this.responseBody = responseBody;
        }

        public void setStatusCode(Integer statusCode) {
            this.statusCode = statusCode;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setBody(responseBody);
            res.setStatusCode(statusCode);
            return res;
        }
    }
}