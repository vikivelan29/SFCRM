@isTest
public class ABSLI_RemoveAccountTeamBatchTest {
    
    @testSetup
    static void setup() {
        // Create test data for UserRole
        UserRole userRole = [SELECT Id FROM UserRole WHERE DeveloperName = 'ABSLI_Virtual_Relationship_Manager' LIMIT 1];
        
        // Create test data for Users
        User testUser = new User(Username = 'testuserforABSLI@example.com', 
                                 LastName = 'Test', 
                                 Email = 'testuserforABSLI@example.com', 
                                 Alias = 'tuser1', 
                                 TimeZoneSidKey = 'GMT', 
                                 LocaleSidKey = 'en_US', 
                                 EmailEncodingKey = 'UTF-8', 
                                 ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
                                 UserRoleId = userRole.Id,
                                 LanguageLocaleKey = 'en_US');
        insert testUser;
        
         System.runAs(testUser) {
         	// Create test data for Accounts
            Account testAccount1 = new Account(Name = 'Test Account 1');
            Account testAccount2 = new Account(Name = 'Test Account 2');
            insert new List<Account> { testAccount1, testAccount2 };
            
            // Create test data for Assets
            Asset testAsset1 = new Asset(Name = 'Test Asset 1', AccountId = testAccount1.Id, Assign_to_DM__c = 'Yes');
            Asset testAsset2 = new Asset(Name = 'Test Asset 2', AccountId = testAccount2.Id, Channel__c = 'DM');
            insert new List<Asset> { testAsset1, testAsset2 };
            
            // Create test data for AccountTeamMember
            AccountTeamMember atm1 = new AccountTeamMember(AccountId = testAccount1.Id, UserId = testUser.Id, TeamMemberRole = 'ABSLI Virtual Relationship Manager');
            AccountTeamMember atm2 = new AccountTeamMember(AccountId = testAccount2.Id, UserId = testUser.Id, TeamMemberRole = 'ABSLI Virtual Relationship Manager');
            insert new List<AccountTeamMember> { atm1, atm2 };    
        }
        
        
    }

    @isTest
    static void testBatchableMethods() {

        Test.startTest();
        
        ABSLI_RemoveAccountTeamBatch batch = new ABSLI_RemoveAccountTeamBatch();
        Database.executeBatch(batch);

        Test.stopTest();
        
        // Verify the AccountTeamMember records
        List<AccountTeamMember> remainingAccountTeamMembers = [SELECT Id, AccountId, UserId FROM AccountTeamMember];
        System.assertEquals(2, remainingAccountTeamMembers.size(), 'There should be 2 AccountTeamMember records remaining');
        
        Set<Id> remainingAccountIds = new Set<Id>();
        for (AccountTeamMember atm : remainingAccountTeamMembers) {
            remainingAccountIds.add(atm.AccountId);
        }

        // Check that the remaining AccountTeamMember records are for accounts 1 and 2
        System.assert(remainingAccountIds.contains([SELECT Id FROM Account WHERE Name = 'Test Account 1'].Id), 'Account 1 should have AccountTeamMember');
        System.assert(remainingAccountIds.contains([SELECT Id FROM Account WHERE Name = 'Test Account 2'].Id), 'Account 2 should have AccountTeamMember');
    }
    
    @isTest
    static void testSchedulable() {
        Test.startTest();
        
        // Schedule the batch job
        ABSLI_RemoveAccountTeamBatch batch = new ABSLI_RemoveAccountTeamBatch();
        String jobId = System.schedule('Test ABSLI Remove Account Team Batch Job', '0 0 0 1 1 ? 2050', batch);
        Test.stopTest();
        
        // Verify the scheduled job
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals('0 0 0 1 1 ? 2050', ct.CronExpression, 'Cron expression should match the scheduled time');
        System.assertEquals(0, ct.TimesTriggered, 'Job should not have triggered yet');
    }
}