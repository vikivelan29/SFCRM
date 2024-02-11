@isTest
public class ASF_CaseFrameworkValidator_Test {
    
  /*  @testSetup
    static void setUpData(){
        ASF_TestDataFactory.createCaseCategoryConfig();
        ASF_TestDataFactory.createCaseRecords(1);
        
        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c, PAY_Payment_Detail__c, PAY_Payment_Detail__r.Payment_mode__c,
                           SLA_Target_1__c, CSAT__c, DB_Hours__c, has_CheckLists__c, Has_Open_Tasks__c, Reopen_Days__c,Reopened__c,ABHFL_Case_Detail__r.EMI_Tenure__c  from case LIMIT 1];
        
        ABHFL_Case_Detail__c caseExtension = new ABHFL_Case_Detail__c();
        caseExtension.Case__c=caseRecord.id;
        caseExtension.EMI_Tenure__c=3;
        caseExtension.Part_Payment_Amount__c=100;
        caseExtension.Payable_Charges__c=1000;
        caseExtension.Realization_status__c='Cleared';
        insert caseExtension;
        
        ASF_TestDataFactory.createC3WithPrePopulateIntegrations();
        
        PAY_Payment_Detail__c payDetailRecord = new PAY_Payment_Detail__c();
        payDetailRecord.Txn_ref_no__c = '1011010110';
        insert payDetailRecord;
        
        List<ASF_Case_Stage_Config__c> stageConfigList = [SELECT Id FROM ASF_Case_Stage_Config__c LIMIT 1];
        List<ASF_Case_Rule__c> caseRuleList = new List<ASF_Case_Rule__c>();
         ASF_Case_Rule__c stage1_StageMovement_Rule = new ASF_Case_Rule__c();

        stage1_StageMovement_Rule.Case_Stage_Config__c = stageConfigList[0].Id;
        stage1_StageMovement_Rule.Logical_Condition__c = '1 AND 2 AND 3 AND 4 AND 7 AND 8 AND 9 AND (5 OR 6)';
        stage1_StageMovement_Rule.Order__c = 1;
        stage1_StageMovement_Rule.Type__c = 'Approval';
        
        caseRuleList.add(stage1_StageMovement_Rule);
        insert stage1_StageMovement_Rule;
        
        List<ASF_Case_Rule_Entry__c> Stage1CREs = new List<ASF_Case_Rule_Entry__c>();
        
        ASF_Case_Rule_Entry__c stage2_Work_RuleEntry = new ASF_Case_Rule_Entry__c();
        stage2_Work_RuleEntry.Number__c = 1;
        stage2_Work_RuleEntry.Case_Rule__c = stage1_StageMovement_Rule.Id;
        stage2_Work_RuleEntry.Field_Api_Name__c = 'Stage__c';
        stage2_Work_RuleEntry.Operator__c = '=';
        stage2_Work_RuleEntry.Data_Type__c = 'STRING';
        stage2_Work_RuleEntry.Value__c = 'In Progress with Recovery';
        stage2_Work_RuleEntry.External_ID__c = 'CRE-STAGEMV-OD-003';
        
        Stage1CREs.add(stage2_Work_RuleEntry);
        
        ASF_Case_Rule_Entry__c stage2_Work_RuleEntry1 = new ASF_Case_Rule_Entry__c();
        stage2_Work_RuleEntry1.Number__c = 2;
        stage2_Work_RuleEntry1.Case_Rule__c = stage1_StageMovement_Rule.Id;
        stage2_Work_RuleEntry1.Field_Api_Name__c = 'DB_Hours__c';
        stage2_Work_RuleEntry1.Operator__c = '=';
        stage2_Work_RuleEntry1.Data_Type__c = 'STRING';
        stage2_Work_RuleEntry1.Value__c = '12';
        stage2_Work_RuleEntry1.External_ID__c = 'CRE-Work-CIBIL-OD-004';
        
        Stage1CREs.add(stage2_Work_RuleEntry1);
        
        ASF_Case_Rule_Entry__c stage2_Work_RuleEntry2 = new ASF_Case_Rule_Entry__c();
        stage2_Work_RuleEntry2.Number__c = 3;
        stage2_Work_RuleEntry2.Case_Rule__c = stage1_StageMovement_Rule.Id;
        stage2_Work_RuleEntry2.Field_Api_Name__c = 'Reopened__c';
        stage2_Work_RuleEntry2.Operator__c = '=';
        stage2_Work_RuleEntry2.Data_Type__c = 'boolean';
        stage2_Work_RuleEntry2.Value__c = 'True';
        stage2_Work_RuleEntry2.External_ID__c = 'CRE-Work-CIBIL-OD-005';
        
        Stage1CREs.add(stage2_Work_RuleEntry2);
        
        ASF_Case_Rule_Entry__c stage2_Work_RuleEntry3 = new ASF_Case_Rule_Entry__c();
        stage2_Work_RuleEntry3.Number__c = 4;
        stage2_Work_RuleEntry3.Case_Rule__c = stage1_StageMovement_Rule.Id;
        stage2_Work_RuleEntry3.Field_Api_Name__c = 'Stage__c';
        stage2_Work_RuleEntry3.Operator__c = 'not in';
        stage2_Work_RuleEntry3.Data_Type__c = 'STRING';
        stage2_Work_RuleEntry3.Value__c = 'In Progress with Recovery';
        stage2_Work_RuleEntry3.External_ID__c = 'CRE-Work-CIBIL-OD-006';
        Stage1CREs.add(stage2_Work_RuleEntry3);
       
        ASF_Case_Rule_Entry__c stage2_Work_RuleEntry4 = new ASF_Case_Rule_Entry__c();
        stage2_Work_RuleEntry4.Number__c = 5;
        stage2_Work_RuleEntry4.Case_Rule__c = stage1_StageMovement_Rule.Id;
        stage2_Work_RuleEntry4.Field_Api_Name__c = 'Stage__c';
        stage2_Work_RuleEntry4.Operator__c = 'contains';
        stage2_Work_RuleEntry4.Data_Type__c = 'STRING';
        stage2_Work_RuleEntry4.Value__c = 'In Progress with Recovery';
        stage2_Work_RuleEntry4.External_ID__c = 'CRE-Work-CIBIL-OD-007';
        Stage1CREs.add(stage2_Work_RuleEntry4);
        
        ASF_Case_Rule_Entry__c stage2_Work_RuleEntry5 = new ASF_Case_Rule_Entry__c();
        stage2_Work_RuleEntry5.Number__c = 6;
        stage2_Work_RuleEntry5.Case_Rule__c = stage1_StageMovement_Rule.Id;
        stage2_Work_RuleEntry5.Field_Api_Name__c = 'Stage__c';
        stage2_Work_RuleEntry5.Operator__c = '!=';
        stage2_Work_RuleEntry5.Data_Type__c = 'STRING';
        stage2_Work_RuleEntry5.Value__c = 'In Progress with Recovery';
        stage2_Work_RuleEntry5.External_ID__c = 'CRE-Work-CIBIL-OD-008';
        Stage1CREs.add(stage2_Work_RuleEntry5);
        
        ASF_Case_Rule_Entry__c stage2_Work_RuleEntry6 = new ASF_Case_Rule_Entry__c();
        stage2_Work_RuleEntry6.Number__c = 7;
        stage2_Work_RuleEntry6.Case_Rule__c = stage1_StageMovement_Rule.Id;
        stage2_Work_RuleEntry6.Field_Api_Name__c = 'Reopened__c';
        stage2_Work_RuleEntry6.Operator__c = '!=';
        stage2_Work_RuleEntry6.Data_Type__c = 'boolean';
        stage2_Work_RuleEntry6.Value__c = 'True';
        stage2_Work_RuleEntry6.External_ID__c = 'CRE-Work-CIBIL-OD-009';
        Stage1CREs.add(stage2_Work_RuleEntry6);
        
        ASF_Case_Rule_Entry__c stage2_Work_RuleEntry7 = new ASF_Case_Rule_Entry__c();
        stage2_Work_RuleEntry7.Number__c = 8;
        stage2_Work_RuleEntry7.Case_Rule__c = stage1_StageMovement_Rule.Id;
        stage2_Work_RuleEntry7.Field_Api_Name__c = 'ABHFL_Case_Detail__r.Realization_status__c';
        stage2_Work_RuleEntry7.Operator__c = '=';
        stage2_Work_RuleEntry7.Data_Type__c = 'STRING';
        stage2_Work_RuleEntry7.Value__c = 'Cleared';
        stage2_Work_RuleEntry7.External_ID__c = 'CRE-Work-CIBIL-OD-010';
        Stage1CREs.add(stage2_Work_RuleEntry7);
        
        ASF_Case_Rule_Entry__c stage2_Work_RuleEntry8 = new ASF_Case_Rule_Entry__c();
        stage2_Work_RuleEntry8.Number__c = 9;
        stage2_Work_RuleEntry8.Case_Rule__c = stage1_StageMovement_Rule.Id;
        stage2_Work_RuleEntry8.Field_Api_Name__c = 'ABHFL_Case_Detail__r.EMI_Tenure__c';
        stage2_Work_RuleEntry8.Operator__c = '=';
        stage2_Work_RuleEntry8.Data_Type__c = 'Decimal';
        stage2_Work_RuleEntry8.Value__c = '10';
        stage2_Work_RuleEntry8.External_ID__c = 'CRE-Work-CIBIL-OD-011';
        Stage1CREs.add(stage2_Work_RuleEntry8);
         
        insert Stage1CREs;
       
    } */
    
    @isTest
    private static void evaluateCaseRuleTest() {
        //User testUser = ASF_TestDataFactory.createCS60UserWithPermissions();
        //System.runAs(testUser){ 
       /* Id caseRuleId = [select id from ASF_Case_Rule__c where Type__c = 'Stage Movement' and Logical_Condition__c = '1' LIMIT 1].Id;
        
        List<ASF_Case_Rule_Entry__c> caseRuleEntryList = [Select Id, Number__c, Case_Rule__c, Field_Api_Name__c, Operator__c, Data_Type__c, 
                                                          Value__c, External_ID__c from ASF_Case_Rule_Entry__c where Case_Rule__c =: caseRuleId];
        
        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c, PAY_Payment_Detail__c, PAY_Payment_Detail__r.Payment_mode__c,
                           SLA_Target_1__c, CSAT__c, DB_Hours__c, has_CheckLists__c, Has_Open_Tasks__c from case LIMIT 1];  
        
        PAY_Payment_Detail__c paymentRec = [select Id, Payment_mode__c from PAY_Payment_Detail__c LIMIT 1];
        caseRecord.PAY_Payment_Detail__c = paymentRec.Id;
        update caseRecord;
        
        Test.startTest();
        Boolean evaluationResult = ASF_CaseFrameworkValidator.evaluateCaseRule('1', caseRuleEntryList, caseRecord);
        Test.stopTest();
        Assert.areEqual(evaluationResult, true); */
        //}    
    }
    
   /* @isTest
    private static void evaluateCaseRuleTest2() {
        //User testUser = ASF_TestDataFactory.createCS60UserWithPermissions();
        //System.runAs(testUser){
        Id caseRuleId = [select id from ASF_Case_Rule__c where Type__c = 'Approval' and Logical_Condition__c = '1 AND 2 AND 3 AND 4 AND 7 AND 8 AND 9 AND (5 OR 6)' LIMIT 1].Id;
        
        List<ASF_Case_Rule_Entry__c> caseRuleEntryList = [Select Id, Number__c, Case_Rule__c, Field_Api_Name__c, Operator__c, Data_Type__c, 
                                                          Value__c, External_ID__c from ASF_Case_Rule_Entry__c where Case_Rule__c =: caseRuleId];
        
        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c, PAY_Payment_Detail__c, PAY_Payment_Detail__r.Payment_mode__c,
                           SLA_Target_1__c, CSAT__c, DB_Hours__c, has_CheckLists__c, Has_Open_Tasks__c, Reopen_Days__c,Reopened__c,ABHFL_Case_Detail__r.EMI_Tenure__c  from case LIMIT 1];  
        
        PAY_Payment_Detail__c paymentRec = [select Id, Payment_mode__c from PAY_Payment_Detail__c LIMIT 1];
        caseRecord.PAY_Payment_Detail__c = paymentRec.Id;
        update caseRecord;
        
        Test.startTest();
        Boolean evaluationResult = ASF_CaseFrameworkValidator.evaluateCaseRule('1 AND 2 AND 3 AND 4 AND 7 AND 8 AND 9 AND (5 OR 6)', caseRuleEntryList, caseRecord);
        Test.stopTest();
        Assert.areNotEqual(evaluationResult, true);
        //}    
    }
    
    @isTest
    private static void validateChecklistsTest() {
        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case LIMIT 1];
        
        Test.startTest();
        Boolean evaluationResult = ASF_CaseFrameworkValidator.validateChecklists(caseRecord);
        Test.stopTest();
        Assert.areEqual(evaluationResult, true);   
    }
    
    @isTest
    private static void validateValidationTest() {
        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case LIMIT 1];
      
        List<ASF_Case_Stage_Config__c> stageConfigList = [select Id, Order__c, StageName__c, Stage_SLA_1__c, Status_Mapping__c,
                                                         SLA_Target_1_Type__c, Query_Fields__c, Manual_Stage__c 
                                                         from ASF_Case_Stage_Config__c where Status_Mapping__c= 'In Progress'];
        Test.startTest();
        String evaluationResult = ASF_CaseFrameworkValidator.validateValidations(caseRecord,stageConfigList[0]);
        Test.stopTest();
        Assert.areEqual('Success', evaluationResult);   
    }
    
    @isTest
    private static void validateTasksTest() {
        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case LIMIT 1];
        
        Test.startTest();
        Boolean evaluationResult = ASF_CaseFrameworkValidator.validateTasks(caseRecord);
        Test.stopTest();
        Assert.areEqual(evaluationResult, true);   
    }

    @isTest
    private static void validateApprovals(){
        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case LIMIT 1];
        
        Test.startTest();
            Boolean evaluationResult = ASF_CaseFrameworkValidator.validateApprovals(caseRecord);
        Test.stopTest();
        Assert.areEqual(evaluationResult, true);   
    }

    
    @isTest
    private static void validateIntegrationsTest() {
        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case LIMIT 1];
        List<ASF_Integration__c> IntegrationList = [select Id, Case_Stage_Config__c from ASF_Integration__c where Mandatory_At_Stage_Movement__c=true];
        
        List<ASF_Case_Stage_Config__c> stageConfigList = [select Id, Order__c, StageName__c, Stage_SLA_1__c, Status_Mapping__c,
                                                         SLA_Target_1_Type__c, Query_Fields__c, Manual_Stage__c 
                                                         from ASF_Case_Stage_Config__c where Id=: IntegrationList[0].Case_Stage_Config__c];
        Test.startTest();
        String evaluationResult = ASF_CaseFrameworkValidator.validateIntegrations(caseRecord, stageConfigList[0]);
        Test.stopTest();   
    } */
    
}