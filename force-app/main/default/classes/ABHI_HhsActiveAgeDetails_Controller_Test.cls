/**************
*Class        :  ABHI_HhsActiveAgeDetails_Controller_Test
*Author       :  Kuldeep Mishra
*Created Date :  12/08/2024
*Last Modified:  15/08/2024
*@description  :  This class used as Test class for ABHI_HhsActiveAgeDetails_Controller
***************/
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
    @isTest static void successHhsActiveAge(){
         Account acc = [SELECT id from Account LIMIT 1];
        User testUser = [SELECT id from User where LastName='User ABHI' LIMIT 1];
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new ABHI_HhsActiveAgeDetailsMockHttpResponse());
        System.runAs(testUser){
            Test.startTest();
            ABHI_HhsActiveAgeDetails_Controller.IntegrationResponseWrapper res= ABHI_HhsActiveAgeDetails_Controller.GetHhsActiveAge(acc.Id);
            Test.stopTest();
            System.assertEquals(res.StatusCode, '200', 'Expected status code 200');
            System.assertEquals('Success', res.Message, 'Expected message to be "Success"');

            
        }
        
    }
    @isTest static void failureHhsActiveAge() {
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
        }
            Test.stopTest();
            
    }
    }
    
  // Mock class for successful response  
   @SuppressWarnings('PMD.ApexDoc,PMD.VariableNamingConventions')
    public class ABHI_HhsActiveAgeDetailsMockHttpResponse implements HttpCalloutMock {
        // Http Mock success response 
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
String jsonResponse = '{'
            + '"HHSDetails": {'
                + '"operationStatus": "SUCCESS",'
                + '"serviceMessages": ['
                    + '{'
                        + '"systemCode": "JAVAFSTXSERINF001",'
                        + '"businessCode": "FSTXSERINF001",'
                        + '"businessDesc": "Result found",'
                        + '"serviceMessageType": "INFORMATION",'
                        + '"messageTime": "2024-08-26T11:27:19.019+05:30"'
                    + '}'
                + '],'
                + '"responseMap": {'
                    + '"resultsList": {'
                        + '"gender": "M",'
                        + '"totalFsScore": 7,'
                        + '"startDate": "2023-11-03T00:00:00.00005:30",'
                        + '"expiryDate": "2024-11-02T00:00:00.000+05:30",'
                        + '"scoreDate": "2023-11-03T00:00:00.00005:30",'
                        + '"tierLevelName": "Amber",'
                        + '"customerNumber": "3319509",'
                        + '"activities": ['
                            + '{'
                                + '"name": "Digital Screening Score",'
                                + '"code": "DIGITALSCREENING",'
                                + '"value": "7.0",'
                                + '"score": 7,'
                                + '"effFromDate": "2023-11-03T00:00:00.000+05:30",'
                                + '"effToDate": "2024-11-02T00:00:00.000+05:30",'
                                + '"attributes": ['
                                    + '{ "attributeCode": "SYSTOLIC", "attributeValue": "136" }'
                                + ']'
                            + '},'
                            + '{'
                                + '"name": "AGE",'
                                + '"code": "AGE",'
                                + '"value": "58",'
                                + '"score": 4'
                            + '}'
                        + ']'
                    + '}'
                + '}'
            + '},'
            + '"activeAge": {'
                + '"customerNo": 1187714,'
                + '"actualAge": 35,'
                + '"multiplyAge": 34,'
                + '"heartAge": 35.04,'
                + '"calculationDate": "2021-01-24"'
            + '},'
            + '"StatusCode": 200,'
            + '"Message": "Success"'
        + '}';              res.setBody(jsonResponse);
            res.setStatusCode(200);
            return res;
        }
    }
    
  // Mock class for failure response
  @SuppressWarnings('PMD.ApexDoc,PMD.VariableNamingConventions')
    public class ABHI_HhsActiveAgeDetailsFailureResponseGenerator implements HttpCalloutMock {
       
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
			/*res.setBody('{"StatusCode": "1001","Message": "FALevelDetails Failure"}'
                        );
          
            res.setStatusCode(400);*/
            String failureResponse = '{"ReturnCode":"2","ReturnMessage":"Nodatafound"}';
            res.setBody(failureResponse);
            res.setStatusCode(1001);
            return res;
        }
    }
    
     @isTest
    static void testIntegrationResponseWrapperConstructor() {
        // Test the constructor directly
        ABHI_HhsActiveAgeDetails_Controller.IntegrationResponseWrapper wrapper = new ABHI_HhsActiveAgeDetails_Controller.IntegrationResponseWrapper('200', 'Success');
 System.debug('Wrapper Message: ' + wrapper.Message);
        // Assert that the values are set correctly
        System.assertEquals('200', wrapper.StatusCode, 'StatusCode should be 1000');
        System.assertEquals('Success', wrapper.Message, 'Message should be Success');
    }
    
    
}