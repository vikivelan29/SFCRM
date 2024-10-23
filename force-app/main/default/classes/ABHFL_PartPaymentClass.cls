/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 07-01-2024
 * @last modified by  : rsinghnagar@salesforce.com 
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   07-01-2024   rsinghnagar@salesforce.com   Initial Version
**/
public with sharing class ABHFL_PartPaymentClass implements ASF_CaseStageClassInvocable { 
    
    public Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> beforeStageMovement(List<Case> caseRecords){

        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> retrnClass = new Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper>();
        initializeImpactFld(caseRecords);
        return retrnClass;
    }

    public Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> afterStageMovement(List<Case> caseRecords){

        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> returnClass = validateImpactField(caseRecords);
        return returnClass;
    }
    
    public Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> validateImpactField(List<Case> caseRecords){
        
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> returnWrapper = new Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper>();
        List<String> caseIdList = new List<String>();
        List<String> validCTST = new List<String>{'qbccdd01'};
        
        for(Case casRec : caseRecords) {
            caseIdList.add(casRec.Id);
        }
        List<Case> caseRecList = [SELECT Id, ABHFL_Case_Detail__r.Impact__c, Asset.Loan_Disbursement_Status__c, CCC_External_Id__c, Stage__c 
                                    FROM Case WHERE Id IN :caseIdList];

        for(Case caseRec : caseRecList){
            ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
            retCls.status = ABHFL_Constants.SUCCESS;
            returnWrapper.put(caseRec.Id, retCls);

            String loanDisbStatus = caseRec.Asset.Loan_Disbursement_Status__c;
            String impactVal      = caseRec.ABHFL_Case_Detail__r.Impact__c;

            if(validCTST.contains(caseRec.CCC_External_Id__c) && caseRec.Stage__c=='CPU Banking' && loanDisbStatus == 'Partially' && impactVal != 'EMI'){
                retCls = returnWrapper.get(caseRec.Id);
                retCls.status = ABHFL_Constants.ERROR;
                retCls.errorMessage = System.Label.Impact_Field_Error;
                returnWrapper.put(caseRec.Id, retCls);
            }
        }

        return returnWrapper;
    }

    public void initializeImpactFld(List<Case> caseRecs) {

        List<String> caseIdList = new List<String>();
        List<String> abhflCaseDetailList = new List<String>();
        List<String> validCTST = new List<String>{'qbccdd01'};

        for(Case casRec : caseRecs) {
            caseIdList.add(casRec.Id);
        }
        List<Case> caseRecList = [SELECT Id, ABHFL_Case_Detail__c, Asset.Loan_Disbursement_Status__c, CCC_External_Id__c 
                                    FROM Case WHERE Id IN :caseIdList];

        for(Case casRec : caseRecList) {
            String loanDisbStatus = casRec.Asset.Loan_Disbursement_Status__c;
            if(validCTST.contains(casRec.CCC_External_Id__c)) {
                abhflCaseDetailList.add(casRec.ABHFL_Case_Detail__c);
            }
        }

        List<ABHFL_Case_Detail__c> updateAbhflCaseDetailList = [SELECT id, Impact__c FROM ABHFL_Case_Detail__c WHERE Id IN :abhflCaseDetailList];

        for(ABHFL_Case_Detail__c abhflCaseDetailRec : updateAbhflCaseDetailList) {
            abhflCaseDetailRec.Impact__c = 'EMI';
        }

        if(updateAbhflCaseDetailList.size() > 0) {
            update updateAbhflCaseDetailList;  
        }
    }
}