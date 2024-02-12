public class ABHFL_requestInProgressApexClass implements ASF_CaseStageClassInvocable {
    public static ASF_CaseMovementHelper.CaseStageValidationWrapper beforeStageMovement(Case caseRec){
        ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
        //Assign to Branch for Address Change
        if(caseRec.CCC_External_Id__c == 'hfl003'){
            case caseRecord = ABHFL_CTSTHelper.assignCaseToBranchTDS(caseRec);
        	retCls.status = ABHFL_Constants.SUCCESS;
        	retCls.updatedCase = caseRecord;
        	retCls.isCaseUpdated = true;
        }else{
            //Assign to Branch for other Requests
        	case caseRecord = ABHFL_CTSTHelper.assignCaseToBranch(caseRec);
        	retCls.status = ABHFL_Constants.SUCCESS;
        	retCls.updatedCase = caseRecord;
        	retCls.isCaseUpdated = true;
        }											
        return retCls;
            
    }
     public static ASF_CaseMovementHelper.CaseStageValidationWrapper afterStageMovement(Case caseRec){
        ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
        
        return retCls;
    }
}