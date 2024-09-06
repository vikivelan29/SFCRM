/**
 * @description       : Test Class for ABHI_FAHistoryDetailsController
 * @author            : Amrit Preet Singh
 * @group             : 
 * @last modified on  : 06/08/2024 
 * @last modified by  : Amrit Preet Singh 1
 * Modifications Log
 * Ver   Date         Author                            Modification
 * 1.0   08-06-2024   amritpreet.singh@salesforce.com   Initial Version
**/
@isTest
public class ABHI_FAHistoryDetailsController_Test {

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
        PermissionSetGroup psg = [SELECT id from PermissionSetGroup where DeveloperName = 'ABHI_Users_PSG'];
        PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = testUser.Id, PermissionSetGroupId = psg.Id);
        insert psa;
        System.runAs(testUser){
            Account acc = new Account( 
                Name='testAcc',
                Client_Code__c = '1234');
            insert acc;
            Account accWithoutCode = new Account( 
                Name='testAcc');
            insert accWithoutCode;
        }
    }
    
    @isTest static void testgetFADetails() {
        Account acc = [SELECT id from Account LIMIT 1];
        User testUser = [SELECT id from User where LastName='User ABHI' LIMIT 1];
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new ABHI_FAHistoryDetailsMockHttpResponse());
        System.runAs(testUser){
            Test.startTest();
            ABHI_FAHistoryDetailsController.IntegrationResponseWrapper res= ABHI_FAHistoryDetailsController.getFADetails(acc.Id);
            Test.stopTest();
            System.assertEquals(1000, res.StatusCode, 'code');
        }
    }

    @isTest static void testgetFailureFADetails() {
        Account acc = [SELECT id from Account LIMIT 1];
        User testUser = [SELECT id from User where LastName='User ABHI' LIMIT 1];
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new ABHI_FAHistoryDetailsFailureResponseGenerator());
        System.runAs(testUser){
            Test.startTest();
            ABHI_FAHistoryDetailsController.IntegrationResponseWrapper res= ABHI_FAHistoryDetailsController.getFADetails(acc.Id);
            Test.stopTest();
            System.assertEquals(400, res.StatusCode, 'code');
        }
    }
    
    @isTest static void testgetFADetailsWithoutCustomerId() {
        Account acc = [SELECT id from Account where Client_Code__c = '' LIMIT 1];
        User testUser = [SELECT id from User where LastName='User ABHI' LIMIT 1];
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new ABHI_FAHistoryDetailsFailureResponseGenerator());
        System.runAs(testUser){
            Test.startTest();
            ABHI_FAHistoryDetailsController.IntegrationResponseWrapper res= ABHI_FAHistoryDetailsController.getFADetails(acc.Id);
            Test.stopTest();
            System.assertEquals(400, res.StatusCode, 'code');
        }
    }

    /**
    * @description  Mocking success response
    */ 
    public class ABHI_FAHistoryDetailsMockHttpResponse implements HttpCalloutMock {
        /**
            * @description  Mocking success response
            * @param req
            ** @return HTTPResponse
        */ 
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String s = '{\"info\":{\"status\":\"SUCCESS\",\"messageCode\":\"JAVASUCCESS0001\",\"messageDesc\":\"Successfullyfetchappointmenthistory\",\"serviceMessageType\":\"INFORMATION\"},\"customerAppointments\":[{\"bookingId\":5905,\"bookingHistories\":[{\"id\":12806,\"status\":\"REQUESTRECEIVED\",\"bookingSlot\":\"11AM\",\"comments\":\"Appointmentbookedsuccessfully\",\"createdBy\":\"NareshM\",\"appointmentDate\":\"2024-01-13\",\"createdDate\":\"2024-01-12T17:48:43\",\"fitnessCenterBranch\":\"KrishnaMarg\"}]}],\"StatusCode\":\"1000\",\"Message\":\"Success\"}';
            res.setBody(s);
            res.setStatusCode(200);
            return res;
        }
    }

    /**
    * @description Mocking failure response
    */ 
    public class ABHI_FAHistoryDetailsFailureResponseGenerator implements HttpCalloutMock {
        /**
            * @description  Mocking failure response
            * @param req
            ** @return HTTPResponse
        */ 
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String s = '{\"ReturnCode\":\"2\",\"ReturnMessage\":\"Nodatafound\"}';
            res.setBody(s);
            res.setStatusCode(400);
            return res;
        }
    }
}