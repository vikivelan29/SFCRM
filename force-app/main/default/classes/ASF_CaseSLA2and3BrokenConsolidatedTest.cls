/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 07-01-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   06-28-2024   rsinghnagar@salesforce.com   Initial Version
**/
@isTest
public  class ASF_CaseSLA2and3BrokenConsolidatedTest {


    @testSetup
    static void setupTestData(){
        List<sObject> ls = Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
        ASF_TestDataFactory.createCaseCategoryConfig();
        ASF_TestDataFactory.createC3WithPrePopulateIntegrations();
        ASF_TestDataFactory.createCaseRecords(0);
        
    }

    @IsTest
    static void testSchedulerSLA2(){
        
        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case LIMIT 1]; 
        caseRecord.Stage_SLA_2__c = Datetime.now().addHours(-5);
        caseRecord.SLA_Target_1__c = UserInfo.getUserEmail();
        caseRecord.SLA_Target_2__c = UserInfo.getUserEmail();
        caseRecord.SLA_Target_3__c = UserInfo.getUserEmail();
        caseRecord.Last_Owner_Change_Date__c = system.now();
        update caseRecord;

        // Set SLA Broken to Level 1
        List<ASF_Case_SLA_History__c> hist = [SELECT Id FROM ASF_Case_SLA_History__c WHERE Case__c =: caseRecord.Id];
        hist[0].Level__c = '1';
        update hist;

        Test.startTest();

            ASF_CaseSLA2and3BrokenConsolidatedBatch batchCls = new ASF_CaseSLA2and3BrokenConsolidatedBatch();
            String sch = '0 0 23 * * ?';
            system.schedule('Test Run', sch, batchCls);
            batchCls.execute(null);

        Test.stopTest();

        // Confirm SLA History fields
        hist = [SELECT Id, Level__c, SLA_2_Email_Sent__c FROM ASF_Case_SLA_History__c WHERE Case__c =: caseRecord.Id];
        // System.assertEquals('2', hist[0].Level__c);
        // System.assertEquals(UserInfo.getUserEmail(), hist[0].SLA_2_Email_Sent__c);
        
    }


    @IsTest
    static void testSchedulerSLA3(){
        
        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case LIMIT 1]; 
        caseRecord.Stage_SLA_3__c = Datetime.now().addHours(-5);
        caseRecord.SLA_Target_1__c = UserInfo.getUserEmail();
        caseRecord.SLA_Target_2__c = UserInfo.getUserEmail();
        caseRecord.SLA_Target_3__c = UserInfo.getUserEmail();
        caseRecord.Last_Owner_Change_Date__c = system.now();
        update caseRecord;

        // Set SLA Broken to Level 1
        List<ASF_Case_SLA_History__c> hist = [SELECT Id FROM ASF_Case_SLA_History__c WHERE Case__c =: caseRecord.Id];
        hist[0].Level__c = '2';
        update hist;

        Test.startTest();

            ASF_CaseSLA2and3BrokenConsolidatedBatch batchCls = new ASF_CaseSLA2and3BrokenConsolidatedBatch();
            String sch = '0 0 23 * * ?';
            system.schedule('Test Run', sch, batchCls);
            batchCls.execute(null);

        Test.stopTest();

        // Confirm SLA History fields
        hist = [SELECT Id, Level__c, SLA_3_Email_Sent__c FROM ASF_Case_SLA_History__c WHERE Case__c =: caseRecord.Id];
        // System.assertEquals('3', hist[0].Level__c);
        // System.assertEquals(UserInfo.getUserEmail(), hist[0].SLA_3_Email_Sent__c);
        
    }

}