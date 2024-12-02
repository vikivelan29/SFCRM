@IsTest
private class RNWL_DocumentImagePreviewControllerTest { 
    @isTest static void testDocumentImagePreview() { 
        Document testDoc = new Document( FolderId = UserInfo.getUserId(),  
                                        Name = 'Test Document', DeveloperName = 'Test_Document_Dev_Name', 
                                        ContentType = 'text/plain', Body = Blob.valueOf('Sample Content') ); 
        insert testDoc;  
        RNWL_DocumentImagePreviewVFCController controller = new RNWL_DocumentImagePreviewVFCController(); 
        controller.strDocumentName = 'Test_Document_Dev_Name';  
        String imageURL = controller.strImageURL; 
        System.assertNotEquals('', imageURL, 'The image URL should not be empty.');
        System.assert(imageURL.contains(testDoc.Id), 'The URL should contain the Document ID.');
        System.assert(imageURL.contains(UserInfo.getOrganizationId()), 'The URL should contain the Organization ID.'); 
    } 
    @isTest static void testDocumentNotFound() {  
        RNWL_DocumentImagePreviewVFCController controller = new RNWL_DocumentImagePreviewVFCController();
        controller.strDocumentName = 'NonExistentDocument';  
        String imageURL = controller.strImageURL; 
        System.assertEquals('', imageURL, 'The image URL should be empty when no document is found.'); 
    }
}