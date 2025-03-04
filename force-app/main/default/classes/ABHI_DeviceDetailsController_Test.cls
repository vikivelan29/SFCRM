/**
 * @description       : Test Class for ABHI_DeviceDetailsController
 * @author            : Amrit Preet Singh
 * @group             : 
 * @last modified on  : 06/08/2024
 * @last modified by  : Amrit Preet Singh
 * Modifications Log
 * Ver   Date         Author                            Modification
 * 1.0   08-06-2024   amritpreet.singh@salesforce.com   Initial Version
**/
@isTest
public class ABHI_DeviceDetailsController_Test {
    @TestSetup
    static void makeData(){
        Profile abhilProfile = [SELECT id, name from Profile where name = 'ABHI Base Profile'];
        
        User testUser = new User(
            IsActive = true,
            Business_Unit__c='ABHI',
            FirstName = 'Test',
            LastName='User ABHI',
            Username='abhitestuser@test.com',
            Email='abhitestuser@test.com',
            Alias = 'atus',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', 
            ProfileId = abhilProfile.Id, 
            TimeZoneSidKey='America/Los_Angeles'
        );
        insert testUser; 
        PermissionSet psg = [SELECT id from PermissionSet where Name = 'API_Admin_User_PS'];
        PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = testUser.Id, PermissionSetId = psg.Id);
        insert psa;
        System.runAs(testUser){
            Account acc = new Account( 
                Name='testAcc',
                Client_Code__c = '1234');
            insert acc;
        }
    }

    @isTest
    static void testgetDeviceDetails() {
        Account acc = [SELECT id, Client_Code__c from Account where Name = 'testAcc' LIMIT 1];
        User testUser = [SELECT id from User where LastName='User ABHI' LIMIT 1];
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new ABHI_DeviceDetailsMockHttpResponse());
        System.runAs(testUser){
            Test.startTest();
            ABHI_DeviceDetailsController.ResponseWrapper res= ABHI_DeviceDetailsController.getDeviceDetails(acc.Id);
            Test.stopTest();
            System.assertEquals(1000, res.StatusCode, 'code');
            System.assertEquals('Success', res.Message, 'Message');
        }
    }
    @isTest
    static void testgetFailureDeviceDetails() {
        Account acc = [SELECT id, Client_Code__c from Account where Name = 'testAcc' LIMIT 1];
        User testUser = [SELECT id from User where LastName='User ABHI' LIMIT 1];
        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new ABHI_DeviceDetailsFailureResponseGenerator());
        System.runAs(testUser){
            Test.startTest();
            ABHI_DeviceDetailsController.ResponseWrapper res= ABHI_DeviceDetailsController.getDeviceDetails(acc.Id);
            Test.stopTest();
            System.assertEquals(1001, res.StatusCode, 'code');
        }
    }

     /**
    * @description  Mocking success response
    */ 
    public class ABHI_DeviceDetailsMockHttpResponse implements HttpCalloutMock {
        /**
            * @description  Mocking success response
            * @param req
            ** @return HTTPResponse
        */ 
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String s = '{\"Content\":\"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\",\"StatusCode\":\"1000\",\"Message\":\"Success\"}';
            res.setBody(s);
            res.setStatusCode(200);
            return res;
        }
    }

     /**
    * @description Mocking failure response
    */ 
    public class ABHI_DeviceDetailsFailureResponseGenerator implements HttpCalloutMock {
        /**
            * @description  Mocking failure response
            * @param req
            ** @return HTTPResponse
        */ 
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
			String s = '{\"Content\":\"AFfSJT4iV7UwdIQNseRlld21/nfM5HBD7kBnemXTIql8LCdgZzwwnNgxdYxVgXtn8bq4bQvZZVN9ZxGZxvLw4A==\",\"StatusCode\":\"1001\",\"Message\":\"DeviceDetailsFailure\"}';
            res.setBody(s);
            res.setStatusCode(400);
            return res;
        }
    }
}