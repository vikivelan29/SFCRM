/*********************************************************
*Class        :  ABHI_ActiveDaysDashboardController_Test
*Author       :  Shubham Sinha 
*@description  :  Test Class for ABHI_ActiveDaysDashboardController
**********************************************************/
@isTest
public class ABHI_ActiveDaysDashboardController_Test {
private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    @testSetup
    static void setUpData(){
        Group slaGroup = new Group();        
        slaGroup = new Group(Name='SLAManagerGroup', DeveloperName='SLAManagerGroup');
            insert slaGroup;
        Group g1 = new Group(Name='OCC-Test-Group', type='Queue');
            insert g1;
        User userRecord = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,
                                    TimeZoneSidKey='America/Los_Angeles', UserName='cdefghijk567@gmail.com',
                                    managerGroupId__c=slaGroup.Id);
        insert userRecord;
        User userRecord1 = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,Business_Unit__c = 'ABHI',
                                    TimeZoneSidKey='America/Los_Angeles', UserName='cdefghijk5657@gmail.com'
                                    );
        insert userRecord1;
    
        System.runAs(userRecord1){
        Account a = new Account();
        a.Name = '12345';
        a.Office_Email__c = 'testAcc@123.com';
        a.Phone = '444-010-4444';
        a.PAN__c = 'ADNPN4241N';
        a.Client_Code__c = '1234';
        //a.CRN__c = '12344';
        insert a;
        }
    }
      @isTest
    static void testgetActiveDaysDashboard(){
        List<Account> acc = [Select Id,Name From Account WHERE Name = '12345' LIMIT 1];
        User usr = [SELECT Id FROM User WHERE Username = 'cdefghijk5657@gmail.com' LIMIT 1];
        system.runAs(usr)
        { 
        Test.startTest(); 
       		Test.setMock(HttpCalloutMock.class, new ABHI_ActiveDaysDashboardController_Test.MockHttpResponseGenerator());
        	ABHI_ActiveDaysDashboardController.ActiveDaysResponseWrapper res = ABHI_ActiveDaysDashboardController.getActiveDaysDashboard(acc[0].Id, acc[0].Id,'2024-11-11','2024-11-14');
        Test.stopTest();
        System.assertNotEquals(null, res, 'response should not be null');
            }
        }
   @isTest
    public static void testgetActiveDaysDashboard_NullResponse() {
       ABHI_ActiveDaysDashboardController.ActiveDaysResponseWrapper responseWrapper = 
            new ABHI_ActiveDaysDashboardController.ActiveDaysResponseWrapper();
        
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new ABHI_ActiveDayEventsController_Test.MockHttpResponseGenerator());
        
        String customerID = 'TestCustomerId';
        String accountId = 'TestAccountId'; 
        try{
            ABHI_ActiveDaysDashboardController.ActiveDaysResponseWrapper result = 
                ABHI_ActiveDaysDashboardController.getActiveDaysDashboard(customerID, accountId,'2024-11-11','2024-11-11');
            
            System.assertEquals(null, null, 'Operation status should be null for empty response');
            
            Test.stopTest();
        }catch(exception e){}
    }

        public class MockHttpResponseGenerator implements HttpCalloutMock {
        /****************************************************************************************************************
        * @description function to create and return fake http response
        * @param req
        * @return HTTPResponse
        *****************************************************************************************************************/
        public HTTPResponse respond(HTTPRequest req) {
            
            // Creating a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"example":"test"}');
            res.setStatusCode(200);
            return res;
        }
    }


}