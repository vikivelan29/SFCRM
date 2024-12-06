/******************************************************  
* Author           - Tanmay Metkar
* Date             - 06-November-2024
* Description      - Test class for ABML_ReportsIntegration
********************************************************
*/
@isTest
public with sharing class ABML_ReportsIntegration_Test{
    
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];    
    
    @testSetup
    static void setupTestData() {
        
        User userRecord = new User(Alias = 'usr1', Email = 'standarduser@testorg.com', EmailEncodingKey = 'UTF-8', LastName = 'Test', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', 
                                   ProfileId = SYSTEMADMIN_PROFILE.Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'testAbmlUser1@gmail.com', Business_Unit__c = 'ABML');
        insert userRecord;
        List<ABML_Daily_Report_Sender__c> listOfReportSender = new List<ABML_Daily_Report_Sender__c>();
        ABML_Daily_Report_Sender__c objReportSenderTwo = new ABML_Daily_Report_Sender__c( Name = 'ordWideAddress', Email__c = 'abctsl.crmteam-noreply@adityabirlacapital.com');
        listOfReportSender.add(objReportSenderTwo);
        insert listOfReportSender;
        System.runAs(userRecord) {            
            Account acc = new Account(Client_Code__c = 'ABCTest321', FirstName = 'test', LastName = 'test2', PersonEmail='testuser@example.com', Business_Unit__c ='ABML');
            insert acc;
            
            // Create a Case record
            Case testCase = new Case(Business_Unit__c = 'ABML', AccountId = acc.Id, Source__c = 'Email', Stage__c = 'Resolved', Status = 'New');
            insert testCase;
            
            List<ASF_Case_Integration__c> listAsfCaseIntegration = new List<ASF_Case_Integration__c>();            
            ASF_Case_Integration__c objAsfCaseInt = new ASF_Case_Integration__c(Case__c = testCase.Id, Status__c = 'Pending', Response__c = 'Waiting for API response',
                                                                                Request__c = 'StatementOfAccount', Business_External_Id__c = 'ABML_Report_Integration' );
            listAsfCaseIntegration.add(objAsfCaseInt);            
            ASF_Case_Integration__c obAsfCaseInt = new ASF_Case_Integration__c( Case__c = testCase.Id, Status__c = 'Success',  Response__c = 'Waiting for API response',
                                                                               Request__c = 'Contract Note' );
            listAsfCaseIntegration.add(obAsfCaseInt);            
            insert listAsfCaseIntegration;
            
            List<ContentVersion> listContentVersion = new List<ContentVersion>();            
            ContentVersion objcontentVerion = new ContentVersion( Title = 'Report.pdf', VersionData = Blob.valueOf('Sample content for the report'), 
                                                                 FirstPublishLocationId = listAsfCaseIntegration[0].Id,  PathOnClient = 'Contract Note.PDF' );
            listContentVersion.add(objcontentVerion);            
            ContentVersion obcontentVerion = new ContentVersion( Title = 'Report1.pdf', VersionData = Blob.valueOf('Sample content for the report'),
                                                                FirstPublishLocationId = listAsfCaseIntegration[1].Id, PathOnClient = 'Contract Note.PDF' );
            listContentVersion.add(obcontentVerion);            
            insert listContentVersion;
        }
        
    }
    
    @isTest 
    static void getReportsNoteTest(){
        
        User objUser = [SELECT Id, Name, UserName FROM User WHERE Business_Unit__c = 'ABML' and LastName = 'Test' LIMIT 1];
        System.runAs(objUser){
            
            Case caseObj = [SELECT Id, Business_Unit__c, Source__c,Stage__c FROM Case Limit 1];
            ASF_Case_Integration__c updatedCaseInt = [SELECT Status__c, Request__c, Response__c,Case__c FROM ASF_Case_Integration__c WHERE Case__c =: caseObj.Id LIMIT 1];
            
            Test.startTest();
            ABML_ReportsIntegration.getReports(caseObj.Id, '01-01-2024', '31-12-2024', 'Contract Note', '2024-2025');
            Test.stopTest();
            System.assertEquals(updatedCaseInt.Status__c , 'Pending');
            System.assert(updatedCaseInt.Request__c.contains('StatementOfAccount')); // Validate the request payload
            System.assertEquals(updatedCaseInt.Response__c , 'Waiting for API response'); // Check response field
            
        }
    }
    
    @isTest 
    static void getReportsAccountTest(){
        
        User objUser = [SELECT Id, Name, UserName FROM User WHERE Business_Unit__c = 'ABML' and LastName = 'Test' LIMIT 1];
        System.runAs(objUser){           
            Case caseObj = [SELECT Id, Business_Unit__c, Source__c, Stage__c FROM Case Limit 1];
            ASF_Case_Integration__c updatedCaseInt = [SELECT Status__c, Request__c, Response__c, Case__c FROM ASF_Case_Integration__c WHERE Case__c =: caseObj.Id LIMIT 1];
            
            Test.startTest();
            ABML_ReportsIntegration.getReports( caseObj.Id, '01-01-2024', '31-12-2024', 'Statement Of Account', '2024-2025');
            Test.stopTest();
            System.assertEquals(updatedCaseInt.Status__c, 'Pending');
            System.assert(updatedCaseInt.Request__c.contains('StatementOfAccount')); // Validate the request payload
            System.assertEquals(updatedCaseInt.Response__c, 'Waiting for API response'); // Check response field
        }
        
    }
    
    @isTest 
    static void getReportsTransactionTest(){
        
        User objUser = [SELECT Id, Name, UserName FROM User WHERE Business_Unit__c = 'ABML' and LastName = 'Test' LIMIT 1];
        System.runAs(objUser){           
            Case caseObj = [SELECT Id, Business_Unit__c, Source__c, Stage__c FROM Case Limit 1];
            ASF_Case_Integration__c updatedCaseInt = [SELECT Status__c, Request__c, Response__c,Case__c FROM ASF_Case_Integration__c WHERE Case__c =: caseObj.Id LIMIT 1];
            
            Test.startTest();
            ABML_ReportsIntegration.getReports( caseObj.Id, '01-01-2024', '31-12-2024', 'Statement Of Transaction', '2024-2025');
            Test.stopTest();
            System.assertEquals(updatedCaseInt.Status__c, 'Pending');
            System.assert(updatedCaseInt.Request__c.contains('StatementOfAccount')); // Validate the request payload
            System.assertEquals(updatedCaseInt.Response__c, 'Waiting for API response'); // Check response field
        }
    }
    
    @isTest 
    static void sendEmailAttachmentsTestMethod(){
        User objUser = [SELECT Id, Name, UserName FROM User WHERE Business_Unit__c = 'ABML' and LastName = 'Test' LIMIT 1];
        System.runAs(objUser){    
            Case caseObj = [SELECT Id, Business_Unit__c, Source__c, Stage__c, AccountId FROM Case Where AccountId != null LIMIT 1];
            ASF_Case_Integration__c updatedCaseInt = [SELECT Id, Status__c, Request__c, Response__c, Case__c FROM ASF_Case_Integration__c WHERE Status__c = 'Success' LIMIT 1];
            ContentVersion sentContent = [SELECT Id, Title, VersionData, FirstPublishLocationId FROM ContentVersion WHERE FirstPublishLocationId =: updatedCaseInt.Id];
            Test.startTest();
            ABML_ReportsIntegration.sendEmailAttachments(new List<ASF_Case_Integration__c>{ updatedCaseInt });    
            Test.stopTest();
            System.assertNotEquals(sentContent, null);
            System.assertEquals(sentContent.Title, 'Report1.pdf');
        }
    }
}