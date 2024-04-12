/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 04-11-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   04-11-2024   rsinghnagar@salesforce.com   Initial Version
**/
public with sharing class ABFL_InactiveOwnerCaseReassignmentBatch implements Database.Batchable<sObject>, Database.Stateful {
    private Map<Id, User> allInactiveUser = new Map<Id, User>();
    private Map<Id, User> allactiveUser = new Map<Id, User>();
    private Map<String, ASF_Case_Stage_Config__c> mStageConfigs = new Map<String, ASF_Case_Stage_Config__c>();
    private Map<String, List<ASF_Case_Rule__c>> mStageRuleConfigs = new Map<String, List<ASF_Case_Rule__c>>();
    public Database.QueryLocator start(Database.BatchableContext BC) {
        // get all stage config records for ABFL where Status_Mapping__c != isClosed values
        List<String> lOpenStatuses = new List<String>();
        for(CaseStatus rec: [Select Id, MasterLabel,ApiName From CaseStatus Where IsClosed = false]){
            lOpenStatuses.add(rec.ApiName);
        }
        List<Id> lStageIds = new List<Id>();
        // CSC have many stages and these are mapped to case statuses via Status_Mapping__c
        for(ASF_Case_Stage_Config__c rec: [SELECT Id,Default_Queue__c,Case_Category_Config__r.CCC_External_Id__c, StageName__c , 
                                                    (SELECT Id FROM Case_Rules__r WHERE type__c = 'Assignment')
                                            FROM ASF_Case_Stage_Config__c
                                            WHERE Case_Category_Config__r.Business_Unit__c=:ABFL_Constants.ABFL
                                            AND Status_Mapping__c IN :lOpenStatuses])
        {
            mStageConfigs.put(rec.Case_Category_Config__r.CCC_External_Id__c+rec.StageName__c,rec);
            if(rec.Case_Rules__r.size() > 0){
                lStageIds.add(rec.Id);
            }
        }
        System.debug('***mStageConfigs:'+mStageConfigs);
        for(ASF_Case_Rule__c rec: [SELECT Id, type__c, Logical_Condition__c, Assigned_Queue_Id__c, Assigned_Error_Queue_Id__c, Case_Stage_Config__c,
                                    (SELECT Id, Data_Type__c, Number__c, Operator__c, Value__c, Field_Api_Name__c 
                                            FROM Case_Rule_Entries__r) 
                                    FROM ASF_Case_Rule__c WHERE type__c = 'Assignment' and Case_Stage_Config__c IN :lStageIds])
        {
            if(mStageRuleConfigs.containsKey(rec.Case_Stage_Config__c)){
                mStageRuleConfigs.get(rec.Case_Stage_Config__c).add(rec);
            }else{
                mStageRuleConfigs.put(rec.Case_Stage_Config__c, new List<ASF_Case_Rule__c>{rec});
            }
        }
        System.debug('***mStageRuleConfigs:'+mStageRuleConfigs);

        // Get active and inactive user map
        for(User rec: [SELECT Id, IsActive, ManagerId,Manager.Name FROM User]){
            if(rec.IsActive){
                allactiveUser.put(rec.Id, rec);
            }else{
                allInactiveUser.put(rec.Id, rec);
            }
        }

        return Database.getQueryLocator([SELECT Id, ABFL_Case_Detail__c, ABFL_Case_Detail__r.Autoclosure_IN_RR__c, ABFL_Case_Detail__r.IsRegisteredCustomer__c,
                                            ABFL_Case_Detail__r.Autoclosed__c, ABFL_Case_Detail__r.Closure_Time__c,CCC_External_Id__c,ContactId,No_Auto_Communication__c,
                                            ABFL_Case_Detail__r.Document_URL__c ,LAN__c, Account.IsPersonAccount,Asset.Loan_Start_Date__c,
                                            Account.PersonEmail, Account.Office_Email__c, Account.PersonMobilePhone,
                                            Account.Name, Client_Code__c,Vertical__c,
                                            Account.Phone, ABFL_Case_Detail__r.Bank_IFSC_Code__c,
                                            ABFL_Case_Detail__r.Bank_Account_No__c, ABFL_Case_Detail__r.Frequency__c,
                                            ABFL_Case_Detail__r.Emi_Amount__c, ABFL_Case_Detail__r.New_Bank_Account_No__c,
                                            ABFL_Case_Detail__r.Amount__c, ABFL_Case_Detail__r.Debit_Type__c ,
                                            Technical_Source__c, AccountId, AssetId, Source__c, MoveToNext__c,
                                            CaseNumber,Business_Unit__c,ContactEmail,ContactMobile,
                                            ABFL_Case_Detail__r.From_Date__c, ABFL_Case_Detail__r.To_Date__c,
                                            BRE_Source__c, SuppliedEmail, Origin, ABFL_Case_Detail__r.IsSMT__c, OwnerId, Stage__c 
                                            FROM Case 
                                            // WHERE id='500Bl0000098v7EIAQ']);
                                            WHERE Business_Unit__c = :ABFL_Constants.ABFL AND Owner.IsActive = false AND isClosed=false]);
        
    }

    public void execute(Database.BatchableContext BC, List<Case> scope) {
        System.debug('***scope'+scope);
        // get all stage config records for the records in scope
        List<Case> casesToUpdate = new List<Case>();
        for(Case cs : scope) {
            String owner = reassignCase(cs);
            if (String.isNotBlank(owner)) {
                cs.OwnerId = owner;
                casesToUpdate.add(cs);
            }
           
        }
        
        if (!casesToUpdate.isEmpty()) {
            try {
                Database.update(casesToUpdate);
            } catch (Exception e) {
                ABCL_Logger.enableExceptionLogging();
                ABCL_Logger.push('ABFL_InactiveOwnerCaseReassignmentBatch.execute.casesToUpdate');
                ABCL_Logger.message(e.getMessage());
                ABCL_Logger.emit();
            }
        }
    }

    public void finish(Database.BatchableContext BC) {

    }

    //Get default queue assigned to the stage
    public Id reassignCase(Case cs) {
        String cccId = cs.CCC_External_Id__c;
        String stage = cs.Stage__c;
        String caseId = cs.Id;
        ASF_Case_Stage_Config__c csc = mStageConfigs.get(cccId+stage);
        //System.debug(csc);

        Id assignedQueue = csc.Default_Queue__c;
        if (String.isBlank(assignedQueue)){
            if (csc.Case_Rules__r.size() > 0) {
                Map<Id, List<ASF_Case_Rule__c>> mapOfCaseRules = new Map<Id, List<ASF_Case_Rule__c>>();
                mapOfCaseRules.put(cs.Id, mStageRuleConfigs.get(csc.Id));
                System.debug('***mapOfCaseRules:'+mapOfCaseRules);
                Map<Id, ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo> mapOfAssignedQueue = ASF_CaseFrameworkHelper.runAssignmentRules(new List<Case>{cs},mapOfCaseRules);
                assignedQueue = mapOfAssignedQueue.get(cs.Id).defaultOwnerId;
            }else {
                assignedQueue = getActiveManagerId(cs.OwnerId);
            }
        }
        return assignedQueue;
    }
    
    public Id getActiveManagerId(Id userId){
        Id mgrId=userId;
        // in case userId (ManagerId in recurssive call) is not null
        if(userId!=null){
            if (allactiveUser.containsKey(allInactiveUser.get(userId).managerId)){
                // in case manager is active
                mgrId = allInactiveUser.get(userId).managerId;           
            }else if (!allactiveUser.containsKey(allInactiveUser.get(userId).managerId)){
                // in case manager is inactive - recurrsive call
                mgrId = getActiveManagerId(allInactiveUser.get(userId).managerId);            
            }
        }
        return mgrId;
    }
}