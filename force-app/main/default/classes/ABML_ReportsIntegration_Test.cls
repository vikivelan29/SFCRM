/******************************************************  
* Author           - 
* Date             - 
* Description      - Test class for ABML_ReportsIntegration
********************************************************
*/
@isTest
public with sharing class ABML_ReportsIntegration_Test {
    
    @testSetup
    static void setupTestData() {
        Account acc = new Account(
            Client_Code__c = 'ABCTest321',
            FirstName = 'test',
            LastName = 'test2',
            Business_Unit__c ='ABML'    
        );
        insert acc;
        
        // Create a Case record
        Case testCase = new Case(
            Business_Unit__c = 'ABML',
            SuppliedEmail = 'testuser@example.com',
            AccountId = acc.Id,
            Source__c = 'Email',
            Stage__c = 'Resolved',
            Status = 'New'
        );
        insert testCase;
        
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c(
            Case__c = testCase.Id,
            Status__c = 'Pending',
            Response__c = 'Waiting for API response',
            Request__c = 'StatementOfAccount',
            Business_External_Id__c = 'ABML_Report_Integration'
        );
        insert caseInt;
        
        ASF_Case_Integration__c caseInt1 = new ASF_Case_Integration__c(
            Case__c = testCase.Id,
            Status__c = 'Success',
            Response__c = 'Waiting for API response',
            Request__c = 'Contract Note'
        );
        insert caseInt1;
        
        ContentVersion content = new ContentVersion(
            Title = 'Report.pdf',
            VersionData = Blob.valueOf('Sample content for the report'),
            FirstPublishLocationId = caseInt.Id,
            PathOnClient = 'Contract Note.PDF'
        );
        insert content;
        
        ContentVersion content1 = new ContentVersion(
            Title = 'Report1.pdf',
            VersionData = Blob.valueOf('Sample content for the report'),
            FirstPublishLocationId = caseInt1.Id,
            PathOnClient = 'Contract Note.PDF'
        );
        insert content1;   
    }
    
    @isTest 
    static void getReportsTestMethod() {
        Case caseObj = [SELECT Id,Business_Unit__c, SuppliedEmail, Source__c,Stage__c FROM Case Limit 1];
        ASF_Case_Integration__c updatedCaseInt = [SELECT Status__c, Request__c, Response__c,Case__c FROM ASF_Case_Integration__c WHERE Case__c = :caseObj.Id limit 1];
        
        Test.startTest();
        ABML_ReportsIntegration.getReports(
            caseObj.Id,
            '01-01-2024',
            '31-12-2024',
            'Contract Note',
            '2024-2025'
        );
        Test.stopTest();
        System.assertEquals(updatedCaseInt.Status__c, 'Pending');
        System.assert(updatedCaseInt.Request__c.contains('StatementOfAccount')); // Validate the request payload
        System.assertEquals(updatedCaseInt.Response__c, 'Waiting for API response'); // Check response field
        
    }
    
    @isTest 
    static void getReportsTestMethod1() {
        Case caseObj = [SELECT Id,Business_Unit__c, SuppliedEmail, Source__c,Stage__c FROM Case Limit 1];
        ASF_Case_Integration__c updatedCaseInt = [SELECT Status__c, Request__c, Response__c,Case__c FROM ASF_Case_Integration__c WHERE Case__c = :caseObj.Id limit 1];
        
        Test.startTest();
        ABML_ReportsIntegration.getReports(
            caseObj.Id,
            '01-01-2024',
            '31-12-2024',
            'Statement Of Account',
            '2024-2025'
        );
        Test.stopTest();
        System.assertEquals(updatedCaseInt.Status__c, 'Pending');
        System.assert(updatedCaseInt.Request__c.contains('StatementOfAccount')); // Validate the request payload
        System.assertEquals(updatedCaseInt.Response__c, 'Waiting for API response'); // Check response field
        
    }
    
    @isTest 
    static void getReportsTestMethod2() {
        Case caseObj = [SELECT Id,Business_Unit__c, SuppliedEmail, Source__c,Stage__c FROM Case Limit 1];
        ASF_Case_Integration__c updatedCaseInt = [SELECT Status__c, Request__c, Response__c,Case__c FROM ASF_Case_Integration__c WHERE Case__c = :caseObj.Id limit 1];
        
        Test.startTest();
        ABML_ReportsIntegration.getReports(
            caseObj.Id,
            '01-01-2024',
            '31-12-2024',
            'Statement Of Transaction',
            '2024-2025'
        );
        Test.stopTest();
        System.assertEquals(updatedCaseInt.Status__c, 'Pending');
        System.assert(updatedCaseInt.Request__c.contains('StatementOfAccount')); // Validate the request payload
        System.assertEquals(updatedCaseInt.Response__c, 'Waiting for API response'); // Check response field
        
    }
    
    @isTest 
    static void sendEmailAttachmentsTestMethod() {
        Case caseObj = [SELECT Id,Business_Unit__c, SuppliedEmail, Source__c,Stage__c,AccountId FROM Case Where AccountId!=null Limit 1];
        ASF_Case_Integration__c updatedCaseInt = [SELECT Id,Status__c, Request__c, Response__c,Case__c FROM ASF_Case_Integration__c WHERE Status__c='Success' limit 1];
        ContentVersion sentContent = [SELECT Id, Title, VersionData,FirstPublishLocationId FROM ContentVersion WHERE FirstPublishLocationId = :updatedCaseInt.Id];
        Test.startTest();
        ABML_ReportsIntegration.sendEmailAttachments(new List<ASF_Case_Integration__c>{ updatedCaseInt });    
        Test.stopTest();
        System.assertNotEquals(sentContent, null);
        System.assertEquals(sentContent.Title, 'Report1.pdf');
    }
}