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
        PermissionSetGroup psg = [SELECT id from PermissionSetGroup where DeveloperName = 'ABHI_Users_PSG'];
        PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = testUser.Id, PermissionSetGroupId = psg.Id);
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
            System.assertEquals(400, res.StatusCode, 'code');
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
            String s = '{\"code\":1,\"msg\":\"Success\",\"error\":null,\"Message\":null,\"data\":{\"deviceCategories\":[\"Recommended\",\"Forotherdeviceusers\"],\"devices\":{\"Recommended\":[{\"logo_url\":\"https://activdayz.adityabirlahealth.com/Activedays/Image/noise-icon.png\",\"name\":\"Noise\",\"subname\":\"NS\",\"sync_url\":\"https://activdayz.adityabirlahealth.com/activedays/Device/Connect?DeviceCode=NS&MemberID=PT87902899&WellnessID=2758580&PolicyStartDate=2022-11-24&OS=android&Source=health\",\"synced\":\"0\",\"redirect_uri\":\"info\",\"googlefitProfile\":null},{\"logo_url\":\"https://activdayz.adityabirlahealth.com/Activedays/Image/health_connect_logo.png\",\"name\":\"HealthConnect\",\"subname\":\"HC\",\"sync_url\":\"https://activdayz.adityabirlahealth.com/activedays/Device/Connect?DeviceCode=HC&MemberID=PT87902899&WellnessID=2758580&PolicyStartDate=2022-11-24&OS=android&Source=health\",\"synced\":\"1\",\"redirect_uri\":\"info\",\"googlefitProfile\":null},{\"logo_url\":null,\"name\":\"GoogleFit\",\"subname\":\"GF\",\"sync_url\":\"https://activdayz.adityabirlahealth.com/activedays/Device/Connect?DeviceCode=GF&MemberID=PT87902899&WellnessID=2758580&PolicyStartDate=2022-11-24&OS=android&Source=health\",\"synced\":\"0\",\"redirect_uri\":\"info\",\"googlefitProfile\":{\"Display_Name\":\"MuthuNadar\",\"Email\":\"nadarmuthukumar1987@gmail.com\",\"Family_Name\":null,\"Given_Name\":\"Muthu\",\"ID\":\"114978213301391808742\",\"ID_Token\":\"\",\"Server_Auth_Code\":\"4/0ATx3LY4zA5UiI4rFTmP4oyz7UkeDt-jsax2spszTVRjXVtBHB1I992sv6CGplH6M_5tNbw\",\"Photo_URL\":\"https://lh3.googleusercontent.com/a/ACg8ocK3oO3Kg8icWkBxGoQH1bJ8HrS7XHFs2IjDdzQqrvoriEcvh774Vw\"}}],\"Others\":[{\"logo_url\":\"https://activdayz.adityabirlahealth.com/Activedays/Image/garmin-connect.png\",\"name\":\"Garmin\",\"subname\":\"GR\",\"sync_url\":\"https://activdayz.adityabirlahealth.com/activedays/Device/Connect?DeviceCode=GR&MemberID=PT87902899&WellnessID=2758580&PolicyStartDate=2022-11-24&OS=android&Source=health\",\"synced\":\"0\",\"redirect_uri\":\"info\",\"googlefitProfile\":null},{\"logo_url\":\"https://hpre.adityabirlahealth.com/Activedays/Image/SH.png\",\"name\":\"SamsungHealth\",\"subname\":\"SH\",\"sync_url\":\"https://activdayz.adityabirlahealth.com/activedays/Device/Connect?DeviceCode=SH&MemberID=PT87902899&WellnessID=2758580&PolicyStartDate=2022-11-24&OS=android&Source=health\",\"synced\":\"0\",\"redirect_uri\":\"info\",\"googlefitProfile\":null},{\"logo_url\":\"https://activdayz.adityabirlahealth.com/Activedays/Image/fitbit-icon.png\",\"name\":\"FitBit\",\"subname\":\"FB\",\"sync_url\":\"https://activdayz.adityabirlahealth.com/activedays/Device/Connect?DeviceCode=FB&MemberID=PT87902899&WellnessID=2758580&PolicyStartDate=2022-11-24&OS=android&Source=health\",\"synced\":\"0\",\"redirect_uri\":\"info\",\"googlefitProfile\":null}]}},\"StatusCode\":\"1000\",\"Message\":\"Success\"}';
            res.setBody(s);
            res.setStatusCode(1000);
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
			String s = '{\"ReturnCode\":\"2\",\"ReturnMessage\":\"Nodatafound\"}';
            res.setBody(s);
            res.setStatusCode(400);
            return res;
        }
    }
}