public class ABHFL_PreClsStatementStageApex implements ASF_CaseStageClassInvocable {
	public static ASF_CaseMovementHelper.CaseStageValidationWrapper beforeStageMovement(Case caseRec){
        ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
        retCls.status = ABHFL_Constants.SUCCESS;
        retCls.updatedCase = caseRec;
        retCls.isCaseUpdated = false;
        if(caseRec.Stage__c == 'Open' || 
   		   caseRec.Stage__c == 'CPU Banking' || 
   		   (caseRec.Stage__c == 'CPU FCL Issuance' && caseRec.CCC_External_Id__c != 'RRSDPRSHFC01') ||
           caseRec.Stage__c == 'CPU PP' ||	
           caseRec.Stage__c == 'Pending Ammortization') {
               ABHFL_CTSTHelper.sendTrackingLink(caseRec);
         }
	 	//send FCL issuance closure email as 
        if(caseRec.Stage__c == 'CPU FCL Issuance' && caseRec.CCC_External_Id__c == 'RRSDPRSHFC01'){
            ABHFL_CTSTHelper.sendPrclsStatementclosure(caseRec);
        }
        
        return retCls;
    }
     public static ASF_CaseMovementHelper.CaseStageValidationWrapper afterStageMovement(Case caseRec){
        ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
        return retCls;
    }
}