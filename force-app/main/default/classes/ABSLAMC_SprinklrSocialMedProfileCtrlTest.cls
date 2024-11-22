@isTest
public class ABSLAMC_SprinklrSocialMedProfileCtrlTest {

    @testSetup
    static void setupTestData() {
        Id recordTypeId = Account.SObjectType.getDescribe()
                     .getRecordTypeInfosByDeveloperName()
                     .get('Non_Individual')
                     .getRecordTypeId();
        
        Account nonIndAcc = new Account (
        Name = 'Test User',
        Business_Unit__c = ABSLAMC_Constants.ABSLAMCBU,
        RecordTypeId = recordTypeId);
        
        insert nonIndAcc;
        
        Contact con = new Contact(
        LastName = 'TestCon',
        Phone = '1789736567',
        Email = 'abc@def.com',
        AccountId = nonIndAcc.Id);
        
        insert con;
        
        // Insert an Account record for testing
        Account testAccount = new Account(
            FirstName = 'TestOne',
            LastName = 'User',
            PersonEmail = 'testuser990@example.com',
            PersonMobilePhone = '1234567890',
            Business_Unit__c = ABSLAMC_Constants.ABSLAMCBU
        );
        insert testAccount;
        
         // Insert an Account record for testing
        Account testAccountOne = new Account(
            FirstName = 'TestTwo',
            LastName = 'User',
            PersonEmail = '',
            PersonMobilePhone = '1234567890',
            Business_Unit__c = ABSLAMC_Constants.ABSLAMCBU
        );
        insert testAccountOne;
        
        // Insert an Account record for testing
        Account testAccountTwo = new Account(
            FirstName = 'TestThree',
            LastName = 'User',
            PersonEmail = 'testuser990@example.com',
            PersonMobilePhone = '',
            Business_Unit__c = ABSLAMC_Constants.ABSLAMCBU
        );
        insert testAccountTwo;
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
    static void testGetSocialMediaResponseError() {
          Test.setMock(HttpCalloutMock.class, new MockIntegrationCalloutError());
        
        Account acc = [Select Id from Account Where FirstName = 'TestOne' Limit 1];
        
        Test.starttest();
        ABSLAMC_SprinklrSocialMediaProfileCtrl.responseWrapper result = ABSLAMC_SprinklrSocialMediaProfileCtrl.getSocialMediaProfileResponse(acc.Id);
        Test.stoptest();  
        System.assert(result != null, 'Expected result to be not null');
        System.assertEquals(false,result.isSuccess);
    }
    
    @IsTest
    static void testGetSocialMediaResponseSuccess() {
          Test.setMock(HttpCalloutMock.class, new MockIntegrationCallout());
        
        Account acc = [Select Id from Account Where FirstName = 'TestOne' Limit 1];
        
        Test.starttest();
        ABSLAMC_SprinklrSocialMediaProfileCtrl.responseWrapper result = ABSLAMC_SprinklrSocialMediaProfileCtrl.getSocialMediaProfileResponse(acc.Id);
        Test.stoptest();  
        System.assert(result != null, 'Expected result to be not null');
        System.assertEquals(true,result.isSuccess);
    }
    
    @IsTest
    static void testGetSocialMediaResponseSuccessBlankEmail() {
          Test.setMock(HttpCalloutMock.class, new MockIntegrationCallout());
        Account acc = [Select Id from Account Where FirstName = 'TestTwo' Limit 1];
        Test.starttest();
        ABSLAMC_SprinklrSocialMediaProfileCtrl.responseWrapper result = ABSLAMC_SprinklrSocialMediaProfileCtrl.getSocialMediaProfileResponse(acc.Id);
        Test.stoptest();   
        System.assert(result != null, 'Expected result to be not null');
        System.assertEquals(true,result.isSuccess);
    }
    
       @IsTest
    static void testGetSocialMediaResponseSuccessBlankPhone() {
          Test.setMock(HttpCalloutMock.class, new MockIntegrationCallout());
        Account acc = [Select Id from Account Where FirstName = 'TestThree' Limit 1];
        Test.starttest();
        ABSLAMC_SprinklrSocialMediaProfileCtrl.responseWrapper result = ABSLAMC_SprinklrSocialMediaProfileCtrl.getSocialMediaProfileResponse(acc.Id);
        Test.stoptest();  
        System.assert(result != null, 'Expected result to be not null');
        System.assertEquals(true,result.isSuccess);
    }
    
      @IsTest
    static void testGetSocialMediaResponseSuccessNonIndAcc() {
          Test.setMock(HttpCalloutMock.class, new MockIntegrationCallout());
        Account acc = [Select Id,(SELECT Id,Phone,Email FROM Contacts LIMIT 1) from Account Where Name = 'Test User' Limit 1];
        System.debug('Acc:'+acc);
        Test.starttest();
        ABSLAMC_SprinklrSocialMediaProfileCtrl.responseWrapper result = ABSLAMC_SprinklrSocialMediaProfileCtrl.getSocialMediaProfileResponse(acc.Id);
        Test.stoptest();  
        System.assert(result != null, 'Expected result to be not null');
        System.assertEquals(true,result.isSuccess);
    }

    
}