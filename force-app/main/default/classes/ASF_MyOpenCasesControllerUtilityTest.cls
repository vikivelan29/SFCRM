@isTest(SeeAllData = false)
public class ASF_MyOpenCasesControllerUtilityTest {
    @testSetup
    static void setupTestData() {
        // Create a test user to assign as the case owner
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tstuser',
            Email = 'testuser@example.com',
            Username = 'testuser0909@example.com.' + System.currentTimeMillis(),
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            Business_Unit__c = 'ABSLAMC'
        );
        insert testUser;

        // Create test Account for association with cases
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create Case records with different stages
        List<Case> cases = new List<Case>{
            new Case(AccountId = testAccount.Id, Stage__c = 'Open', OwnerId = testUser.Id, Business_Unit__c = 'ABSLAMC'),
            new Case(AccountId = testAccount.Id, Stage__c = 'Approval', OwnerId = testUser.Id, Business_Unit__c = 'ABSLAMC'),
            new Case(AccountId = testAccount.Id, Stage__c = 'Reply Received from App Support', OwnerId = testUser.Id, Business_Unit__c = 'ABSLAMC'),
            new Case(AccountId = testAccount.Id, Stage__c = 'Pending with CAMS', OwnerId = testUser.Id, Business_Unit__c = 'ABSLAMC'),
            new Case(AccountId = testAccount.Id, Stage__c = 'Reply Received from CAMS', OwnerId = testUser.Id, Business_Unit__c = 'ABSLAMC')
        };
        insert cases;
    }

    @isTest(SeeAllData = false)
    static void testGetCasesGroupedByStage() {
        // Get the test user ID
        User testUser = [SELECT Id,Business_Unit__c FROM User WHERE Alias = 'tstuser' LIMIT 1];
        // Call the method
        Map<String, List<Case>> result = ASF_MyOpenCasesControllerUtility.getOpenCasesByOwner(testUser.Id);

        // Verify the results
        System.assertNotEquals(null, result, 'Expected non-null map of cases grouped by stage');
        // Verify that each stage has the expected number of cases
        System.assertEquals(1, result.get('Open').size(), 'Expected 2 cases in "Open" stage');
        System.assertEquals(1, result.get('Approval').size(), 'Expected 2 cases in "Approval" stage');
        System.assertEquals(1, result.get('Pending with CAMS').size(), 'Expected 1 case in "Pending with CAMS" stage');

        // Verify case details in one of the stages
        Case newCase = result.get('Open')[0];
        System.assertEquals('Open', newCase.Stage__c, 'Case stage should be "New"');
        System.assertNotEquals(null, newCase.CaseNumber, 'Case should have a CaseNumber');
        System.assertNotEquals(null, newCase.Account.Name, 'Case should have an Account Name');
    }
}