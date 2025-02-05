@isTest
private class CaseEmailBatchTest {
    
    @testSetup
    static void setup() {
        // Create test Email Template
        /*
        EmailTemplate emailTemplate = new EmailTemplate(
            DeveloperName = 'apologize_email_to_customer_1726208031855',
            Name = 'Test Email Template',
            Subject = 'Self Service Option',
            HtmlValue = '<p>This is a test email body.</p>'
        );
        insert emailTemplate;
        */
        
        // Optional: Create a test User if needed for ownership
        User testUser = new User(
            Username = 'testABCapitaluser3@example.com',
            Email = 'testABCapitaluser3@example.com',
            LastName = 'testABC',
            Alias = 'testuser',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
    }
    
    @isTest
    static void testCaseEmailBatch() {
        // Retrieve setup data
        //EmailTemplate emailTemplate = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'apologize_email_to_customer_1726208031855' LIMIT 1];
        //OrgWideEmailAddress orgWideEmail = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'abctsl.crmteam-noreply@adityabirlacapital.com' LIMIT 1];
        
        // Retrieve record type IDs
        String individualRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Individual').getRecordTypeId();
        String nonIndividualRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Non-Individual').getRecordTypeId();
        
        // Create Accounts with specific record types
        Account individualAccount = new Account(
            LastName = 'Test Individual Account',
            RecordTypeId = individualRecordTypeId,
            PersonEmail = 'individual@example.com'
        );
        
        Account nonIndividualAccount = new Account(
            Name = 'Test Non-Individual Account',
            RecordTypeId = nonIndividualRecordTypeId
        );
        
        insert new List<Account>{individualAccount, nonIndividualAccount};
        
        // Create a Contact for the Non-Individual account
        Contact contact = new Contact(
            LastName = 'Test Contact',
            Email = 'contact@example.com',
            AccountId = nonIndividualAccount.Id
        );
        insert contact;
        
        // Create Cases associated with the Accounts
        Case case1 = new Case(
            Subject = 'Test Case for Individual',
            AccountId = individualAccount.Id,
            Status = 'New'
        );
        
        Case case2 = new Case(
            Subject = 'Test Case for Non-Individual',
            AccountId = nonIndividualAccount.Id,
            Status = 'New'
        );
        
        insert new List<Case>{case1, case2};
        
        // Execute the Batch
        Test.startTest();
        CaseEmailBatch batch = new CaseEmailBatch();
        Database.executeBatch(batch,1);
        Test.stopTest();
        
        
        List<Case> updatedCases = [SELECT Id, Status, Resolution_Comments__c FROM Case];
        for (Case c : updatedCases) {
            //System.assertEquals('Resolved', c.Status, 'Case status should be resolved');
            //System.assertEquals('Self Service', c.Resolution_Comments__c, 'Resolution Comments should be set');
        }
    }
}
