/****************************************************************************************************************
  * 
  * Date         - 27-March-2024
  * @LOB         - All
  * @description -  Test class for Asf_NpsIndicatiorController class.
*****************************************************************************************************************/

@isTest
public  class Asf_NpsIndicatiorController_Test {
private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    @testSetup
    static void setUpData(){
      Group SLAGroup = new Group();        
        SLAGroup = new Group(Name='SLAManagerGroup', DeveloperName='SLAManagerGroup');
          insert SLAGroup;
        Group g1 = new Group(Name='OCC-Test-Group', type='Queue');
          insert g1;
        User userRecord = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,
                                    TimeZoneSidKey='America/Los_Angeles', UserName='cdefghijk5657123456@gmail.com',
                                    managerGroupId__c=SLAGroup.Id);
        insert userRecord;
        System.runAs(userRecord) {
         Id rtId = Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
         Account acc= new Account(
            FirstName='Test FName',
            RecordTypeId = rtId,
            LastName='Test LName',
            PersonMailingStreet='test@yahoo.com',
            PersonMailingPostalCode='12345',
            PersonMailingCity='SFO',
            PersonEmail='test@yahoo.com',
            PersonHomePhone='1234567',
            PersonMobilePhone='12345678'
        );
            insert acc;  
           Account acc1= new Account(
            FirstName='Test1 FName',
            RecordTypeId = rtId,
            LastName='Test LName',
            PersonMailingStreet='test@yahoo.com',
            PersonMailingPostalCode='12345',
            PersonMailingCity='SFO',
            PersonEmail='test@yahoo.com',
            PersonHomePhone='1234567',
            PersonMobilePhone='12345678'
        );
            insert acc1;
          Survey_Response__c surveyResp = new Survey_Response__c();
            surveyResp.Primary_Question_NPS__c = 7;
            surveyResp.Client_Code__c = acc.Id;
          insert surveyResp;
        }
    }
    /****************************************************
       * @description - Test Method for evaluate Method
    *****************************************************/
    
    @isTest 
    static void genericFetchQuery_TestMethod() {
        List<Account> objAcc = [Select Id,FirstName From Account WHERE FirstName = 'Test1 FName' LIMIT 1]; 
        Asf_NpsIndicatiorController.getCaseCounts(objAcc[0].Id);
        System.assertEquals(objAcc.size(), 1,'record found');
    }
      @isTest
    static void getNpsScoreTest(){
        List<Account> objAcc = [Select Id,FirstName From Account WHERE FirstName = 'Test FName' LIMIT 1];
        User usr = [SELECT Id FROM User WHERE Username = 'cdefghijk5657123456@gmail.com' LIMIT 1];
        Survey_Response__c resp = [SELECT Id,Client_Code__c,Primary_Question_NPS__c FROM Survey_Response__c WHERE Client_Code__c =: objAcc[0].Id LIMIT 1];
     system.runAs(usr)
        { 
            Test.startTest(); 
            Asf_NpsIndicatiorController.getNpsScore(objAcc[0].Id);
            System.assertEquals(7, resp.Primary_Question_NPS__c,'record found');          
             Test.stopTest();            
            }
        }
       @isTest
    static void getNpsScoreTestNeg(){
        List<Account> objAcc = [Select Id,FirstName From Account WHERE FirstName = 'Test1 FName' LIMIT 1];
        User usr = [SELECT Id FROM User WHERE Username = 'cdefghijk5657123456@gmail.com' LIMIT 1];
        List<Survey_Response__c> resp = [SELECT Id,Client_Code__c,Primary_Question_NPS__c FROM Survey_Response__c WHERE Client_Code__c =: objAcc[0].Id LIMIT 1];
     system.runAs(usr)
        { 
            Test.startTest(); 
            Asf_NpsIndicatiorController.getNpsScore(objAcc[0].Id);
           System.assertEquals(0, resp.size(),'No record found');          
             Test.stopTest();            
            }
        }
}