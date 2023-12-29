public with sharing class ABHFL_ComplaintsValidateOnResolvedStage implements ASF_CaseStageClassInvocable {
	public static ASF_CaseMovementHelper.CaseStageValidationWrapper beforeStageMovement(Case caseRec){
        ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
        retCls.status = ABHFL_Constants.SUCCESS;
        retCls.errorMessage = '';
        retCls.updatedCase = caseRec;
        retCls.isCaseUpdated = false;
		Boolean isGrievanceUser = ABHFL_ComplaintCTSTHelper.isInGrievanceTeam(caseRec);
        if(!isGrievanceUser){
             retCls.status = ABHFL_Constants.ERROR;
             retCls.errorMessage = Custom_Messages__mdt.getInstance('ABHFL_Not_allowed_to_resolve_this_case').Message__c;
        }
        Boolean checkGAPFields = ABHFL_ComplaintCTSTHelper.validateGAPfields(caseRec);
        if(isGrievanceUser && checkGAPFields){
            retCls.status = ABHFL_Constants.ERROR;
            retCls.errorMessage = Custom_Messages__mdt.getInstance('ABHFL_Complaints_GAP_validation_error').Message__c;
        }
        return retCls;
        
    }
    public static ASF_CaseMovementHelper.CaseStageValidationWrapper afterStageMovement(Case caseRec){
        ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
        
        return retCls;
    }
}