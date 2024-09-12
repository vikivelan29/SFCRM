@isTest
public class ABHI_HhsActiveAgeDetails_Controller_Test {
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
    
    @isTest static void Success_HhsActiveAge(){
         Account acc = [SELECT id from Account LIMIT 1];
        User testUser = [SELECT id from User where LastName='User ABHI' LIMIT 1];
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new ABHI_HhsActiveAgeDetailsMockHttpResponse());
        System.runAs(testUser){
            Test.startTest();
            ABHI_HhsActiveAgeDetails_Controller.IntegrationResponseWrapper res= ABHI_HhsActiveAgeDetails_Controller.GetHhsActiveAge(acc.Id);
            Test.stopTest();
            System.assertEquals('1000', res.StatusCode, 'code');
            
        }
        
    }
    
    @isTest static void Failure_HhsActiveAge() {
        Account acc = [SELECT id from Account LIMIT 1];
        User testUser = [SELECT id from User where LastName='User ABHI' LIMIT 1];
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new ABHI_HhsActiveAgeDetailsFailureResponseGenerator());
        System.runAs(testUser){
            Test.startTest();
            try{
                ABHI_HhsActiveAgeDetails_Controller.IntegrationResponseWrapper res= ABHI_HhsActiveAgeDetails_Controller.GetHhsActiveAge(acc.Id);
            }catch (AuraHandledException e) {
                // Assert that the exception message contains expected information
                System.assert(e.getMessage().contains('Error'), 'Exception message should contain "Error"');
            //System.assertEquals('400', res.StatusCode, 'code');  
        }
            Test.stopTest();
    }
    }
    
  // Mock class for successful response  
    public class ABHI_HhsActiveAgeDetailsMockHttpResponse implements HttpCalloutMock {
        // Http Mock success response 
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(
                '{"HHSDetails":{"operationStatus":"SUCCESS","serviceMessages":[{"systemCode":"JAVAFSTXSERINF001","businessCode":"FSTXSERINF001","businessDesc":"Result found","serviceMessageType":"INFORMATION","messageTime":"2024-07-24T14:49:34.034+05:30"}],"responseMap":{"resultsList":{"gender":"M","totalFsScore":7,"startDate":"2023-11-03T00:00:00.000+05:30","expiryDate":"2024-11-02T00:00:00.000+05:30","scoreDate":"2023-11-03T00:00:00.000+05:30","tierLevelName":"Amber","customerNumber":"3319509","activities":[{"name":"Digital Screening Score","code":"DIGITALSCREENING","value":"7.0","score":7,"effFromDate":"2023-11-03T00:00:00.000+05:30","effToDate":"2024-11-02T00:00:00.000+05:30","attributes":[{"SYSTOLIC":"","EA_DATE_OF_BIRTH":"","BMI":"","AGE":"","DIASTOLIC":"","SOURCENAME":"","EA_GENDER":"","SMOKING_STATUS":"","DIABETES":""}]},{"name":"AGE","code":"AGE","value":"58","score":4}]},"activeAge":{"customerNo":1187714,"actualAge":35,"multiplyAge":34,"heartAge":35.04,"calculationDate":"2021-01-24"},"StatusCode":"1000","Message":"Succes"'
                );
            res.setStatusCode(1000);
            return res;
        }
    }
    
  // Mock class for failure response
    public class ABHI_HhsActiveAgeDetailsFailureResponseGenerator implements HttpCalloutMock {
       
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
			/*res.setBody('{"StatusCode": "1001","Message": "FALevelDetails Failure"}'
                        );
          
            res.setStatusCode(400);*/
            String s = '{\"ReturnCode\":\"2\",\"ReturnMessage\":\"Nodatafound\"}';
            res.setBody(s);
            res.setStatusCode(400);
            return res;
        }
    }
    
     @isTest
    static void TestIntegrationResponseWrapperConstructor() {
        // Test the constructor directly
        ABHI_HhsActiveAgeDetails_Controller.IntegrationResponseWrapper wrapper = new ABHI_HhsActiveAgeDetails_Controller.IntegrationResponseWrapper('1000', 'Success');
        
        // Assert that the values are set correctly
        System.assertEquals('1000', wrapper.StatusCode, 'StatusCode should be 1000');
        System.assertEquals('Success', wrapper.Message, 'Message should be Success');
    }
    
    
}