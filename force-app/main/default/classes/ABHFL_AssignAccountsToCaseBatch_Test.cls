@isTest
private class ABHFL_AssignAccountsToCaseBatch_Test {
    
     @testSetup
    static void setup() {
        SLA_Threshold_Warning__c slaTw = new SLA_Threshold_Warning__c ();
        slaTw.Customer_Email_buffer_hours__c = 30;
        slaTw.setupOwnerId = System.Userinfo.getOrganizationId();
        slaTw.Case_SLA_Threshold_1__c = 12;
        slaTw.Case_SLA_Threshold_2__c = 12;
        slaTw.Stage_SLA_Threshold_1__c = 12;
        slaTw.Case_SLA_Threshold_3__c = 12;
        Insert slaTw;
    
        RecordType rcdType = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Case' AND Name = 'Interaction' LIMIT 1];
    
        // Create test data
        Case testCase = new Case(
            RecordTypeId = rcdType.Id,
            Status = 'New',
            Technical_Source__c = 'Email',
            Business_Unit__c = 'ABHFL',
            SuppliedEmail = 'test@email.com',
            accountId = null
        );
        insert testCase;
        
        Account testAccount = new Account(
            //RecordTypeId = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Individual' LIMIT 1].Id,
          Name = 'Test Acc'
        );
        insert testAccount;
        
        Contact con = new contact();
        con.LastName = 'Test';
        con.accountId = testAccount.Id;
        con.email = 'test@email.com';
        INSERT Con;
    }

   public static testMethod void testschedule() {
        Test.StartTest();
            ABHFL_AssignAccountsToCaseBatchScheduler testsche = new ABHFL_AssignAccountsToCaseBatchScheduler();
            String sch = '0 0 23 * * ?';
            system.schedule('Test status Check', sch, testsche );
        Test.stopTest();
    }

    @isTest
    static void testBatchExecution() {
        
        // Start the batch job
        Test.startTest();
            ABHFL_AssignAccountsToCaseBatch batchJob = new ABHFL_AssignAccountsToCaseBatch();
            Database.executeBatch(batchJob);
        Test.stopTest();
    
    // Assert results
        account acc = [SELECT Id FROM account limit 1];
        
        List<Case> accountsAssigned = [SELECT Id FROM Case WHERE accountId = :acc.Id];
        System.assertEquals(1, accountsAssigned.size(), 'An account should be assigned to the case');
    }
}