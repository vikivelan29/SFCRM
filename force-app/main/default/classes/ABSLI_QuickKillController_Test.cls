@isTest
public class ABSLI_QuickKillController_Test {
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
                
            ASF_Quick_Link_Config__mdt qkCommMdt = [SELECT ID, FunctionName__c ,FunctionCode__c,SMSMetadataName__c 
                                                FROM ASF_Quick_Link_Config__mdt WHERE FunctionCode__c ='ADDRU'];
        
        Customer_Notification_Config__mdt commMdt= [SELECT ID,SMS_Entity_Id__c,
                                                    SMS_Sender_Id__c,SMS_Template_Name__c,external_templateID__c
                                                    FROM Customer_Notification_Config__mdt 
                                                    WHERE DeveloperName=: qkCommMdt.SMSMetadataName__c ];

        List<ASF_Communication_Log__c> masterLogs = new List<ASF_Communication_Log__c>();
            
            ASF_Communication_Log__c cLog = new ASF_Communication_Log__c();
            cLog.Account__c = testAccount.Id;
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
        
        EmailTemplate lightningEmailTempalte = new EmailTemplate();
        lightningEmailTempalte.isActive = true;
        lightningEmailTempalte.Name = 'TestLightning';
        lightningEmailTempalte.HtmlValue = '<html><body>$$ABHFL_Case_Detail__r.As_On_Date__c$$ -- $$Asset.Last_Disbursement_Date__c$$.</body></html>';
        lightningEmailTempalte.DeveloperName = 'TestVf_un';
        lightningEmailTempalte.TemplateType = 'custom';
        lightningEmailTempalte.FolderId = UserInfo.getUserId();
        insert lightningEmailTempalte;
        
    } 
    @isTest
    static void testSendCommunication() {
        // Query the test account and branch created in the test setup
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Asset testAsset = [SELECT Id FROM Asset LIMIT 1];
        Contact testContact = [SELECT Id, MobilePhone FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
		EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'TestVf_un' LIMIT 1];
        // Verify that the ASF_Communication_Log__c was created
        ASF_Communication_Log__c[] logs = [SELECT Id, Account__c, Contact__c, Phone__c, Status__c FROM ASF_Communication_Log__c WHERE Account__c = :testAccount.Id];
        System.assertEquals(1, logs.size(), 'One communication log should be created.');
        ASF_Communication_Log__c log = logs[0];
        System.assertEquals(testAccount.Id, log.Account__c, 'Account ID should match.');
        System.assertEquals(testContact.Id, log.Contact__c, 'Contact ID should match.');
        Test.setMock(HttpCalloutMock.class, new BitlyApiMock());
        // Call the method and verify the results
        Test.startTest();
        ABSLI_QuickKillController.generateBitlyLink(log.Id,'ADDRU');
        ABSLI_QuickKillController.generateLink('ADDRU',testAccount.Id,testAsset.Id);
        ABSLI_QuickKillController.sendCommunication(log.Id,'text','123456');
        ABSLI_QuickKillController.deleteDraftLogs(log.Id);
        ABSLI_QuickKillController.getPolicyColumns();
        ABSLI_QuickKillController.getAllRelatedAssets(testAccount.Id);
        //ABSLI_QuickKillController.getTemplateBody(null,'ADDRU');
        //String retVal = ABSLI_QuickKillController.generateMessageBody(template.Id,UserInfo.getUserId(),null,false);
        Test.stopTest();
        
	}
    public class BitlyApiMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{\"URLReturned\": \"http://bit.ly/mockurl\"}');
        res.setStatusCode(200);
        return res;
    }
}
  
}