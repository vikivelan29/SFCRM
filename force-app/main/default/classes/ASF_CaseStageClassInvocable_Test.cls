/*********************************************************
*Class        :  ASF_CaseStageClassInvocable_Test
*Author       :  Ritika Dhandia
*Description  :  Test Class, which implements the Case Stage Class Invocable
*********************************************************/
@isTest
public with sharing class ASF_CaseStageClassInvocable_Test implements ASF_CaseStageClassInvocable{
    

    public static Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> beforeStageMovement(List<Case> caseRecords){
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> returnWrapper = new Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper>();
        for(Case caseRec : caseRecords){
            ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
            retCls.status = 'Success';
            returnWrapper.put(caseRec.Id, retCls);
        }
        return returnWrapper;
    }

    public static Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> afterStageMovement(List<Case> caseRecords){
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> returnWrapper = new Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper>();
        for(Case caseRec : caseRecords){
            ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
            retCls.status = 'Error';
            retCls.errorMessage = 'Test Error Message';
            returnWrapper.put(caseRec.Id, retCls);
        }
        return returnWrapper;
    }

}