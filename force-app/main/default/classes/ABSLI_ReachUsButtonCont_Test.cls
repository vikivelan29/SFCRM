@SuppressWarnings('PMD.MethodNamingConventions')
@isTest
public class ABSLI_ReachUsButtonCont_Test {
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
                UniqueKey__c = '234234'
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
            
            // Create test assets
        	Asset asset1 = new Asset(Name = 'Asset 1', AccountId = testAccount.Id);
        	Asset asset2 = new Asset(Name = 'Asset 2', AccountId = testAccount.Id);
        	insert new List<Asset>{ asset1, asset2 };
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
    static void testGetTemplateBody() {
        Asset testAsset = [SELECT Id FROM Asset LIMIT 1];
     
        Test.startTest();
        String templateBody = ABSLI_ReachUsButtonController.getTemplateBody(testAsset.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, templateBody, 'Template body should not be null');
    }
    
    @isTest
    static void testSendCommunication() {
        // Query the test account and branch created in the test setup
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Asset testAsset = [SELECT Id FROM Asset LIMIT 1];
        Contact testContact = [SELECT Id, MobilePhone FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];

        // Call the method and verify the results
        Test.startTest();
        ABSLI_ReachUsButtonController.sendCommunication(testAccount.Id,'1234567890');
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