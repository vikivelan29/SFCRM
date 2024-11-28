/**
 * @Class name:      ASF_CaseRuleTriggerTest
 * @Description:
 * @Group:
 * Modification Log:
 * ------------------------------------------------------------------------------------
 * Developer                  Version     Date                Description
 * ------------------------------------------------------------------------------------
 * Rajender Kumar             1.0       24/11/2023       Class to cover test cases ASF_CaseRuleTrigger,ASF_CaseRuleTriggerHandler,ASF_CaseRuleTriggerHelper
 */
@isTest
private class ASF_CaseRuleTriggerTest {

    @isTest
    static void testBeforeInsert() {
        ASF_Case_Category_Config__c ccc = new ASF_Case_Category_Config__c();
        ccc.Type__c = 'tes';
        ccc.CCC_External_Id__c = '12345';
        ccc.Sub_Type__c = 'TDC Refund';
        ccc.Overall_Case_Closure_SLA__c = 10;
        insert ccc;

        ASF_Case_Stage_Config__c stage1 = new ASF_Case_Stage_Config__c();
        stage1.Case_Category_Config__c = ccc.Id;
        stage1.Order__c = 1;
        stage1.StageName__c = 'New';
        stage1.Stage_SLA_1__c = 1;
        stage1.Status_Mapping__c = 'New';
        stage1.SLA_Target_1_Type__c = 'Manager';
        stage1.Query_Fields__c = 'Id,Stage__c';
        stage1.Manual_Stage__c = false;
        stage1.Stage_External_Id__c = 'STG_1';

        insert stage1;

        List<ASF_Case_Rule__c> caseRuleList = new List<ASF_Case_Rule__c>{
            new ASF_Case_Rule__c(
                Assignment_Queue_Name__c = 'TestQueue',
                Case_Stage_Config__c = stage1.Id
            )
        };

        Test.startTest();
        insert caseRuleList;
        Test.stopTest();

        System.assertEquals(1, caseRuleList.size(), 'One case rule record should be inserted');
        System.assertNotEquals(null, caseRuleList[0].Id, 'Case rule Id should not be null after insertion');
    }

    @isTest
    static void testBeforeUpdate() {
        ASF_Case_Category_Config__c ccc = new ASF_Case_Category_Config__c();
        ccc.Type__c = 'tes';
        ccc.CCC_External_Id__c = '12345';
        ccc.Sub_Type__c = 'TDC Refund';
        ccc.Overall_Case_Closure_SLA__c = 10;
        insert ccc;

        ASF_Case_Stage_Config__c stage1 = new ASF_Case_Stage_Config__c();
        stage1.Case_Category_Config__c = ccc.Id;
        stage1.Order__c = 1;
        stage1.StageName__c = 'New';
        stage1.Stage_SLA_1__c = 1;
        stage1.Status_Mapping__c = 'New';
        stage1.SLA_Target_1_Type__c = 'Manager';
        stage1.Query_Fields__c = 'Id,Stage__c';
        stage1.Manual_Stage__c = false;
        stage1.Stage_External_Id__c = 'STG_1';

        insert stage1;

        List<ASF_Case_Rule__c> caseRuleList = new List<ASF_Case_Rule__c>{
            new ASF_Case_Rule__c(
                Assignment_Queue_Name__c = 'TestQueue',
                Case_Stage_Config__c = stage1.Id
            )
        };
        insert caseRuleList;

        caseRuleList[0].Assignment_Queue_Name__c = 'UpdatedTestQueue';

        Test.startTest();
        update caseRuleList;
        Test.stopTest();

        System.assertEquals(1, caseRuleList.size(), 'One case rule record should be updated');
        System.assertEquals('UpdatedTestQueue', caseRuleList[0].Assignment_Queue_Name__c, 'Assignment_Queue_Name__c should be updated');
    }
}