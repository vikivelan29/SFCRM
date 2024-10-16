/****************************************************************************************************************
* Author       - Anirudh Raturi
* Date         - 16-Oct-2024
* @BU          - ABHI
* @description - This class is used to determine the Repeated Case
*****************************************************************************************************************/

public class ABHI_Repeated_Case_Batch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

    private Map<String, Integer> mapOfKeyToRepeatedCount = new Map<String, Integer>();
    private Map<String, List<String>> mapOfKeyToAbhiCaseDetId = new Map<String, List<String>>();
    
    /**
    * @description  Calling ABHI specific Business Logic method
    * @param businessUnit - Business Unit of the Organization
    * @param createdDateVal -  Fetch data for the number of days.
    * @param caseStage -  Value of the Case Stage.
    */
    public void initializeRepeatedCases(String businessUnit, DateTime createdDateVal, String caseStage) {
        List<AggregateResult> aggregateRepeatedCsListCount = [SELECT Count(id) repeatedCount,Nature__c,Type_Text__c, Sub_Type_Text__c,
                                                             AccountId, LAN__c 
                                                             FROM Case 
                                                             WHERE CreatedDate >= :createdDateVal AND Stage__c =:caseStage 
                                                                  AND Business_Unit__c  =:businessUnit AND AccountId != null AND 
                                                              		  CCC_External_Id__c != null
                                                             group by AccountId,LAN__c,Stage__c,Nature__c, Type_Text__c, 
                                                              		  Sub_Type_Text__c 
                                                             Limit 50000];
        
        List<Case> resolvedCsList = [SELECT id,Nature__c,Type_Text__c, Sub_Type_Text__c, LAN__c, ABHI_Case_Detail__c,
                                     		AccountId  
                                     FROM Case 
                                     WHERE CreatedDate >= :createdDateVal AND Stage__c =:caseStage AND Business_Unit__c  =:businessUnit
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
            String abhiCsDetId = cs?.ABHI_Case_Detail__c ?? '';
            if(String.isNotBlank(abhiCsDetId)) {
                if(mapOfKeyToAbhiCaseDetId.containsKey(key)) {
                    mapOfKeyToAbhiCaseDetId.get(key).add(cs.ABHI_Case_Detail__c);
                }
                else {
                    mapOfKeyToAbhiCaseDetId.put(key, new List<String>{cs.ABHI_Case_Detail__c}); 
                }
            }
        }
    }
    
    /**
    * @description  Calling ABHI specific Business Logic method
    * @param bc - BatchableContext
    * @return queryForTodayCases
    */
    public Database.QueryLocator start(Database.BatchableContext bc){

        Integer numberOfDays = -1 * Integer.valueOf(Label.Repeated_Indicator);
        DateTime createdDateValue = System.now().addDays(numberOfDays);
        initializeRepeatedCases('ABHI', createdDateValue, 'Resolved');

        String queryForTodayCases = 'SELECT id, AccountId, LAN__c, Nature__c, Type_Text__c, Sub_Type_Text__c, ABHI_Case_Detail__c FROM Case ' +
                                    'WHERE CreatedDate = Today and Business_Unit__c = \'ABHI\' and AccountId != null and CCC_External_Id__c != null and ABHI_Case_Detail__c != null';
        return Database.getQueryLocator(queryForTodayCases);
    }
    
    /**
    * @description  Execute method for the batch class
    * @param bc - BatchableContext
    * @param csList -  List of today's cases
    */
    public void execute(Database.BatchableContext bc, List<Case> csList){
        updateCaseDetail(csList);
    }

     /**
    * @description  Execute method for the batch class
    * @param todayCaseList -  List of today's cases
    */
    public void updateCaseDetail(List<Case> todayCaseList) {

        List<String> tempStringList = new List<String>();
        Set<String> abhiCaseDetIdList = new Set<String>();
        
        for(Case caseRec : todayCaseList) {
            String openStageKey = caseRec.AccountId + '$' + caseRec.LAN__c + '$' + caseRec.Nature__c 
                					+ '$' + caseRec.Type_Text__c + '$' + caseRec.Sub_Type_Text__c;
                                    tempStringList.add(openStageKey);
            if(mapOfKeyToRepeatedCount.containsKey(openStageKey)) {
                Integer repeatCount = mapOfKeyToRepeatedCount.get(openStageKey);
                if(repeatCount > 0) {
                    List<String> abhiCaseDetList = mapOfKeyToAbhiCaseDetId.get(openStageKey) != null ? mapOfKeyToAbhiCaseDetId.get(openStageKey) : new List<String>();
                    abhiCaseDetIdList.add(caseRec.ABHI_Case_Detail__c);
                    abhiCaseDetIdList.addAll(abhiCaseDetList);                
                }
            }   		 
        }

        List<ABHI_Case_Detail__c> abhiCsDetLst = new List<ABHI_Case_Detail__c>();
        
        for(String abhiCsDetId : abhiCaseDetIdList) {
            ABHI_Case_Detail__c abhiCaseDetObj = new ABHI_Case_Detail__c();
            abhiCaseDetObj.Id = abhiCsDetId;
			abhiCaseDetObj.Repeated__c = 'Yes';   
            abhiCsDetLst.add(abhiCaseDetObj);
        }

        if(abhiCsDetLst.size() > 0) {
            update abhiCsDetLst;
        }
    }

    @SuppressWarnings('PMD.EmptyStatementBlock')
    /**
    * @description  Finish Method of the Batch Class
    * @param bc - BatchableContext
    */
    public void finish(Database.BatchableContext bc){
    }

    @SuppressWarnings('PMD.EmptyStatementBlock')
    /**
    * @description  Execute Method of the Schedulable Class
    * @param sc - SchedulableContext
    */
    public void execute(SchedulableContext sc) {
    }
}