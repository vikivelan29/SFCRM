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

        Map<Id, List<Case>> existingChildCases = new Map<Id, List<Case>>();

        for(Case cs : [select id, ParentId from case where ParentId IN :caseRecords]){
            if(!existingChildCases.containsKey(cs.ParentId)){
                existingChildCases.put(cs.ParentId, new List<Case>());
            }
            existingChildCases.get(cs.ParentId).add(cs);
        }

        List<Case> newCaseList = new List<Case>();      
        Set<ID>activeuserlst=new set<ID>();
        for(User u: [Select Id from user where Isactive=true]){
            activeuserlst.add(u.Id);
        }
        Id queuewhennospoc=[Select Id,Name from Group where type='Queue' AND Name='Unassigned Queue'].Id;
        //caseRec = [SELECT AssetId, AccountId, Account.Client_Code__c, Asset.LAN__c, Source__c, Technical_Source__c,  Nature__c FROM Case WHERE Id =: caseRec.Id];
        Map<Id, List<ABHFL_Case_Detail__c>> caseIdToAbhflCaseDetailMap = new Map<Id, List<ABHFL_Case_Detail__c>>();

        Map<Id, ABHFL_Case_Detail__c> caseIdToAbhflCaseDetailMapSingle = new Map<Id, ABHFL_Case_Detail__c>();
        List<ABHFL_Case_Detail__c> detailList = new List<ABHFL_Case_Detail__c>();
        for(Case caseRec : caseRecords){
            if(!existingChildCases.containsKey(caseRec.Id)){
                ABHFL_Case_Detail__c abhflCaseDetail = new ABHFL_Case_Detail__c(STP_Request_Type__c = 'Email');
                caseIdToAbhflCaseDetailMapSingle.put(caseRec.Id, abhflCaseDetail);
                // detailList.add(abhflCaseDetail);
            }
        }
        if(!caseIdToAbhflCaseDetailMapSingle.values().isEmpty()){
            insert caseIdToAbhflCaseDetailMapSingle.values();
        }

        for(Case caseRec : caseRecords){
          if(caseIdToAbhflCaseDetailMapSingle.containsKey(caseRec.Id)){
                ABHFL_Case_Detail__c abhflCaseDetailList = caseIdToAbhflCaseDetailMapSingle.get(caseRec.Id);
                Case newCase = ABHFL_CTSTHelper.createCases(caseRec.Account.Client_Code__c, null, 'hfl042', caseRec.Source__c, caseRec.Technical_Source__c, caseRec.Id, ASF_Constants.RT_FRAMEWORK);
                newCase.AccountId = caseRec.AccountId;
                newCase.ABHFL_Case_Detail__c = abhflCaseDetailList.Id;
                newCase.Nature__c = caseRec.Nature__c;
                newCase.AssetId = caseRec.AssetId;
                if(caseRec.AssetId!=Null){
                  Id CRMSPOC=[select Branch__r.CRM_SPOC__c from asset WHERE Id =: caseRec.AssetId].Branch__r.CRM_SPOC__c;
                   if(activeuserlst.contains(CRMSPOC)){
                         newCase.OwnerId = CRMSPOC;     
                        }
                    else{
                        newCase.OwnerId = queuewhennospoc;
                        }
                }
                // newCase.AssetId = caseIdToRelatedAssets.get(caseRec.Id)[i].Asset__c;
                newCaseList.add(newCase);
            }
        }

        ASF_TriggerSkipperUtility.resetTriggerRun('Case');
        ASF_CaseQueryHandler.refreshRecords = true;
        ABHFL_CTSTHelper.insertCases(newCaseList);
        ASF_CaseQueryHandler.refreshRecords = true;
        return returnWrapper;
    }
}