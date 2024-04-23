@isTest
public class ASF_ContentDocumentTrigger_Test {
	
    @testSetup
    static void setupData(){
        
        ContentVersion cv = new ContentVersion(Title = 'Test Content',PathOnClient = 'test.pdf',VersionData = Blob.valueOf('Test Content'));
        insert cv;
        
        cv.Title = 'Updated Test Content';
        update cv;
    }

    static testmethod void contentDocUpdateTest() {

        Test.StartTest();
        ContentDocument cd = [SELECT Id, Title FROM ContentDocument LIMIT 1];
        cd.Title = 'test update';
        delete cd;
        Test.StopTest();   
    }
}