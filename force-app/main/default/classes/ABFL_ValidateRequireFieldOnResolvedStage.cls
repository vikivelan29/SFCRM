/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 01-10-2024
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class ABFL_ValidateRequireFieldOnResolvedStage implements ASF_CaseStageClassInvocable {
    
    public static Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> beforeStageMovement(List<Case> cases){
        
        Map<Id,ASF_CaseMovementHelper.CaseStageValidationWrapper> mCaseIdVsretCls = new Map<Id,ASF_CaseMovementHelper.CaseStageValidationWrapper>();
        
        Set<Id> complaintCaseIds = new Set<Id>();
        
        
        for(Case caseRec : cases){
            ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
            retCls.status = 'Success';
            retCls.errorMessage = '';
            retCls.updatedCase = caseRec;
            retCls.isCaseUpdated = false;
            
            if(ASF_Constants.RESOLUTIONCOMMENT_REQ_TECHSRC.contains(caseRec.Technical_Source__c) && !caseRec.OnCreateCloseSR__c){
                if((caseRec.ABFL_Case_Detail__r.Resolution_Comments__c == null || caseRec.ABFL_Case_Detail__r.Resolution_Comments__c == '') &&
                   (!(caseRec.Source__c == 'Phone-Inbound' && caseRec.Nature__c == 'Query')) && ((caseRec.LOB__c == 'Wealth') || (caseRec.LOB__c != 'Wealth' && caseRec.Nature__c != 'Complaint')))
                {
                    retCls.status = 'Error';
                    retCls.errorMessage = 'Resolution Comments is required when changing Stage to Resolved.';
                }
            }
            
            if(caseRec.Nature__c == 'Complaint'){     
                complaintCaseIds.add(caseRec.Id);
            }
            
            mCaseIdVsretCls.put(caseRec.Id,retCls);
        }
        
        // //Complaint Nature Cases RCA Validation, exempt for Wealth LOB   
        if(complaintCaseIds.size()>0){
            Map<Id,Set<String>> retVal = ABFL_ComplaintsValidateOnResolvedStage.validateRCAfields(complaintCaseIds);
            
            if(retVal.keySet().size()>0){
                for(Id retCaseId : retVal.keySet()){
                    if(mCaseIdVsretCls.containsKey(retCaseId)){
                        ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = mCaseIdVsretCls.get(retCaseId);
                        retCls.status = 'Error';
                        retCls.errorMessage = 'Please fill the RCA fields on Verification Stage';
                        mCaseIdVsretCls.put(retCaseId,retCls);
                    }
                }
            }
        }
        
        
        return mCaseIdVsretCls;        
    }
    
    public static Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> afterStageMovement(List<Case> cases){
        Map<Id,ASF_CaseMovementHelper.CaseStageValidationWrapper> mCaseIdVsretCls = new Map<Id,ASF_CaseMovementHelper.CaseStageValidationWrapper>();
        
        return mCaseIdVsretCls;
    }
}