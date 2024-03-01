public with sharing class ABHFL_ComplaintsValidateOnResolvedStage implements ASF_CaseStageClassInvocable {
	public static Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> beforeStageMovement(List<Case> caseRecords){
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> returnWrapper = new Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper>();
        for(Case caseRec : caseRecords){
            ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
            retCls.status = ABHFL_Constants.SUCCESS;
            retCls.errorMessage = '';
            retCls.isCaseUpdated = false;
            returnWrapper.put(caseRec.Id, retCls);
        }

		Map<Id, Boolean> isGrievanceUserMap = ABHFL_ComplaintCTSTHelper.isInGrievanceTeam(caseRecords);
        List<Case> validateRCACases = new List<Case>();
        for(Case caseRec : caseRecords){
            //Vaidation for Case Resolution - only Grievance team can Resolve the case.
            if(isGrievanceUserMap.containsKey(caseRec.Id) && !isGrievanceUserMap.get(caseRec.Id) && !ASF_BulkCaseProcessorUtility.isBulkProcessing){
                ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = returnWrapper.get(caseRec.Id);
                retCls.status = ABHFL_Constants.ERROR;
                retCls.errorMessage = Custom_Messages__mdt.getInstance('ABHFL_Not_allowed_to_resolve_this_case').Message__c;
                returnWrapper.put(caseRec.Id, retCls);
            }
            //Vaidation for RCA Fields
            if(isGrievanceUserMap.containsKey(caseRec.Id) && isGrievanceUserMap.get(caseRec.Id)){
                validateRCACases.add(caseRec);
            }
		}
        if(!validateRCACases.isEmpty()){
            Map<Id, ABHFL_ComplaintCTSTHelper.FieldValidationResult> wrapperResultMap = ABHFL_ComplaintCTSTHelper.validateRCAfields(validateRCACases);
            for(Id caseId : wrapperResultMap.keySet()){
                ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = returnWrapper.get(caseId);
                ABHFL_ComplaintCTSTHelper.FieldValidationResult wrapperResult = wrapperResultMap.get(caseId);
                if(wrapperResult.result && !wrapperResult.blankFields.isEmpty()){
                    retCls.status = ABHFL_Constants.ERROR;
                    retCls.errorMessage = wrapperResult.message; 
                }
                returnWrapper.put(caseId, retCls);
            }
        }
        return returnWrapper;
    }
    public static Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> afterStageMovement(List<Case> caseRecords){
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> returnWrapper = new Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper>();
        for(Case caseRec : caseRecords){
            ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
            returnWrapper.put(caseRec.Id, retCls);
        }
        return returnWrapper;
    }
}