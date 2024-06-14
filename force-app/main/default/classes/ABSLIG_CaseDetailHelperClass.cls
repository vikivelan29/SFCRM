/**
 * @description       : Class for ABSLIG Case Detail Object Business Logic
 * @author            : Anirudh Raturi
 * @createdDate       : 14-06-2024
 * @last modified on  : 14-06-2024
 * @last modified by  : Anirudh Raturi
 * Modifications Log
 * Ver   Date         Author           Modification
 * 1.0   14-06-2024   Anirudh Raturi   Initial Version
**/

public with sharing class ABSLIG_CaseDetailHelperClass {

     /**
     * @Function - populateABSLIG_CaseDetail_Fields
     * @param newCsList -  List of new case records.
     * @description - Invoked from executeAfterASFCodeInAfterInsert method, this method populates fields on ABSLIG_Case_Detail__c.
    **/
    public void populateABSLIGCaseDetailFields(List<Case> newCsList) {

        Map<String, Case> mapOfCsDetIdsToCase = new Map<String, Case>();

        for (Case caseRecord : newCsList) {
            String absligCsDetId = caseRecord?.ABSLIG_Case_Detail__c;
            String businessUnit  = caseRecord?.Business_Unit__c;
            if (absligCsDetId != null && businessUnit == 'ABSLIG') {
                mapOfCsDetIdsToCase.put(absligCsDetId, caseRecord);
            }
        }
        
        if(mapOfCsDetIdsToCase.keySet().size() > 0) {

            Map<Id, ABSLIG_Case_Detail__c> caseDetailMap = new Map<Id, ABSLIG_Case_Detail__c>([
                SELECT Id, Requirement_Met_Date__c
                FROM ABSLIG_Case_Detail__c
                WHERE Id IN :mapOfCsDetIdsToCase.keySet()
            ]);
        
    
            for (ABSLIG_Case_Detail__c caseDetRecord : caseDetailMap.values()) {
                Case csRecord = mapOfCsDetIdsToCase.get(caseDetRecord.Id);
                caseDetRecord.Requirement_Met_Date__c = csRecord.CreatedDate;
            }
            
            if(caseDetailMap.keyset().size() > 0) {
                update caseDetailMap.values();
            }
        }
    }
}