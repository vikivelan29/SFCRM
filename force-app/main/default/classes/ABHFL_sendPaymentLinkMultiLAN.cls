public class ABHFL_sendPaymentLinkMultiLAN implements ASF_CaseStageClassInvocable {
	public static ASF_CaseMovementHelper.CaseStageValidationWrapper beforeStageMovement(Case caseRec){
        ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
        ABHFL_CTSTHelper.storeMultipleLANs(caseRec);
        retCls.status = ABHFL_Constants.SUCCESS;
        retCls.updatedCase = caseRec;
        retCls.isCaseUpdated = false;
        return retCls;
    }
     public static ASF_CaseMovementHelper.CaseStageValidationWrapper afterStageMovement(Case caseRec){
        ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
        
        return retCls;
    }
}