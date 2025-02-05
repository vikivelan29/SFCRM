/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-24-2024
 * @last modified by  : rsinghnagar@salesforce.com
**/
@SuppressWarnings('PMD.FormalParameterNamingConventions')
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
        List<Case> caseList = [select Id,LOB__c, CCC_External_Id__c, Stage__c, pending_clarification__c,PAY_Payment_Detail__c,SLA_Target_1__c, PAY_Payment_Detail__r.Payment_mode__c,
                          CSAT__c, DB_Hours__c, has_CheckLists__c, Has_Open_Tasks__c from case LIMIT 1];
        System.debug('@@@caseRuleList'+caseRuleList);
        Map<Id, List<ASF_Case_Rule__c>> allCaseRules = new Map<Id, List<ASF_Case_Rule__c>>();
        for(case caseRec : caseList){
             allCaseRules.put(caseRec.Id, caseRuleList);
        }
        Test.startTest();
        system.debug('rule list--'+caseRuleList.size()+caseRuleList);
        Map<Id, List<ASF_Case_Approv__c>> approvalList = ASF_CaseFrameworkHelper.addApprovals(caseList, allCaseRules);
        Test.stopTest();
        Assert.isNotNull(approvalList, 'approvalList should not be null'); 
        //}    
    } 
    
    @isTest
    private static void addChecklistsTest() {
        List<ASF_Case_Rule__c> caseRuleList = ASF_CaseFrameworkHelper_Test.queryData('Checklists');
        List<Case> caseList = [select Id, LOB__c,CCC_External_Id__c, Stage__c, CSAT__c, pending_clarification__c, Business_Unit__c from case where CCC_External_Id__c = 'CCC-CC-CCLTD-01'];
        Map<Id, List<ASF_Case_Rule__c>> allCaseRules = new Map<Id, List<ASF_Case_Rule__c>>();
        for(case caseRec : caseList){
             allCaseRules.put(caseRec.Id, caseRuleList);
        }
        
        Test.startTest();
        Map<Id, List<ASF_Checklist__c>> checklistList = ASF_CaseFrameworkHelper.addChecklists(caseList, allCaseRules);
        Test.stopTest();
        Assert.isNotNull(checklistList, 'checklist should not be null');
        
    }
    
    @isTest
    private static void addTasksTest() {
        List<ASF_Case_Rule__c> caseRuleList = ASF_CaseFrameworkHelper_Test.queryData('Work');
        List<Case> caseList = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c, BusinessHoursId from case];
        Map<Id, List<ASF_Case_Rule__c>> allCaseRules = new Map<Id, List<ASF_Case_Rule__c>>();
        for(case caseRec : caseList){
             allCaseRules.put(caseRec.Id, caseRuleList);
        }
        
        Test.startTest();
        Map<Id, List<Task>> taskList = ASF_CaseFrameworkHelper.addTasks(caseList, allCaseRules);
        Test.stopTest();
        Assert.isNotNull(taskList, 'tasklist should not be null');
        
    }
    
    @isTest
    private static void addSlaTest() {
        List<ASF_Case_Rule__c> caseRuleList = ASF_CaseFrameworkHelper_Test.queryData('SLA Override');
        List<Case> caseList = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c, BusinessHoursId from case];
        Map<Id, List<ASF_Case_Rule__c>> allCaseRules = new Map<Id, List<ASF_Case_Rule__c>>();
        for(case caseRec : caseList){
             allCaseRules.put(caseRec.Id, caseRuleList);
        }
        
        Test.startTest();
        Map<Id, Map<string,long>> slaList = ASF_CaseFrameworkHelper.addSLA(caseList, allCaseRules);
        Test.stopTest();
    }
    
    @isTest
    private static void runAssignmentRulesTest() {
        List<ASF_Case_Rule__c> caseRuleList = ASF_CaseFrameworkHelper_Test.queryData('Assignment'); 
        List<Case> caseList = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c, CreatedById,PAY_Payment_Detail__c,SLA_Target_1__c, PAY_Payment_Detail__r.Payment_mode__c,
                          CSAT__c, DB_Hours__c, has_CheckLists__c, Has_Open_Tasks__c from case where CCC_External_Id__c = 'CCC-CC-CCLTD-01'];
        Map<Id, List<ASF_Case_Rule__c>> allCaseRules = new Map<Id, List<ASF_Case_Rule__c>>();
        for(case caseRec : caseList){
             allCaseRules.put(caseRec.Id, caseRuleList);
        }
        Test.startTest();
        Map<Id,ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo> info = ASF_CaseFrameworkHelper.runAssignmentRules(caseList, allCaseRules);
        Test.stopTest();
        Assert.isNotNull(info, 'assignmentRule should not be null');
        
    }
    
    @isTest
    private static void runValidationRulesTest() {
        List<ASF_Case_Rule__c> caseRuleList = ASF_CaseFrameworkHelper_Test.queryData('Validation'); 
        List<Case> caseList = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c, CreatedById,PAY_Payment_Detail__c,SLA_Target_1__c, PAY_Payment_Detail__r.Payment_mode__c,
                          CSAT__c, DB_Hours__c, has_CheckLists__c, Has_Open_Tasks__c from case where CCC_External_Id__c = 'CCC-CC-CCLTD-01'];
        Map<Id, List<ASF_Case_Rule__c>> allCaseRules = new Map<Id, List<ASF_Case_Rule__c>>();
        for(case caseRec : caseList){
             allCaseRules.put(caseRec.Id, caseRuleList);
        }
        Test.startTest();
        Map<Id,String> validationResult = ASF_CaseFrameworkHelper.runValidationRules(caseList, allCaseRules);
        Test.stopTest();
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
        List<ASF_Integration__c> caseIntList =[Select Id, Auto_Run_on_Load__c ,C3ExternalId__c, Display_Name__c ,Display_Order__c ,STP_API_Identifier__c,
        External_Id__c,Mandatory_At_Stage_Movement__c ,Processing_Class__c ,STP_Processing_Class__c, Type__c,
        UI_Component__c ,Visibility_Class__c ,When_to_Appear__c,Query_Fields__c,Case_Stage_Config__c
                                               FROM ASF_Integration__c];
        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case LIMIT 1];
        
        Test.startTest();
            ASF_IntegrationsController.IntegrationWrapper result =  ASF_CaseFrameworkHelper.runIntegrations(caseRecord, caseIntList);
        Test.stopTest();
        System.assertEquals('Error', result.status);
        
    }
    @isTest
    private static void runIntRulesListTest() {
        List<ASF_Integration__c> caseIntList =[Select Id, External_Id__c, Case_Stage_Config__c, Type__c, When_to_Appear__c, Display_Name__c, 
                                               Auto_Run_on_Load__c, Processing_Class__c, Query_Fields__c, Priority__c
                                               FROM ASF_Integration__c];
        List<Case> caseList = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c,Technical_Source__c from case];
        Map<Id, List<ASF_Integration__c>> allIntegrations = new Map<Id, List<ASF_Integration__c>>();
        for(Case caseRec : caseList){
            allIntegrations.put(caseRec.Id, caseIntList);
        }
        Test.startTest();
            Map<Id, ASF_IntegrationsController.IntegrationWrapper> result =  ASF_CaseFrameworkHelper.runIntegrations(caseList, allIntegrations);
        Test.stopTest();
        //System.assertEquals('Error', result.status);
        
    }

    @isTest
    private static void testFindAssignmentPreviouslyVisited(){
        
        List<Case> caseList = [
                            SELECT Id, AccountId, CCC_External_Id__c,  contactId, Status, Stage__c, pending_clarification__c 
                            FROM case 
                            WHERE CCC_External_Id__c='12345'];

        Map<Id, String> caseStageMap = new Map<Id, String>();
        for(case caseRec : caseList){
             caseStageMap.put(caseRec.Id, caseRec.Stage__c);
        }        
        Map<Id, ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo> info = ASF_CaseFrameworkHelper.findAssignmentForPreviouslyVisitedStage(caseStageMap);
    }
    
    static List<ASF_Case_Rule__c> queryData(String TypeVal){
        
        return [Select Id, Case_Stage_Config__c, Logical_Condition__c, Order__c, Type__c, Assign_to_Initiator__c, Step_1_Approver_1__c,
                Step_1_Approver_2__c, Step_2_Approver_1__c, Step_2_Approver_2__c, Approval_Style__c,Assigned_Queue_Id__c,
                Assigned_Error_Queue_Id__c,Assignment_Queue_Name__c,
                (select Id, Number__c, Field_Api_Name__c, Operator__c, Data_Type__c, 
                 Value__c, External_ID__c from Case_Rule_Entries__r),
                (select id, Case_Rule__c, name, Mandatory__c, Description__c, Type__c, Checklist_External_Id__c,Label__c,Picklist_Options__c from Case_Checklist_Masters__r),
                (select Id, Task_Title__c, Task_Description__c, Completion_Time__c, Case_Rule__c,
                 Assigned_Queue__c, Work_Item_External_ID__c from Work_Items__r)
                FROM ASF_Case_Rule__c where Type__c =: TypeVal];
        
        
    } 
      
}