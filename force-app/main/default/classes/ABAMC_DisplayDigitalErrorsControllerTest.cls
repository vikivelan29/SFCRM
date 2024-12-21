@isTest
public class ABAMC_DisplayDigitalErrorsControllerTest {
    
     @testSetup
    static void setupTestData() {
        
        Account acc = new Account(Name = 'Test Acc', PAN__c = 'ABCDX', Business_Unit__c = 'ABSLAMC');
        insert acc;
        
    }
    
          // Mock for the callout response
    private class MockIntegrationCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String jsonString = '{"statusCode":200,"responseBody":"{\\"response_key\\":\\"response_value\\"}"}';
            res.setBody(jsonString);
            res.setStatusCode(200);
            return res;
        }
    }
    
    // Mock for the SIP error callout response
    private class MockIntegrationCalloutError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(400);
            res.setBody('{"ReturnCode": "0", "ReturnMessage": "Error retrieving record."}');
            return res;
        }
    }
    
     @IsTest
    static void testfetchDigitalErrorsSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockIntegrationCallout());
        
        Account acc = [Select Id,PAN__c,Business_Unit__c from Account Limit 1];
        
        Test.startTest();
        ABAMC_DisplayDigitalErrorsController.ReturnWrapper result = ABAMC_DisplayDigitalErrorsController.fetchDigitalErrors(acc.Id);
        Test.stopTest();
        System.assert(result != null, 'Expected result to be not null');
        System.assertEquals(true,result.isSuccess);
    }
    
     @IsTest
    static void testfetchDigitalErrorsFailure() {
        Test.setMock(HttpCalloutMock.class, new MockIntegrationCalloutError());
        
        Account acc = [Select Id,PAN__c,Business_Unit__c from Account Limit 1];
        
        Test.startTest();
        ABAMC_DisplayDigitalErrorsController.ReturnWrapper result = ABAMC_DisplayDigitalErrorsController.fetchDigitalErrors(acc.Id);
        Test.stopTest();
        System.assert(result != null, 'Expected result to be not null');
        System.assertEquals(false,result.isSuccess);
    }

}