/*********************************************************
*@Class        :  ABHFL_PreClosureCaseCreation
*@Author       :  Anjali Sharma
*@Created Date :  12/12/2023
*@Last Modified:  
*@description  :  Class for Preclosure case creation 
*********************************************************/

public with sharing class ABHFL_PreClosureCaseCreation implements ASF_CaseStageClassInvocable {
	public static Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> beforeStageMovement(List<Case> caseRecords){
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> returnWrapper = new Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper>();
        for(Case caseRec : caseRecords){
            ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
            returnWrapper.put(caseRec.Id, retCls);
        }
        return returnWrapper;
    }

    public static Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> afterStageMovement(List<Case> caseRecords){
        
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> returnWrapper = new Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper>();
        for(Case caseRec : caseRecords){
            ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = new ASF_CaseMovementHelper.CaseStageValidationWrapper();
            retCls.status = ABHFL_Constants.SUCCESS;
            retCls.errorMessage = '';
            retCls.isCaseUpdated = false;
            returnWrapper.put(caseRec.Id, retCls);
        }
        
        Map<Id, List<ABHFL_Asset_Detail__c>> caseIdToRelatedAssets = new Map<Id, List<ABHFL_Asset_Detail__c>>();

        for(ABHFL_Asset_Detail__c asset : [SELECT Id, Asset__c, Name, Account_Status__c, Amount_Overdue__c, LAN__C,
        Asset__r.Lan__c, Case__c, Current_Balance__c, Loan_Status__c
        FROM ABHFL_Asset_Detail__c WHERE Case__c IN :caseRecords])
        {
            if(!caseIdToRelatedAssets.containsKey(asset.Case__c)){
                caseIdToRelatedAssets.put(asset.Case__c, new List<ABHFL_Asset_Detail__c>());
            }
            caseIdToRelatedAssets.get(asset.Case__c).add(asset);
        }

        List<Case> newCaseList = new List<Case>();

        //caseRec = [SELECT AssetId, AccountId, Account.Client_Code__c, Asset.LAN__c, Source__c, Technical_Source__c,  Nature__c FROM Case WHERE Id =: caseRec.Id];
        Map<Id, List<ABHFL_Case_Detail__c>> caseIdToAbhflCaseDetailMap = new Map<Id, List<ABHFL_Case_Detail__c>>();
        List<ABHFL_Case_Detail__c> detailList = new List<ABHFL_Case_Detail__c>();
        for(Case caseRec : caseRecords){
            if(caseIdToRelatedAssets.containsKey(caseRec.Id)){
                for(ABHFL_Asset_Detail__c asset : caseIdToRelatedAssets.get(caseRec.Id)){
                    ABHFL_Case_Detail__c abhflCaseDetail = new ABHFL_Case_Detail__c(STP_Request_Type__c = 'Email');
                    if(!caseIdToAbhflCaseDetailMap.containsKey(caseRec.Id)){
                        caseIdToAbhflCaseDetailMap.put(caseRec.Id, new List<ABHFL_Case_Detail__c>());
                    }
                    caseIdToAbhflCaseDetailMap.get(caseRec.Id).add(abhflCaseDetail);
                    detailList.add(abhflCaseDetail);
                }
            }
        }
        if(!detailList.isEmpty()){
            insert detailList;
        }
        for(Case caseRec : caseRecords){
            if(caseIdToRelatedAssets.containsKey(caseRec.Id)){
                List<ABHFL_Case_Detail__c> abhflCaseDetailList = caseIdToAbhflCaseDetailMap.get(caseRec.Id);
                for(Integer i=0; i<caseIdToRelatedAssets.get(caseRec.Id).size(); i++){
                    Case newCase = ABHFL_CTSTHelper.createCases(caseRec.Account.Client_Code__c, caseIdToRelatedAssets.get(caseRec.Id)[i].LAN__c, 'hfl042', caseRec.Source__c, caseRec.Technical_Source__c, caseRec.Id, ASF_Constants.RT_FRAMEWORK);
                    newCase.AccountId = caseRec.AccountId;
                    newCase.ABHFL_Case_Detail__c = abhflCaseDetailList[i].Id;
                    newCase.Nature__c = caseRec.Nature__c;
                    newCase.AssetId = caseIdToRelatedAssets.get(caseRec.Id)[i].Asset__c;
                    newCaseList.add(newCase);
                }
            }
        }

        ABHFL_CTSTHelper.insertCases(newCaseList);
        return returnWrapper;
    }
}