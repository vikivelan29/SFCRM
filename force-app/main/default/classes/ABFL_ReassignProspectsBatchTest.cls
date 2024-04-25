@isTest
private class ABFL_ReassignProspectsBatchTest {
    
    @testSetup
    static void setupTestData(){
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1]; 
        User adminUser = new User(Alias = 'standt', Email='standarduser@testorg.com', 
             EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
             LocaleSidKey='en_US', ProfileId = p.Id, 
             TimeZoneSidKey='America/Los_Angeles', UserName='adminUserabcl@gmail.com');
        insert adminUser;
        System.runAs(adminUser) {
            List<ABFL_Case_Detail__c> caseDetailList = ABFL_TestDataFactory.createCaseDetail('Corporate', true);
            Id caseDetailId = caseDetailList.isEmpty() ? null : caseDetailList[0].Id;
            if(caseDetailId != null) {
                ABFL_TestDataFactory.createCaseRecords(1, caseDetailId, true);
            }
            //Lead testLead = new Lead(LastName='Test', Company='Test Company', Business_Unit__c='ABFL');
            //insert testLead;
            Id personRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Individual').getRecordTypeId();
            Id nonpersonRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Non-Individual').getRecordTypeId();
            Account personacc = new Account(LastName='Test Account', PersonEmail='testpersonacc@test.com', RecordTypeId=personRecordTypeId, Business_Unit__c='ABFL');
            insert personacc;
            Account nonpersonacc = new Account(Name='Test Account', Office_Email__c='testnonpersonacc@test.com', RecordTypeId=nonpersonRecordTypeId, Business_Unit__c='ABFL');
            insert nonpersonacc;
        }
    }
    
    @isTest
    static void caseReassignmentOneHierarchy(){
        // Get admin user
        User admin = [SELECT Id FROM User WHERE Username='adminUserabcl@gmail.com' LIMIT 1];
        //Lead ld = [SELECT Id FROM Lead LIMIT 1];
        Account ac = [SELECT Id, PersonEmail FROM Account where PersonEmail='testpersonacc@test.com' LIMIT 1];
        Case cs = new Case(
            Subject = 'Test Case',
            //Lead__c = ld.Id,
            SuppliedEmail = ac.PersonEmail,
            Business_Unit__c = 'ABFL'
        );
        insert cs;
        
        Test.startTest();
        ABFL_ReassignProspectsBatch batchJob = new ABFL_ReassignProspectsBatch();
        Database.executeBatch(batchJob);
        Test.stopTest();
        
        Case updatedCase = [SELECT Id, OwnerId FROM Case LIMIT 1];
        System.assertEquals(admin.Id, updatedCase.OwnerId, 'Prospects should be reassigned');
    }
    @isTest
    static void caseReassignmenttwoHierarchy(){
        // Get admin user
        User admin = [SELECT Id FROM User WHERE Username='adminUserabcl@gmail.com' LIMIT 1];
        //Lead ld = [SELECT Id FROM Lead LIMIT 1];
        Account ac = [SELECT Id, Name,Office_Email__c FROM Account where Office_Email__c='testnonpersonacc@test.com' LIMIT 1];
        Case cs = new Case(
            Subject = 'Test Case',
            //Lead__c = ld.Id,
            SuppliedEmail = ac.Office_Email__c,
            Business_Unit__c = 'ABFL'
        );
        insert cs;
        
        Test.startTest();
        ABFL_ReassignProspectsBatch batchJob = new ABFL_ReassignProspectsBatch();
        Database.executeBatch(batchJob);
        Test.stopTest();
        
        Case updatedCase = [SELECT Id, OwnerId FROM Case LIMIT 1];
        System.assertEquals(admin.Id, updatedCase.OwnerId, 'Prospects should be reassigned');
    }
    
}