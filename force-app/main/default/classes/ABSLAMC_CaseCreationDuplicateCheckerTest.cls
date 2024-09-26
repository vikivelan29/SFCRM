@isTest
public class ABSLAMC_CaseCreationDuplicateCheckerTest {
    
    @testSetup
    static void setupData() {
        
        Profile nonAdminProfile = [SELECT Id FROM Profile WHERE Name = 'ABSLAMC Base User' LIMIT 1];
        
        User nonAdminUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser@example.com' + System.currentTimeMillis(),
            Alias = 'test',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = nonAdminProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert nonAdminUser;
        
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        User adminUser = new User(
            FirstName = 'Admin',
            LastName = 'User',
            Email = 'adminuser@example.com',
            Username = 'adminuser@example.com' + System.currentTimeMillis(),
            Alias = 'admin',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = adminProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert adminUser;
        
        System.runAs(nonAdminUser) {
            Account testAccount = new Account(
                Name = 'Test Account'
            );
            insert testAccount;
            
            Asset testAsset = new Asset(
                Name = 'Test Asset',
                AccountId = testAccount.Id
            );
            insert testAsset;
            
            Case existingCase = new Case(
                CCC_External_Id__c = '12345',
                Type_text__c = 'Support',
                Sub_Type_Text__c = 'Technical',
                AccountId = testAccount.Id,
                AssetId = testAsset.Id,
                Status = 'New',
                Source__c = 'Email'
            );
            insert existingCase;
        }
    }
    @isTest
    static void testDuplicateCheckWithNonAdmin() {
        
        User testUser = [Select Id from user where Email = 'testuser@example.com' Limit 1];
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Asset testAsset = [SELECT Id FROM Asset WHERE Name = 'Test Asset' LIMIT 1];
        
        // Run the logic as the non-admin user
        System.runAs(testUser) {
            
            // Create a new case to trigger the duplicate logic
            Case newCase = new Case(
                CCC_External_Id__c = '12345',
                Type_text__c = 'Support',
                Sub_Type_Text__c = 'Technical',
                AccountId = testAccount.Id,
                AssetId = testAsset.Id,
                Status = 'New'
            );
            
            List<Case> newCases = new List<Case>{ newCase };
                
                Test.startTest();
            ABSLAMC_CaseCreationDuplicateChecker.runDuplicateCheck2(newCases);
            Test.stopTest();
            
            // Verify that the duplicate case error is triggered
            System.assertEquals(1, newCase.getErrors().size(), 'There should be one duplicate error');
            System.assertEquals('Duplicate case: A case with same criteria is already open with source as Email', 
                                newCase.getErrors()[0].getMessage(), 'Duplicate error message should match');
        }
    }
    
    @isTest
    static void testDuplicateCheckWithAdmin() {
        // Get the system admin user from test setup
        User adminUser = [SELECT Id FROM User WHERE Alias = 'admin' LIMIT 1];
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Asset testAsset = [SELECT Id FROM Asset WHERE Name = 'Test Asset' LIMIT 1];
        
        System.runAs(adminUser) {
            // Create a case to test the duplicate logic
            Case newCase = new Case(
                CCC_External_Id__c = '12345',
                Type_text__c = 'Support',
                Sub_Type_Text__c = 'Technical',
                AccountId = testAccount.Id,
                AssetId = testAsset.Id,
                Status = 'New'
            );
            
            List<Case> newCases = new List<Case>{ newCase };
          
                Test.startTest();
            ABSLAMC_CaseCreationDuplicateChecker.runDuplicateCheck2(newCases);
            Test.stopTest();
            
            // Verify that no errors are added for system admin
            System.assertEquals(0, newCase.getErrors().size());
        }
    }
    
    @isTest
    static void testNoDuplicateCase() {
        // Get the non-admin user from test setup
        User nonAdminUser = [SELECT Id FROM User WHERE Alias = 'test' LIMIT 1];
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Asset testAsset = [SELECT Id FROM Asset WHERE Name = 'Test Asset' LIMIT 1];
        
        System.runAs(nonAdminUser) {
            // Create a case that doesn't match the existing case
            Case newCase = new Case(
                CCC_External_Id__c = '54321',
                Type_text__c = 'Support',
                Sub_Type_Text__c = 'Billing',
                AccountId = testAccount.Id,
                AssetId = testAsset.Id,
                Status = 'New'
            );
            
            List<Case> newCases = new List<Case>{ newCase };
                
                
                Test.startTest();
            ABSLAMC_CaseCreationDuplicateChecker.runDuplicateCheck2(newCases);
            Test.stopTest();
            
            // Verify that no errors are added since this is not a duplicate
            System.assertEquals(0, newCase.getErrors().size());
        }
    }
}