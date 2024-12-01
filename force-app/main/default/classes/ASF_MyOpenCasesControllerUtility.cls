public with sharing class ASF_MyOpenCasesControllerUtility {
    
    @AuraEnabled(cacheable=true)
    public static Map<String, List<Case>> getOpenCasesByOwner(String userId) {
        
        Map<String, List<Case>> casesByStage = new Map<String, List<Case>>();
       
        String userBu = [SELECT Id,Business_Unit__c FROM User WHERE Id =:userId 
                         AND Business_Unit__c != '' Limit 1].Business_Unit__c;
        
        List<Case> caseList = [Select Id,CaseNumber,Account.Name,Stage__c 
                               FROM Case 
                               WHERE Business_Unit__c =:userBu
                               AND AccountId != null
                               AND OwnerId =:userId
                               AND Stage__c NOT IN ('Resolved','Unresolved') order by createddate desc];
        
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