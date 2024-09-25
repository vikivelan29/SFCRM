/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 05-14-2024
 * @last modified by  : rsinghnagar@salesforce.com
**/
public without sharing class ASF_CaseQueryHandler {
    private static List<Case> cases = null;
    private static List<ASF_Checklist__c> caseIncompleteChecklists = null;
    private static List<ASF_Case_Approv__c> caseApprovals = null;
    private static List<Task> caseIncompleteTasks = null;
    private static List<ASF_Integration__c> cccIntegrations = null;
    private static List<ASF_Case_Integration__c> caseIntegrations = null;
    private static List<ASF_Case_Stage_Config__c> caseStageConfigs = null;
    private static list<ASF_Case_Rule__c> caseRules = null;
    private static list<ASF_Case_Rule__c> caseRulesWithHierarchy = null;
    private static list<ASF_Case_SLA_History__c> caseSLAHistories = null;
    private static List<ASF_Case_Category_Config__c> caseCategoryConfigs = null;
    private static List<Asset> caseRelatedAssets = null;
    private static Map<String, Boolean> caseStatusMap = null;
    private static List<Case> casesWithConfigQueryFields = null;
    public static boolean refreshRecords = false;
    
    
    /**
    * @description : getcases
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    * @param recordIds 
    * @return List<Case> 
    **/
    public static List<Case> getCases(Set<Id> recordIds){
        if(cases == null || refreshRecords){
            cases = [SELECT Id,BusinessHoursId,Status,OwnerId,CCC_External_Id__c,Stage__c,pending_clarification__c,CreatedById,
                     Previous_Stage__c,ClosedDate, PAY_Payment_Detail__c, SLA_Target_1__c, CSAT__c, DB_Hours__c,
                     has_CheckLists__c, Has_Open_Tasks__c,ABFL_Case_Detail__c,ABFL_Case_Detail__r.ABCOwner__c,Technical_Source__c,
                     ABFL_Case_Detail__r.Resolution_Comments__c, Source__c,Nature__c,Description,
                     (Select Id, Checklist_External_Id__c, Status__c, Case__c from Checklists__r),
                     (Select Id, Work_Item_External_ID__c, WhatId from Tasks)
                     FROM Case
                     WHERE Id = :recordIds WITH SYSTEM_MODE];
        }
        return cases;
    }
    
    /**
    * @description : getIncompleteCaseChecklists
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    * @param caseIds 
    * @param caseStages 
    * @return List<ASF_Checklist__c> 
    **/
    public static List<ASF_Checklist__c> getIncompleteCaseChecklists(Set<Id> caseIds, Set<String> caseStages){
        if(caseIncompleteChecklists == null || refreshRecords){
            caseIncompleteChecklists = [SELECT Id, Case__c, Mandatory__c, Stage_Name__c, Type__c, Status__c
                                        FROM ASF_Checklist__c
                                        WHERE
                                        Mandatory__c = TRUE
                                        AND Status__c NOT IN : ASF_Constants.completeChecklistStatus
                                        AND Case__c = :caseIds
                                        AND Stage_Name__c = :caseStages WITH SYSTEM_MODE];
        }
        return caseIncompleteChecklists;
    }

    /**
    * @description : getCaseApprovals
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    * @param caseIds 
    * @param caseStages 
    * @return List<ASF_Case_Approv__c> 
    **/
    public static List<ASF_Case_Approv__c> getCaseApprovals(Set<Id> caseIds, Set<String> caseStages){
        if(caseApprovals == null || refreshRecords){
            caseApprovals = [
                                SELECT Id, Approval_Status__c, SR__c, CreatedDate
                                FROM ASF_Case_Approv__c
                                WHERE SR__c = :caseIds
                                AND Case_Stage_At_Creation__c = :caseStages
                                AND Is_Recategorization_Request__c = false // production ticket: INC000000055852/182117
                                ORDER BY CreatedDate desc];
        }
        return caseApprovals;
    }
    
    /**
    * @description : getIncompleteCaseTasks
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    * @param caseIds 
    * @param caseStages 
    * @return List<Task> 
    **/
    public static List<Task> getIncompleteCaseTasks(Set<Id> caseIds, Set<String> caseStages){
        if(caseIncompleteTasks == null){
            caseIncompleteTasks = [SELECT Id, Status, WhatId, Case_Stage__c
                                   FROM Task
                                   WHERE
                                   Status NOT IN ('Completed','Rejected')
                                   AND WhatId = :caseIds
                                   AND Case_Stage__c = :caseStages WITH SYSTEM_MODE];
        }
        return caseIncompleteTasks;
    }
    
    /**
    * @description : getIntegrationsFromConfig
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    * @param caseStageConfigIds 
    * @return List<ASF_Integration__c> 
    **/
    public static List<ASF_Integration__c> getIntegrationsFromConfig(Set<Id> caseStageConfigIds){
        if(cccIntegrations == null){
            cccIntegrations = [SELECT Id, External_Id__c, Display_Name__c, Case_Stage_Config__c, C3ExternalId__c
                               FROM ASF_Integration__c
                               WHERE Mandatory_At_Stage_Movement__c = true
                               AND Case_Stage_Config__c =: caseStageConfigIds WITH SYSTEM_MODE];
        }
        return cccIntegrations;
    }
    
    /**
    * @description : getCaseRelatedIntegrations
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    * @param cccIntegrationExtIds 
    * @param caseIds 
    * @return List<ASF_Case_Integration__c> 
    **/
    public static List<ASF_Case_Integration__c> getCaseRelatedIntegrations(Set<String> cccIntegrationExtIds, Set<Id> caseIds){
        if(caseIntegrations == null || refreshRecords){
            caseIntegrations = [SELECT Id, Is_Validation_Success__c, Integration_Ext_Id__c, Case__c
                                FROM ASF_Case_Integration__c
                                WHERE Case__c =: caseIds
                                AND Integration_Ext_Id__c in: cccIntegrationExtIds WITH SYSTEM_MODE
                                ORDER BY LastModifiedDate desc];
        }
        return caseIntegrations;
    }

    /**
    * @description : Added ABFL_BRE_CalloutClass__c field on ASF_Integration for BRE callout - AC
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    * @param cccExternalId 
    * @return list<ASF_Case_Stage_Config__c> 
    **/
    public static list<ASF_Case_Stage_Config__c> getCaseStageConfigWithRlAndIntr(Set<String> cccExternalId){
        if(caseStageConfigs == null || refreshRecords){
            caseStageConfigs = [SELECT ID,StageName__c,Status_Mapping__c,Order__c,Query_Fields__c,Manual_Stage__c,
                                Is_Approval_Stage__c,Manual_Approval__c,Case_Category_Config__r.CCC_External_Id__c,
                                Case_Category_Config__r.Order__c,SLA_Target_1_Type__c,SLA_Target_2_Type__c,SLA_Target_3_Type__c,
                                Optional_Stage__c,Default_Queue__c,Default_Error_Queue__c, Gateway_Stage__c,
                                AfterStageApexClass__c, BeforeStageApexClass__c,Assign_To_Last_Actioned_Stage__c,Case_Category_Config__c,
                                (SELECT ID,Order__c,Type__c,Logical_Condition__c,Name,Assigned_Queue_Id__c,Validation_Message__c,Stage_Name__c,Step_1_Approver_1__c,
                                 Step_1_Approver_2__c,Step_2_Approver_1__c,Step_2_Approver_2__c,Approval_Success_Fields_to_Update__c,
                                 Approval_Rejected_Fields_to_Update__c,Approval_Style__c,Approval_SuccessStageMovement__c FROM Case_Rules__r),
                                (SELECT ID, Auto_Run_on_Load__c ,C3ExternalId__c, Display_Name__c ,Display_Order__c ,STP_API_Identifier__c,
                                 External_Id__c,Mandatory_At_Stage_Movement__c ,Processing_Class__c ,STP_Processing_Class__c, Type__c,
                                 UI_Component__c ,Visibility_Class__c ,When_to_Appear__c, Query_Fields__c, Priority__c  FROM ASF_Integrations__r)
                                FROM ASF_Case_Stage_Config__c
                                WHERE Case_Category_Config__r.CCC_External_Id__c = :cccExternalId WITH SYSTEM_MODE
                                ORDER BY Case_Category_Config__c, Order__c];
        }
        return caseStageConfigs;
        
    }
        
    /**
    * @description : getCaseRuleWithHierarchy
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    * @param caseCCCExternalIds 
    * @return list<ASF_Case_Rule__c> 
    **/
    public static list<ASF_Case_Rule__c> getCaseRuleWithHierarchy(Set<String> caseCCCExternalIds){
        if(caseRulesWithHierarchy == null){
            caseRulesWithHierarchy = [
                SELECT
                Id,
                Order__c,
                Type__c,
                Logical_Condition__c,
                Name,
                Assigned_Queue_Id__c,
                Assigned_Error_Queue_Id__c,
                Validation_Message__c,
                C3ExternalId__c,
                Stage_Name__c,
                Case_Stage_Config__c,
                (
                    SELECT
                    Id,
                    Field_Api_Name__c,
                    Operator__c,
                    Value__c,
                    Data_Type__c,
                    Number__c
                    FROM Case_Rule_Entries__r
                ),
                (
                    SELECT
                    Id,
                    Task_Title__c,
                    Task_Description__c,
                    Assigned_Queue__c,
                    Completion_Time__c,
                    Work_Item_External_ID__c
                    FROM Work_Items__r
                ),
                (
                    SELECT Id, Name, Type__c, Mandatory__c,Description__c, Checklist_External_Id__c
                    FROM Case_Checklist_Masters__r
                ),
                Step_1_Approver_1__c,
                Step_1_Approver_2__c,
                Step_2_Approver_1__c,
                Step_2_Approver_2__c,
                Approval_Success_Fields_to_Update__c,
                Approval_Rejected_Fields_to_Update__c,
                Approval_Style__c,
                Approval_SuccessStageMovement__c,
                Assign_to_Initiator__c,
                SLA_override_value_in_Hrs__c,
                Overall_SLA_Closure__c,
                Stage_SLA_Override_1__c,
                Stage_SLA_Override_2__c,
                Stage_SLA_Override_3__c,
                Case_Stage_Config__r.SLA_Override_Enabled__c
                FROM ASF_Case_Rule__c
                WHERE
                Type__c IN (
                    'Stage Movement',
                    'Assignment',
                    'Work',
                    'Checklists',
                    'Approval',
                    'Validation',
                    'SLA Override'
                )
                AND C3ExternalId__c = :caseCCCExternalIds WITH SYSTEM_MODE
                ORDER BY C3ExternalId__c,Case_Stage_Config__r.Order__c, Order__c];
        }
        return caseRulesWithHierarchy;
    }
    
    
    /**
    * @description : getCaseSLAHistories
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    * @param caseIds 
    * @return List<ASF_Case_SLA_History__c> 
    **/
    public static List<ASF_Case_SLA_History__c> getCaseSLAHistories(Set<Id> caseIds){
        if(caseSLAHistories == null || refreshRecords){
            caseSLAHistories = [SELECT Id, Case__c, Actual_Time_Taken__c, Agent_CC__c, 
                                                          Agent_LOB__c, Agent_LOC__c, Agent__c, Agreed_SLA_in_Hrs__c, Breached_User_Id__c, 
                                                          Breached_User_Level1__c, Breached_User_Level2__c, Breached_User_Level3__c, 
                                                          Breached_User_Level_1__c, Breached_User_Level_2__c, Breached_User_Level_3__c, 
                                                          Breached_User__c, Bulk_Movement_User_Id__c, 
                                                          Bulk_Movement_User__c, Bulk_Operation__c, 
                                                          BusinessHoursId__c, Current_Owner_Id__c, Current_Owner__c, 
                                                          Del_Business_Hour_Id__c, Delete_Breached_User__c, 
                                                          Is_Bulk_Updated__c, Is_Move_Back__c, Last_Owner_Change_Date__c, 
                                                          Level__c, Overdue_Time_in_Hrs__c, Overdue__c, 
                                                          Rejection_Id__c, SLA_2_Email_Sent__c, SLA_3_Email_sent__c, 
                                                          SLA_CC__c, SLA_LOB__c, SLA_LOC__c, Stage_End_Date__c, 
                                                          Stage_Start_Date__c, Stage_Violation_Start_Date__c, 
                                                          Stage__c, Status__c, Time_Taken_In_Business_Hour__c, Time_Taken__c, is_Running_Record__c 
                                                          FROM ASF_Case_SLA_History__c
                                                          WHERE Case__c =: caseIds WITH SYSTEM_MODE order by Stage_End_Date__c DESC
                                                         ];
        }
        return caseSLAHistories;
    }
    
    
    /**
    * @description : getCaseStatusMap
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    * @return Map<String, Boolean> 
    **/
    public static Map<String, Boolean> getCaseStatusMap(){
        Map<String, Boolean> returnMap = new Map<String, Boolean>();
        if(caseStatusMap == null){
            for(CaseStatus cs : [Select Id, ApiName, IsClosed from CaseStatus WITH SYSTEM_MODE]){
                returnMap.put(cs.ApiName, cs.IsClosed);
            }
            caseStatusMap = returnMap;
        }
        return caseStatusMap;
    }
    
    /**
    * @description : getCaseCategoryConfigs
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    * @param cccExternalIds 
    * @return List<ASF_Case_Category_Config__c> 
    **/
    public static List<ASF_Case_Category_Config__c> getCaseCategoryConfigs(List<String> cccExternalIds) {
        if(caseCategoryConfigs == null || refreshRecords){
            
            caseCategoryConfigs = [SELECT Id, Is_FTR_Journey__c, Nature__c, Product__c, Source__c, 
                                    Type__c, Sub_Type__c, Type_Synonyms__c, Business_Unit__c, CCC_External_Id__c, 
                                    First_Stage__c, Is_Bulk_Creatable__c, ASF_Is_Cloneable__c,
                                    Reopen_Days__c, Reopen_Style__c, Is_STP__c,Multiple_Child_Details__c,
                                    Only_CRN_Mandatory__c,Custom_Segment__c,is_FA_Mandatory__c,Priority__c,
                                    Is_Recategorise_Allowed__c,Allow_file_upload__c,LOB__c, No_Owner_Change_on_Recat__c 
                                    FROM ASF_Case_Category_Config__c 
                                    WHERE CCC_External_Id__c IN :cccExternalIds WITH SYSTEM_MODE];
                                    
        }
        return caseCategoryConfigs;
    }

    /**
    * @description : getAssets
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    * @param assetIds 
    * @return List<Asset> 
    **/
    public static List<Asset> getAssets(List<Id> assetIds) {
        if(caseRelatedAssets == null || refreshRecords){
            caseRelatedAssets = [SELECT Id, LAN__c FROM Asset WHERE ID IN :assetIds WITH SYSTEM_MODE];
        }
        return caseRelatedAssets;
    }

    /**
    * @description : getCaseRecordWithQueryFields
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    * @param queryFields 
    * @param caseIdList 
    * @return List<Case> 
    **/
    public static List<Case> getCaseRecordWithQueryFields(Set<String> queryFields, Set<Id> caseIdList) {
        if(casesWithConfigQueryFields == null || refreshRecords){
            casesWithConfigQueryFields = (List<Case>) Database.query(
                'SELECT ' +
                String.join(queryFields, ',') +
                ' FROM Case WHERE Id IN :caseIdList'
            );

        }
        return casesWithConfigQueryFields;
    }

    /**
    * @description : Virendra - This method is used to get the IntegrationRecords in retry mechanism
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    * @param integrationExtnId 
    * @return List<ASF_Integration__c> 
    **/
    public static List<ASF_Integration__c> getASFIntegrationRecordsForRetry(Set<String> integrationExtnId){
        
        return [SELECT ID, Auto_Run_on_Load__c ,C3ExternalId__c, Display_Name__c ,Display_Order__c ,STP_API_Identifier__c,
                                 External_Id__c,Mandatory_At_Stage_Movement__c ,Processing_Class__c ,STP_Processing_Class__c, Type__c,
                                 UI_Component__c ,Visibility_Class__c ,When_to_Appear__c,Query_Fields__c  FROM ASF_Integration__c WHERE External_Id__c =: integrationExtnId WITH SYSTEM_MODE];
    }

    /**
    * @description : getCaseRecordToRetryIntegrations
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    * @param caseIds 
    * @return List<Case> 
    **/
    public static List<Case> getCaseRecordToRetryIntegrations(Set<Id> caseIds){
        
        return [SELECT ID,CaseNumber, AccountId, Business_Unit__c,IsClosed   FROM Case WHERE Id =: caseIds WITH SYSTEM_MODE];
    }
    
}
