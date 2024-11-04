public with sharing class ABSLAMC_MyOpenCasesController {
    
    @AuraEnabled(cacheable=true)
    public static Map<String, List<Case>> getOpenCasesByOwner(String userId) {
        
        Map<String, List<Case>> casesByStage = new Map<String, List<Case>>();
        List<Case> caseList = [Select Id,CaseNumber,Account.Name,Stage__c 
                               FROM Case 
                               WHERE OwnerId =:userId
                               AND Stage__c NOT IN ('Resolved','Unresolved')];
        
        for(Case caseRec:caseList){
            String stage = caseRec.Stage__c;
            if (!casesByStage.containsKey(stage)) {
                casesByStage.put(stage, new List<Case>());
            }
            casesByStage.get(stage).add(caseRec);
        }
        
        System.debug('Cases:'+casesByStage);
        return casesByStage;
        
    }
}