@isTest
public class ASF_BooleanExpression_Test {

    @testSetup
    static void setUpData() {
        ASF_TestDataFactory.createCaseRecords(1);
        ASF_TestDataFactory.createCaseCategoryConfig();
        ASF_TestDataFactory.createC3WithPrePopulateIntegrations();
    }

    @isTest
    private static void evaluateAdvanceLogicTest() {
        Id caseRuleId = [SELECT Id FROM ASF_Case_Rule__c WHERE Type__c = 'Work' LIMIT 1].Id;

        List<ASF_Case_Rule_Entry__c> caseRuleEntryList = [
            SELECT Id, Number__c, Case_Rule__c, Field_Api_Name__c, Operator__c, Data_Type__c, Value__c, External_ID__c
            FROM ASF_Case_Rule_Entry__c WHERE Case_Rule__c = :caseRuleId
        ];

        caseRuleEntryList[0].Data_Type__c = 'BOOLEAN';
        update caseRuleEntryList;

        Case caseRecord = [
            SELECT Id, CCC_External_Id__c, Stage__c, pending_clarification__c, PAY_Payment_Detail__c,
                   PAY_Payment_Detail__r.Payment_mode__c, SLA_Target_1__c, CSAT__c, DB_Hours__c FROM Case LIMIT 1
        ];

        Test.startTest();
        Map<Integer, Boolean> values = new Map<Integer, Boolean> {1 => true, 2 => true, 3 => false, 4 => true, 5 => true};
        Boolean evaluationResult = ASF_BooleanExpression.evaluateAdvanceLogic('1 AND 2 AND 3 AND (4 OR 5)', values);
        ASF_BooleanExpression boolExpObj = new ASF_BooleanExpression();
        Boolean complexEvalResult = boolExpObj.getComplexCriteriaEvaluation('1 AND 2 AND 3 AND (4 OR 5)', values);
        Test.stopTest();

        System.assertNotEquals(evaluationResult, true, 'Evaluation result should not be true');
    }
}