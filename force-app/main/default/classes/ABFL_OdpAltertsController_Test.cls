/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 06-28-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   06-28-2024   rsinghnagar@salesforce.com   Initial Version
**/
@isTest
public class ABFL_OdpAltertsController_Test {
    
    // Inner class for mocking HTTP response
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"alerts": [{"id": "001", "message": "Test Alert"}]}');
            res.setStatusCode(200);
            return res;
        }
    }
    @isTest
    static void testGetOdpAlerts() {
        // Test data setup
        Account testAccount = new Account(Name = 'Test Acc',Client_Code__c = 'TestClientCode');
        insert testAccount;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        // Test the getOdpAlerts method
        List<ODPAlertResponse> result = ABFL_OdpAltertsController.getOdpAlerts(testAccount.Id);
        Test.stopTest();
        testAccount.Client_Code__c = '';
        update testAccount;
        try{
			Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());            
            ABFL_OdpAltertsController.getOdpAlerts(testAccount.Id);
            
        }catch(Exception e){
            System.AssertEquals('System.AuraHandledException: Script-thrown exception', e.toString(),'should match with the AuraHandled Exception');
        }
        System.assertNotEquals(null, result,'result should not be null');    
    }
}