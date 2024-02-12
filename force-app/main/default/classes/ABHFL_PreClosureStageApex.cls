public with sharing class ABHFL_PreClosureStageApex implements ASF_CaseStageClassInvocable {
	public static ASF_CaseMovementHelper.CaseStageValidationWrapper beforeStageMovement(Case caseRec){
        ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
        retCls.status = ABHFL_Constants.SUCCESS;
        retCls.updatedCase = caseRec;
        retCls.isCaseUpdated = false;
        if(caseRec.Stage__c == 'Open' || 
   		   caseRec.Stage__c == 'CPU Banking' || 
   		   caseRec.Stage__c == 'CPU FCL Issuance' || 
   		   caseRec.Stage__c == 'NDC' || 
   		   caseRec.Stage__c == 'Retrieval' || 
   		   caseRec.Stage__c == 'Hub Location' || 
   		   caseRec.Stage__c == 'Branch' || 
   		   caseRec.Stage__c == 'AOM/ROM') {
               ABHFL_CTSTHelper.sendTrackingLink(caseRec);
         }
        if(caseRec.Stage__c == 'Hub Location'){
            Case updatedCaseRec = ABHFL_CTSTHelper.assignCaseToPreferredBranch(caseRec);
            retCls.updatedCase = updatedCaseRec;
            retCls.isCaseUpdated = true;
        }
         if(caseRec.Stage__c == 'Branch'){
            Case updatedCaseRec = ABHFL_CTSTHelper.assignCaseToAOMROM(caseRec);
            retCls.updatedCase = updatedCaseRec;
            retCls.isCaseUpdated = true;
        }
        return retCls;
    }
     public static ASF_CaseMovementHelper.CaseStageValidationWrapper afterStageMovement(Case caseRec){
        ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
        retCls.status = ABHFL_Constants.SUCCESS;
        retCls.updatedCase = caseRec;
        retCls.isCaseUpdated = false;
        if(caseRec.Stage__c == 'Retrieval'){
          ABHFL_CTSTHelper.sendLoanClosedEmail(caseRec);    
         } 
        return retCls;
    }
}