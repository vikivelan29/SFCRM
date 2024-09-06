public class ABHFL_PreClsStatementStageApex implements ASF_CaseStageClassInvocable {
	public static Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> beforeStageMovement(List<Case> caseRecords){
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> returnWrapper = new Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper>();
        List<Case> sendTrackingLinkEligibleCases = new List<Case>();
        List<Case> sendPrclsStatementclosureEligibleCases = new List<Case>();
        for(Case caseRec : caseRecords){
            ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
            retCls.status = ABHFL_Constants.SUCCESS;
            retCls.isCaseUpdated = false;
            returnWrapper.put(caseRec.Id, retCls);
            if(caseRec.Stage__c == 'Open' || 
            caseRec.Stage__c == 'CPU Banking' || 
            (caseRec.Stage__c == 'CPU FCL Issuance' && caseRec.CCC_External_Id__c != 'RRSDPRSHFC01') ||
            caseRec.Stage__c == 'CPU PP' ||	
            caseRec.Stage__c == 'Pending Ammortization') {
                sendTrackingLinkEligibleCases.add(caseRec);
            }
            //send FCL issuance closure email for PreCls Statement/Precls Statement ret/rej. /Reissuance of FCL 
            if((caseRec.ABHFL_Case_Detail__r.As_On_Date__c != Null && caseRec.Stage__c == 'Resolved' &&  caseRec.CCC_External_Id__c == 'RRSDPRSHFC01')|| 
            (caseRec.ABHFL_Case_Detail__r.As_On_Date__c != Null && caseRec.Stage__c == 'Resolved' && caseRec.CCC_External_Id__c == 'RLOAPRONHFC') ||
            (caseRec.ABHFL_Case_Detail__r.As_On_Date__c != Null && caseRec.Stage__c == 'Resolved' && caseRec.CCC_External_Id__c == 'REFCL001') ){
                sendPrclsStatementclosureEligibleCases.add(caseRec);
                
            }
              if(caseRec.CCC_External_Id__c=='RLOAPRONHFC'){
                ABHFL_CTSTHelper.storeMultipleLANs(caseRecords);
                ASF_CaseMovementHelper.CaseStageValidationWrapper retCls1 = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
                retCls1.status = ABHFL_Constants.SUCCESS;
                retCls1.updatedCase = caseRec;
                retCls1.isCaseUpdated = false;
              returnWrapper.put(caseRec.Id, retCls1);
           }
            //AM-PR970457-1214-COmments
            if(caseRec.CCC_External_Id__c=='qbccdd01' && caseRec.Stage__c=='Pending Amortization' && caseRec.ABHFL_Case_Detail__r.PP_Status__c=='Part Payment Not Done'){
                retCls = returnWrapper.get(caseRec.Id);
                retCls.status = ABHFL_Constants.ERROR;
                retCls.errorMessage = 'Cannot move to next stage when Part Payment not done';
                returnWrapper.put(caseRec.Id, retCls);
            }
        }
        if(!sendPrclsStatementclosureEligibleCases.isEmpty()){
            ABHFL_CTSTHelper.sendPrclsStatementclosure(sendPrclsStatementclosureEligibleCases);
        }
        if(!sendTrackingLinkEligibleCases.isEmpty()){
            ABHFL_CTSTHelper.sendTrackingLink(sendTrackingLinkEligibleCases);
        }
        return returnWrapper;
    }
     public static Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> afterStageMovement(List<Case> caseRecords){
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> returnWrapper = new Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper>();
        List<Case> eligibleCases = new List<Case>();
        for(Case caseRec : caseRecords){
            ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
            retCls.status = ABHFL_Constants.SUCCESS;
            retCls.isCaseUpdated = false;
            returnWrapper.put(caseRec.Id, retCls);
            //Send VAN email for ROI Revision
            if(caseRec.CCC_External_Id__c == 'hfl069'){
                eligibleCases.add(caseRec);
                
            }
        }
        if(!eligibleCases.isEmpty()){
            ABHFL_CTSTHelper.sendCommunicationPayableCharges(eligibleCases);
        }
        return returnWrapper;
    }
}