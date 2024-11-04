@isTest
public class ABSLI_UploadIGMSComplaints_Test {
	@testSetup
    static void testSetup(){
        
        Id recordTypeId =Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
        Account objAccount = new Account();
        objAccount.FirstName = 'TestFirstName';
        objAccount.LastName  = 'TestFirstName';
        objAccount.RecordTypeId = recordTypeId;
        objAccount.Client_Code__c = 'ABSLI001';
        insert objAccount;
        
        Case testCase = new Case();
        testCase.CCC_External_Id__c = 'PNFT007';
        testCase.Business_Unit__c = 'ABSLI';
        testCase.Source__c = 'Email';
        testCase.Client_Code_Text__c = 'ABSLI001';
        testCase.AccountId = objAccount.Id;
        insert testCase;
        
        // Create a ContentVersion record
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.txt',
            VersionData = Blob.valueOf('This is a test file.')
        );
        insert contentVersion;
        
        // Query the ContentDocument Id from the ContentVersion
        ContentVersion contentVersionQueried = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :contentVersion.Id 
            LIMIT 1
        ];
        
        // Create the ContentDocumentLink record
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
            ContentDocumentId = contentVersionQueried.ContentDocumentId,
            LinkedEntityId = testCase.Id,
            ShareType = 'V' // Viewer access
        );
        insert contentDocumentLink;
        
        // Verify the ContentDocumentLink record was created
        ContentDocumentLink contentDocumentLinkQueried = [
            SELECT Id, ContentDocumentId, LinkedEntityId, ShareType 
            FROM ContentDocumentLink 
            WHERE Id = :contentDocumentLink.Id 
            LIMIT 1
        ];
        
        ABSLI_IGMS_Document__c doc = new ABSLI_IGMS_Document__c();
        doc.Case__c = testCase.Id;
        doc.IRDA_Token_Number__c = '2';
        doc.Document_Id__c = 'DOC-1234';
        insert doc;
    }
    @isTest
    static void testExecuteQuery() {
		Case caseobj = [Select Id From Case limit 1];
         // Create IGMSDocumentWrapper JSON string
        ABSLI_UploadIGMSComplaintsIntegration.IGMSUploadDocumentWrapper docWrapper = new ABSLI_UploadIGMSComplaintsIntegration.IGMSUploadDocumentWrapper();
        //docWrapper.contentDocumentId = contentDocument.ContentDocumentId;
        docWrapper.fileName = 'Test File.txt';
        String docWrapperJson = JSON.serialize(docWrapper);

        // Call the uploadAttachment method
        Test.startTest();
        List<ABSLI_UploadIGMSComplaintsIntegration.IGMSDocumentWrapper> result = ABSLI_UploadIGMSComplaintsIntegration.executeQuery(caseobj.Id,new List<String>());
        ABSLI_UploadIGMSComplaintsIntegration.ResponseWrapper response = ABSLI_UploadIGMSComplaintsIntegration.uploadAttachment(caseobj.Id, docWrapperJson);
        Test.stopTest();
        
    }

}