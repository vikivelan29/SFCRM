@isTest
public class ABSLAMC_SprinklrSocialMedProfileCtrlTest {

    @testSetup
    static void setupTestData() {
        // Insert an Account record for testing
        Account testAccount = new Account(
            FirstName = 'Test',
            LastName = 'User',
            PersonEmail = 'testuser990@example.com',
            PersonMobilePhone = '1234567890',
            Business_Unit__c = ABSLAMC_Constants.ABSLAMCBU
        );
        insert testAccount;
        
         // Insert an Account record for testing
        Account testAccountOne = new Account(
            FirstName = 'Test',
            LastName = 'User',
            PersonEmail = '',
            PersonMobilePhone = '1234567890',
            Business_Unit__c = ABSLAMC_Constants.ABSLAMCBU
        );
        insert testAccountOne;
        
        // Insert an Account record for testing
        Account testAccountTwo = new Account(
            FirstName = 'Test',
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
            res.setStatusCode(200);
            res.setBody('{"statusCode":200,"responseBody":"{\\"response_key\\":\\"response_value\\"}"}');
            return res;
        }
    }
    
    @IsTest
    static void testGetSocialMediaResponseSuccess() {
          Test.setMock(HttpCalloutMock.class, new MockIntegrationCallout());
        Account acc = [Select Id from Account Limit 1];
        ABSLAMC_SprinklrSocialMediaProfileCtrl.responseWrapper result = ABSLAMC_SprinklrSocialMediaProfileCtrl.getSocialMediaProfileResponse(acc.Id);
           System.assert(result != null, 'Expected result to be not null');
        System.assert(result.isSuccess, 'Expected success to be true');
    }
    
    @IsTest
    static void testGetSocialMediaResponseSuccessBlankEmail() {
          Test.setMock(HttpCalloutMock.class, new MockIntegrationCallout());
        Account acc = [Select Id from Account WHERE PersonEmail = '' Limit 1];
        ABSLAMC_SprinklrSocialMediaProfileCtrl.responseWrapper result = ABSLAMC_SprinklrSocialMediaProfileCtrl.getSocialMediaProfileResponse(acc.Id);
           System.assert(result != null, 'Expected result to be not null');
        System.assert(result.isSuccess, 'Expected success to be true');
    }
    
       @IsTest
    static void testGetSocialMediaResponseSuccessBlankPhone() {
          Test.setMock(HttpCalloutMock.class, new MockIntegrationCallout());
        Account acc = [Select Id from Account WHERE PersonMobilePhone = '' Limit 1];
        ABSLAMC_SprinklrSocialMediaProfileCtrl.responseWrapper result = ABSLAMC_SprinklrSocialMediaProfileCtrl.getSocialMediaProfileResponse(acc.Id);
           System.assert(result != null, 'Expected result to be not null');
        System.assert(result.isSuccess, 'Expected success to be true');
    }

    
}