/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 11-29-2024
 * @last modified by  : rsinghnagar@salesforce.com 
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   11-29-2024   rsinghnagar@salesforce.com   Initial Version
**/
@isTest
public class ASF_ContentDocumentLinkTrigger_Test {
    
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
        Id caseId = [select Id from case LIMIT 1].Id;
        ContentDocumentLink cdl = [select Id from ContentDocumentLink cdl where LinkedEntityId =: caseId LIMIT 1]; 
        Assert.isNotNull(cdl);
        delete cdl;
        Test.StopTest();   
    }
}