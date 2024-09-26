/*********************************************************
*@Class        :  ABSLAMC_BU_CTSTHelper
*@Author       :  Santosh
*@Created Date :  8/30/2024
*@Last Modified:  8/30/2024
*@description  :  Class for ABSLAMC BU Specific Methods. 
*********************************************************/

public with sharing class ABSLAMC_BU_CTSTHelper {
    
    
    /**
* @param newCaseList - list of new value cases from trigger
* @param olCasesMap - Map of old value cases from trigger
* @return null
* @description - calling this method in Before update trigger to Restring agent's backward movement from Stage 3 to Stage 1 for ABSLAMC BU for Journey 5 - US PR1030924-53
*/
    public static void restrictBackStageMovementFromStage3ToSatage1(Map<Id, Case> newCaseMap, Map<Id, Case> oldCasesMap){
        String backstageError = System.label.ABSLAMC_Back_Stage_Movement_Error;
        for(Case currentCase: newCaseMap.values()){
            Case oldCase = oldCasesMap.get(currentCase.Id);
            if(currentCase.Stage__c != oldCase.Stage__c  && currentCase.Pending_Clarification__c && currentCase.Business_Unit__c == ABSLAMC_Constants.ABSLAMCBU
               && oldCase.Stage__c == ABSLAMC_Constants.REPLY_RECEIVED_FROM_APP_SUPPORT && currentCase.Stage__c == ABSLAMC_Constants.OPEN_STAGE){
                   currentCase.addError(backstageError);
               }
        }
    }

      /**
* @param newCaseList - list of new value cases from trigger
* @return null
* @description - this method is used to validate if the case is in mandatory approval stage or not
*/
public static void validateManualApproval(Map<Id, Case> newMapCase, Map<Id, Case> oldMapCase) {
    
    Set<String> statusToCheck = new Set<String>{ABSLAMC_Constants.CAMSPENDINGSTATUS};
    Map<Id, Case> amcCAMSApprovalSpecificCases = new Map<Id, Case>();
    Set<Id> caseIds = new Set<Id>();
    Map<Id, List<ASF_Case_Approv__c>> caseApprovalsMap = new Map<Id, List<ASF_Case_Approv__c>>();
    Map<Id, String> caseIdToCCCMap = new Map<Id, String>();
    Map<Id, Set<String>> caseIdToSkipperFlag = new Map<Id, Set<String>>();
    string mandatoryAppErrMsg = label.ABSLAMC_MandatoryApprovalRequired;
    string nonMandatoryAppErrMsg = label.ABSLAMC_NonMandatoryAppErrMsg;
    string atleastOneApprRecordErrMsg = label.ABSLAMC_NoApprovalRecordsFound;
    
    for (Case caseRec : newMapCase.values()) {
        Case oldCaseRec = oldMapCase.get(caseRec.Id);
        
        // Check if the Stage__c is moving from 2 to 3
        if (caseRec.Stage__c == ABSLAMC_Constants.CAMSPENDINGSTATUS && oldCaseRec.Stage__c == ABSLAMC_Constants.CAMSAPPROVALSTAGE && 
            caseRec.Business_Unit__c == ABSLAMC_Constants.ABSLAMCBU && 
            statusToCheck.contains(caseRec.Stage__c)) {
            
            amcCAMSApprovalSpecificCases.put(caseRec.Id, caseRec); 
            if (String.isNotBlank(caseRec.CCC_External_Id__c)) {
                caseIdToCCCMap.put(caseRec.Id, caseRec.CCC_External_Id__c); 
            }
        }
    }


    if (!caseIdToCCCMap.isEmpty()) {
        // Fetch the relevant stage configuration records
        List<ASF_Case_Stage_Config__c> stageConfigs = [
            SELECT Id, Mandatory_Approval__c, Case_Category_Config__r.CCC_External_Id__c, StageName__c, Is_Approval_Stage__c 
            FROM ASF_Case_Stage_Config__c  
            WHERE Case_Category_Config__r.CCC_External_Id__c IN :caseIdToCCCMap.values() 
            AND StageName__c = :ABSLAMC_Constants.CAMSAPPROVALSTAGE
        ];
        
        
        if (!stageConfigs.isEmpty()) {
            List<ASF_Case_Approv__c> approvalRecords = [
                SELECT Id, Approval_Status__c, SR__c, CreatedDate
                FROM ASF_Case_Approv__c
                WHERE SR__c IN :caseIdToCCCMap.keySet()
                ORDER BY CreatedDate DESC
            ];  
            
            for (ASF_Case_Approv__c approval : approvalRecords) {
                if (!caseApprovalsMap.containsKey(approval.SR__c)) {
                    caseApprovalsMap.put(approval.SR__c, new List<ASF_Case_Approv__c>());
                }
                caseApprovalsMap.get(approval.SR__c).add(approval);
            }
        }
        
        for (ASF_Case_Stage_Config__c stageConfig : stageConfigs) {
            Id caseId = null;
            for (Id id : caseIdToCCCMap.keySet()) {
                if (stageConfig.Case_Category_Config__r.CCC_External_Id__c.equals(caseIdToCCCMap.get(id))) {
                    caseId = id;
                    break;
                }
            }
            
            Case caseRec = amcCAMSApprovalSpecificCases.get(caseId);
         
            if (caseRec != null) {
                List<ASF_Case_Approv__c> approvals = caseApprovalsMap.get(caseRec.Id);
                
                if (approvals != null && !approvals.isEmpty()) {
                    ASF_Case_Approv__c latestApproval = approvals[0];
                    
                    if (stageConfig.Mandatory_Approval__c && stageConfig.Is_Approval_Stage__c) {
                        // Check if the latest approval record is approved
                        if (latestApproval.Approval_Status__c != ABSLAMC_Constants.APPROVEDSTATUS) {
                            caseRec.addError(mandatoryAppErrMsg);
                        }
                    } else if (!stageConfig.Mandatory_Approval__c && stageConfig.Is_Approval_Stage__c) {
                        // Check if the latest approval record is approved or recalled
                        if (latestApproval.Approval_Status__c != ABSLAMC_Constants.APPROVEDSTATUS && latestApproval.Approval_Status__c != ABSLAMC_Constants.RECALLEDSTATUS) {
                            caseRec.addError(nonMandatoryAppErrMsg);
                        } else { 
                        caseIdToSkipperFlag.put(caseRec.Id, new Set<String>{ASF_Constants.SKIP_APPROVAL_CHECKS});}
                    }
                } else {
                    if (stageConfig.Mandatory_Approval__c && stageConfig.Is_Approval_Stage__c) {
                        // No approval records found for mandatory approval stage, add an error
                        caseRec.addError(atleastOneApprRecordErrMsg);
                    }
                }
            }
             if(!caseIdToSkipperFlag.isEmpty()){
                ASF_CaseTriggerModularHelper.setManualSkipperFlags(caseIdToSkipperFlag, null);
            }
        }
    }
}
    
}