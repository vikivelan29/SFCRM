/*********************************************************
*Class        :  ASF_CaseStageClassInvocable_Test
*Author       :  Ritika Dhandia
*Description  :  Test Class, which implements the Case Stage Class Invocable
*********************************************************/
@isTest
public with sharing class ASF_CaseStageClassInvocable_Test implements ASF_CaseStageClassInvocable{
    

    public ASF_CaseMovementHelper.CaseStageValidationWrapper beforeStageMovement(Case caseRec){
        ASF_CaseMovementHelper.CaseStageValidationWrapper wrap = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
        wrap.status = 'Success';
        return wrap;
    }

    public ASF_CaseMovementHelper.CaseStageValidationWrapper afterStageMovement(Case caseRec){
        ASF_CaseMovementHelper.CaseStageValidationWrapper wrap = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
        wrap.status = 'Error';
        return wrap;
    }

}