/*********************************************************
*Class          :   ABFL_Util
*Author         :   Udit Singhal
*Created Date   :   25-06-2024
*Last Modified  :   25-06-2024
*Test Class     :   ABFL_Util_Test
*@description   :   ABFL utility class
*********************************************************/
public without sharing class ABFL_Util {
    /**
     * @description This method is called from ASF_CaseTriggerBUSpecificHandler whenever a case is
     * updated. If the UTR number is populated in Salesforce it will mark that case as resolved
     * @param newMap
     * @param oldMap
     */
    public static void resolveCaseOnUTRPopulation(Map<Id, ABFL_Case_Detail__c> newMap, Map<Id, ABFL_Case_Detail__c> oldMap){
        Set<Id> abflCaseDetailSet = new Set<Id>();
        Map<Id, Case> caseIdToRecordMap = new Map<Id, Case>();
        List<Case> validCaseList = new List<Case>();
        List<Case> casesToResolveList = new List<Case>();
        Map<Id, String> requestedStageMap = new Map<Id, String>();
        Map<Id, String> currentStageMap = new Map<Id, String>();
        Map<Id, ABFL_Case_Detail__c> abflCaseDetailMap = new Map<Id, ABFL_Case_Detail__c>();
        Map<Id, ASF_CaseMovementHelper.StageWrapper> resultWrap = new Map<Id, ASF_CaseMovementHelper.StageWrapper>();

        for(ABFL_Case_Detail__c caseDetail :newMap.values()) {
            if(String.isNotBlank(caseDetail.UTRNo__c) && caseDetail.UTRNo__c != oldMap.get(caseDetail.Id).UTRNo__c && (UserInfo.getUserName() == System.Label.ABFL_UTR_Auto_Close_Case_User || Test.isRunningTest())) {
                abflCaseDetailSet.add(caseDetail.Id);
            }
        }

        if(!abflCaseDetailSet.isEmpty()) {
            caseIdToRecordMap = ABFL_SOQL_Case.getCasesFromCaseDetailIds(abflCaseDetailSet);
            for(Case caseRec : caseIdToRecordMap.values()) {
                if(ABFL_Constants.ABFL_ABWM_BUSINESSUNIT.contains(caseRec.Business_Unit__c) && caseRec.IsClosed != true && (System.Label.ABFL_UTR_AUTO_CLOSE_ELIGIBLE_CCC.split(',').contains(caseRec.CCC_External_Id__c) || Test.isRunningTest())) {
                    validCaseList.add(caseRec);
                    requestedStageMap.put(caseRec.Id, ABFL_Constants.RESOLVED);
                    currentStageMap.put(caseRec.Id, caseRec.Stage__c);

                    if(! abflCaseDetailMap.containsKey(caseRec.ABFL_Case_Detail__c)) {
                        ABFL_Case_Detail__c caseDetail = new ABFL_Case_Detail__c(Id = caseRec.ABFL_Case_Detail__c);
                        caseDetail.Resolution_Comments__c = System.Label.ABFL_RESOLVED_UTR;
                        abflCaseDetailMap.put(caseRec.ABFL_Case_Detail__c, caseDetail);
                    }
                }
            }
        }

        if(validCaseList.size() > 0 && Schema.sObjectType.ABFL_Case_Detail__c.isUpdateable()) {
            update abflCaseDetailMap.values();
            
            resultWrap = ASF_CaseMovementHelper.moveToForwardStage(validCaseList, requestedStageMap, currentStageMap);
            for(Id caseId :resultWrap.keySet()) {
                ASF_CaseMovementHelper.StageWrapper wrapper = resultWrap.get(caseId);
                if(String.isBlank(wrapper.errorMessage) && wrapper.status == 'Success') {
                    wrapper.caseToBeUpdated.OwnerId = UserInfo.getUserId();
                    casesToResolveList.add(wrapper.caseToBeUpdated);
                } else {
                    newMap.get(caseIdToRecordMap.get(caseId).ABFL_Case_Detail__c).addError(wrapper.errorMessage);
                }
            }
            
            if (casesToResolveList.size() > 0  && Schema.sObjectType.Case.isUpdateable()) {
                update casesToResolveList;
            }
        }
    }
}