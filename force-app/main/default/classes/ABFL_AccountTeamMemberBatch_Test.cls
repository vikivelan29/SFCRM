/*********************************************************
*Class        :  ABFL_AccountTeamMemberBatch_Test
*Author       :  Shubham Sinha 
*Created Date :  18/01/2024
*Description  :  Test Class of ABFL_AccountTeamMemberBatch
*********************************************************/
@isTest
public class ABFL_AccountTeamMemberBatch_Test {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    @testSetup
    static void setUpData(){
    	Group SLAGroup = new Group();        
        SLAGroup = new Group(Name='SLAManagerGroup', DeveloperName='SLAManagerGroup');
        	insert SLAGroup;
        Group g1 = new Group(Name='OCC-Test-Group', type='Queue');
        	insert g1;
        UserRole role = [SELECT Id FROM UserRole WHERE DeveloperName = 'ABFL_Sales' LIMIT 1];
        User userRecord = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,
                                    TimeZoneSidKey='America/Los_Angeles',FederationIdentifier='FED12345', UserName='cdefghijk567@gmail.com',
                                    managerGroupId__c=SLAGroup.Id,UserRoleId  = role.Id);
        insert userRecord;
        User userRecord1 = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,Business_Unit__c = 'ABFL',
                                    TimeZoneSidKey='America/Los_Angeles',FederationIdentifier='FED12346',UserRoleId  = role.Id, UserName='cdefghijk5657@gmail.com'
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
            assetObj.RM_Code__c = 'FED12346';
            assetObj.RM_Assignment__c = 'Pending';
            assetObj.Business_Unit__c ='ABFL';
            insert assetObj;
        }
    }
     @isTest
    static void beforeUpdateContainsABFLTest(){
        User usr = [SELECT Id FROM User WHERE Username = 'cdefghijk567@gmail.com' LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE LastName = 'Test LName' LIMIT 1];
 		system.runAs(usr)
        { 
           Test.startTest(); 
           ABFL_AccountTeamMemberBatch batch= new ABFL_AccountTeamMemberBatch();
           	Id jobid= Database.executeBatch(batch,5);         
           Test.stopTest();    
           List<AccountTeamMember> insertedTeamMembers = [SELECT Id FROM AccountTeamMember Where AccountId =: acc.Id ];
		   System.assertEquals( 1, insertedTeamMembers.size(), 'Account team member found');

         }
    }
}