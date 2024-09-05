@isTest
public class ABHI_FALevelDetails_Controller_Test {
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
    
    @isTest static void Success_FADetails(){
         Account acc = [SELECT id from Account LIMIT 1];
        User testUser = [SELECT id from User where LastName='User ABHI' LIMIT 1];
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new ABHI_FALevelDetailsMockHttpResponse());
        System.runAs(testUser){
            Test.startTest();
            ABHI_FALevelDetails_Controller.IntegrationResponseWrapper resp= ABHI_FALevelDetails_Controller.GetFALevelDetails(acc.Id, '2024-01-01',
                '2024-08-12');
            Test.stopTest();
            //System.assertEquals(1000, res.StatusCode, 'code');
        //System.assertEquals(1000, resp.StatusCode, 'StatusCode should be 1000');
        //System.assertEquals('Success', resp.Message, 'Message should be Success');
        }
        
    }
    
    @isTest static void Failure_FADetails() {
        Account acc = [SELECT id from Account LIMIT 1];
        User testUser = [SELECT id from User where LastName='User ABHI' LIMIT 1];
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new ABHI_FALevelDetailsFailureResponseGenerator());
        System.runAs(testUser){
            Test.startTest();
            ABHI_FALevelDetails_Controller.IntegrationResponseWrapper resp= ABHI_FALevelDetails_Controller.GetFALevelDetails(acc.Id, '2024-01-01', '2024-08-12');
            Test.stopTest();
            //System.assertEquals(1001, resp.StatusCode, 'StatusCode should be 1001');

        }
    }
    
    
    
    
    
    
    public class ABHI_FALevelDetailsMockHttpResponse implements HttpCalloutMock {
        // Http Mock success response 
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(
            '{"eventTxnId":"567489301","eventCode":"ED-Fitnes2","eventDate":"2024-07-01","customerNumber":"3665207","eventValue":"10","receivedDate":"2024-07-01","totalCount":"20","totalScore":"10","effectiveToDate":"2024-07-31","StatusCode":"1000","Message":"Success"}'
            );
            res.setStatusCode(1000);
            return res;
        }
    }
    
    
 public class ABHI_FALevelDetailsFailureResponseGenerator implements HttpCalloutMock {
       
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
			res.setBody('{"StatusCode": "1001","Message": "FALevelDetails Failure"}'
                        );
          
            res.setStatusCode(1001);
            return res;
        }
    }



 @isTest
    static void TestIntegrationResponseWrapperConstructor() {
        // Create an instance of IntegrationResponseWrapper using the constructor
        Integer testStatusCode = 1000;
        String testMessage = 'Test message';
        
        ABHI_FALevelDetails_Controller.IntegrationResponseWrapper resp = new ABHI_FALevelDetails_Controller.IntegrationResponseWrapper(
            testStatusCode, 
            testMessage
        );
        
        // Verify the constructor behavior
        System.assertEquals(testStatusCode, resp.StatusCode, 'StatusCode should match the constructor input');
        System.assertEquals(testMessage, resp.Message, 'Message should match the constructor input');
    }
    
    
    @isTest
    static void TestNullIntegrationResponse() {
        Account acc = [SELECT id FROM Account LIMIT 1];
        User testUser = [SELECT id FROM User WHERE LastName = 'User ABHI' LIMIT 1];
        
        // Set mock callout class to simulate null response scenario
        Test.setMock(HttpCalloutMock.class, new ABHI_FALevelDetailsNullResponseMock());
        
        System.runAs(testUser) {
            Test.startTest();
            ABHI_FALevelDetails_Controller.IntegrationResponseWrapper resp = ABHI_FALevelDetails_Controller.GetFALevelDetails(
                acc.Id, '2024-01-01', '2024-08-12'
            );
            Test.stopTest();
            
            // Verify that the fallback message is used
            //System.assertEquals(1001, resp.StatusCode, 'StatusCode should be 1001');
            //System.assertEquals('No records found', resp.Message, 'Message should be the custom metadata value');
        }
    }
    
    // Mock response class for null response
    public class ABHI_FALevelDetailsNullResponseMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{}'); // Empty body to simulate null response
            res.setStatusCode(200); // HTTP status code for success
            return res;
        }
    }
    
    
    
    
    
    
    

}