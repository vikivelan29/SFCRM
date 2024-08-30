/*********************************************************
*Class        :  ABSLI_CaseIntegrationHelper_Test
*Author       :  Anirudh Raturi
*Created Date :  04/07/2024
*Last Modified:
*description  :  Test Class for ABSLI_CaseIntegrationHelper
*********************************************************/
@SuppressWarnings('PMD')
@isTest
public class ABSLI_CaseIntegrationHelper_Test {

    @TestSetup
    static void setup() {

        ASF_TestDataFactory.createCaseCategoryConfig();
        ASF_Case_Category_Config__c updateCCCRec = [Select id,Business_Unit__c From ASF_Case_Category_Config__c LIMIT 1];
        updateCCCRec.Business_Unit__c = 'ABSLI';
        update updateCCCRec;

        Id recordTypeId =Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
        Account objAccount = new Account();
        objAccount.FirstName = 'TestFirstName';
        objAccount.LastName  = 'TestFirstName';
        objAccount.Client_Code__c  = 'ABSLI0010';
        objAccount.Business_Unit__c = 'ABSLI';
        objAccount.RecordTypeId = recordTypeId;
        insert objAccount;

        Contact  cont = ASF_TestDataFactory.insertContact('Test 1@', '');

        ABSLI_Case_Detail__c caseDetailRecord = new ABSLI_Case_Detail__c();
        caseDetailRecord.Account_Number__c = 'Test ABSLI Record';
        insert caseDetailRecord;

        List<Case> caseList = ASF_TestDataFactory.createCaseRecords(0);
        caseList[0].ABSLI_Case_Detail__c = caseDetailRecord.Id;
        caseList[0].Comments = 'Test Comments';
        update caseList;

        // Create mock ASF_Case_Integration__c record
        ASF_Case_Integration__c caseIntegration = new ASF_Case_Integration__c(
            Type__c = 'eBOT',
            Status__c = 'Success',
            Case__c = caseList[0].id
        );
        insert caseIntegration;

        ContentVersion testContentVersion = new ContentVersion();
        testContentVersion.Title = 'Test File';
        testContentVersion.PathOnClient = 'testfile.txt';
        testContentVersion.VersionData = Blob.valueOf('This is test content');
        testContentVersion.IsMajorVersion = true;
        testContentVersion.Is_Email_Body__c = true;
        testContentVersion.For_Registered_Customer__c = true;
        insert testContentVersion;

        // Step 3: Retrieve the ContentDocumentId from the ContentVersion
        testContentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id];

        // Step 4: Create a ContentDocumentLink to link the file to the Account
        ContentDocumentLink contentDocLink = new ContentDocumentLink();
        contentDocLink.ContentDocumentId = testContentVersion.ContentDocumentId;
        contentDocLink.LinkedEntityId = caseIntegration.Id;
        contentDocLink.ShareType = 'V'; // Viewer permission
        contentDocLink.Visibility = 'AllUsers';
        insert contentDocLink;
    }

    // Test method for eBotResponseHandler
    @isTest
    static void testEBotResponseHandler() {

        // Create mock records
        ASF_Case_Integration__c caseIntegration = [SELECT id FROM ASF_Case_Integration__c LIMIT 1];
        Case caseRecord = [Select id FROM Case Limit 1];

        // Create mock ebot response
        ABSLI_EbotWrapper.EbotResponseWrapper ebotResponse = new ABSLI_EbotWrapper.EbotResponseWrapper();
        ebotResponse.CaseSubSubType = 'CCC-CC-CCLTD-01';
        ebotResponse.Comments = 'Test Comments';
        ebotResponse.Issue_Type = 'Policy Details';
        ebotResponse.FTR = false;
        ebotResponse.ClientId = 'TestClientId';
        ebotResponse.PolicyNo = 'TestPolicyNo';
        ebotResponse.FromDate = '2023-01-01';
        ebotResponse.ToDate = '2023-12-31';
        ebotResponse.Email_Details = new List<ABSLI_EbotWrapper.EmailDetailsWrapper>();

        ABSLI_EbotWrapper.EmailDetailsWrapper emailDetails = new ABSLI_EbotWrapper.EmailDetailsWrapper();
        emailDetails.EmailTo = 'test@example.com';
        emailDetails.EmailSubject = 'Test Subject';
        emailDetails.EmailCustomerFlag = true;
        emailDetails.Is_Register_Customer = true;
        emailDetails.Static_Attachment = new List<ABSLI_EbotWrapper.StaticAttachmentWrapper>();

        ABSLI_EbotWrapper.StaticAttachmentWrapper staticAttachment = new ABSLI_EbotWrapper.StaticAttachmentWrapper();
        staticAttachment.AttachmentName = 'TestAttachment';
        emailDetails.Static_Attachment.add(staticAttachment);
        ebotResponse.Email_Details.add(emailDetails);

        // Call the method
        Test.startTest();
        ABSLI_CaseIntegrationHelper.eBotResponseHandler(caseRecord.Id, ebotResponse, caseIntegration);
        Test.stopTest();

        // Verify the results
        caseRecord = [SELECT ABSLI_Case_Detail__c, CCC_External_Id__c, Comments, Issue_Type__c, FTR__c, MoveToNext__c FROM Case WHERE Id = :caseRecord.Id];
        System.assertEquals(ebotResponse.CaseSubSubType, caseRecord.CCC_External_Id__c);
    }

    // Test method for transferAttachmentToCase
    @isTest
    static void testTransferAttachmentToCase() {

        ASF_Case_Integration__c caseIntegRec = [SELECT id FROM ASF_Case_Integration__c LIMIT 1];
        // Call the method
        Test.startTest();
        ABSLI_CaseIntegrationHelper.ContentRelationWrapper result = ABSLI_CaseIntegrationHelper.transferAttachmentToCase(caseIntegRec);
        Test.stopTest();

        // Verify the results
        System.assertNotEquals(null, result);
        System.assertEquals(0, result.registeredAttachments.size());
    }

    // Test method for handleEmailMessages
    @isTest
    static void testHandleEmailMessages() {
        // Create mock records
        Case caseRecord = [Select id FROM Case Limit 1];

        // Create mock ebot response and ContentRelationWrapper
        ABSLI_EbotWrapper.EbotResponseWrapper ebotResponse = new ABSLI_EbotWrapper.EbotResponseWrapper();
        ebotResponse.FromDate = '2023-01-01';
        ebotResponse.ToDate = '2023-12-31';
        ebotResponse.Email_Details = new List<ABSLI_EbotWrapper.EmailDetailsWrapper>();

        ABSLI_EbotWrapper.EmailDetailsWrapper emailDetails = new ABSLI_EbotWrapper.EmailDetailsWrapper();
        emailDetails.EmailTo = 'test@example.com';
        emailDetails.EmailSubject = 'Test Subject';
        emailDetails.EmailCustomerFlag = false;
        emailDetails.Is_Register_Customer = false;
        emailDetails.Static_Attachment = new List<ABSLI_EbotWrapper.StaticAttachmentWrapper>();

        ABSLI_EbotWrapper.StaticAttachmentWrapper staticAttachment = new ABSLI_EbotWrapper.StaticAttachmentWrapper();
        staticAttachment.AttachmentName = 'TestAttachment';
        emailDetails.Static_Attachment.add(staticAttachment);
        ebotResponse.Email_Details.add(emailDetails);

        ABSLI_CaseIntegrationHelper.ContentRelationWrapper contentRelation = new ABSLI_CaseIntegrationHelper.ContentRelationWrapper();
        contentRelation.registeredTemplateId = '0690';
        contentRelation.unregisteredTemplateId = '0691';
        contentRelation.registeredAttachments = new List<String>{'0680'};
        contentRelation.unregisteredAttachments = new List<String>{'0681'};

        // Call the method
        Test.startTest();
        ABSLI_Case_Detail__c result = ABSLI_CaseIntegrationHelper.handleEmailMessages(caseRecord.Id, ebotResponse, contentRelation);
        Test.stopTest();

        // Verify the results
        System.assertNotEquals(null, result);
        System.assertEquals(Date.valueOf('2023-01-01'), result.From_Date__c);
        System.assertEquals(Date.valueOf('2023-12-31'), result.To_Date__c);
        System.assertEquals('test@example.com', result.Draft_To_Address__c);
        System.assertEquals('Test Subject', result.Draft_Subject__c);
        System.assertEquals('0681', result.Draft_AttachmentIds__c);
    }

    // Test method for sendAutoMail
    @isTest
    static void testSendAutoMail() {
        // Create mock case record
        Case caseRecord = [Select id FROM Case Limit 1];
        ContentVersion contVerRec = [SELECT id,ContentDocumentId FROM ContentVersion LIMIT 1];

        // Call the method
        Test.startTest();
        ABSLI_CaseIntegrationHelper.sendAutoMail('test@example.com', 'Test Subject', contVerRec.ContentDocumentId, contVerRec.Id, caseRecord.Id);
        Test.stopTest();

        // Verify the results
        List<PE_Logger__c> peLoggers = [SELECT Id, Subject__c, Specific_To_Address__c FROM PE_Logger__c WHERE RecordID__c = :caseRecord.Id];
        System.assertEquals(1, peLoggers.size());
        System.assertEquals('Test Subject', peLoggers[0].Subject__c);
        System.assertEquals('test@example.com', peLoggers[0].Specific_To_Address__c);
    }

    // Test method for updateCase
    @isTest
    static void testUpdateCase() {
        // Create mock records
        ABSLI_Case_Detail__c caseDetail = [SELECT id FROM ABSLI_Case_Detail__c LIMIT 1];
        Case caseRecord = [Select id FROM Case Limit 1];

        // Create mock ebot response
        ABSLI_EbotWrapper.EbotResponseWrapper ebotResponse = new ABSLI_EbotWrapper.EbotResponseWrapper();
        ebotResponse.CaseSubSubType = 'CCC-CC-CCLTD-01';
        ebotResponse.Comments = 'Test Comments';
        ebotResponse.Issue_Type = 'Maturity Related	';
        ebotResponse.FTR = false;
        ebotResponse.ClientId = 'ABSLI0010';

        // Call the method
        Test.startTest();
        Case updatedCase = ABSLI_CaseIntegrationHelper.updateCase(caseRecord.Id, ebotResponse, caseDetail);
        Test.stopTest();

        // Verify the results
        System.assertEquals('Test Comments', updatedCase.Comments);
        System.assertEquals('CCC-CC-CCLTD-01', updatedCase.CCC_External_Id__c);
    }

    // Test method for ebotEmailComposerHandler
    @isTest
    static void testEBotEmailComposerHandler() {
        // Create mock case record
        Case caseRecord = [Select id FROM Case Limit 1];

        // Call the method
        Test.startTest();
        ABSLI_CaseIntegrationHelper.EmailComposerWrapper emailWrapper = ABSLI_CaseIntegrationHelper.ebotEmailComposerHandler(caseRecord.Id);
        Test.stopTest();

        // Verify the results
        System.assertNotEquals(null, emailWrapper);
    }

    // Test method for sendMail
    @isTest
    static void testSendMail() {
        // Create mock case record
        Case caseRecord = [Select id FROM Case Limit 1];
        ContentVersion contVerRec = [SELECT id,ContentDocumentId FROM ContentVersion LIMIT 1];

        // Create mock email composer wrapper
        ABSLI_CaseIntegrationHelper.EmailComposerWrapper emailWrapper = new ABSLI_CaseIntegrationHelper.EmailComposerWrapper();
        emailWrapper.emailBody = 'Test Body';
        emailWrapper.emailSubject = 'Test Subject';
        emailWrapper.emailToAddress = 'test@example.com';
        emailWrapper.emailTemplateId = contVerRec.ContentDocumentId;

        // Call the method
        Test.startTest();
        Boolean isSuccess = ABSLI_CaseIntegrationHelper.sendMail(caseRecord.Id, JSON.serialize(emailWrapper));
        Test.stopTest();

        // Verify the results
        System.assert(isSuccess);
    }
}