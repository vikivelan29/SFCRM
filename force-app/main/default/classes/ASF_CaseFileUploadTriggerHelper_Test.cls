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
    }

    static testmethod void contentLinkDeleteTest() {

        Test.StartTest();
        Case caseRec = [select Id, Status from case LIMIT 1];
        caseRec.Status = 'Closed';
        update caseRec;
        ContentDocumentLink cdl = [select Id from ContentDocumentLink where LinkedEntityId =: caseRec.Id LIMIT 1]; 
        Assert.isNotNull(cdl);
        try {
            delete cdl;
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
}