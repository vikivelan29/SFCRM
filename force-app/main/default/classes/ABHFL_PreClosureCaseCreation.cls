/*********************************************************
*@Class        :  ABHFL_PreClosureCaseCreation
*@Author       :  Anjali Sharma
*@Created Date :  12/12/2023
*@Last Modified:  
*@description  :  Class for Preclosure case creation 
*********************************************************/

public with sharing class ABHFL_PreClosureCaseCreation implements ASF_CaseStageClassInvocable {
	public static ASF_CaseMovementHelper.CaseStageValidationWrapper beforeStageMovement(Case caseRec){
        ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
        return retCls;
    }

    public static ASF_CaseMovementHelper.CaseStageValidationWrapper afterStageMovement(Case caseRec){
        ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
        retCls.status = ABHFL_Constants.SUCCESS;
        retCls.errorMessage = '';
        retCls.updatedCase = caseRec;
        retCls.isCaseUpdated = false;
        
        List<ABHFL_Asset_Detail__c> assetDetailRecords = [SELECT Id, Asset__c, Name, Account_Status__c, Amount_Overdue__c, LAN__C,
        Asset__r.Lan__c, Case__c, Current_Balance__c, Loan_Status__c
        FROM ABHFL_Asset_Detail__c WHERE Case__c=:caseRec.Id];
        List<Case> newCaseList = new List<Case>();

        caseRec = [SELECT AssetId, AccountId, Account.Client_Code__c, Asset.LAN__c, Source__c, Technical_Source__c,  Nature__c FROM Case WHERE Id =: caseRec.Id];
        List<ABHFL_Case_Detail__c> abhflCaseDetailList = new List<ABHFL_Case_Detail__c>();
        for(ABHFL_Asset_Detail__c asset : assetDetailRecords){
            ABHFL_Case_Detail__c abhflCaseDetail = new ABHFL_Case_Detail__c(STP_Request_Type__c = 'Email');
            abhflCaseDetailList.add(abhflCaseDetail);
        }
        if(!abhflCaseDetailList.isEmpty()){
            insert abhflCaseDetailList;
        }

        for(Integer i=0; i<assetDetailRecords.size(); i++){
            case newCase = ABHFL_CTSTHelper.createCases(caseRec.Account.Client_Code__c, assetDetailRecords[i].LAN__c, 'hfl042', caseRec.Source__c, caseRec.Technical_Source__c, caseRec.Id);
            newCase.AccountId = caseRec.AccountId;
            newCase.ABHFL_Case_Detail__c = abhflCaseDetailList[i].Id;
            newCase.Nature__c = caseRec.Nature__c;
            newCase.AssetId = assetDetailRecords[i].Asset__c;
            newCaseList.add(newCase);
        }

        ABHFL_CTSTHelper.insertCases(newCaseList);
        return retCls;
    }
}
