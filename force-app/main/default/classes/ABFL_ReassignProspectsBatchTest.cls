@isTest
private class ABFL_ReassignProspectsBatchTest {
    
    static testMethod void testBatchExecution() {
        // Test data setup
        Account testAccount = new Account(
            Name = 'Test Account',
            PersonEmail = 'test@example.com'
        );
        insert testAccount;
        
        Case testCase = new Case(
            Subject = 'Test Case',
            Lead__c = '00Q9I00000918CzUAI',
            SuppliedEmail = 'test@example.com',
            Business_Unit__c = 'ABFL'
        );
        insert testCase;
        
        // Starting the batch job
        Test.startTest();
        ABFL_ReassignProspectsBatch batchJob = new ABFL_ReassignProspectsBatch();
        Database.executeBatch(batchJob);
        Test.stopTest();
        
        // Verifying the results
        List<Case> updatedCases = [SELECT Id, AccountId FROM Case WHERE Id = :testCase.Id];
        System.assertEquals(1, updatedCases.size(), 'Expected one updated case');
        System.assertNotEquals(null, updatedCases[0].AccountId, 'Account should be assigned');
        System.assertEquals(testAccount.Id, updatedCases[0].AccountId, 'Case should be assigned to the test account');
    }
}