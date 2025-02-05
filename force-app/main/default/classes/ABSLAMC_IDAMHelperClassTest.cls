@isTest
public class ABSLAMC_IDAMHelperClassTest {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name = 'System Administrator' LIMIT 1];
    
    @TestSetup
    static void makeData(){
        ASF_TriggerSkipperUtility.markTriggerRun('User');
        
        Test.enableChangeDataCapture();
        User userRecord1 = new User(
            Alias = 'standt', 
            Email = 'stanrduseremails@testorg.com',
            Old_Email__c = 'stanrduseremails@testorg.com',
            EmailEncodingKey = 'UTF-8',
            Business_Unit__c = ABSLAMC_Constants.ABSLAMCBU,
            LOB__c = 'MF',
            LastName = 'Testing', 
            LanguageLocaleKey = 'en_US', 
            LocaleSidKey = 'en_US', 
            ProfileId = SYSTEMADMIN_PROFILE.Id, 
            TimeZoneSidKey = 'America/Los_Angeles', 
            UserName = 'cdefghijk567ABSLAMCTestUser@gmail.com'
        );
        insert userRecord1;
        Test.getEventBus().deliver();
        
        Account accountRecord = new Account();
        accountRecord.Name = 'Test Account';
        accountRecord.Handle_With_Care_HWC__c = ABSLAMC_Constants.Y;
        accountRecord.HWC_Reason__c = ABSLAMC_Constants.ABSLAMC_HWC_REASON_SOCIAL_MEDIA;
        insert accountRecord;
        
        Case newCase = new Case();
        newCase.AccountId = accountRecord.Id;
        newCase.Subject = 'Test Case Creation';
        newCase.CCC_External_Id__c = '';
        newCase.Source__c = 'Email';
        newCase.Stage__c = 'Open';
        newCase.SuppliedEmail = 'a.balasubramanian@adityabirlacapital.com';
        newCase.Business_Unit__c = 'ABSLAMC';
        newCase.OwnerId = userRecord1.Id;
        newCase.SLA_Target_1__c = 'stanrduseremails@testorg.com';
        newCase.SLA_Target_2__c = 'stanrduseremails@testorg.com';
        newCase.SLA_Target_3__c = 'stanrduseremails@testorg.com';

        newCase.origin = 'ABSLAMC Email';
        insert newCase;
    }

    @IsTest(seeAllData = false)
    static void populateOldEmailTest() {
        Test.startTest();
        User userRecord2 = new User(
            Alias = 'standt2', 
            Email = 'stanrduserEmails2@testorg.com', 
            EmailEncodingKey = 'UTF-8',
            Business_Unit__c = ABSLAMC_Constants.ABSLAMCBU,
            LOB__c = 'MF',
            LastName = 'Testing', 
            LanguageLocaleKey = 'en_US', 
            LocaleSidKey = 'en_US', 
            ProfileId = SYSTEMADMIN_PROFILE.Id, 
            TimeZoneSidKey = 'America/Los_Angeles', 
            UserName = 'cdefghijk5678ABSLAMC@gmail.com'
        );

        insert userRecord2;
        Test.stopTest();

        User updatedUserRecord = [SELECT Id,Email,Old_Email__c FROM User WHERE Id = :userRecord2.Id];

        Assert.areEqual(updatedUserRecord.Email, updatedUserRecord.Old_Email__c, 'Old Email should have been populated on user record');
    }

    @IsTest(seeAllData = false)
    static void handleLOBChangesTest() {
        User userRecord = [SELECT Id FROM User WHERE UserName = 'cdefghijk567ABSLAMCTestUser@gmail.com'];

        Test.startTest();
        userRecord.LOB__c = 'RE;PMS';
        update userRecord;
        Test.stopTest();
        
        List<GroupMember> groupMemberList  = [SELECT Id,GroupId, UserOrGroupId, Group.Name FROM GroupMember WHERE UserOrGroupId = :userRecord.Id];

        Assert.areEqual(2, groupMemberList.size(), 'The user should have been a member of 2 groups.');
    }

    @IsTest(seeAllData = false)
    static void evaluateSLATargetUpdatesTest() {
        User userRecord2 = new User(
            Alias = 'standt2', 
            Email = 'stanrduserEmails2@testorg.com', 
            EmailEncodingKey = 'UTF-8',
            Business_Unit__c = ABSLAMC_Constants.ABSLAMCBU,
            LastName = 'Testing', 
            LanguageLocaleKey = 'en_US', 
            LocaleSidKey = 'en_US', 
            ProfileId = SYSTEMADMIN_PROFILE.Id, 
            TimeZoneSidKey = 'America/Los_Angeles', 
            UserName = 'cdefghijk567ABSLAMCTestUser8@gmail.com'
        );

        insert userRecord2;

        User userRecord = [SELECT Id FROM User WHERE UserName = 'cdefghijk567ABSLAMCTestUser@gmail.com'];
        
        Test.startTest();
        userRecord.ManagerId = userRecord2.Id;
        update userRecord;
        Test.stopTest();

        List<Case> caseList = [SELECT Id, OwnerId, SLA_Target_1__c, SLA_Target_2__c, SLA_Target_3__c FROM Case WHERE IsClosed = FALSE AND ( SLA_Target_1__c ='stanrduserEmails2@testorg.com')];

        Assert.areEqual(1, caseList.size(), 'The SLA_Target_1__c on case should have been updated');
    }
    
    @IsTest(seeAllData = false)
    static void updateSLATargetsOnUserEmailChangeTest() {
        User userRecord = [SELECT Id,Email FROM User WHERE UserName = 'cdefghijk567ABSLAMCTestUser@gmail.com'];
        
        Test.enableChangeDataCapture(); 
        Test.startTest();
        userRecord.Email = 'cdefghijk5678ABSLAMC@gmail.com';
        update userRecord;
		Test.getEventBus().deliver();
        Test.stopTest();
        
        List<Case> caseList = [SELECT Id, OwnerId, SLA_Target_1__c, SLA_Target_2__c, SLA_Target_3__c FROM Case WHERE IsClosed = FALSE AND (SLA_Target_1__c ='cdefghijk5678ABSLAMC@gmail.com')];

        Assert.areEqual(1, caseList.size(), 'The SLA_Target_1__c on case should have been updated');
    }
}