@SuppressWarnings('PMD.MethodNamingConventions')
@isTest
public class ABSLI_BranchAddressButtonCnt_Test {
	 @testSetup
    static void setupTestData() {
        // Create a non-setup user to insert non-setup objects
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User testUser = new User(
            Alias = 'standt',
            Email = 'bslitestuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'bslitestuser@test.com'
        );
        insert testUser;

        // Insert Branch_Master__c record using non-setup user
        System.runAs(testUser) {
            Branch_Master__c testBranch = new Branch_Master__c(
                Name = 'Test Branch',
                Address__c = '123 Test Street',
                Phone__c = '123-456-7890',
                City__c = 'Test City',
                State__c = 'Test State',
                Pincode__c = '123456',
                UniqueKey__c = '123123'
            );
            insert testBranch;
            // Insert Account
        	Account testAccount = new Account(Name = 'Test Account');
        	insert testAccount;

        	// Insert Contact
        	Contact testContact = new Contact(
            	LastName = 'Test Contact',
            	AccountId = testAccount.Id,
            	MobilePhone = '1234567890'
        	);
        	insert testContact;
		}
        
        EmailTemplate testTemplate = new EmailTemplate(
            Name = 'Test Template',
            DeveloperName = 'Test_Template',
            Body = '<html><body>Hello, {!(User.FirstName)},</body></html>',
            HtmlValue = '<html><body>Hello, {!(User.FirstName)},</body></html>',
            Subject = 'Test Subject',
            FolderId = UserInfo.getUserId(),
            TemplateType = 'Custom'
        );
        insert testTemplate;
    }
	

    @isTest
    static void testGetBranchDetails() {
       
        Branch_Master__c testBranch = [SELECT Id FROM Branch_Master__c LIMIT 1];
        
        Test.startTest();
        Branch_Master__c branchDetails = ABSLI_BranchAddressButtonController.getBranchDetails(testBranch.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, branchDetails, 'Branch details should not be null');
        System.assertEquals('Test Branch', branchDetails.Name, 'Branch name should match');
    }

    @isTest
    static void testGetTemplateBody() {
        Branch_Master__c testBranch = [SELECT Id FROM Branch_Master__c LIMIT 1];
     
        Test.startTest();
        String templateBody = ABSLI_BranchAddressButtonController.getTemplateBody(UserInfo.getUserId(), testBranch.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, templateBody, 'Template body should not be null');
    }
    
    @isTest
    static void testSendCommunication() {
        // Query the test account and branch created in the test setup
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Branch_Master__c testBranch = [SELECT Id FROM Branch_Master__c LIMIT 1];
        Contact testContact = [SELECT Id, MobilePhone FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];

        // Call the method and verify the results
        Test.startTest();
        ABSLI_BranchAddressButtonController.sendCommunication(testAccount.Id, testBranch.Id, null);
        Test.stopTest();

        // Verify that the ASF_Communication_Log__c was created
        ASF_Communication_Log__c[] logs = [SELECT Id, Account__c, Contact__c, Phone__c, Status__c FROM ASF_Communication_Log__c WHERE Account__c = :testAccount.Id];
        System.assertEquals(1, logs.size(), 'One communication log should be created.');
        ASF_Communication_Log__c log = logs[0];
        System.assertEquals(testAccount.Id, log.Account__c, 'Account ID should match.');
        System.assertEquals(testContact.Id, log.Contact__c, 'Contact ID should match.');
        System.assertEquals(testContact.MobilePhone, log.Phone__c, 'Phone number should match.');
        System.assertEquals('In Progress', log.Status__c, 'Status should be "In Progress".');

        
    }
}