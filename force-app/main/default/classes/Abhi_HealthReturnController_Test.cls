@IsTest
public class Abhi_HealthReturnController_Test {

    @IsTest
    static void testHealthReturnCalloutSuccess() {
        // Mock the response for a successful API call based on provided mock response
        String successResponseBody = '{"Response":[{"vchPolicyNumber":"31-24-0098014-00","vchClientCode":"PT87552250","Name":"PRADIP  BHUIN","Year":"2024","Month":"8","HealthAssessment":"0","HealthyHeartScore":"G","FitnessAssessment":"0","ActiveDays":"10","HealthReturnsforrespectivemonth":"0.0","ChronicMgmtProgramCompliance":"","HealthReturnsTMthroughBenefitforHospitalRoomchoice":"0.0","HealthReturnsTMthroughCarriedforwardOPDexpensesandBonus":"0.0","TotalHealthReturnsTMEarned":"0.0","TotalHealthReturnsTMBurnt":"0.0","TotalHealthReturnsTM":"0.0","HealthQuestionnaire":"","HRPercentage":"0.0"}],"StatusCode":1000,"message":"Success"}';
        ABCL_IntegrationCallout.IntegrationResponseWrapper mockResponse = new ABCL_IntegrationCallout.IntegrationResponseWrapper();
        mockResponse.responseBody = successResponseBody;
        mockResponse.statusCode = 200;

        Test.startTest();
        // Mocking the callout
        ABCL_IntegrationCalloutMock mock = new ABCL_IntegrationCalloutMock(mockResponse);
        Test.setMock(HttpCalloutMock.class, mock);

        // Call the method
        Abhi_HealthReturnController.ResponseWrapper response = Abhi_HealthReturnController.healthReturnCallout('12345', '54321');

        // Validate the response
        System.assertEquals(1000, response.StatusCode);

        // Validate the fields within the Response list
        System.assertEquals(1, response.Response.size());
        Abhi_HealthReturnController.Response res = response.Response[0];

        System.assertEquals('31-24-0098014-00', res.vchPolicyNumber, '');
        System.assertEquals('PT87552250', res.vchClientCode, '');
        System.assertEquals('PRADIP  BHUIN', res.Name, '');
        System.assertEquals('2024', res.Year, '');
        System.assertEquals('8', res.Month, '');
        System.assertEquals('0', res.HealthAssessment, '');
        System.assertEquals('G', res.HealthyHeartScore, '');
        System.assertEquals('0', res.FitnessAssessment, '');
        System.assertEquals('10', res.ActiveDays, '');
        System.assertEquals('0.0', res.HealthReturnsforrespectivemonth, '');
        System.assertEquals('0.0', res.HealthReturnsTMthroughBenefitforHospitalRoomchoice, '');
        System.assertEquals('0.0', res.HealthReturnsTMthroughCarriedforwardOPDexpensesandBonus, '');
        System.assertEquals('0.0', res.TotalHealthReturnsTMEarned, '');
        System.assertEquals('0.0', res.TotalHealthReturnsTMBurnt, '');
        System.assertEquals('0.0', res.TotalHealthReturnsTM, '');
        System.assertEquals('', res.ChronicMgmtProgramCompliance, '');
        System.assertEquals('', res.HealthQuestionnaire, '');
        System.assertEquals('0.0', res.HRPercentage, '');

        Test.stopTest();
    }

    @IsTest
    static void testHealthReturnCalloutFailure() {
        // Mock the response for a failed API call
        ABCL_IntegrationCallout.IntegrationResponseWrapper mockResponse = new ABCL_IntegrationCallout.IntegrationResponseWrapper();
        mockResponse.responseBody = '';
        mockResponse.statusCode = 500;

        Test.startTest();
        // Mocking the callout
        ABCL_IntegrationCalloutMock mock = new ABCL_IntegrationCalloutMock(mockResponse);
        Test.setMock(HttpCalloutMock.class, mock);

        // Call the method
        Abhi_HealthReturnController.ResponseWrapper response = Abhi_HealthReturnController.healthReturnCallout('12345', '54321');

        // Validate the response
        System.assertEquals(500, response.StatusCode, '');
        Test.stopTest();
    }

    @IsTest
    static void testPrepareRequestPayload() {
        Test.startTest();
        Abhi_HealthReturnController controller = new Abhi_HealthReturnController();
        Abhi_HealthReturnController.RequestWrapper request = controller.prepareRequestPayload('12345', '54321');
        
        // Validate the request payload
        System.assertEquals('12345', request.PolicyNumber, '');
        System.assertEquals('54321', request.ProposalNumber, '');
        System.assertEquals('HealthReturn', request.RequestType, '');
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexDoc')
    // Mock class for the integration callout.
    private class ABCL_IntegrationCalloutMock implements HttpCalloutMock {
        private ABCL_IntegrationCallout.IntegrationResponseWrapper responseWrapper;

        public ABCL_IntegrationCalloutMock(ABCL_IntegrationCallout.IntegrationResponseWrapper responseWrapper) {
            this.responseWrapper = responseWrapper;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setBody(responseWrapper.responseBody);
            res.setStatusCode(responseWrapper.statusCode);
            return res;
        }
    }
}