public class ABHFL_requestInProgressApexClass implements ASF_CaseStageClassInvocable {
    public static ASF_CaseMovementHelper.CaseStageValidationWrapper beforeStageMovement(Case caseRec){
        ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
        case caseRecord = ABHFL_CTSTHelper.assignCaseToBranch(caseRec);
        retCls.status = ABHFL_Constants.SUCCESS;
        retCls.updatedCase = caseRecord;
        retCls.isCaseUpdated = true;
        return retCls;
    }
     public static ASF_CaseMovementHelper.CaseStageValidationWrapper afterStageMovement(Case caseRec){
        ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
        
        return retCls;
    }
}