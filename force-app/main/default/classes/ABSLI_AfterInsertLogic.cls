public with sharing class ABSLI_AfterInsertLogic {
    public static void executeAfterInsertLogic(List<Case> newCases) {
        Map<Id, Case> mAbsliCases = new Map<Id, Case>();
        
        for (Case caseRec : newCases) {
            if (caseRec.Business_Unit__c == ASF_Constants.ABSLI_BU) {
                mAbsliCases.put(caseRec.Id, caseRec);
            }
        }
        if(mAbsliCases.keySet().size()>0){
            populateEntityRefNumber(mAbsliCases);
        }
    }
    
    private static void populateEntityRefNumber(Map<Id, Case> mAbsliCases){
        for(Case c : mAbsliCases.values()){
            Case updCase = new Case(Id = c.Id);
            updCase.Entity_Reference_No__c = 'BSLI'+c.CaseNumber; 
            ASF_CaseTriggerModularHelper.addTocaseFinalDMLMap(updCase);
            System.debug(c);
        }
    }

}