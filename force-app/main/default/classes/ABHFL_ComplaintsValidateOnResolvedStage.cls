public class ABHFL_ComplaintsValidateOnResolvedStage implements ASF_CaseStageClassInvocable {
	public static ASF_CaseMovementHelper.CaseStageValidationWrapper beforeStageMovement(Case caseRec){
        ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
        retCls.status = 'Success';
        retCls.errorMessage = '';
        retCls.updatedCase = caseRec;
        retCls.isCaseUpdated = false;
		Boolean isGrievanceUser = ABHFL_ComplaintCTSTHelper.isInGrievanceTeam(caseRec);
        if(!isGrievanceUser){
             retCls.status = 'Error';
             retCls.errorMessage = 'You are not allowed to Resolve this Case.';
        }
        Boolean checkGAPFields = ABHFL_ComplaintCTSTHelper.validateGAPfields(caseRec);
        System.debug('Check GAP Fields: ' + checkGAPFields);
        if(isGrievanceUser && checkGAPFields){
            retCls.status = 'Error';
            retCls.errorMessage = 'Any one of GAP or Regulator Initiated should be selected to complete RCA';
        }
        return retCls;
        
    }
    public static ASF_CaseMovementHelper.CaseStageValidationWrapper afterStageMovement(Case caseRec){
        ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
        
        return retCls;
    }
}