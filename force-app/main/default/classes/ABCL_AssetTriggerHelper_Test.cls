/*********************************************************
*Class        :  ABCL_AssetTriggerHelper
*Author       :  Shubham Sinha 
*Created Date :  17/01/2024
*@description  :  Test Class
*********************************************************/
@isTest
public class ABCL_AssetTriggerHelper_Test {
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
                                    TimeZoneSidKey='America/Los_Angeles', UserName='cdefghijk5657123456@gmail.com',
                                    managerGroupId__c=slaGroup.Id);
        insert userRecord;
        User userRecord1 = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,Business_Unit__c = 'ABFL',
                                    TimeZoneSidKey='America/Los_Angeles', UserName='cdefghijk565712345@gmail.com'
                                    );
        insert userRecord1;
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
            Asset assetObj = new Asset();
            assetObj.Name = '981726345';
            assetObj.AccountId = acc.Id;
            assetObj.RM_Assignment__c = 'Processed';
            assetObj.Business_Unit__c ='ABFL';
            insert assetObj;
        }
    }
      @isTest
    static void beforeUpdateContainsABFLTest(){
        List<Asset> objAsset = [Select Id,Business_Unit__c,RM_Code__c From Asset WHERE Business_Unit__c = 'ABFL' LIMIT 1];
        User usr = [SELECT Id FROM User WHERE Username = 'cdefghijk5657123456@gmail.com' LIMIT 1];
 		system.runAs(usr)
        { 
            Test.startTest(); 
            objAsset[0].RM_Code__c= '12345';
            update objAsset[0]; 
            System.assertEquals(1, objAsset.size(),'record found');          
             Test.stopTest();            
            }
        }
}