/*********************************************************
*Class        :  ABSLAMC_CaseAssignmentHelper
*Author       :  Neeraj Kumar
*Created Date :  12/08/2024
*@description  :  This class is created to assign the case record to different Queue/User for ABSLAMC
*********************************************************/

@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.ExcessiveParameterList,PMD.NcssMethodCount,PMD.StdCyclomaticComplexity,PMD.AvoidDeeplyNestedIfStmts')
public with sharing class ABSLAMC_CaseAssignmentHelper {
    /****************************************************************************************************************
* @param newMapCase
* @description - created to change the owner of case wrt to the Source of the case
*****************************************************************************************************************/ 
    public static void updateAssignmentOnStageChange(Map<Id,Case> newMapCase,Map<Id,Case> oldMapCase){
        
        //TODO: PUT Business Unit CHECK OF AMSLAMC cases only. Proceed only if AMSLAMC cases are present in newMapCase
        
        
        // Retrieve queue names and source values from custom labels
        List<String> queueNames = new List<String>(Label.ABSLAMC_CaseAssignmentQueueNames.split(','));
        List<String> caseSources = new List<String>(Label.ABSLAMC_CaseSourcesforAssignment.split(','));
        Map<String, Id> queueMap = new Map<String, Id>(); 
        List<ASF_Case_SLA_History__c> caseSLAHistories = new List<ASF_Case_SLA_History__c>();
        Map<Id, Set<String>> caseIdToSkipperFlag = new Map<Id, Set<String>>();
        
        
        // Fetching Queue to be assigned to the case
        Map<String, Id> queueMap = new Map<String, Id>();
        for (Group queue : [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name IN :queueNames]) {
            queueMap.put(queue.Name, queue.Id);
        }
        
        // Populate the caseSlaHistoryMap
        for (ASF_Case_SLA_History__c history : caseSLAHistories) {
            if (!caseSlaHistoryMap.containsKey(history.Case__c)) {
                caseSlaHistoryMap.put(history.Case__c, new List<ASF_Case_SLA_History__c>());
            }
            caseSlaHistoryMap.get(history.Case__c).add(history);
        }
        
        if(!amcSpecificCases.isEmpty()){ 
            // Fetching Queue to be assigned to the case    
            for (Group queue : [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name IN :queueNames]) {
                queueMap.put(queue.Name, queue.Id);
            }
            
            for (Case caseRec : amcSpecificCases.values()) {
                if (caseRec.Business_Unit__c == ABSLAMC_Constants.ABSLAMCBU 
                               // Assign to last owner of open stage
                                       caseRec.OwnerId = history.Current_Owner_Id__c;
                                       break;
                                   }
                           }
                       }
                   }
                {
                    if (queueMap.containsKey(ABSLAMC_Constants.ISSUE_MANAGEMENT_UNIT) 
                        && caseSources.contains(caseRec.Source__c)) {
                            caseRec.OwnerId = queueMap.get(ABSLAMC_Constants.ISSUE_MANAGEMENT_UNIT);
                            caseIdToSkipperFlag.put(caseRec.Id, new Set<String>{ASF_Constants.SKIP_ASSIGNMENT});
                    }
                    else if(caseSlaHistoryMap.containsKey(caseRec.Id)) {
                        // Assign to last owner of open stage
                        for (ASF_Case_SLA_History__c history : caseSlaHistoryMap.get(caseRec.Id)) {
                            if (history.Stage__c == ABSLAMC_Constants.OPEN_STAGE) {
                                caseRec.OwnerId = history.Current_Owner_Id__c;
                                break;
                            }
                        }
                    }
                }
            }

            if(!caseIdToSkipperFlag.isEmpty()){
                ASF_CaseTriggerModularHelper.setManualSkipperFlags(caseIdToSkipperFlag, null);
            }
        }
        
    }
    
    /****************************************************************************************************************
* @param newMapCase
* @description - created to change the owner of case wrt to the Source of the case
*****************************************************************************************************************/ 
    public Static void dummyMethod(Map<Id,Case> newMapCase,Map<Id,Case> oldMapCase){
        System.debug('fired::');
        List<String> caseDetailIds = new List<String>();
        Map<Id, ABSLAMC_Case_Detail__c> caseToCaseDetailMap = new Map<Id, ABSLAMC_Case_Detail__c>();
        
        // Collecting the Case Detail IDs
        for (Case caseRec : newMapCase.values()) {
            if (caseRec.ABSLAMC_Case_Detail__c != null) {
                caseDetailIds.add(caseRec.ABSLAMC_Case_Detail__c);
            }
        }
        System.debug('fired::'+caseDetailIds);
        // Querying the ABSLAMC_Case_Detail__c records and initializing them as a map
        Map<Id, ABSLAMC_Case_Detail__c> caseDetailMap = new Map<Id, ABSLAMC_Case_Detail__c>([
            SELECT Id, Date_of_App_Support_Response__c, Date_of_Reply_back_to_App_Support__c, No_of_iterations__c
            FROM ABSLAMC_Case_Detail__c
            WHERE Id IN :caseDetailIds
        ]);
        System.debug('fired::'+caseDetailMap);
        // Mapping Case Id to Case Detail using Ids
        for (Id caseId : newMapCase.keySet()) {
            Case caseRec = newMapCase.get(caseId);
            if (caseRec.ABSLAMC_Case_Detail__c != null && caseDetailMap.containsKey(caseRec.ABSLAMC_Case_Detail__c)) {
                caseToCaseDetailMap.put(caseId, caseDetailMap.get(caseRec.ABSLAMC_Case_Detail__c));
            }
        }
        System.debug('fired::'+caseToCaseDetailMap);
        // List to hold the updated ABSLAMC_Case_Detail__c records
        List<ABSLAMC_Case_Detail__c> caseDetailToUpdate = new List<ABSLAMC_Case_Detail__c>();
        
        // Looping over the caseToCaseDetailMap and checking conditions
        for (Id caseId : caseToCaseDetailMap.keySet()) {
            Case caseRec = newMapCase.get(caseId);
            ABSLAMC_Case_Detail__c caseDetailRec = caseToCaseDetailMap.get(caseId);
            System.debug('New Stage: '+caseRec.Stage__c);
            System.debug('Old Stage: '+caseRec.Previous_Stage__c);
            System.debug('CD: '+caseDetailRec);
            //check if moved backward/forward from Stage 2;
            if(caseRec.Stage__c == ABSLAMC_Constants.REPLY_RECEIVED_FROM_APP_SUPPORT || caseRec.Stage__c == ABSLAMC_Constants.OPEN_STAGE){
                System.debug('inside 1');
                caseDetailRec.Date_of_App_Support_Response__c = DateTime.now();
                caseDetailRec.No_of_iterations__c = (caseDetailRec.No_of_iterations__c != null) ? caseDetailRec.No_of_iterations__c + 1 : 1;
                caseDetailToUpdate.add(caseDetailRec);
            } 
            // Checking if the current stage is 1 and the previous stage is 2
            if (caseRec.Stage__c == ABSLAMC_Constants.AWAITING_RESPONSE_FROM_APP_SUPPORT && oldMapCase.containsKey(caseRec.Id) && oldMapCase.get(caseRec.Id).Stage__c == ABSLAMC_Constants.REPLY_RECEIVED_FROM_APP_SUPPORT) {
                System.debug('inside 2');
                caseDetailRec.Date_of_Reply_back_to_App_Support__c = DateTime.Now();
                
                // Adding the updated case detail to the list
                caseDetailToUpdate.add(caseDetailRec);
            }
        }
        
        // Updating the ABSLAMC_Case_Detail__c records
        if (!caseDetailToUpdate.isEmpty()) {
            update caseDetailToUpdate;
        }
        
    }
    
}