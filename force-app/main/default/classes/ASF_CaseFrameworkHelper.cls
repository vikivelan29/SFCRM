public with sharing class ASF_CaseFrameworkHelper {
    
    /**
     * If Approval Rules are present, Add new Approval Records with Approvers set
     * Return the Approval Records to calling method, to b
     * e inserted
     */
    public static List<ASF_Case_Approv__c> addApprovals(Case currentCase, List<ASF_Case_Rule__c> allCaseRules){

        List<ASF_Case_Approv__c> approvalList = new List<ASF_Case_Approv__c>();
        for (ASF_Case_Rule__c caseRule : allCaseRules){
            if(caseRule.Type__c == 'Approval'){
                
                boolean result = ASF_CaseFrameworkValidator.evaluateCaseRule(
                    caseRule.Logical_Condition__c,
                    caseRule.Case_Rule_Entries__r,
                    currentCase);
                if (result == true) {
                    //Logic to insert into approvals
                    ASF_Case_Approv__c caseApprovalRecord = new ASF_Case_Approv__c();
                    caseApprovalRecord.Approver_01__c  = caseRule.Step_1_Approver_1__c;
                    caseApprovalRecord.Approver_02__c = caseRule.Step_1_Approver_2__c;
                    caseApprovalRecord.Approver_03__c = caseRule.Step_2_Approver_1__c;
                    caseApprovalRecord.Approver_04__c = caseRule.Step_2_Approver_2__c;
                    caseApprovalRecord.Approval_Type__c = caseRule.Approval_Style__c;
                    caseApprovalRecord.Approval_Status__c  = 'Pending';
                    caseApprovalRecord.Case_Stage_At_Creation__c = currentCase.Stage__c;
                    caseApprovalRecord.SR__c = currentCase.Id;
                    approvalList.add(caseApprovalRecord);
                    break;
                }
            }
        }
        return approvalList;
    }

    /**
     * If Checklist Rules are present, Add new Checklist Records from Master
     * Return the Checklist Records to calling method, to be inserted
     */
    public static List<ASF_Checklist__c> addChecklists(Case currentCase, List<ASF_Case_Rule__c> allCaseRules){
        
        List<ASF_Checklist__c> checklistList = new List<ASF_Checklist__c>();
        
        for (ASF_Case_Rule__c caseRule : allCaseRules) {

            if(caseRule.Type__c == 'Checklists'){
                boolean result = ASF_CaseFrameworkValidator.evaluateCaseRule(
                    caseRule.Logical_Condition__c,
                    caseRule.Case_Rule_Entries__r,
                    currentCase);
                if (result == true){
                    for (ASF_Case_Checklist_Master__c chklistMaster : caseRule.Case_Checklist_Masters__r) {
                        
                        ASF_Checklist__c checklistRecord = new ASF_Checklist__c();
                        checklistRecord.Label__c = chklistMaster.Name;
                        checklistRecord.Mandatory__c = chklistMaster.Mandatory__c;
                        checklistRecord.Description__c = chklistMaster.Description__c;
                        checklistRecord.Type__c = chklistMaster.Type__c;
                        checklistRecord.Status__c = 'Pending';
                        checklistRecord.Systeminitiated__c = true;
                        checklistRecord.Case__c = currentCase.Id;
                        checklistRecord.Stage_Name__c = currentCase.Stage__c;
                        checklistList.add(checklistRecord);
                    }
                    break;
                }
            }
        }
        return checklistList;
    }
    
     /*
    SLA overide rules. only for few case types , SLA override rules will be enabled
    */

    public static  map<string,long> addSLA(Case currentCase, List<ASF_Case_Rule__c> allCaseRules){

        map<string,long> slaMap = new map<string,long>();
        
        for (ASF_Case_Rule__c caseRule : allCaseRules) {

            if(caseRule.Type__c == 'SLA Override' && caseRule.Case_Stage_Config__r.SLA_Override_Enabled__c){
                boolean result = ASF_CaseFrameworkValidator.evaluateCaseRule(
                    caseRule.Logical_Condition__c,
                    caseRule.Case_Rule_Entries__r,
                    currentCase);
                if (result == true){
                    slaMap.put('caseOverride',caseRule.Overall_SLA_Closure__c.longValue());
                    slaMap.put('stageSLA1Override',caseRule.Stage_SLA_Override_1__c.longValue());
                    slaMap.put('stageSLA2Override',caseRule.Stage_SLA_Override_2__c.longValue());
                    slaMap.put('stageSLA3Override',caseRule.Stage_SLA_Override_3__c.longValue());    
                    break;
                }
            }
        }
        return slaMap;
    }   

    /**
     * If Work Rules are present, Add new Task Records from Master
     * Return the Checklist Records to calling method, to be inserted
     */
    public static List<Task> addTasks(Case currentCase, List<ASF_Case_Rule__c> allCaseRules){
        
        List<Task> tasksList = new List<Task>();

        for (ASF_Case_Rule__c caseRule : allCaseRules) {

            if(caseRule.Type__c == 'Work'){
                boolean result = ASF_CaseFrameworkValidator.evaluateCaseRule(
                    caseRule.Logical_Condition__c,
                    caseRule.Case_Rule_Entries__r,
                    currentCase);
                if (result == true){
                    for (ASF_Work_Item__c workItem : caseRule.Work_Items__r) {
                        Task newTask = new Task();
                        newTask.OwnerId = workItem.Assigned_Queue__c;
                        newTask.Subject = workItem.Task_Title__c;
                        newTask.Description = workItem.Task_Description__c;
                        newTask.WhatId = currentCase.Id;
                        newTask.Case_Stage__c = currentCase.Stage__c;
                        newTask.Systeminitiated__c = true;
                        newTask.Task_Type__c ='Automatic';
                        newTask.ActivityDate = Date.valueOf(
                            BusinessHours.add(
                                currentCase.BusinessHoursId,
                                System.now(),
                                Integer.valueOf(workItem.Completion_Time__c * 60 * 60 * 1000)
                            )
                        );
                        newTask.Due_Date_Time__c = 
                            BusinessHours.add(
                            currentCase.BusinessHoursId,
                            System.now(),
                            Integer.valueOf(workItem.Completion_Time__c * 60 * 60 * 1000)
                        );
                        tasksList.add(newTask);
                    }
                    break;
                }
            }
        }
        return tasksList;
    }

    /**
     * Run the Assignment Rules for the Stage passed
     * Returns the Owner Id (Default Queue from Stage Config) or One
     * Determined by the Assignment Rule 
     */
    public static CaseRuleAssignmentInfo runAssignmentRules(Case currentCase, List<ASF_Case_Rule__c> allCaseRules){
        
        CaseRuleAssignmentInfo resultInfo = new CaseRuleAssignmentInfo();
        
        for (ASF_Case_Rule__c caseRule : allCaseRules) {

            if(caseRule.Type__c == 'Assignment'){

                boolean result = ASF_CaseFrameworkValidator.evaluateCaseRule(
                    caseRule.Logical_Condition__c,
                    caseRule.Case_Rule_Entries__r,
                    currentCase);
                
                system.debug('Ritika Case Rule' + ' ' + result);
                if (result == true) {
                    resultInfo.defaultOwnerId = caseRule.Assigned_Queue_Id__c;
                    resultInfo.defaultErrorOwnerId = caseRule.Assigned_Error_Queue_Id__c;
                    break;
                }                
            }
        }
        return resultInfo;
    }

    /**
     * Run the Assignment Rules for the Stage Passed, for Backward movement
     * Returns the Owner and Error Owner info - Id or Queue Id
     * For Back Movement, Find the Previously Actioned User
     */
    public static CaseRuleAssignmentInfo findAssignmentForPreviouslyVisitedStage(Case caseRec, String stageName){
        
        CaseRuleAssignmentInfo resultInfo = new CaseRuleAssignmentInfo();

        // To be able to find the Owner, below is the Logic
        // 1. Find the Last Actioned User of that Stage using SLA History
        // 2. If that user is Inactive, Run Assignment Rule of that Stage and Return the Queue

        List<ASF_Case_SLA_History__c> slaHistoryList = ASF_CaseQueryHandler.getCaseSLAHistories(new Set<Id>{caseRec.Id});
        //TODO - ASk for Created Date DESC in Query
        Id lastActionedUserId;
        for(ASF_Case_SLA_History__c history : slaHistoryList){
            if(history.Stage__c == stageName){
                lastActionedUserId = history.Current_Owner_Id__c;
                break;
            }
        }

        if(lastActionedUserId != null){
            // Check if User is Active
            List<User> lastActionedUser = [
                SELECT Id, IsActive
                FROM User
                WHERE Id=: lastActionedUserId
            ];
            if(lastActionedUser.size() == 1 && lastActionedUser[0].IsActive == true){
                resultInfo.defaultOwnerId = lastActionedUserId;
            }
        }

        return resultInfo;

    }

    /**
     * Run the Assignment Rules for the Stage passed
     * Returns the Boolean if the Rules Pass
     */
    public static Boolean runStageMovementRules(Case currentCase, List<ASF_Case_Rule__c> allCaseRules){
        Boolean result = false;
       
        for (ASF_Case_Rule__c caseRule : allCaseRules) {
            System.debug('@@Logic'+caseRule.Logical_Condition__c);
            if(caseRule.Type__c == 'Stage Movement'){

                result = ASF_CaseFrameworkValidator.evaluateCaseRule(
                    caseRule.Logical_Condition__c,
                    caseRule.Case_Rule_Entries__r,
                    currentCase);

                if(result == true){
                    break;
                }
            }
        }
        return result;
    }

    /**
     * Run All Integrations defined on the Case Stage Config 
     * of Type Auto Run on Load
     */
    public static ASF_IntegrationsController.IntegrationWrapper runIntegrations(Case currentCase, List<ASF_Integration__c> allIntegrations){

        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = 'Success';
        List<ASF_IntegrationsController.IntegrationWrapper> intResults = new List<ASF_IntegrationsController.IntegrationWrapper>();
        for(ASF_Integration__c integ : allIntegrations){
            if(integ.Auto_Run_on_Load__c){
                ASF_IntegrationsController.IntegrationWrapper intResult = ASF_IntegrationsController.runIntegration(integ, currentCase);
                intResults.add(intResult);
            }
        }

        for(ASF_IntegrationsController.IntegrationWrapper wrap : intResults){
            if(wrap.status == 'Error'){
                result =  wrap;
                break;
            }
        }

        return result;
    }


    /**
     * Run All Case Validation Rules defined on the Case Stage Config 
     * If any Rule Fails, 
     */
    public static String runValidationRules(Case currentCase, List<ASF_Case_Rule__c> allCaseRules){
        String returnResult = 'Success';
        for (ASF_Case_Rule__c caseRule : allCaseRules) {

            if(caseRule.Type__c == 'Validation'){

                boolean result = ASF_CaseFrameworkValidator.evaluateCaseRule(
                    caseRule.Logical_Condition__c,
                    caseRule.Case_Rule_Entries__r,
                    currentCase);
                System.debug('***result:'+ result);
                if (result == false) {
                    returnResult = caseRule.Validation_Message__c;
                    break;
                }                
            }
        }    
        return returnResult;
    }

    public class CaseRuleAssignmentInfo{
        public Id defaultOwnerId;
        public Id defaultErrorOwnerId;
        public string status; 
        public string errorMessage;
    }

}