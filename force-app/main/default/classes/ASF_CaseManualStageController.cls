/*********************************************************
*Class        :  ASF_CaseManualStageController
*Author       :  Salesforce
*Description  :  Controller Class to get the stage details from configuration records
contains methods to fetch Case SLA history
*********************************************************/
public without sharing class ASF_CaseManualStageController {
    @AuraEnabled (cacheable=true)
    public static List<ASF_Case_SLA_History__c> fetchCaseSLAHistoryRecords(string caseId, string stage){
        try {
            List<ASF_Case_SLA_History__c> historyRecords =new List<ASF_Case_SLA_History__c>();
            for(ASF_Case_SLA_History__c cHistory : [SELECT Name, Id, CreatedDate, Case__c, Stage_End_Date__c,
                                                    Stage_Start_Date__c, Stage__c, Breached_User__c FROM 
                                                    ASF_Case_SLA_History__c WHERE Case__c =:caseId And Stage__c=:stage
                                                    WITH SECURITY_ENFORCED ORDER BY Stage_Start_Date__c ASC]){
                                                        historyRecords.add(cHistory);                          
                                                    }
            return historyRecords;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled (cacheable=true)
    public static list<ManualStagesWrapper> fetchManualStages(string externalID){
        list<ManualStagesWrapper> result = new list<ManualStagesWrapper>();
        try {
            list<ASF_Case_Stage_Config__c > caseStageConfigs = [select Id,StageName__c,Case_Category_Config__r.CCC_External_Id__c,Is_Approval_Stage__c from ASF_Case_Stage_Config__c  WHERE Case_Category_Config__r.CCC_External_Id__c =:externalID AND Manual_Stage__c=true WITH SECURITY_ENFORCED];
            
            for(ASF_Case_Stage_Config__c  csc: caseStageConfigs){
                ManualStagesWrapper temp = new ManualStagesWrapper();
                temp.label = csc.StageName__c;
                temp.value = csc.StageName__c;
                if(csc.Is_Approval_Stage__c == false){
                    temp.noAssignmentRules = true;
                }
                
                result.add(temp);
                
            }
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return result;
    }
    
    @AuraEnabled (cacheable=true)
    public static list<ManualStagesWrapper> fetchNextManualStages(string externalID, string currentStage){
        list<ManualStagesWrapper> result = new list<ManualStagesWrapper>();
        try {
            Decimal currentStageOrder = [Select Order__c FROM ASF_Case_Stage_Config__c WHERE Parent_C3_Record__c =:externalID AND StageName__c =: currentStage ].get(0).Order__c;
            list<ASF_Case_Stage_Config__c> caseStageConfigs = [Select Id, Order__c, Optional_Stage__c,StageName__c,Default_Queue__c,Is_Approval_Stage__c,(Select Id from Case_Rules__r where Type__c ='Assignment') FROM ASF_Case_Stage_Config__c where Parent_C3_Record__c =:externalID AND Manual_Stage__c = TRUE AND Order__c > :currentStageOrder Order by Order__c];
            
            for(ASF_Case_Stage_Config__c csc: caseStageConfigs){
                ManualStagesWrapper temp = new ManualStagesWrapper();
                temp.label = csc.StageName__c;
                temp.value = csc.StageName__c;
                if( csc.Is_Approval_Stage__c == false){
                    temp.noAssignmentRules = true;
                }
                // else{
                //     temp.noAssignmentRules = false;
                // }
                result.add(temp);
                
            }
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return result;
    }
    
    @AuraEnabled (cacheable=true)
    public static list<ManualStagesWrapper> fetchAllManualStagesWithCase(string caseId){
        list<ManualStagesWrapper> result = new list<ManualStagesWrapper>();
        try {
            Case case1 = [SELECT CCC_External_Id__c,Stage__c,IsClosed FROM Case WHERE Id =:caseId].get(0);
            if(case1.IsClosed){
                return result;
            }
            Decimal currentStageOrder = [Select Order__c,Parent_C3_Record__c FROM ASF_Case_Stage_Config__c WHERE Parent_C3_Record__c =:case1.CCC_External_Id__c AND StageName__c=:case1.Stage__c ].get(0).Order__c;
            for(ASF_Case_Stage_Config__c csc:[select Id,StageName__c,Case_Category_Config__r.CCC_External_Id__c,Default_Queue__c,Is_Approval_Stage__c,(Select Id from Case_Rules__r where Type__c ='Assignment') from ASF_Case_Stage_Config__c
                                              WHERE Case_Category_Config__r.CCC_External_Id__c =:case1.CCC_External_Id__c AND Manual_Stage__c=true and Order__c > :currentStageOrder WITH SECURITY_ENFORCED] ) {
                                                  if(csc.StageName__c != case1.Stage__c){
                                                      ManualStagesWrapper temp = new ManualStagesWrapper();
                                                      temp.label = csc.StageName__c;
                                                      temp.value = csc.StageName__c;
                                                      if(csc.Is_Approval_Stage__c == false){
                                                          temp.noAssignmentRules = true;
                                                      }
                                                      // else{
                                                      //     temp.noAssignmentRules = false;
                                                      // }
                                                      result.add(temp); 
                                                  }
                                              }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return result;
    }

    /**
     * Provide Stages for Backward Manual Movement
     * Filter the ones where Manual_Backward_Stage__c is True, and Order is
     * less than the current stage
     */
    @AuraEnabled (cacheable=true)
    public static List<String> fetchBackwardStages(string externalID, string currentStage, string caseId){
    
        List<String> stageList = new List<String>();
        try {
            if(currentStage != 'Rejected' && currentStage != 'Closed' && currentStage != 'Resolved'){
                
                // Query All Stage Configs for the CCC
                List<ASF_Case_Stage_Config__c> allStageConfigs = [
                        SELECT Order__c,StageName__c, Manual_Backward_Stage__c
                        FROM ASF_Case_Stage_Config__c
                        WHERE Parent_C3_Record__c =:externalID
                ];

                // Find Current Stage Order
                Decimal currentOrder;
                for(ASF_Case_Stage_Config__c config : allStageConfigs){
                    if(config.StageName__c == currentStage){
                        currentOrder = config.Order__c;
                        break;
                    }
                }

                for(ASF_Case_Stage_Config__c config : allStageConfigs){
                    if(config.Order__c < currentOrder && config.Manual_Backward_Stage__c == true){
                        stageList.add(config.StageName__c);
                    }
                }
            }
            return stageList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage() + e.getStackTraceString());
        }
    }
    

    // @AuraEnabled (cacheable=true)
    // public static List<String> fetchStages(string externalID, string currentStage, string caseId){
    //     Set<String> stageSet = new Set<String>();
    //     List<String> stageLst = new List<String>();
    //     Set<String> slaHistory = new Set<String>();
    //     try {
    //         if(currentStage != 'Rejected' && currentStage != 'Closed' && currentStage != 'Resolved'){
    //             ASF_Case_Stage_Config__c currentStageConfig = [Select Order__c,Gateway_Stage__c FROM ASF_Case_Stage_Config__c WHERE Parent_C3_Record__c =:externalID AND StageName__c =: currentStage ].get(0);
    //             //Dont Show Gateway stages if you are currently in Gateway stages
    //             if(currentStageConfig.Gateway_Stage__c == true){
    //                 for(ASF_Case_Stage_Config__c csc: [Select Id, Order__c,StageName__c FROM ASF_Case_Stage_Config__c where Parent_C3_Record__c =:externalID AND Order__c < :currentStageConfig.Order__c WITH SECURITY_ENFORCED ORDER BY Order__c])
    //                 {
    //                     stageSet.add(csc.StageName__c);
    //                 }
    //             }else{
    //                 for(ASF_Case_Stage_Config__c csc: [Select Id, Order__c,StageName__c FROM ASF_Case_Stage_Config__c where Parent_C3_Record__c =:externalID AND Order__c < :currentStageConfig.Order__c AND Don_t_show_in_back_stages__c  = false WITH SECURITY_ENFORCED ORDER BY Order__c])
    //                 {
    //                     stageSet.add(csc.StageName__c);
    //                 }
                    
    //             }
                
    //             for(ASF_Case_SLA_History__c his : [SELECT Id, Case__c, Stage__c FROM ASF_Case_SLA_History__c 
    //                                                WHERE Case__c =:caseId and Stage__c != :currentStage ORDER BY CreatedDate]){
    //                                                    if(his.Stage__c!='Pending with Initiator'){
    //                                                        slaHistory.add(his.Stage__c);
    //                                                    }
    //                                                }
    //             //System.debug('SLAHISTORY--' + slaHistory);
                
    //             for(String str : stageSet){
    //                 if(slaHistory.contains(str)){
    //                     stageLst.add(str);
    //                 }
                    
    //             }
    //         }
            
    //         return stageLst;
    //     } catch (Exception e) {
    //         throw new AuraHandledException(e.getMessage() + e.getStackTraceString());
    //     }
    // }
    
    @AuraEnabled
    public static boolean rejectCase(string recordId,string reason){
        boolean result = false;
        try {
            Case currentCase = new Case();
            currentCase.Id = recordId;
            currentCase.Stage__c = 'Rejected';
            currentCase.Status = 'Rejected';
            currentCase.Rejected_Reason__c = reason;
            
            update currentCase;
            list<ASF_Checklist__c> checklists =  [Select Id,Case__c,Rejected_Reason__c,Status__c FROM ASF_Checklist__c where Case__c = :recordId and Status__c='Pending'];
            for(ASF_Checklist__c c: checklists){
                c.Status__c = 'Rejected';
                c.Rejected_Reason__c = reason;
            }
            
            update checklists;
            
            list<Task> tasks = [SELECT Id, Status,WhatId,Case_Stage__c FROM Task WHERE  Status ='Open' and WhatId =:recordId];
            for(task t: tasks){
                t.Status = 'Rejected';
                t.Rejected_Reason__c = reason;
            }
            
            update tasks;
            result = true;
            
        } catch (Exception e) {
			System.debug('@@Mess'+e.getMessage());
            // throw new AuraHandledException(e.getMessage());
        }
        return result;
    }
    
    @AuraEnabled (cacheable=true)
    public static list<Group> fetchQueues(string recordId){
        list<Group> queueList =new list<Group>();
        try {
            Case caseRec =[Select Id,CCC_External_Id__c,CaseNumber From Case where Id=:recordId];
            ASF_Case_Category_Config__c  caseCategoryConfigRecord =[select Id,CCC_External_Id__c,Name,
                                                                    (Select Id,Name, Default_Queue__c From Case_Stage_Configs__r WHERE Default_Queue__c!=null)
                                                                    from ASF_Case_Category_Config__c  WHERE CCC_External_Id__c=:caseRec.CCC_External_Id__c];
            list<ASF_Case_Stage_Config__c > stageConfigRecords =caseCategoryConfigRecord.Case_Stage_Configs__r;
            set<String> groupIdSet =new set<String>();
            for(ASF_Case_Stage_Config__c  stageRec :stageConfigRecords){
                groupIdSet.add(stageRec.Default_Queue__c);
            }
            queueList =[select Id,Name, Type from Group Where Type ='queue'];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage()); 
        }
        return queueList;
    }
    
    
    @AuraEnabled
    public static list<list<sobject>> getOwnerSearchResult(string searchString){
        try {
            
            string keyword = '%'+searchString+'%';
            return [FIND :keyword IN ALL FIELDS RETURNING User(Id, Name, FirstName, LastName, Email, username where isActive=true and Id NOT IN :new list<Id>{UserInfo.getUserId()}), Group(Id,Name Where Type='Queue')];
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    
    public class ManualStagesWrapper{
        @AuraEnabled
        public string label {get;set;}
        
        @AuraEnabled
        public string value {get;set;}
        
        @AuraEnabled
        public boolean noAssignmentRules {get;set;}
        
    }
    
}