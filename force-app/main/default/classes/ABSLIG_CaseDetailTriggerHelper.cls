/**
 * @description       : Class for business Logic
 * @author            : Anirudh Raturi
 * @createdDate       : 08-06-2024
 * @last modified on  : 08-06-2024
 * @last modified by  : Anirudh Raturi 
 * Modifications Log
 * Ver   Date         Author           Modification
 * 1.0   08-06-2024   Anirudh Raturi   Initial Version
**/

public with sharing class ABSLIG_CaseDetailTriggerHelper {
    
    /**
     * @Function - populateFieldsOfABSLIGCaseDetail
     * @param newMap -  map of ABSLIG_Case_Detail__c from trigger.new.
     * @param oldMap -  map of ABSLIG_Case_Detail__c from trigger.oldMap.
     * @description - Invoked from BeforeUpdate method, this method pre-populates fields on ABSLIG_Case_Detail__c.
    **/
    public void populateFieldsOfABSLIGCaseDetail(Map<Id, ABSLIG_Case_Detail__c> newMap, Map<Id, ABSLIG_Case_Detail__c> oldMap) {
        
        List<ABSLIG_Case_Detail__c> newListOfABSLIGCaseDetail = newMap.values();

        Id loggedInUserId  = UserInfo.getUserId();
        User loggedInUser  = [SELECT Id, Manager.Name FROM User WHERE Id = :loggedInUserId WITH SECURITY_ENFORCED];
        String managerName = loggedInUser?.Manager?.Name;

        for(ABSLIG_Case_Detail__c absligCsDetRec : newListOfABSLIGCaseDetail){
            if(absligCsDetRec.Maker_Comment__c != oldMap.get(absligCsDetRec.Id).Maker_Comment__c){
                absligCsDetRec.Maker_Name__c = UserInfo.getName();
                absligCsDetRec.Maker_Manager__c   = managerName;
            }
            if(absligCsDetRec.Checker_Comment__c != oldMap.get(absligCsDetRec.Id).Checker_Comment__c){
                absligCsDetRec.Checker_Name__c = UserInfo.getName();
                absligCsDetRec.Checker_Manager__c = managerName;
            }   
        }
    }
}