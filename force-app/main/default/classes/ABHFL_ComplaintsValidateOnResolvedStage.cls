public with sharing class ABHFL_ComplaintsValidateOnResolvedStage implements ASF_CaseStageClassInvocable {
	public static ASF_CaseMovementHelper.CaseStageValidationWrapper beforeStageMovement(Case caseRec){
        ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
        retCls.status = ABHFL_Constants.SUCCESS;
        retCls.errorMessage = '';
        retCls.updatedCase = caseRec;
        retCls.isCaseUpdated = false;
		Boolean isGrievanceUser = ABHFL_ComplaintCTSTHelper.isInGrievanceTeam(caseRec);
        //Vaidation for Case Resolution - only Grievance team can Resolve the case.
        if(!isGrievanceUser && !ASF_BulkCaseProcessorUtility.isBulkProcessing){
             retCls.status = ABHFL_Constants.ERROR;
             retCls.errorMessage = Custom_Messages__mdt.getInstance('ABHFL_Not_allowed_to_resolve_this_case').Message__c;
        }
        //Vaidation for RCA Fields
        if(isGrievanceUser){
            ABHFL_ComplaintCTSTHelper.FieldValidationResult wrapperResult = ABHFL_ComplaintCTSTHelper.validateRCAfields(caseRec);
            if(wrapperResult.result && !wrapperResult.blankFields.isEmpty()){
               retCls.status = ABHFL_Constants.ERROR;
			   retCls.errorMessage = wrapperResult.message; 
        } 
    		
		}

        return retCls;
        
    }
    public static ASF_CaseMovementHelper.CaseStageValidationWrapper afterStageMovement(Case caseRec){
        ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
        
        return retCls;
    }
}