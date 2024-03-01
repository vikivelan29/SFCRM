public with sharing class ABHFL_PreClosurePaymentCheck implements ASF_CaseStageClassInvocable {
	public static Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> beforeStageMovement(List<Case> caseRecords){
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> returnWrapper = new Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper>();
        for(Case caseRec : caseRecords){
            ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
            retCls.status = ABHFL_Constants.SUCCESS;
            retCls.errorMessage = '';
            retCls.isCaseUpdated = false;
            returnWrapper.put(caseRec.Id, retCls);
        }
        Map<Id, Boolean> isPaymentsClearedMap = ABHFL_CTSTHelper.validatePayments(caseRecords);
        List<Case> paymentClearedCases = new List<Case>();
        if(!isPaymentsClearedMap.isEmpty()){
            for(Case caseRec : caseRecords){
                if(isPaymentsClearedMap.containsKey(caseRec.Id) && !isPaymentsClearedMap.get(caseRec.Id)){
                    ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = returnWrapper.get(caseRec.Id);
                    retCls.status = ABHFL_Constants.ERROR;
                    retCls.errorMessage = 'Payments should be Cleared in order to move to Next Stage.';
                    returnWrapper.put(caseRec.Id, retCls);
                }else{
                    paymentClearedCases.add(caseRec);
                }
            }
        }
        if(!paymentClearedCases.isEmpty()){
            ABHFL_CTSTHelper.sendEmailPaymentReceived(paymentClearedCases);
            ABHFL_CTSTHelper.sendTrackingLink(paymentClearedCases);
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