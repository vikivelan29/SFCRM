@SuppressWarnings('PMD.MethodNamingConventions')
@isTest
public class ABSLI_FundValueCompController_Test {
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
                UniqueKey__c = '324234'
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
        	Asset asset1 = new Asset(Name = 'Asset 1', AccountId = testAccount.Id,Type__c = 'ULIP',Business_Unit__c = 'ABSLI');
        	Asset asset2 = new Asset(Name = 'Asset 2', AccountId = testAccount.Id,Type__c = 'ULIP',Business_Unit__c = 'ABSLI');
        	insert new List<Asset>{ asset1, asset2 };
                
            ASF_Quick_Link_Config__mdt qkCommMdt = [SELECT ID, FunctionName__c ,FunctionCode__c,SMSMetadataName__c 
                                                FROM ASF_Quick_Link_Config__mdt WHERE FunctionCode__c ='ADDRU'];
        
        Customer_Notification_Config__mdt commMdt= [SELECT ID,SMS_Entity_Id__c,
                                                    SMS_Sender_Id__c,SMS_Template_Name__c,external_templateID__c
                                                    FROM Customer_Notification_Config__mdt 
                                                    WHERE DeveloperName=: qkCommMdt.SMSMetadataName__c ];

        List<ASF_Communication_Log__c> masterLogs = new List<ASF_Communication_Log__c>();
            
            ASF_Communication_Log__c cLog = new ASF_Communication_Log__c();
            cLog.Account__c = testAccount.Id;
            cLog.Phone__c = '1234567890';
            cLog.Contact__c = testContact.Id;
            cLog.Contact_Name__c = testContact.Name;
            cLog.SMS_Entity_Id__c = commMdt.SMS_Entity_Id__c;
            cLog.SMS_Sender_Id__c = commMdt.SMS_Sender_Id__c;
            cLog.SMS_LT_Name__c = commMdt.SMS_Template_Name__c;
            cLog.External_Template_ID__c = commMdt.external_templateID__c;
            cLog.Status__c = 'In Progress';
            cLog.Function_Name__c = qkCommMdt.FunctionName__c;
            cLog.Loan_Type__c = asset1.Loan_Type__c;
            cLog.Policy_No__c = asset1.Name;
            cLog.LOB__c = 'ABSLI';
            cLog.Encrypted_URL__c = 'http://bit.ly/mockurl';
            insert cLog;
            System.debug('record Inserted...'+cLog.Id);    
                
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
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
     	Test.setMock(HttpCalloutMock.class, new ABSLI_FundValueResponseGenerator());
        Test.startTest();
        ABSLI_FundValueCompController.responseWrapper templateBody = ABSLI_FundValueCompController.getTemplateBody(testAccount.Id, testAsset.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, templateBody.message, 'Template body should not be null');
    }
    
    @isTest
    static void testSendCommunication() {
        // Query the test account and branch created in the test setup
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Asset testAsset = [SELECT Id FROM Asset LIMIT 1];
        Contact testContact = [SELECT Id, MobilePhone FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
		ASF_Communication_Log__c[] logs = [SELECT Id, Account__c, Contact__c, Phone__c, Status__c FROM ASF_Communication_Log__c WHERE Account__c = :testAccount.Id];
        System.assertEquals(1, logs.size(), 'One communication log should be created.');
        ASF_Communication_Log__c log = logs[0];
        // Call the method and verify the results
        Test.startTest();
        ABSLI_FundValueCompController.sendCommunication(testAccount.Id, testAsset.Id, log.Id);
        Test.stopTest();

        // Verify that the ASF_Communication_Log__c was created
        
        System.assertEquals(testAccount.Id, log.Account__c, 'Account ID should match.');
        System.assertEquals(testContact.Id, log.Contact__c, 'Contact ID should match.');
        System.assertEquals(testContact.MobilePhone, log.Phone__c, 'Phone number should match.');
        System.assertEquals('In Progress', log.Status__c, 'Status should be "In Progress".');
	}
     @isTest
    static void testGetAllRelatedAssets() {
        // Get the test account
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

        // Call the method
        List<Asset> assets = ABSLI_FundValueCompController.getAllRelatedAssets(testAccount.Id);

        // Verify the results
        System.assertEquals(2, assets.size(), 'There should be two assets related to the test account.');
        System.assertNotEquals(null, assets[0].Id, 'The first asset should have an Id.');
        System.assertNotEquals(null, assets[1].Id, 'The second asset should have an Id.');
    }
    
    public class ABSLI_FundValueResponseGenerator implements HttpCalloutMock {
        /**
            * @description  Mocking failure response
            * @param req
            ** @return HTTPResponse
        */ 
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String s = '{\"BFID_RESPONSE\":{\"TOTAL_FUND_VALUE\":"1000000"}}';
            res.setBody(s);
            res.setStatusCode(200);
            return res;
        }
    }
}