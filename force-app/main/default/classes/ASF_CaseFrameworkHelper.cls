/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-17-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class ASF_CaseFrameworkHelper {
    
    /**
     * If Approval Rules are present, Add new Approval Records with Approvers set
     * Return the Approval Records to calling method, to b
     * e inserted
     */
    public static Map<Id, Boolean> runIntegrationFromLwc = new Map<Id, Boolean>();
    public static Map<Id, List<ASF_Case_Approv__c>> addApprovals(List<Case> caseList, Map<Id, List<ASF_Case_Rule__c>> allCaseRules){

        Map<Id, List<ASF_Case_Approv__c>> approvalMap = new Map<Id, List<ASF_Case_Approv__c>>();
        for (Case caseRec : caseList){
            List<ASF_Case_Approv__c> approvalList = new List<ASF_Case_Approv__c>();
            if(allCaseRules.containsKey(caseRec.Id)){
                for (ASF_Case_Rule__c caseRule : allCaseRules.get(caseRec.Id)){
                    
                    if(caseRule.Type__c == 'Approval'){  
                    boolean result = ASF_CaseFrameworkValidator.evaluateCaseRule(
                        caseRule.Logical_Condition__c,
                        caseRule.Case_Rule_Entries__r,
                        caseRec);
                        if (result == true) {
                            //Logic to insert into approvals
                            ASF_Case_Approv__c caseApprovalRecord = new ASF_Case_Approv__c();
                            caseApprovalRecord.Approver_01__c  = caseRule.Step_1_Approver_1__c;
                            caseApprovalRecord.Approver_02__c = caseRule.Step_1_Approver_2__c;
                            caseApprovalRecord.Approver_03__c = caseRule.Step_2_Approver_1__c;
                            caseApprovalRecord.Approver_04__c = caseRule.Step_2_Approver_2__c;
                            caseApprovalRecord.Approval_Type__c = caseRule.Approval_Style__c;
                            caseApprovalRecord.Approval_Status__c  = 'Pending';
                            caseApprovalRecord.Case_Stage_At_Creation__c = caseRec.Stage__c;
                            caseApprovalRecord.SR__c = caseRec.Id;
                            caseApprovalRecord.Line_Of_Business__c = caseRec.LOB__c;
                            approvalList.add(caseApprovalRecord);
                            break;
                        }
                    }
                }
            }
            //considering same case will not be uploaded in the same transaction
           	approvalMap.put(caseRec.Id,approvalList); 
        }
        
        return approvalMap;
    }

    /**
     * If Checklist Rules are present, Add new Checklist Records from Master
     * Return the Checklist Records to calling method, to be inserted
     */
    public static Map<Id, List<ASF_Checklist__c>> addChecklists(List<Case> caseList, Map<Id, List<ASF_Case_Rule__c>> allCaseRules){
        
        Map<Id, List<ASF_Checklist__c>> checklistMap = new Map<Id, List<ASF_Checklist__c>>();
        for (Case caseRec : caseList){
            List<ASF_Checklist__c> checklistList = new List<ASF_Checklist__c>();
            if(allCaseRules.containsKey(caseRec.Id)){
                for (ASF_Case_Rule__c caseRule : allCaseRules.get(caseRec.Id)){
                    
                    if(caseRule.Type__c == 'Checklists'){
                    boolean result = ASF_CaseFrameworkValidator.evaluateCaseRule(
                        caseRule.Logical_Condition__c,
                        caseRule.Case_Rule_Entries__r,
                        caseRec);
                        if (result == true){
                            for (ASF_Case_Checklist_Master__c chklistMaster : caseRule.Case_Checklist_Masters__r) {
                                
                                ASF_Checklist__c checklistRecord = new ASF_Checklist__c();
                                checklistRecord.Label__c = chklistMaster.Label__c;
                                checklistRecord.Mandatory__c = chklistMaster.Mandatory__c;
                                checklistRecord.Description__c = chklistMaster.Description__c;
                                checklistRecord.Type__c = chklistMaster.Type__c;
                                checklistRecord.Status__c = 'Pending';
                                checklistRecord.Systeminitiated__c = true;
                                checklistRecord.Case__c = caseRec.Id;
                                checklistRecord.Stage_Name__c = caseRec.Stage__c;
                                checklistRecord.Business_Unit__c = caseRec.Business_Unit__c;
                                checklistRecord.Checklist_External_Id__c = chklistMaster.Checklist_External_Id__c;
                                // VIRENDRA - 13 June 2024 - Added Picklist Option field on ASF_Checklist.
                                checklistRecord.Status_Picklist_Options__c = chklistMaster.Picklist_Options__c;
                                // VIRENDRA - 13 June 2024 - ENDS HERE.
                                //PR1030924-60, for populating new Line_Of_Business__c field
                                checklistRecord.Line_Of_Business__c = caseRec.LOB__c;
                                checklistList.add(checklistRecord);
                            }
                            break;
                        }
                    }
                }
            }
        	//considering same case will not be uploaded in the same transaction
           	checklistMap.put(caseRec.Id,checklistList);
        }
            
        return checklistMap;
    }
    
     /*
    SLA overide rules. only for few case types , SLA override rules will be enabled
    */

    public static  Map<Id, Map<string,long>> addSLA(List<Case> caseList, Map<Id, List<ASF_Case_Rule__c>> allCaseRules){

        Map<Id, Map<string,long>> caseSlaMap = new Map<Id, Map<string,long>>();
        
        for (Case caseRec : caseList){
            Map<string,long> slaMap = new Map<string,long>();
            if(allCaseRules.containsKey(caseRec.Id)){
                for (ASF_Case_Rule__c caseRule : allCaseRules.get(caseRec.Id)){
                    
                    if(caseRule.Type__c == 'SLA Override' && caseRule.Case_Stage_Config__r.SLA_Override_Enabled__c){
                    boolean result = ASF_CaseFrameworkValidator.evaluateCaseRule(
                        caseRule.Logical_Condition__c,
                        caseRule.Case_Rule_Entries__r,
                        caseRec);
                        if (result == true){
                            slaMap.put('caseOverride',caseRule.Overall_SLA_Closure__c?.longValue() ?? null);
                            slaMap.put('stageSLA1Override',caseRule.Stage_SLA_Override_1__c?.longValue() ?? null);
                            slaMap.put('stageSLA2Override',caseRule.Stage_SLA_Override_2__c?.longValue() ?? null);
                            slaMap.put('stageSLA3Override',caseRule.Stage_SLA_Override_3__c?.longValue() ?? null);    
                            break;
                        }
                    }
                }
            }
            //considering same case will not be uploaded in the same transaction
           	caseSlaMap.put(caseRec.Id,slaMap);
        }
        
        return caseSlaMap;
    }   

    /**
     * If Work Rules are present, Add new Task Records from Master
     * Return the Checklist Records to calling method, to be inserted
     */
    public static Map<Id, List<Task>> addTasks(List<Case> caseList, Map<Id, List<ASF_Case_Rule__c>> allCaseRules){
        
         Map<Id, List<Task>> tasksMap = new Map<Id, List<Task>>();
        for (Case caseRec : caseList){
            List<Task> tasksList = new List<Task>();
            if(allCaseRules.containsKey(caseRec.Id)){
                for (ASF_Case_Rule__c caseRule : allCaseRules.get(caseRec.Id)){
                    
                    if(caseRule.Type__c == 'Work'){
                    boolean result = ASF_CaseFrameworkValidator.evaluateCaseRule(
                        caseRule.Logical_Condition__c,
                        caseRule.Case_Rule_Entries__r,
                        caseRec);
                        if (result == true){
                            for (ASF_Work_Item__c workItem : caseRule.Work_Items__r) {
                                Task newTask = new Task();
                                newTask.OwnerId = workItem.Assigned_Queue__c;
                                newTask.Subject = workItem.Task_Title__c;
                                newTask.Description = workItem.Task_Description__c;
                                newTask.WhatId = caseRec.Id;
                                newTask.Case_Stage__c = caseRec.Stage__c;
                                newTask.Systeminitiated__c = true;
                                newTask.Task_Type__c ='Automatic';
                                newTask.Work_Item_External_ID__c = workItem.Work_Item_External_ID__c;
                                newTask.ActivityDate = Date.valueOf(
                                    BusinessHours.add(
                                        caseRec.BusinessHoursId,
                                        System.now(),
                                        Integer.valueOf(workItem.Completion_Time__c * 60 * 60 * 1000)
                                    )
                                );
                                newTask.Due_Date_Time__c = 
                                    BusinessHours.add(
                                    caseRec.BusinessHoursId,
                                    System.now(),
                                    Integer.valueOf(workItem.Completion_Time__c * 60 * 60 * 1000)
                                );
                                tasksList.add(newTask);
                            }
                            break;
                        
                        }
                    }
                }
            }
            //considering same case will not be uploaded in the same transaction
            tasksMap.put(caseRec.Id,tasksList);
        }

        return tasksMap;
    }

    /**
     * Run the Assignment Rules for the Stage passed
     * Returns the Owner Id (Default Queue from Stage Config) or One
     * Determined by the Assignment Rule 
     */
    public static Map<Id, CaseRuleAssignmentInfo> runAssignmentRules(List<Case> caseList, Map<Id, List<ASF_Case_Rule__c>> allCaseRules){
        
        Map<Id, CaseRuleAssignmentInfo> resultInfoMap = new Map<Id, CaseRuleAssignmentInfo>();
        System.debug(allCaseRules);
        for (Case caseRec : caseList){
            CaseRuleAssignmentInfo resultInfo = new CaseRuleAssignmentInfo();
            if(allCaseRules.containsKey(caseRec.Id)){
                for (ASF_Case_Rule__c caseRule : allCaseRules.get(caseRec.Id)){
                    
                    if(caseRule.Type__c == 'Assignment'){

                    boolean result = ASF_CaseFrameworkValidator.evaluateCaseRule(
                        caseRule.Logical_Condition__c,
                        caseRule.Case_Rule_Entries__r,
                        caseRec);
                    
                    system.debug('Ritika Case Rule' + ' ' + result);
                        if (result == true) {
                            resultInfo.defaultOwnerId = caseRule.Assigned_Queue_Id__c;
                            resultInfo.defaultErrorOwnerId = caseRule.Assigned_Error_Queue_Id__c;
                            // VIRENDRA - 8 JUNE 2024 - ADDED Assignment_Queue_Name__c to response resultInfo.
                            resultInfo.defaultOwnerName = caseRule.Assignment_Queue_Name__c;
                            break;
                        }                
                    }
                }
            }
            //considering same case will not be uploaded in the same transaction
            resultInfoMap.put(caseRec.Id,resultInfo);
        }
        return resultInfoMap;
    }

    /**
     * Run the Assignment Rules for the Stage Passed, for Backward movement
     * Returns the Owner and Error Owner info - Id or Queue Id
     * For Back Movement, Find the Previously Actioned User
     */
    public static Map<Id, CaseRuleAssignmentInfo> findAssignmentForPreviouslyVisitedStage(Map<Id, String> caseStageMap){
        Map<Id,User> mINTEGRATIONUSERS = new Map<Id,User>([SELECT ID FROM User WHERE Profile.Name = 'Salesforce API Only System Integrations']);
        Map<Id, CaseRuleAssignmentInfo> resultInfoMap = new Map<Id, CaseRuleAssignmentInfo>();
        //Checks whether to skip case assignment rule or not based on the Feature_Skipper_Flag__c field on case
        Map<Id, Set<String>> skipperFlagMap = ASF_CaseTriggerModularHelper.getSkipperFlagMap();
        Map<Id, String> filteredCaseStageMap = new Map<Id,String>();
        for(Id caseId : caseStageMap.keySet()){
            if(!(skipperFlagMap.containsKey(caseId) && skipperFlagMap.get(caseId).contains(ASF_Constants.SKIP_ASSIGNMENT))){
                filteredCaseStageMap.put(caseId,caseStageMap.get(caseId)) ;
            }
        }
        // To be able to find the Owner, below is the Logic
        // 1. Find the Last Actioned User of that Stage using SLA History
        // 2. If that user is Inactive, Run Assignment Rule of that Stage and Return the Queue

        List<ASF_Case_SLA_History__c> slaHistoryList = ASF_CaseQueryHandler.getCaseSLAHistories(caseStageMap.keySet());
        Map<Id, List<ASF_Case_SLA_History__c>> caseSlaHistoryMap = new Map<Id, List<ASF_Case_SLA_History__c>>();
        
        for(ASF_Case_SLA_History__c history : slaHistoryList){
            if(!caseSlaHistoryMap.containsKey(history.Case__c))
                    caseSlaHistoryMap.put(history.Case__c,new List<ASF_Case_SLA_History__c>());
                caseSlaHistoryMap.get(history.Case__c).add(history);
        }
        
       //Map<Id,Id> lastActionedUserIdMap = new Map<Id,Id>();
       Map<Id,ASF_Case_SLA_History__c> lastActionedUserHistoryMap = new Map<Id,ASF_Case_SLA_History__c>();
        Set<Id> lastActionedUsers = new Set<Id>();
        
        for(Id caseId : filteredCaseStageMap.keySet()){
            for(ASF_Case_SLA_History__c history : caseSlaHistoryMap.get(caseId)){
                if(history.Stage__c == filteredCaseStageMap.get(caseId)){
                    if(!mINTEGRATIONUSERS.containsKey(history.Current_Owner_Id__c)){
                        //lastActionedUserIdMap.put(caseId, history.Current_Owner_Id__c);
                        lastActionedUserHistoryMap.put(caseId,history);
                        lastActionedUsers.add(history.Current_Owner_Id__c);
                    	break;
                    }
                }
        	}
        }
        
        //if(!lastActionedUserIdMap.isEmpty()){
        if(!lastActionedUserHistoryMap.isEmpty() && lastActionedUsers.size()>0){
            // Check if User is Active
            Map<Id, User> lastActionedUserMap = new Map<Id, User>([ SELECT Id, IsActive FROM User
                								WHERE Id IN: lastActionedUsers AND IsActive = true]);
            for(Id caseId : lastActionedUserHistoryMap.keySet()){
                CaseRuleAssignmentInfo resultInfo;
                if(lastActionedUserMap.containsKey(lastActionedUserHistoryMap.get(caseId).Current_Owner_Id__c)){
                    resultInfo = new CaseRuleAssignmentInfo();
                    resultInfo.defaultOwnerId = lastActionedUserHistoryMap.get(caseId).Current_Owner_Id__c;
                    resultInfo.defaultOwnerName = lastActionedUserHistoryMap.get(caseId).Case_Assigned_Team__c != null ? lastActionedUserHistoryMap.get(caseId).Case_Assigned_Team__c : '';
                    resultInfoMap.put(caseId, resultInfo);
                }
            }
        } 
        return resultInfoMap;

    }

    /**
     * Run the Assignment Rules for the Stage passed
     * Returns the Boolean if the Rules Pass. Only True values will be part of the Map
     */
    public static Boolean runStageMovementRules(Case caseRec, List<ASF_Case_Rule__c> allCaseRules){
        
        Boolean result = true;
        for (ASF_Case_Rule__c caseRule : allCaseRules){
            System.debug('@@Logic'+caseRule.Logical_Condition__c);
            if(caseRule.Type__c == 'Stage Movement'){

                result = ASF_CaseFrameworkValidator.evaluateCaseRule(
                    caseRule.Logical_Condition__c,
                    caseRule.Case_Rule_Entries__r,
                    caseRec);

                if(result == false){
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
        ASF_Case_Stage_Config__c currentStageConfig;
        List<ASF_Case_Stage_Config__c> allStageConfigs = ASF_CaseQueryHandler.getCaseStageConfigWithRlAndIntr(new Set<String>{currentCase.CCC_External_Id__c});
        for(ASF_Case_Stage_Config__c config: allStageConfigs){
            if(config.StageName__c == currentCase.Stage__c){
                currentStageConfig = config;
            }
        }
        List<ASF_IntegrationsController.IntegrationWrapper> intResults = new List<ASF_IntegrationsController.IntegrationWrapper>();
        for(ASF_Integration__c integ : allIntegrations){
            if(integ.Auto_Run_on_Load__c){
                ASF_IntegrationsController.IntegrationWrapper intResult = ASF_IntegrationsController.runIntegration(integ, currentCase);
                intResults.add(intResult);
            }
        }

        for(ASF_IntegrationsController.IntegrationWrapper wrap : intResults){
            if(wrap.status == 'Error'){
                if(currentStageConfig != null){
                    wrap.assignToId = currentStageConfig.Default_Error_Queue__c;
                }
                result =  wrap;
                break;
            }
        }

        return result;
    }

    /**
     * Run All Integrations defined on the Case Stage Config 
     * of Type Auto Run on Load
     */
    public static Map<Id, ASF_IntegrationsController.IntegrationWrapper> runIntegrations(List<Case> caseList, Map<Id, List<ASF_Integration__c>> allIntegrations){

        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        List<Case> applicableCases = new List<Case>();
        Map<Id, List<ASF_Integration__c>> eligibleIntegrationsMap = new Map<Id, List<ASF_Integration__c>>();
		for (Case caseRec : caseList){
            if(allIntegrations.get(caseRec.Id)!=null){
                for (ASF_Integration__c integ : allIntegrations.get(caseRec.Id)){
                    if(integ.Auto_Run_on_Load__c && (!(caseRec.Technical_Source__c =='LWC' && integ.Run_Integration_From_LWC__c == false) || (runIntegrationFromLwc.containsKey(caseRec.Id) && runIntegrationFromLwc.get(caseRec.Id) == true))){
                        if(!eligibleIntegrationsMap.containsKey(caseRec.Id)){
                            eligibleIntegrationsMap.put(caseRec.Id, new List<ASF_Integration__c>());
                            applicableCases.add(caseRec);
                        }
                        eligibleIntegrationsMap.get(caseRec.Id).add(integ);
                    }
                }
                runIntegrationFromLwc.put(caseRec.Id, false);
            }
        }

        if(!applicableCases.isEmpty()){
            resultMap = ASF_IntegrationsController.runIntegration(eligibleIntegrationsMap, applicableCases);
        }
        // for (Case caseRec : caseList){
        //     List<ASF_IntegrationsController.IntegrationWrapper> intResults = new List<ASF_IntegrationsController.IntegrationWrapper>();
        //     for (ASF_Integration__c integ : allIntegrations.get(caseRec.Id)){
        //         if(integ.Auto_Run_on_Load__c){
        //             ASF_IntegrationsController.IntegrationWrapper intResult = ASF_IntegrationsController.runIntegration(integ, caseRec);
		// 			intResults.add(intResult);      
        //         }
        //     }
        //     for(ASF_IntegrationsController.IntegrationWrapper wrap : intResults){
        //         if(wrap.status == 'Error'){
        //             resultMap.put(caseRec.Id, wrap);
        //             break;
        //         }
        // 	}
        // }
        return resultMap;
    }


    /**
     * Run All Case Validation Rules defined on the Case Stage Config 
     * If any Rule Fails, 
     */
    public static Map<Id, String> runValidationRules(List<Case> caseList, Map<Id, List<ASF_Case_Rule__c>> allCaseRules){
        
        Map<Id, String> returnResultMap = new Map<Id, String>();
        
        for (Case caseRec : caseList){
            if(allCaseRules.containsKey(caseRec.Id)){
                for (ASF_Case_Rule__c caseRule : allCaseRules.get(caseRec.Id)){
                    if(caseRule.Type__c == 'Validation'){

                    boolean result = ASF_CaseFrameworkValidator.evaluateCaseRule(
                        caseRule.Logical_Condition__c,
                        caseRule.Case_Rule_Entries__r,
                        caseRec);
                    System.debug('***result:'+ result);
                        if (result == false) {
                            //Only Failed rule values will be part of the Map
                            returnResultMap.put(caseRec.Id, caseRule.Validation_Message__c);
                            break;
                        }                
                    }
                }
            }
        }
        return returnResultMap;
    }

    public class CaseRuleAssignmentInfo{
        public Id defaultOwnerId;
        public Id defaultErrorOwnerId;
        public string status; 
        public string errorMessage;
        // VIRENDRA: 8 JUNE 2024 - ADDED BELOW VARIABLE TO SHOW ASSIGNED TEAM ON ON CASE.
        public string defaultOwnerName;
    }
}
