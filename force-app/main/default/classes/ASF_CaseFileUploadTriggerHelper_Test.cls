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
        
         Profile apiUserProfile = [SELECT Id FROM Profile WHERE Name = :ABSLAMC_Constants.APIUSERPROILENAME LIMIT 1];

        // Create API User
        User apiUser = new User(
            Alias = 'apiuser',
            Email = 'apiuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'API User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = apiUserProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'apiuser@test090.com'
        );
        insert apiUser;
        
              System.runAs(apiUser) {

                  Case caseRec = new Case(
                CCC_External_Id__c = '12345',
                Type_text__c = 'Support',
                Sub_Type_Text__c = 'Technical',
          
                Status = 'New',
                Source__c = 'Email',
                Business_Unit__c = 'ABSLAMC'
            );
            insert caseRec;
            ContentVersion cv1 = new ContentVersion(Title = 'Test Content',PathOnClient = 'test.pdf',VersionData = Blob.valueOf('Test Content'));
            insert cv1;
             ContentDocumentLink cdl1 = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv1.Id].ContentDocumentId,
            LinkedEntityId = [select Id from case LIMIT 1].Id,
            ShareType = 'V'
        );
        insert cdl1;
              }
        
        
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
    
    static testmethod void checkifCaseAttachmentAddedTest(){
    
           // Run as API user
        User apiUser = [SELECT Id FROM User WHERE UserName = 'apiuser@test090.com' LIMIT 1];
        System.runAs(apiUser) {

               /*   Case caseRec = new Case(
                CCC_External_Id__c = '12345',
                Type_text__c = 'Support',
                Sub_Type_Text__c = 'Technical',
          
                Status = 'New',
                Source__c = 'Email',
                Business_Unit__c = 'ABSLAMC'
            );
            insert caseRec;
            ContentVersion cv = new ContentVersion(Title = 'Test Content',PathOnClient = 'test.pdf',VersionData = Blob.valueOf('Test Content'));
            insert cv;
             ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId,
            LinkedEntityId = [select Id from case LIMIT 1].Id,
            ShareType = 'V'
        );
        insert cdl;*/
            // Fetch setup data
            List<Case> cases = [SELECT Id, Business_Unit__c FROM Case WHERE Business_Unit__c = 'ABSLAMC' Limit 1];
            ContentDocument contentDoc = [SELECT Id FROM ContentDocument LIMIT 1];
            ContentDocumentLink links = [SELECT Id, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId = :contentDoc.Id Limit 1];

            // Simulate new ContentDocumentLink
            Map<Id, ContentDocumentLink> newMap = new Map<Id, ContentDocumentLink>();
            newMap.put(links.Id,links);

            // Test the method
            Test.startTest();
            ASF_CaseFileUploadTriggerHelper.checkifCaseAttachmentAdded(newMap);
            Test.stopTest();

            // Assertions
            List<Case> notifiedCases = [SELECT Id FROM Case WHERE Id IN :cases];
            System.assertEquals(1, notifiedCases.size(), 'Cases in eligible BUs should trigger notifications.');
        }
    }
}