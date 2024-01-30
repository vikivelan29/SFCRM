public with sharing class ABHFL_PreClosureStageApex implements ASF_CaseStageClassInvocable {
	public static ASF_CaseMovementHelper.CaseStageValidationWrapper beforeStageMovement(Case caseRec){
        ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
        retCls.status = ABHFL_Constants.SUCCESS;
        retCls.updatedCase = caseRec;
        retCls.isCaseUpdated = false;
        
        if(caseRec.Stage__c == 'Hub Location'){
            Case updatedCaseRec = ABHFL_CTSTHelper.assignCaseToPreferredBranch(caseRec);
            retCls.updatedCase = updatedCaseRec;
            retCls.isCaseUpdated = true;
        }
         if(caseRec.Stage__c == 'Branch'){
            Case updatedCaseRec = ABHFL_CTSTHelper.assignCaseToAOMROM(caseRec);
            retCls.updatedCase = updatedCaseRec;
            retCls.isCaseUpdated = true;
        }
        return retCls;
    }
     public static ASF_CaseMovementHelper.CaseStageValidationWrapper afterStageMovement(Case caseRec){
        ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
        
        return retCls;
    }
}