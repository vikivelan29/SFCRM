/**
* @description       :
* @author            : Dhinesh
* @group             :
* @last modified on  : 14-06-2024
* @last modified by  : Dhinesh
* Modifications Log
* Ver   Date         Author                       Modification
* 1.0   14-06-2024   Dhinesh Initial Version
**/
public with sharing class ABSLI_RequestResolutionBeforeStage implements ASF_CaseStageClassInvocable {
	public static Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> beforeStageMovement(List<Case> caseRecords){

        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> returnWrapper = new Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper>();
        for(Case caseRec : caseRecords){
            ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
            retCls.status = ABSLI_Constants.SUCCESS;
            retCls.errorMessage = '';
            retCls.isCaseUpdated = false;
            returnWrapper.put(caseRec.Id, retCls);
        }
        List<Case> validateResolutionCases = new List<Case>();
        for(Case caseRec : caseRecords){
            if(caseRec.Technical_Source__c != 'API' && (UserInfo.getName() != System.Label.ABCL_Integration_UserName) ){
               validateResolutionCases.add(caseRec);
            }
		}
       	Map<Id, ABSLI_CTSTHelper.FieldValidationResult> wrapperResultMap = ABSLI_CTSTHelper.validateResolutionfields(validateResolutionCases);
        for(Id caseId : wrapperResultMap.keySet()){
                ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = returnWrapper.get(caseId);
                ABSLI_CTSTHelper.FieldValidationResult wrapperResult = wrapperResultMap.get(caseId);
                if(wrapperResult.result && !wrapperResult.blankFields.isEmpty()){
                    retCls.status = ABSLI_Constants.ERROR;
                    retCls.errorMessage = wrapperResult.message;
                }
           		if(wrapperResult.result && wrapperResult.blankFields.isEmpty()){
                    retCls.status = ABSLI_Constants.ERROR;
                    retCls.errorMessage = wrapperResult.message;
                }
                returnWrapper.put(caseId, retCls);
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