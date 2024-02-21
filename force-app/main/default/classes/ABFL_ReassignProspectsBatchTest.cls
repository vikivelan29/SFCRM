@isTest
private class ABFL_ReassignProspectsBatchTest {
    @testSetup
    static void setupTestData() {
        Id individualRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();

        // Create test accounts
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 100; i++) {
            testAccounts.add(new Account(
                FirstName = 'John' + i,
                LastName = 'Doe' + i,
                PersonEmail = 'test' + i + '@example.com',
                PersonBirthdate = Date.newInstance(1990, 1, 1),
                RecordTypeId = individualRecordTypeId,
                PAN__c = 'ABC123'
            ));
        }
        insert testAccounts;

        // Create test leads
        List<Lead> testLeads = new List<Lead>();
        for (Integer i = 0; i < 100; i++) {
            testLeads.add(new Lead(
                FirstName = 'John' + i,
                LastName = 'Doe' + i,
                Email = 'test' + i + '@example.com',
                PANNO__c = 'ABC123'
            ));
        }
        insert testLeads;

        // Create test cases using ABFL_TestDataFactory
        List<ABFL_Case_Detail__c> caseDetailList=ABFL_TestDataFactory.createCaseDetail('Corporate',true);
        Id caseDetailId=[select id from ABFL_Case_Detail__c limit 1].id;
        ABFL_TestDataFactory.createCaseRecords(100, caseDetailId, true);
    }

    @isTest
    static void testBatch() {
        // Executing the batch job
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        List<Case> csList = new List<Case>();
        for (Case cs : [SELECT Id, Lead__c FROM Case]) {
            cs.Lead__c = testLead.Id;
            cs.Business_Unit__c = 'ABFL';
            csList.add(cs);
        }
        update csList;

        // Getting the first account for assertion
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        ABFL_ReassignProspectsBatch batchJob = new ABFL_ReassignProspectsBatch();
        Database.executeBatch(batchJob);
        Test.stopTest();

        // Verifying  the results
        List<Case> updatedCases = [SELECT Id, AccountId FROM Case];
        System.assertEquals(100, updatedCases.size(), 'Incorrect updated case size.');

        for (Case updatedCase : updatedCases) {
            System.assertEquals(acc.Id, updatedCase.AccountId, 'Account should be the original account.');
        }
    }
}