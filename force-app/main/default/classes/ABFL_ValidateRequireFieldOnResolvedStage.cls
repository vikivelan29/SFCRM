/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-10-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class ABFL_ValidateRequireFieldOnResolvedStage implements ASF_CaseStageClassInvocable {
    
    public ASF_CaseMovementHelper.CaseStageValidationWrapper beforeStageMovement(Case caseRec){

        ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
        retCls.status = 'Success';
        retCls.errorMessage = '';
        retCls.updatedCase = caseRec;
        retCls.isCaseUpdated = false;

        if(ASF_Constants.RESOLUTIONCOMMENT_REQ_TECHSRC.contains(caseRec.Technical_Source__c)){
            if((caseRec.ABFL_Case_Detail__r.Resolution_Comments__c == null || caseRec.ABFL_Case_Detail__r.Resolution_Comments__c == '') &&
               (!(caseRec.Source__c == 'Phone-Inbound' && caseRec.Nature__c == 'Query')) && ((caseRec.LOB__c == 'Wealth') || (caseRec.LOB__c != 'Wealth' && caseRec.Nature__c != 'Complaint')))
            {
                retCls.status = 'Error';
                retCls.errorMessage = 'Resolution Comments is required when changing Stage to Resolved.';
            }
        }    
         //Complaint Nature Cases RCA Validation, exempt for Wealth LOB   
        if(caseRec.Nature__c == 'Complaint'){     

            Set<String> blankRCA_Fields = ABFL_ComplaintsValidateOnResolvedStage.validateRCAfields(caseRec);
                
                // setting the Error Message if RCA fields found blank
                if(blankRCA_Fields.size() > 0){   
                    
                    retCls.status = 'Error';
                    retCls.errorMessage = 'Please fill the RCA fields on Verification Stage';
                }  
        } 

        return retCls;        
    }
    
    public ASF_CaseMovementHelper.CaseStageValidationWrapper afterStageMovement(Case caseRec){
        ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
        
        return retCls;
    }
}