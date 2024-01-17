/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-22-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public class ASF_CaseFrameworkHelper_Test {
    

    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    @testSetup
    static void setUpData(){
        ASF_TestDataFactory.createCaseRecords(1);
        
        ASF_TestDataFactory.createCaseCategoryConfig();
        //ASF_TestDataFactory.createC3IntegrationsAndCase();
        ASF_TestDataFactory.createC3WithPrePopulateIntegrations();
        insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                          Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                          Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
         Account a = new Account();
         a.Name = '12344';
        //a.CRN__c = '12344';
        insert a;
        
        Asset ast = new Asset();
        ast.accountId = a.id;
        //ast.Financial_Account_Number__c ='2333423';
        ast.Name = 'aas';
        ast.Aggrement_Date__c = Date.newInstance(2023, 06, 09);
        ast.Application_Number__c = '12345';
        ast.Approved_Date__c = Date.newInstance(2023, 06, 10);
        ast.Approved_Limit__c = 200;
        ast.Branch_Code__c = 'AST';
        insert ast;
        
        Contact con = new Contact();
        con.Lastname ='Test con';
        con.AccountId = a.Id;
        con.Email = 'test@test.com';
        con.Phone = '8329673314';
        insert con;
        
       ASF_Case_Category_Config__c ccc = new ASF_Case_Category_Config__c();
        ccc.Type__c = 'tes';
        ccc.CCC_External_Id__c = '12345';
        //ccc.Business_Unit__c = 'ABFL';
        ccc.Sub_Type__c = 'TDC Refund';
        ccc.Overall_Case_Closure_SLA__c = 10;
        insert ccc; 
        
       ASF_Case_Stage_Config__c stage1 = new ASF_Case_Stage_Config__c();
        stage1.Case_Category_Config__c = ccc.Id;
        stage1.Order__c = 1;
        stage1.StageName__c  = 'New';
        stage1.Stage_SLA_1__c = 1;
        stage1.Status_Mapping__c = 'New';
	        // stage1.Stage_SLA_3__c = 3;
        stage1.SLA_Target_1_Type__c = 'Manager';
        stage1.Query_Fields__c = 'Id,Stage__c';
        stage1.Manual_Stage__c = false;
        stage1.Stage_External_Id__c='STG_1';
        
        insert stage1;

        ASF_Case_Stage_Config__c stage2 = new ASF_Case_Stage_Config__c();
        stage2.Case_Category_Config__c = ccc.Id;
        stage2.Order__c = 1;
        stage2.StageName__c  = 'In Progress';
        stage2.Stage_SLA_1__c = 1;
        stage2.Status_Mapping__c = 'In Progress';
        stage2.SLA_Target_1_Type__c = 'Manager';
        stage2.Query_Fields__c = 'Id,Stage__c';
        stage2.Manual_Stage__c = false;
        stage2.Stage_External_Id__c='STG_2';
        
        insert stage2;
        

    List<ASF_Case_Rule__c> caseRuleList = new List<ASF_Case_Rule__c>();
    ASF_Case_Rule__c stage1_StageMovement_Rule = new ASF_Case_Rule__c();

    stage1_StageMovement_Rule.Case_Stage_Config__c = stage1.Id;
    stage1_StageMovement_Rule.Logical_Condition__c = '1';
    stage1_StageMovement_Rule.Order__c = 1;
    stage1_StageMovement_Rule.Type__c = 'Stage Movement';
    caseRuleList.add(stage1_StageMovement_Rule);


    ASF_Case_Rule__c stage2_AssignmentMovement_Rule = new ASF_Case_Rule__c();
    stage2_AssignmentMovement_Rule.Case_Stage_Config__c = stage2.Id;
    stage2_AssignmentMovement_Rule.Logical_Condition__c = '1';
    stage2_AssignmentMovement_Rule.Order__c = 2;
    stage2_AssignmentMovement_Rule.Type__c = 'Assignment';    
    caseRuleList.add(stage2_AssignmentMovement_Rule);
    
    /*ASF_Case_Rule__c stage1_Approvals_Rule = new ASF_Case_Rule__c();

    stage1_Approvals_Rule.Case_Stage_Config__c = stage1.Id;
    stage1_Approvals_Rule.Logical_Condition__c = '1';
    stage1_Approvals_Rule.Order__c = 2;
    stage1_Approvals_Rule.Type__c = 'Approval';
    caseRuleList.add(stage1_Approvals_Rule);*/
        
     
    insert caseRuleList;
        
        List<ASF_Case_Rule_Entry__c> CREs = new List<ASF_Case_Rule_Entry__c>();
        ASF_Case_Rule_Entry__c stage1_Movement_RuleEntry = new ASF_Case_Rule_Entry__c();
        stage1_Movement_RuleEntry.Number__c = 1;
        stage1_Movement_RuleEntry.Case_Rule__c = stage1_StageMovement_Rule.Id;
        stage1_Movement_RuleEntry.Field_Api_Name__c = 'CCC_External_Id__c';
        stage1_Movement_RuleEntry.Operator__c = '=';
        stage1_Movement_RuleEntry.Data_Type__c = 'STRING';
        stage1_Movement_RuleEntry.Value__c = '12345';
        stage1_Movement_RuleEntry.External_ID__c = 'CRE-STAGEMV-OD-010';
        CREs.add(stage1_Movement_RuleEntry);

        ASF_Case_Rule_Entry__c stage2_Assignment_RuleEntry = new ASF_Case_Rule_Entry__c();
        stage2_Assignment_RuleEntry.Number__c = 1;
        stage2_Assignment_RuleEntry.Case_Rule__c = stage2_AssignmentMovement_Rule.Id;
        stage2_Assignment_RuleEntry.Field_Api_Name__c = 'CCC_External_Id__c';
        stage2_Assignment_RuleEntry.Operator__c = '=';
        stage2_Assignment_RuleEntry.Data_Type__c = 'STRING';
        stage2_Assignment_RuleEntry.Value__c = '12345';
        stage2_Assignment_RuleEntry.External_ID__c = 'CRE-STAGEMV-OD-020';


        CREs.add(stage2_Assignment_RuleEntry);
        
        /*ASF_Case_Rule_Entry__c stage1_app_RuleEntry = new ASF_Case_Rule_Entry__c();
        stage1_app_RuleEntry.Number__c = 1;
        stage1_app_RuleEntry.Case_Rule__c = stage1_Approvals_Rule.Id;
        stage1_app_RuleEntry.Field_Api_Name__c = 'CCC_External_Id__c';
        stage1_app_RuleEntry.Operator__c = '=';
        stage1_app_RuleEntry.Data_Type__c = 'STRING';
        stage1_app_RuleEntry.Value__c = '12345';
        stage1_app_RuleEntry.External_ID__c = 'CRE-APP-OD-1';
        CREs.add(stage1_app_RuleEntry);*/
        
        insert CREs;
        
        Case cs = new Case();
        cs.AccountId = a.Id;
        cs.CCC_External_Id__c = '12345';
        cs.contactId = con.Id;
        cs.Status = 'New';
        cs.Stage__c='New';
        insert cs;
        
    }
    
    @isTest
    private static void addApprovalsTest() {
        //User testUser = ASF_TestDataFactory.createCS60UserWithPermissions();
        //System.runAs(testUser){
        List<ASF_Case_Rule__c> caseRuleList = ASF_CaseFrameworkHelper_Test.queryData('Approval');
        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c,PAY_Payment_Detail__c,SLA_Target_1__c, PAY_Payment_Detail__r.Payment_mode__c,
                          CSAT__c, DB_Hours__c, has_CheckLists__c, Has_Open_Tasks__c from case LIMIT 1];
        System.debug('@@@caseRuleList'+caseRuleList);
        
        Test.startTest();
        system.debug('rule list--'+caseRuleList.size()+caseRuleList);
        List<ASF_Case_Approv__c> approvalList = ASF_CaseFrameworkHelper.addApprovals(caseRecord, caseRuleList);
        Test.stopTest();
        Assert.isNotNull(approvalList, 'approvalList should not be null');
        //}    
    }
    
    @isTest
    private static void addChecklistsTest() {
        List<ASF_Case_Rule__c> caseRuleList = ASF_CaseFrameworkHelper_Test.queryData('Checklists');
        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case where CCC_External_Id__c = 'CCC-CC-CCLTD-01' LIMIT 1];
        
        Test.startTest();
        List<ASF_Checklist__c> checklistList = ASF_CaseFrameworkHelper.addChecklists(caseRecord, caseRuleList);
        Test.stopTest();
        Assert.isNotNull(checklistList, 'checklist should not be null');
        
    }
    
    @isTest
    private static void addTasksTest() {
        List<ASF_Case_Rule__c> caseRuleList = ASF_CaseFrameworkHelper_Test.queryData('Work');
        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c, BusinessHoursId from case LIMIT 1];
        
        Test.startTest();
        List<Task> taskList = ASF_CaseFrameworkHelper.addTasks(caseRecord, caseRuleList);
        Test.stopTest();
        Assert.isNotNull(taskList, 'tasklist should not be null');
        
    }
    
    @isTest
    private static void runAssignmentRulesTest() {
        List<ASF_Case_Rule__c> caseRuleList = ASF_CaseFrameworkHelper_Test.queryData('Assignment'); 
        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c, CreatedById,PAY_Payment_Detail__c,SLA_Target_1__c, PAY_Payment_Detail__r.Payment_mode__c,
                          CSAT__c, DB_Hours__c, has_CheckLists__c, Has_Open_Tasks__c from case where CCC_External_Id__c = 'CCC-CC-CCLTD-01' LIMIT 1];
        
        Test.startTest();
        ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo info = ASF_CaseFrameworkHelper.runAssignmentRules(caseRecord, caseRuleList);
        Test.stopTest();
        Assert.areNotEqual(info.defaultOwnerId, 'ownerId should not be null');
        
    }
    
    @isTest
    private static void runValidationRulesTest() {
        List<ASF_Case_Rule__c> caseRuleList = ASF_CaseFrameworkHelper_Test.queryData('Validation'); 
        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c, CreatedById,PAY_Payment_Detail__c,SLA_Target_1__c, PAY_Payment_Detail__r.Payment_mode__c,
                          CSAT__c, DB_Hours__c, has_CheckLists__c, Has_Open_Tasks__c from case where CCC_External_Id__c = 'CCC-CC-CCLTD-01' LIMIT 1];
        
        Test.startTest();
        String validationResult = ASF_CaseFrameworkHelper.runValidationRules(caseRecord, caseRuleList);
        Test.stopTest();
        Assert.areEqual('Success', validationResult);
        
    }
    
    @isTest
    private static void runMovementRulesTest() {
       // List<ASF_Case_Rule__c> caseRuleList = ASF_CaseFrameworkHelper_Test.queryData('Stage Movement');
        List<ASF_Case_Rule__c> caseRuleList=[Select Id, Case_Stage_Config__c, Logical_Condition__c, Order__c, Type__c, Assign_to_Initiator__c, Step_1_Approver_1__c,
                Step_1_Approver_2__c, Step_2_Approver_1__c, Step_2_Approver_2__c, Approval_Style__c,Assigned_Error_Queue_Id__c,
                (select Id, Number__c, Field_Api_Name__c, Operator__c, Data_Type__c, 
                 Value__c, External_ID__c from Case_Rule_Entries__r),
                (select id, Case_Rule__c, name, Mandatory__c, Description__c, Type__c from Case_Checklist_Masters__r),
                (select Id, Task_Title__c, Task_Description__c, Completion_Time__c, Case_Rule__c,
                 Assigned_Queue__c from Work_Items__r)
                FROM ASF_Case_Rule__c where Type__c = 'Stage Movement' AND Stage_external_ID__c='STG_1'];
        System.debug('@@@caseRuleList'+caseRuleList);
        Case caseRecord = [select Id, AccountId, CCC_External_Id__c,  contactId, Status, Stage__c, pending_clarification__c from case where CCC_External_Id__c='12345' LIMIT 1];
        
        Test.startTest();
       Boolean result = ASF_CaseFrameworkHelper.runStageMovementRules(caseRecord, caseRuleList);
        Test.stopTest();
        Assert.areEqual(result,true);
        
    }
    
    @isTest
    private static void runIntRulesTest() {
        List<ASF_Integration__c> caseIntList =[Select Id, External_Id__c, Case_Stage_Config__c, Type__c, When_to_Appear__c, Display_Name__c, 
                                               Auto_Run_on_Load__c, Processing_Class__c
                                               FROM ASF_Integration__c];
        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case LIMIT 1];
        
        Test.startTest();
            ASF_IntegrationsController.IntegrationWrapper result =  ASF_CaseFrameworkHelper.runIntegrations(caseRecord, caseIntList);
        Test.stopTest();
        System.assertEquals('Error', result.status);
        
    }

    @isTest
    private static void testFindAssignmentPreviouslyVisited(){
        
        Case caseRecord = [
                            SELECT Id, AccountId, CCC_External_Id__c,  contactId, Status, Stage__c, pending_clarification__c 
                            FROM case 
                            WHERE CCC_External_Id__c='12345' LIMIT 1];

       
        ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo info = ASF_CaseFrameworkHelper.findAssignmentForPreviouslyVisitedStage(caseRecord, 'New');
        system.assertEquals(info.defaultOwnerId, UserInfo.getUserId());

    }
    
    static List<ASF_Case_Rule__c> queryData(String TypeVal){
        
        return [Select Id, Case_Stage_Config__c, Logical_Condition__c, Order__c, Type__c, Assign_to_Initiator__c, Step_1_Approver_1__c,
                Step_1_Approver_2__c, Step_2_Approver_1__c, Step_2_Approver_2__c, Approval_Style__c,Assigned_Queue_Id__c,
                Assigned_Error_Queue_Id__c,
                (select Id, Number__c, Field_Api_Name__c, Operator__c, Data_Type__c, 
                 Value__c, External_ID__c from Case_Rule_Entries__r),
                (select id, Case_Rule__c, name, Mandatory__c, Description__c, Type__c, Checklist_External_Id__c from Case_Checklist_Masters__r),
                (select Id, Task_Title__c, Task_Description__c, Completion_Time__c, Case_Rule__c,
                 Assigned_Queue__c, Work_Item_External_ID__c from Work_Items__r)
                FROM ASF_Case_Rule__c where Type__c =: TypeVal];
        
        
    }  
      
}