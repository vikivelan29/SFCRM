public with sharing class ABHFL_PreClosurePaymentCheck implements ASF_CaseStageClassInvocable {
	public static ASF_CaseMovementHelper.CaseStageValidationWrapper beforeStageMovement(Case caseRec){
        ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
        retCls.status = ABHFL_Constants.SUCCESS;
        retCls.errorMessage = '';
        retCls.updatedCase = caseRec;
        retCls.isCaseUpdated = false;
		Boolean isPaymentsCleared = ABHFL_CTSTHelper.validatePayments(caseRec);
        if(!isPaymentsCleared){
            retCls.status = ABHFL_Constants.ERROR;
        	retCls.errorMessage = 'Payments should be Cleared in order to move to Next Stage.';
        }else{
            ABHFL_CTSTHelper.sendEmailPaymentReceived(caseRec);
            ABHFL_CTSTHelper.sendTrackingLink(caseRec);
        }
		
        return retCls;
        
    }
    public static ASF_CaseMovementHelper.CaseStageValidationWrapper afterStageMovement(Case caseRec){
        ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
        
        return retCls;
    }
}