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
            if(caseRec.Stage__c == 'Branch'){
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
            assignCaseToAOMROMResults = ABHFL_CTSTHelper.assignCaseToAOMROM(assignCaseToAOMROMCases);
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
        
        /* Start by Nikhil, JIRA ID- PR970457-2176 
           Add conditions For the case if the tagged abhfl case details have the source of funds as 
          'Settlement/Auction' OR 'Mature' OR 'Loan Cancellation' - checklist TAB should not be mandatory. */
       Set<Id> caseIds = new Set<Id>();
        for (Case caseRec : caseRecords) {
            caseIds.add(caseRec.Id);
        }
        
        List<ASF_Checklist__c> getIncompleteCaseChecklists = [
            SELECT Id, Case__c, Mandatory__c, Stage_Name__c, Type__c, Status__c
            FROM ASF_Checklist__c
            WHERE 
            Status__c NOT IN ('Completed', 'Rejected')
            AND Case__c IN :caseIds
        ]; 
        
        Map<Id, List<ASF_Checklist__c>> checklistMap = new Map<Id, List<ASF_Checklist__c>>();
        for (ASF_Checklist__c checklist : getIncompleteCaseChecklists) {
            if (!checklistMap.containsKey(checklist.Case__c)) {
                checklistMap.put(checklist.Case__c, new List<ASF_Checklist__c>());
            }
            checklistMap.get(checklist.Case__c).add(checklist);
        }

        for (Case caseRec : caseRecords) {
            ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
            retCls.status = ABHFL_Constants.SUCCESS;
            if (checklistMap.containsKey(caseRec.Id)) {
                if(caseRec.CCC_External_Id__c == 'hfl060' && 
                   caseRec.ABHFL_Case_Detail__r.Source_of_Funds__c != 'Mature' && 
                   caseRec.ABHFL_Case_Detail__r.Source_of_Funds__c != 'Loan cancellation' && 
                   caseRec.ABHFL_Case_Detail__r.Source_of_Funds__c != 'Settlement/Auction'){
                       retCls.status = ABHFL_Constants.ERROR;
                       retCls.errorMessage = System.Label.Incomplete_Checklist_Error_Message;
                       retCls.isCaseUpdated=false;
                   }
            }
            returnWrapper.put(caseRec.Id, retCls);
        }    
	// End by EY-Nikhil, JIRA ID- PR970457-2176 
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
