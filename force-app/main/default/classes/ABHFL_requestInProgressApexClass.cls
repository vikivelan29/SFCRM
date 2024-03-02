public class ABHFL_requestInProgressApexClass implements ASF_CaseStageClassInvocable {
    public static Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> beforeStageMovement(List<Case> caseRecords){
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> returnWrapper = new Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper>();
        List<Case> hfl003Cases = new List<Case>();
        List<Case> otherCases = new List<Case>();
        for(Case caseRec : caseRecords){
            if(caseRec.CCC_External_Id__c == 'hfl003'){
                //Assign to Branch for Address Change
                hfl003Cases.add(caseRec);
            }else{
                //Assign to Branch for other Requests
                otherCases.add(caseRec);
            }
        }
        Map<Id, Case> returnedUpdatedCaseMap = new Map<Id, Case>();
        if(!hfl003Cases.isEmpty()){
            returnedUpdatedCaseMap.putAll(ABHFL_CTSTHelper.assignCaseToBranchTDS(hfl003Cases));
        }

        if(!otherCases.isEmpty()){
            returnedUpdatedCaseMap.putAll(ABHFL_CTSTHelper.assignCaseToBranch(otherCases));
        }

        for(Case caseRec : caseRecords){
            ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
            retCls.isCaseUpdated = false;
            if(returnedUpdatedCaseMap.containsKey(caseRec.Id)){
                retCls.updatedCase = returnedUpdatedCaseMap.get(caseRec.Id);
        	    retCls.isCaseUpdated = true;
            }
            retCls.status = ABHFL_Constants.SUCCESS;
            returnWrapper.put(caseRec.Id, retCls);
        }
        return returnWrapper;
            
    }
     public static Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> afterStageMovement(List<Case> caseRecords){
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> returnWrapper = new Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper>();

        Map<Id, Case> returnedUpdatedCaseMap = new Map<Id, Case>();
        returnedUpdatedCaseMap.putAll(ABHFL_CTSTHelper.assignCaseCollateralDocs(caseRecords));
        for(Case caseRec : caseRecords){
            ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
            retCls.isCaseUpdated = false;
            if(returnedUpdatedCaseMap.containsKey(caseRec.Id)){
                retCls.updatedCase = returnedUpdatedCaseMap.get(caseRec.Id);
        	    retCls.isCaseUpdated = true;
            }
            retCls.status = ABHFL_Constants.SUCCESS;
            returnWrapper.put(caseRec.Id, retCls);
        }
        return returnWrapper;
    }
}