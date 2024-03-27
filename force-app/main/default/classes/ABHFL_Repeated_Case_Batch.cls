/****************************************************************************************************************
* Author       - Anirudh Raturi
* Date         - 13-March-2024
* @LOB         - ABHFL
* @description -  This class is used to determine the Repeated Case
*****************************************************************************************************************/

public class ABHFL_Repeated_Case_Batch implements Database.Batchable<sObject>, Database.Stateful {
	
    private Map<String, Integer> mapOfKeyToRepeatedCount = new Map<String, Integer>();
    private Map<String, List<String>> mapOfKeyToAbhflCaseDetId = new Map<String, List<String>>();
    
    public void initializeRepeatedCases() {
        List<AggregateResult> aggregateRepeatedCsListCount = [SELECT Count(id) repeatedCount,Nature__c,Type_Text__c, Sub_Type_Text__c,
                                                             AccountId, LAN__c 
                                                             FROM Case 
                                                             WHERE CreatedDate = LAST_N_DAYS:30 AND Stage__c = 'Resolved' 
                                                                  AND Business_Unit__c  = 'ABHFL' AND AccountId != null AND 
                                                              		  CCC_External_Id__c != null
                                                             group by AccountId,LAN__c,Stage__c,Nature__c, Type_Text__c, 
                                                              		  Sub_Type_Text__c 
                                                             Limit 50000];
        
        List<Case> resolvedCsList = [SELECT id,Nature__c,Type_Text__c, Sub_Type_Text__c, LAN__c, ABHFL_Case_Detail__c,
                                     		AccountId  
                                     FROM Case 
                                     WHERE CreatedDate = LAST_N_DAYS:30 AND Stage__c = 'Resolved' AND Business_Unit__c  = 'ABHFL'
                                     		AND AccountId != null AND CCC_External_Id__c != null];
        
        for(AggregateResult csRec : aggregateRepeatedCsListCount) {
            String key = csRec.get('AccountId') + '$' + csRec.get('LAN__c') + '$' +
                		 csRec.get('Nature__c') + '$' + csRec.get('Type_Text__c') + '$' + csRec.get('Sub_Type_Text__c'); 
                		 
           Integer repeatedCount = (Integer) csRec.get('repeatedCount'); 	
           mapOfKeyToRepeatedCount.put(key, repeatedCount);  
        }
        
        for(Case cs : resolvedCsList) {
            String key = cs.AccountId + '$' + cs.LAN__c + '$' + cs.Nature__c + '$' + cs.Type_Text__c + '$' 
                		 + cs.Sub_Type_Text__c; 
            String abhfCsDetId = cs.ABHFL_Case_Detail__c;
            if(String.isNotBlank(abhfCsDetId)) {
                if(mapOfKeyToAbhflCaseDetId.containsKey(key)) {
                    mapOfKeyToAbhflCaseDetId.get(key).add(cs.ABHFL_Case_Detail__c);
                }
                else {
                    mapOfKeyToAbhflCaseDetId.put(key, new List<String>{cs.ABHFL_Case_Detail__c}); 
                }
            }
        }
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        initializeRepeatedCases();
        String queryForTodayCases = 'SELECT id, AccountId, LAN__c, Nature__c, Type_Text__c, Sub_Type_Text__c,  ABHFL_Case_Detail__c FROM Case ' +
                                    'WHERE CreatedDate = Today and Business_Unit__c = \'ABHFL\' and AccountId != null and CCC_External_Id__c != null and ABHFL_Case_Detail__c != null';
        return Database.getQueryLocator(queryForTodayCases);
    }
    
    public void execute(Database.BatchableContext bc, List<Case> csList){
        if(csList.size() > 0) {
            updateCaseDetail(csList);
        }
    }
    
    public void updateCaseDetail(List<Case> todayCaseList) {

        system.debug('mapOfKeyToRepeatedCount--> '+JSON.serialize(mapOfKeyToRepeatedCount));
        system.debug('mapOfKeyToAbhflCaseDetId--> '+JSON.serialize(mapOfKeyToAbhflCaseDetId));
        List<String> tempStringList = new List<String>();
        Set<String> abhflCaseDetIdList = new Set<String>();
        
        for(Case caseRec : todayCaseList) {
            String openStageKey = caseRec.AccountId + '$' + caseRec.LAN__c + '$' + caseRec.Nature__c 
                					+ '$' + caseRec.Type_Text__c + '$' + caseRec.Sub_Type_Text__c;
                                    tempStringList.add(openStageKey);
            if(mapOfKeyToRepeatedCount.containsKey(openStageKey)) {
                Integer repeatCount = mapOfKeyToRepeatedCount.get(openStageKey);
                if(repeatCount > 0) {
                    List<String> abhflCaseDetList = mapOfKeyToAbhflCaseDetId.get(openStageKey) != null ? mapOfKeyToAbhflCaseDetId.get(openStageKey) : new List<String>();
                    abhflCaseDetIdList.add(caseRec.ABHFL_Case_Detail__c);
                    abhflCaseDetIdList.addAll(abhflCaseDetList);                
                }
            }   		 
        }
        system.debug('tempStringList--> '+JSON.serialize(tempStringList));
        system.debug('abhflCaseDetIdList--> '+JSON.serialize(abhflCaseDetIdList));
        List<ABHFL_Case_Detail__c> abhflCsDetLst = new List<ABHFL_Case_Detail__c>();
        
        for(String abhflCsDetId : abhflCaseDetIdList) {
            ABHFL_Case_Detail__c abhflCaseDetObj = new ABHFL_Case_Detail__c();
            abhflCaseDetObj.Id = abhflCsDetId;
			abhflCaseDetObj.Repeated__c = 'Yes';   
            abhflCsDetLst.add(abhflCaseDetObj);
        }
        
        system.debug('abhflCsDetLst--> '+JSON.serialize(abhflCsDetLst));
        if(abhflCsDetLst.size() > 0) {
            update abhflCsDetLst;
        }
    }
    
    public void finish(Database.BatchableContext bc){
    }
}