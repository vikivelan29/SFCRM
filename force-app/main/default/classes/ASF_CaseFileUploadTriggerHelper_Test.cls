@isTest
public class ASF_CaseFileUploadTriggerHelper_Test {

    @testSetup
    static void setupData(){
        
        ContentVersion cv = new ContentVersion(Title = 'Test Content',PathOnClient = 'test.pdf',VersionData = Blob.valueOf('Test Content'));
        insert cv;

        ASF_TestDataFactory.createCaseRecords(0);

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId,
            LinkedEntityId = [select Id from case LIMIT 1].Id,
            ShareType = 'V'
        );
        insert cdl;
        
        EmailMessage emailMessageRec = new EmailMessage(
            ParentId = [select Id from case LIMIT 1].Id,
            Subject = 'Test Email',
            FromAddress = 'test@example.com',
            TextBody = 'This is a test email message.'
        );
        insert emailMessageRec;
        
        // Create a ContentVersion record
        ContentVersion contentVersion = new ContentVersion(
            Title = emailMessageRec.Subject,
            VersionData = Blob.valueOf(emailMessageRec.TextBody),
            PathOnClient = 'test.txt',
            FirstPublishLocationId = emailMessageRec.Id
        );
        insert contentVersion;

        // Create a ContentDocumentLink record associating ContentVersion with Case
        ContentDocumentLink contentLink = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId,
            LinkedEntityId = [select Id from case LIMIT 1].Id,
            ShareType = 'V'
        );
        insert contentLink;
    }

    static testmethod void contentLinkDeleteTest() {

        Test.StartTest();
        Case caseRec = [select Id, Status from case LIMIT 1];
        caseRec.Status = 'Closed';
        update caseRec;
        ContentDocumentLink cdl = [select Id from ContentDocumentLink where LinkedEntityId =: caseRec.Id LIMIT 1];
        //ContentDocumentLink cdlMsg = [select Id from ContentDocumentLink where LinkedEntity.type = 'EmailMessage' LIMIT 1];
        ContentDocumentLink cdlMsg = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId IN (SELECT Id FROM EmailMessage)];
        Assert.isNotNull(cdl);
        try {
            delete cdl;
            delete cdlMsg;
        } catch (DmlException e) {
            Assert.isNotNull(e.getMessage());
        }
        Test.StopTest();   
    }
    static testmethod void contentDocUpdateTest() {

        Test.StartTest();
        Case caseRec = [select Id, Status from case LIMIT 1];
        caseRec.Status = 'Closed';
        update caseRec;
        ContentDocument cd = [select Id, Title from ContentDocument LIMIT 1]; 
        cd.Title = 'Test Title';
        try {
            update cd;
        } catch (DmlException e) {
            Assert.isNotNull(e.getMessage());
        }
        Test.StopTest();   
    }
    static testmethod void fetchContentDocTest() {

        Test.StartTest();
        Id ContentVerisonId = [SELECT Id FROM ContentVersion LIMIT 1].Id;
        String result = ASF_CaseFileUploadTriggerHelper.fetchContentDoc(ContentVerisonId);
        Test.StopTest();   
    }
    static testmethod void deleteFileByIdTest() {

        Test.StartTest();
        Id ContentVerisonId = [SELECT Id FROM ContentVersion where Title='Test Content' LIMIT 1].Id;
        Id ContentVerisonMsg = [SELECT Id FROM ContentVersion where Title='Test Email' LIMIT 1].Id;
        String result = ASF_CaseFileUploadTriggerHelper.deleteFileById(ContentVerisonId, 'Test');
        String resultmsg = ASF_CaseFileUploadTriggerHelper.deleteFileById(ContentVerisonMsg, 'Test email');
        Assert.areNotEqual('Error', result, 'result cannot be Error');
        Test.StopTest();   
    }
}