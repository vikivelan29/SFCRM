@isTest
 class ABHI_PSSReportController_Test {

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
                Client_Code__c = '1234',
                Phone='8987874632',
                Office_Email__c = 'testsfdc@gmail.com');
            insert acc;
            Asset ass = new Asset(
                AccountId = acc.Id,
                Name='testAsset',
                Policy_No__c='56567',
                SerialNumber='445637'
            );
            insert ass;
        }
    }

    @isTest static void testGetSuccessDataForAccount() {
        Account acc = [SELECT id from Account LIMIT 1];
        User testUser = [SELECT id from User where LastName='User ABHI' LIMIT 1];
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new ABHI_PSSReportMockHttpResponse());
        System.runAs(testUser){
            Test.startTest();
            ABHI_PSSReportController.ReportResponseWrapper res= ABHI_PSSReportController.getData(acc.Id);
            Test.stopTest();
            System.assertEquals(200, res.StatusCode, 'code');
        }
    }

    @isTest static void testGetSuccessDataForAsset() {
        Asset ass = [SELECT Policy_No__c, SerialNumber, AccountId from Asset LIMIT 1];
        User testUser = [SELECT id from User where LastName='User ABHI' LIMIT 1];
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new ABHI_PSSReportMockHttpResponse());
        System.runAs(testUser){
            Test.startTest();
            ABHI_PSSReportController.ReportResponseWrapper res= ABHI_PSSReportController.getData(ass.Id);
            Test.stopTest();
            System.assertEquals(200, res.StatusCode, 'code');
        }
    }
    @isTest static void testGetFailureData() {
        Asset ass = [SELECT Policy_No__c, SerialNumber, AccountId from Asset LIMIT 1];
        User testUser = [SELECT id from User where LastName='User ABHI' LIMIT 1];
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new ABHI_PSSReportMockFailureHttpResponse());
        System.runAs(testUser){
            Test.startTest();
            ABHI_PSSReportController.ReportResponseWrapper res= ABHI_PSSReportController.getData(ass.Id);
            Test.stopTest();
            System.assertEquals(400, res.StatusCode, 'code');
        }
    }

    /**
    * @description  Mocking success response
    */ 
    public class ABHI_PSSReportMockHttpResponse implements HttpCalloutMock {
        /**
            * @description  Mocking success response
            * @param req
            ** @return HTTPResponse
        */ 
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String s = '{\"PolicyInfo\":[{\"SNO\":\"7335202\",\"DOCUMENT_ID\":\"A1202\",\"POLICY_NO\":\"GHI-XL-21-2005379\",\"APPLICATION_NO\":\"XL1731684\",\"CLAIM_NO\":\"\",\"SOURCE_SYSTEM\":\"CRM\",\"IMPACT_MODULES\":\"CMSfunctionalitiesinCRM\",\"DOCUMENT_DESCRIPTION\":\"AppDownload(AppDownload)\",\"MODE_OF_COMMUNICATION\":\"Sms\",\"RECORD_PROCESS_DATE\":\"2021-12-1700:00:00.0\",\"EMAIL_ID\":\"\",\"CC_EMAIL_ID\":\"\",\"BCC_EMAIL_ID\":\"\",\"EMAIL_STATUS\":\"NA\",\"EMAIL_CONTENT\":\"NA\",\"EMAIL_REQUEST_TIME\":\"\",\"EMAIL_RESPONSE_TIME\":\"\",\"MOBILE_NO\":\"8160903565\",\"SMS_STATUS\":\"Y\",\"SMS_CONTENT\":\"https://cpssprod.adityabirlahealth.com/ContentViewerService/resources/ContentViewer/getContent?clickID=7335202_PXSM\",\"SMS_REQUEST_TIME\":\"2021-12-1714:58:11.0\",\"SMS_RESPONSE_TIME\":\"2021-12-1714:58:11.0\",\"MEMBER_ID\":\"\",\"NOTIFICATION_STATUS\":\"NA\",\"NOTIFICATION_CONTENT\":\"NA\",\"NOTIFICATION_REQUEST_TIME\":\"\",\"NOTIFICATION_RESPONSE_TIME\":\"\",\"DOCID\":\"NA\",\"TRIGGER_MODE\":\"RealTime\",\"OMNI_UPLOAD_DATETIME\":\"NAForalerts\"},{\"SNO\":\"7335123\",\"DOCUMENT_ID\":\"A1202\",\"POLICY_NO\":\"GHI-XL-21-2005379\",\"APPLICATION_NO\":\"XL1731684\",\"CLAIM_NO\":\"\",\"SOURCE_SYSTEM\":\"CRM\",\"IMPACT_MODULES\":\"CMSfunctionalitiesinCRM\",\"DOCUMENT_DESCRIPTION\":\"AppDownload(AppDownload)\",\"MODE_OF_COMMUNICATION\":\"Sms\",\"RECORD_PROCESS_DATE\":\"2021-12-1700:00:00.0\",\"EMAIL_ID\":\"\",\"CC_EMAIL_ID\":\"\",\"BCC_EMAIL_ID\":\"\",\"EMAIL_STATUS\":\"NA\",\"EMAIL_CONTENT\":\"NA\",\"EMAIL_REQUEST_TIME\":\"\",\"EMAIL_RESPONSE_TIME\":\"\",\"MOBILE_NO\":\"8160903565\",\"SMS_STATUS\":\"Y\",\"SMS_CONTENT\":\"https://cpssprod.adityabirlahealth.com/ContentViewerService/resources/ContentViewer/getContent?clickID=7335123_PXSM\",\"SMS_REQUEST_TIME\":\"2021-12-1714:56:45.0\",\"SMS_RESPONSE_TIME\":\"2021-12-1714:56:45.0\",\"MEMBER_ID\":\"\",\"NOTIFICATION_STATUS\":\"NA\",\"NOTIFICATION_CONTENT\":\"NA\",\"NOTIFICATION_REQUEST_TIME\":\"\",\"NOTIFICATION_RESPONSE_TIME\":\"\",\"DOCID\":\"NA\",\"TRIGGER_MODE\":\"RealTime\",\"OMNI_UPLOAD_DATETIME\":\"NAForalerts\"}]}';
            res.setBody(s);
            res.setStatusCode(200);
            return res;
        }
    }

    /**
    * @description  Mocking success response
    */ 
    public class ABHI_PSSReportMockFailureHttpResponse implements HttpCalloutMock {
        /**
            * @description  Mocking success response
            * @param req
            ** @return HTTPResponse
        */ 
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String s = '{}';
            res.setBody(s);
            res.setStatusCode(400);
            return res;
        }
    }
}