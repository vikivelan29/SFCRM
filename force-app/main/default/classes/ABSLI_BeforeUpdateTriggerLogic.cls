public with sharing class ABSLI_BeforeUpdateTriggerLogic {

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