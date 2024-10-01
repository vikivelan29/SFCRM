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
        
        Map<Id,Case> amcSpecificCases = new Map<Id,Case>();
        Map<Id, List<ASF_Case_SLA_History__c>> caseSlaHistoryMap = new Map<Id, List<ASF_Case_SLA_History__c>>();
        List<String> queueNames = new List<String>(Label.ABSLAMC_CaseAssignmentQueueNames.split(','));
        List<String> caseSources = new List<String>(Label.ABSLAMC_CaseSourcesforAssignment.split(','));
        Map<String, Id> queueMap = new Map<String, Id>(); 
        List<ASF_Case_SLA_History__c> caseSLAHistories = new List<ASF_Case_SLA_History__c>();
        Map<Id, Set<String>> caseIdToSkipperFlag = new Map<Id, Set<String>>();
        
        for(Case caseRec : newMapCase.values()){
            if(caseRec.Business_Unit__c == ABSLAMC_Constants.ABSLAMCBU){
                amcSpecificCases.put(caseRec.Id,caseRec);
            }
        }
        Set<Id> caseIds = amcSpecificCases.keySet();
        // Query SLA histories for all cases at once
        if(!caseIds.isEmpty()){
            caseSLAHistories = [SELECT Id, Case__c, Current_Owner_Id__c, Current_Owner__c,  
                                Stage__c, Status__c, is_Running_Record__c 
                                FROM ASF_Case_SLA_History__c
                                WHERE Case__c IN :caseIds WITH SYSTEM_MODE ORDER BY Stage_End_Date__c DESC
                               ];
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
                    && caseRec.Stage__c != oldMapCase.get(caseRec.Id).Stage__c 
                    && caseRec.Stage__c == ABSLAMC_Constants.OPEN_STAGE) 
                {
                                        if (queueMap.containsKey(ABSLAMC_Constants.ISSUE_MANAGEMENT_UNIT) 
                        && caseSources.contains(caseRec.Source__c)) {
                            caseRec.OwnerId = queueMap.get(ABSLAMC_Constants.ISSUE_MANAGEMENT_UNIT);
                            caseIdToSkipperFlag.put(caseRec.Id, new Set<String>{ASF_Constants.SKIP_ASSIGNMENT});
                        }
                    else if (caseSlaHistoryMap.containsKey(caseRec.Id)) {
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
    public Static void updateCaseExtensionFields(Map<Id,Case> newMapCase,Map<Id,Case> oldMapCase){
        Map<Id,Case> amcSpecificCases = new Map<Id,Case>();
        Set<String> caseDetailIds = new Set<String>();
        Map<Id, ABSLAMC_Case_Detail__c> caseToCaseDetailMap = new Map<Id, ABSLAMC_Case_Detail__c>();
        Map<Id, ABSLAMC_Case_Detail__c> caseDetailMap = new Map<Id, ABSLAMC_Case_Detail__c>();
        List<ABSLAMC_Case_Detail__c> caseDetailToUpdate = new List<ABSLAMC_Case_Detail__c>();
        
        for(Case caseRec : newMapCase.values()){
            if(caseRec.Business_Unit__c == ABSLAMC_Constants.ABSLAMCBU){
                amcSpecificCases.put(caseRec.Id,caseRec);
                if (caseRec.ABSLAMC_Case_Detail__c != null){
                    caseDetailIds.add(caseRec.ABSLAMC_Case_Detail__c);
                }
            }
        }
        
        if(!amcSpecificCases.isEmpty()){
            // Querying the ABSLAMC_Case_Detail__c records and initializing them as a map
            if(!caseDetailIds.isEmpty()){
                caseDetailMap = new Map<Id, ABSLAMC_Case_Detail__c>([
                    SELECT Id, Date_of_App_Support_Response__c, Date_of_Reply_back_to_App_Support__c, No_of_iterations__c
                    FROM ABSLAMC_Case_Detail__c
                    WHERE Id IN :caseDetailIds
                ]);
            }
            
            // Mapping Case Id to Case Detail using Ids
            if(!caseDetailMap.isEmpty()){
                for (Id caseId : amcSpecificCases.keySet()) {
                    Case caseRec = amcSpecificCases.get(caseId);
                    if (caseRec.ABSLAMC_Case_Detail__c != null && caseDetailMap.containsKey(caseRec.ABSLAMC_Case_Detail__c)) {
                        caseToCaseDetailMap.put(caseId, caseDetailMap.get(caseRec.ABSLAMC_Case_Detail__c));
                    }
                }
            }
            
            // Looping over the caseToCaseDetailMap and checking conditions
            if(!caseToCaseDetailMap.isEmpty()){
                for (Id caseId : caseToCaseDetailMap.keySet()) {
                    Case caseRec = amcSpecificCases.get(caseId);
                    ABSLAMC_Case_Detail__c caseDetailRec = caseToCaseDetailMap.get(caseId);
                    //check if moved backward/forward from Stage 2;
                    if((caseRec.Stage__c == ABSLAMC_Constants.REPLY_RECEIVED_FROM_APP_SUPPORT || caseRec.Stage__c == ABSLAMC_Constants.OPEN_STAGE) && oldMapCase.get(caseRec.Id).Stage__c == ABSLAMC_Constants.AWAITING_RESPONSE_FROM_APP_SUPPORT){
                        caseDetailRec.Date_of_App_Support_Response__c = DateTime.now();
                        caseDetailToUpdate.add(caseDetailRec);
                    } 
                    // Checking if the current stage is 1 and the previous stage is 2
                    if (caseRec.Stage__c == ABSLAMC_Constants.AWAITING_RESPONSE_FROM_APP_SUPPORT && oldMapCase.containsKey(caseRec.Id) && oldMapCase.get(caseRec.Id).Stage__c == ABSLAMC_Constants.REPLY_RECEIVED_FROM_APP_SUPPORT) {
                        caseDetailRec.Date_of_Reply_back_to_App_Support__c = DateTime.Now();
                        caseDetailToUpdate.add(caseDetailRec);
                    }
                    // Checking if the current stage is 3 and the previous stage is 2
                    if(caseRec.Stage__c == ABSLAMC_Constants.REPLY_RECEIVED_FROM_APP_SUPPORT && oldMapCase.get(caseRec.Id).Stage__c == ABSLAMC_Constants.AWAITING_RESPONSE_FROM_APP_SUPPORT){
                        caseDetailRec.No_of_iterations__c = (caseDetailRec.No_of_iterations__c != null) ? caseDetailRec.No_of_iterations__c + 1 : 1;
                    }
                }
            }
            if (!caseDetailToUpdate.isEmpty()) {
                update caseDetailToUpdate;
            }
            
        }
    }
    
    /****************************************************************************************************************
* @param newMapCase
* @description - created to update the stage of case from open to resolved when the cases are FTR
*****************************************************************************************************************/ 
    public Static void updateCaseStage(Map<Id,Case> newMapCase,Map<Id,Case> oldMapCase){
        List<Case> caseToUpdateList = new List<Case>();
        for (Case caseRec : newMapCase.values()) {
            if (caseRec.Business_Unit__c == ABSLAMC_Constants.ABSLAMCBU && caseRec.FTR__c != oldMapCase.get(caseRec.Id).FTR__c &&
                caseRec.FTR__c == TRUE && oldMapCase.get(caseRec.Id).Stage__c == ABSLAMC_Constants.OPEN_STAGE && caseRec.MoveToNext__c == TRUE)
            {   
                caseRec.Status = ABSLAMC_Constants.RESOLVED_STAGE;
                caseRec.Stage__c = ABSLAMC_Constants.RESOLVED_STAGE;
            }
        }
    }
    /****************************************************************************************************************
* @param newMapCase, oldMapCase
* @description - created to update the related extension object fields when CAMS updates the case
* @JIRA - PR1030924-187
*****************************************************************************************************************/  
    public Static void updateCaseExtensionFieldsForCams(Map<Id,Case> newMapCase,Map<Id,Case> oldMapCase){
        Set<String> statusToCheck = new Set<String>{ABSLAMC_Constants.CAMSPENDINGSTATUS,ABSLAMC_Constants.REPLYFROMCAMS,ABSLAMC_Constants.RESOLVED_STAGE};
        Map<Id,Case> amcCAMSSpecificCases = new Map<Id,Case>();
        Set<String> caseDetailIds = new Set<String>();
        Map<Id, ABSLAMC_Case_Detail__c> caseToCaseDetailMap = new Map<Id, ABSLAMC_Case_Detail__c>();
        Map<Id, ABSLAMC_Case_Detail__c> caseDetailMap = new Map<Id, ABSLAMC_Case_Detail__c>();
        Map<Id,ABSLAMC_Case_Detail__c> caseDetailToUpdate = new Map<Id,ABSLAMC_Case_Detail__c>();
        Set<String> validReplyTypeForResolveStage = new Set<String>{ABSLAMC_Constants.SATISFACTORYREPLYTYPE};
        String mandatoryFieldsErrMsg = label.ABSLAMC_CAMSMandatoryFieldsErrorMsg;
        String replyTypeErrorMsg = label.ABSLAMC_ClosureReplyTypeForCAMSErrorMsg;
        String backStageReplyTypeError = label.ABSLAMC_BackStageSatisfactoryReolyType; 
        
        
        for(Case caseRec : newMapCase.values()){
            if(caseRec.Business_Unit__c == ABSLAMC_Constants.ABSLAMCBU && statusToCheck.contains(caseRec.Stage__c)){
                amcCAMSSpecificCases.put(caseRec.Id,caseRec);
                if (caseRec.ABSLAMC_Case_Detail__c != null){
                    caseDetailIds.add(caseRec.ABSLAMC_Case_Detail__c);
                }
            }
        }
        
        // Querying the ABSLAMC_Case_Detail__c records and initializing them as a map
        if(!amcCAMSSpecificCases.isEmpty()){
            if(!caseDetailIds.isEmpty()){
                caseDetailMap = new Map<Id, ABSLAMC_Case_Detail__c>([
                    SELECT Id,CAMS_Ticket_Reference_Number__c,CAMS_Ticket_Status__c, No_of_iterations__c,Additional_Remarks_for_CAMS__c,Reply_Type_for_CAMS__c
                    FROM ABSLAMC_Case_Detail__c
                    WHERE Id IN :caseDetailIds
                ]);
            }
        }
        
        // Mapping Case Id to Case Detail using Ids
        if(!caseDetailMap.isEmpty()){
            for (Id caseId : amcCAMSSpecificCases.keySet()) {
                Case caseRec = amcCAMSSpecificCases.get(caseId);
                if (caseRec.ABSLAMC_Case_Detail__c != null && caseDetailMap.containsKey(caseRec.ABSLAMC_Case_Detail__c)) {
                    caseToCaseDetailMap.put(caseId, caseDetailMap.get(caseRec.ABSLAMC_Case_Detail__c));
                }
            }
        }
        
        // Looping over the caseToCaseDetailMap and checking conditions
        if(!caseToCaseDetailMap.isEmpty()){
            for (Id caseId : caseToCaseDetailMap.keySet()) {
                Case caseRec = amcCAMSSpecificCases.get(caseId);
                Case oldCase = oldMapCase.get(caseId);
                ABSLAMC_Case_Detail__c caseDetailRec = caseToCaseDetailMap.get(caseId);
                
                //check if case status updated to reply received from cams and ticket ref no. is not blank, mark cams status closed
                if(caseRec.Stage__c!= oldCase.Stage__c 
                   && caseRec.Stage__c == ABSLAMC_Constants.REPLYFROMCAMS 
                   && String.isNotBlank(caseDetailRec.CAMS_Ticket_Reference_Number__c)){
                       
                       // check if cams status is closed, make ticket number empty
                    //    if(caseDetailRec.CAMS_Ticket_Status__c == ABSLAMC_Constants.CAMSCLOSEDSTATUS){
                    //        caseDetailRec.CAMS_Ticket_Reference_Number__c = '';
                           
                    //        caseDetailToUpdate.put(caseDetailRec.Id,caseDetailRec);
                    //    }
                       // check if case previous stage was 2, then increment by 1
                       if(oldCase.Stage__c == ABSLAMC_Constants.CAMSPENDINGSTATUS){
                           caseDetailRec.No_of_iterations__c = (caseDetailRec.No_of_iterations__c != null) ? caseDetailRec.No_of_iterations__c + 1 : 1;
                           caseDetailRec.Additional_Remarks_for_CAMS__c = '';
                           caseDetailRec.Reply_Type_for_CAMS__c = '';
                           caseDetailToUpdate.put(caseDetailRec.Id,caseDetailRec);
                       }
                       
                   } 
                //clearing values for Additional_Remarks_for_CAMS__c,Reply_Type_for_CAMS__c when moved to stage 3
                if(caseRec.Stage__c!= oldCase.Stage__c 
                             && caseRec.Stage__c == ABSLAMC_Constants.REPLYFROMCAMS 
                             && OldCase.Stage__c == ABSLAMC_Constants.CAMSPENDINGSTATUS){
                                 caseDetailRec.Additional_Remarks_for_CAMS__c = '';
                                 caseDetailRec.Reply_Type_for_CAMS__c = '';
                                 caseDetailToUpdate.put(caseDetailRec.Id,caseDetailRec);
                             }
       
                if(caseRec.Stage__c != oldCase.Stage__c
                   && oldCase.Stage__c == ABSLAMC_Constants.REPLYFROMCAMS
                   && caseRec.Stage__c == ABSLAMC_Constants.CAMSPENDINGSTATUS){
                       
                       String errorMsg = '';
                       if (!String.isNotBlank(caseDetailRec.Reply_Type_for_CAMS__c)) {
                           errorMsg += ABSLAMC_Constants.REPLYTYPEFORCAMS + ', ';
                       }
                       if (!String.isNotBlank(caseDetailRec.Additional_Remarks_for_CAMS__c)) {
                           errorMsg += ABSLAMC_Constants.ADDNTLREMARKSFORCAMS + ', ';
                       }
                       if (!String.isEmpty(errorMsg)) {
                           errorMsg = errorMsg.removeEnd(', ');
                           caseRec.addError(mandatoryFieldsErrMsg+errorMsg);
                       }
                       caseDetailRec.Date_of_Reply_back_to_CAMS__c = DateTime.Now();
                       caseDetailToUpdate.put(caseDetailRec.Id,caseDetailRec);
                   }
                
                //validating if reply type is S,SN when updated to closed stage
                if(caseRec.Stage__c != oldCase.Stage__c
                   && oldCase.Stage__c == ABSLAMC_Constants.REPLYFROMCAMS
                   && caseRec.Stage__c == ABSLAMC_Constants.RESOLVED_STAGE){
                       
                       if(!validReplyTypeForResolveStage.contains(caseDetailRec.Reply_Type_for_CAMS__c)){
                           caseRec.addError(replyTypeErrorMsg);  
                       } 
                   }
                
                //validating if moving from stage 3-2,reply type should not be Satisfactory
                if(caseRec.Stage__c != oldCase.Stage__c
                   && oldCase.Stage__c == ABSLAMC_Constants.REPLYFROMCAMS
                   && caseRec.Stage__c == ABSLAMC_Constants.CAMSPENDINGSTATUS
                   && caseDetailRec.Reply_Type_for_CAMS__c == ABSLAMC_Constants.SATISFACTORYREPLYTYPE){
                       caseRec.addError(backStageReplyTypeError);  
                   }
                
                
            }
        }
        if (!caseDetailToUpdate.isEmpty()) {
            update caseDetailToUpdate.values();
        }
        
    }
    
}