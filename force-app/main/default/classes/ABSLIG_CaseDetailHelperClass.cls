/**
 * @description       : Class for ABSLIG Case Detail Object Business Logic
 * @author            : Anirudh Raturi
 * @createdDate       : 14-06-2024
 * @last modified on  : 08-16-2024
 * @last modified by  : rsinghnagar@salesforce.com
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
   /**
   * @Function - populateABSLIGCaseDetailFieldsAfterCaseUpdate
   * @param newCsList -  List of new case records.
   * @description - Invoked from executeAfterASFCodeInAfterUpdate method, this method populates fields on ABSLIG_Case_Detail__c.
   **/
   public void populateABSLIGCaseDetailFieldsAfterCaseUpdate(List<Case> newCsList) {

       Map<String, Case> mapOfCCCExtIdIdsToCase = new Map<String, Case>();
       Map<String, ASF_Case_Category_Config__c> mapOfCCCExtIdIdsToCCCRec = new Map<String, ASF_Case_Category_Config__c>();
       Map<String, Case> mapOfCsDetailIdsToCase = new Map<String, Case>();

       for (Case caseRecord : newCsList) {

           String absligCsDetId = caseRecord?.ABSLIG_Case_Detail__c;
           String businessUnit  = caseRecord?.Business_Unit__c;
           String cccExternalId = caseRecord?.CCC_External_Id__c;
           
           if (absligCsDetId != null && businessUnit == 'ABSLIG') {
               mapOfCCCExtIdIdsToCase.put(cccExternalId, caseRecord);
               mapOfCsDetailIdsToCase.put(absligCsDetId, caseRecord);
           }
       }

       if(mapOfCCCExtIdIdsToCase.keySet().size() > 0) {

           Map<Id, ASF_Case_Category_Config__c> cccIdToCCCRecMap = new Map<Id, ASF_Case_Category_Config__c>([
               SELECT Id, Fins_Non_Fins__c, CCC_External_Id__c
               FROM ASF_Case_Category_Config__c
               WHERE CCC_External_Id__c IN :mapOfCCCExtIdIdsToCase.keySet() WITH SECURITY_ENFORCED
           ]);

           Map<Id, ABSLIG_Case_Detail__c> caseDetailIdToCaseDetRecMap = new Map<Id, ABSLIG_Case_Detail__c>([
               SELECT Id, Financial_Non_Financial__c
               FROM ABSLIG_Case_Detail__c
               WHERE Id IN :mapOfCsDetailIdsToCase.keySet() WITH SECURITY_ENFORCED
           ]);

           for (ASF_Case_Category_Config__c cccRecord : cccIdToCCCRecMap.values()) {
               String cccExtId = cccRecord?.CCC_External_Id__c;
               mapOfCCCExtIdIdsToCCCRec.put(cccExtId, cccRecord);
           }

           for (ABSLIG_Case_Detail__c caseDetRecord : caseDetailIdToCaseDetRecMap.values()) {
               String cccExtIdOfCase = mapOfCsDetailIdsToCase.get(caseDetRecord.Id)?.CCC_External_Id__c;
               String finNonFin      = mapOfCCCExtIdIdsToCCCRec.get(cccExtIdOfCase)?.Fins_Non_Fins__c;
               caseDetRecord.Financial_Non_Financial__c = finNonFin;
           }

           if(caseDetailIdToCaseDetRecMap.size() > 0 && Schema.sObjectType.ABSLIG_Case_Detail__c.isUpdateable()) {
               update caseDetailIdToCaseDetRecMap.values();
           }
           
       }

   }
}