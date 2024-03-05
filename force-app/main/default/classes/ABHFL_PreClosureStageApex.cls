public with sharing class ABHFL_PreClosureStageApex implements ASF_CaseStageClassInvocable {
	public static Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> beforeStageMovement(List<Case> caseRecords){
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> returnWrapper = new Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper>();
        List<Case> sendTrackingLinkCases = new List<Case>();
        List<Case> assignCaseToPreferredBranchCases = new List<Case>();
        List<Case> assignCaseToAOMROMCases = new List<Case>();
        for(Case caseRec : caseRecords){
            ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
            retCls.status = ABHFL_Constants.SUCCESS;
            retCls.isCaseUpdated = false;
            if(caseRec.Stage__c == 'Open' || 
                caseRec.Stage__c == 'CPU Banking' || 
                caseRec.Stage__c == 'CPU FCL Issuance' || 
                caseRec.Stage__c == 'NDC' || 
                caseRec.Stage__c == 'Retrieval' || 
                caseRec.Stage__c == 'Hub Location' || 
                caseRec.Stage__c == 'Branch' || 
                caseRec.Stage__c == 'AOM/ROM') {
                    sendTrackingLinkCases.add(caseRec);
            }
            if(caseRec.Stage__c == 'AOM/ROM'){
                assignCaseToPreferredBranchCases.add(caseRec);
            }
            if(caseRec.Stage__c == 'AOM/ROM'){
                assignCaseToAOMROMCases.add(caseRec);
            }
            returnWrapper.put(caseRec.Id, retCls);
        }

        if(!sendTrackingLinkCases.isEmpty()){
            ABHFL_CTSTHelper.sendTrackingLink(sendTrackingLinkCases);
        }
        Map<Id, Case> assignCaseToPreferredBranchResults = new Map<Id, Case>();
        if(!assignCaseToPreferredBranchCases.isEmpty()){
            assignCaseToPreferredBranchResults = ABHFL_CTSTHelper.assignCaseToPreferredBranch(assignCaseToPreferredBranchCases);
        }
        Map<Id, Case> assignCaseToAOMROMResults = new Map<Id, Case>();
        if(!assignCaseToAOMROMCases.isEmpty()){
            assignCaseToAOMROMResults = ABHFL_CTSTHelper.assignCaseToPreferredBranch(assignCaseToAOMROMCases);
        }

        for(Case caseRec : caseRecords){
            ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = returnWrapper.get(caseRec.Id);
            if(assignCaseToPreferredBranchResults.containsKey(caseRec.Id)){
                retCls.updatedCase = assignCaseToPreferredBranchResults.get(caseRec.Id);
                retCls.isCaseUpdated = true;
            }
            if(assignCaseToAOMROMResults.containsKey(caseRec.Id)){
                retCls.updatedCase = assignCaseToAOMROMResults.get(caseRec.Id);
                retCls.isCaseUpdated = true;
            }
            returnWrapper.put(caseRec.Id, retCls);
        }
        return returnWrapper;
    }
     public static Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> afterStageMovement(List<Case> caseRecords){
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> returnWrapper = new Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper>();
        List<Case> eligibleCases = new List<Case>();
        for(Case caseRec : caseRecords){
            ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
            retCls.status = ABHFL_Constants.SUCCESS;
            retCls.isCaseUpdated = false;
            returnWrapper.put(caseRec.Id, retCls);
            if(caseRec.Stage__c == 'Retrieval'){
                eligibleCases.add(caseRec);
            }
        }
        ABHFL_CTSTHelper.sendLoanClosedEmail(eligibleCases);   
        return returnWrapper;
    }
}
