/**
 * @description       : BSLI email logic for flow
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 06-01-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class ABSLI_BeforeUpdateTriggerLogic {
    /**
     * @description This method is called from ASF_CaseTriggerBUSpecificHandler whenever a case is
     * updated. If the case is marked as FTR, the case status is updated to 'Resolved'
     * @param newMap
     * @param oldMap
     */
    public static void autoResolveFtrCases(Map<Id, Case> newMap, Map<Id, Case> oldMap){
        Id frameworkRTId = ASF_Constants.RT_FRAMEWORK;
        List<Case> absliCases = new List<Case>();
        Map<ID,List<Case>> mRecordTypeVsCases = ASF_CaseDistributionBasedOnRT.getCaseByRecordType((List<Case>)newMap.values());
        if(mRecordTypeVsCases.containsKey(frameworkRTId)){
            Map<Id,Case> frameworkCases = new Map<Id,Case>(mRecordTypeVsCases.get(frameworkRTId));
            for(Case caseRec : frameworkCases.values()){
                if(caseRec.Business_Unit__c == ASF_Constants.ABSLI_BU){
                    absliCases.add(caseRec);
                }
            }
        }
        if(!absliCases.isEmpty()){
            for(Case caseRec : absliCases){
                if(caseRec.MoveToNext__c != oldMap.get(caseRec.Id).MoveToNext__c 
                && caseRec.MoveToNext__c == true && caseRec.FTR__c == true){
                    caseRec.MoveToNext__c = false;
                    caseRec.Status = ASF_Constants.ONCREATECLOSESTATUS;
                	caseRec.Stage__c = ASF_Constants.ONCREATECLOSESTAGE;
                }
            }
        }   
    }
}