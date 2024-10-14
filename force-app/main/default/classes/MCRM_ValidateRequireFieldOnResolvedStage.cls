/**
* @description       : For multiply CRM
* @author            : rsinghnagar@salesforce.com
* @group             : 
* @last modified on  : 10-14-2024
* @last modified by  : rsinghnagar@salesforce.com
**/
public class MCRM_ValidateRequireFieldOnResolvedStage implements ASF_CaseStageClassInvocable {
    
    public static Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> beforeStageMovement(List<Case> cases){
        
        Map<Id,ASF_CaseMovementHelper.CaseStageValidationWrapper> mCaseIdVsretCls = new Map<Id,ASF_CaseMovementHelper.CaseStageValidationWrapper>();
        Set<Id> complaintCaseIds = new Set<Id>();
        for(Case caseRec : cases){
            ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
            if
                (
                    ASF_Constants.RESOLUTIONCOMMENT_REQ_TECHSRC.contains(caseRec.Technical_Source__c) 
                    && String.isBlank(caseRec.WellnessCaseDetail__r.Resolution_Comments__c)
                )
            {
                retCls.status = 'Error';
                retCls.errorMessage = 'Resolution Comments is required when changing Stage to Resolved.';
            }else{
                retCls.status = 'Success';
                retCls.errorMessage = '';
                retCls.updatedCase = caseRec;
                retCls.isCaseUpdated = false;
            }
            mCaseIdVsretCls.put(caseRec.Id,retCls);
        }
            
        return mCaseIdVsretCls;        
    }
    
    public static Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> afterStageMovement(List<Case> cases){
        Map<Id,ASF_CaseMovementHelper.CaseStageValidationWrapper> mCaseIdVsretCls = new Map<Id,ASF_CaseMovementHelper.CaseStageValidationWrapper>();
        return mCaseIdVsretCls;
    }
}