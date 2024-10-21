/**
 * @description       : Test Class for ABHI_ClickPSSCommController
 * @author            : Amrit Preet Singh
 * @last modified on  : 03/09/2024
 * @last modified by  : Amrit Preet Singh
 * Modifications Log
 * Ver   Date         Author                            Modification
 * 1.0   03-09-2024   amritpreet.singh@salesforce.com   Initial Version
**/
@isTest
public class ABHI_ClickPSSCommController_Test {
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
            Asset ass = new Asset(
                Name='testAsset',
                Policy_No__c='12345',
                AccountId=acc.Id
            );
            insert ass;
        }
    }

    @isTest static void testDoCommunication(){
        Asset ass = [SELECT id from Asset];
        String formData = '{"commType":"SMS","template":"A1159","alertCode":"2","phoneNumber":"54434343434","emailId":""}';
        User testUser = [SELECT id from User where LastName='User ABHI' LIMIT 1];
        String requestString = '';
        Test.setMock(HttpCalloutMock.class, new ABHI_PSSCommunicationMockHttpResponse());
        System.runAs(testUser){
            Test.startTest();
            ABHI_ClickPSSCommController.ClientResponseWrapper res= ABHI_ClickPSSCommController.doCommunication('Asset', ass.id, formData);
            Test.stopTest();
            System.assertEquals(1000, res.statusCode);
        }
    }

    @isTest static void testDoCommunicationFailure(){
        Asset ass = [SELECT id from Asset];

        String formData = '{"commType":"SMS","template":"A1159","alertCode":"2","phoneNumber":"54434343434","emailId":""}';
        User testUser = [SELECT id from User where LastName='User ABHI' LIMIT 1];
        String requestString = '';
        Test.setMock(HttpCalloutMock.class, new ABHI_PSSCommunicationMockFailureHttpResponse());
        System.runAs(testUser){
            Test.startTest();
            ABHI_ClickPSSCommController.ClientResponseWrapper res= ABHI_ClickPSSCommController.doCommunication('Asset', ass.id, formData);
            Test.stopTest();
            System.assertEquals(400, res.statusCode);
        }
    }

    @isTest static void testGetMetadata(){
        User testUser = [SELECT id from User where LastName='User ABHI' LIMIT 1];
        Group gp = [SELECT id from Group where DeveloperName='ABHI_Contact_Center'];
        GroupMember gm = new GroupMember(UserOrGroupId = testUser.Id, GroupId = gp.Id);
        insert gm;
        System.runAs(testUser){
            Test.startTest();
            List<ABHI_PSSCommunicationConfig__mdt> res= ABHI_ClickPSSCommController.getMetadata('Account');
            Test.stopTest();
            System.assertNotEquals(0, res.size());
        }
    }

    /**
    * @description  Mocking success response
    */ 
    public class ABHI_PSSCommunicationMockHttpResponse implements HttpCalloutMock {
        /**
            * @description  Mocking success response
            * @param req
            ** @return HTTPResponse
        */ 
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String s = '{\"PolicyID\":\"\",\"FIELD3\":\"\",\"AppNo\":\"H23000001\",\"alertID\":\"A6091\",\"channel_ID\":\"EmpanelmentPortal\",\"Req_Id\":\"1\",\"Alert_Mode\":\"1\",\"REF_NO\":\"17462089\",\"EMLFLG\":\"0\",\"STATUS\":\"0\",\"field1\":null,\"field2\":null,\"field3\":null,\"error\":null,\"StatusCode\":1000,\"message\":\"Success\"}';
            res.setBody(s);
            res.setStatusCode(200);
            return res;
        }
    }

    /**
    * @description  Mocking success response
    */ 
    public class ABHI_PSSCommunicationMockFailureHttpResponse implements HttpCalloutMock {
        /**
            * @description  Mocking success response
            * @param req
            ** @return HTTPResponse
        */ 
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String s = '';
            res.setBody(s);
            res.setStatusCode(400);
            return res;
        }
    }
}