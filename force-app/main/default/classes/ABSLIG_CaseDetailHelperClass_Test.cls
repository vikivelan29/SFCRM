/**
 * @description       : Test Class for ABSLIG_CaseDetailHelperClass
 * @author            : Anirudh Raturi
 * @createdDate       : 14-06-2024
 * @last modified on  : 14-06-2024
 * @last modified by  : Anirudh Raturi
 * Modifications Log
 * Ver   Date         Author           Modification
 * 1.0   14-06-2024   Anirudh Raturi   Initial Version
**/

@isTest
public with sharing class ABSLIG_CaseDetailHelperClass_Test {
    
    @testSetup
    static void setupTestData() {

        // Create test ABSLIG_Case_Detail__c records
        List<ABSLIG_Case_Detail__c> caseDetailsList = new List<ABSLIG_Case_Detail__c>();
        // Create test Case records
        List<Case> caseRecList = new List<Case>();
        
        for (Integer i = 0; i < 2; i++) {
            caseDetailsList.add(new ABSLIG_Case_Detail__c(
                Policy_ID__c = '123' + i
            ));
        }
        insert caseDetailsList;

        for (Integer i = 0; i < 2; i++) {
            caseRecList.add(new Case(
                Business_Unit__c = 'ABSLIG',
                ABSLIG_Case_Detail__c = caseDetailsList[i].Id
            ));
        }
        insert caseRecList;     
    }

    @isTest
    static void beforeUpdateContainsABFLTest(){

        List<Case> caseRecList = [SELECT Id, ABSLIG_Case_Detail__r.Requirement_Met_Date__c, CreatedDate FROM Case];

        for(Case caseRec : caseRecList) {
            System.assertEquals(caseRec.CreatedDate, caseRec.ABSLIG_Case_Detail__r.Requirement_Met_Date__c, 
                                'Created Date value populate to Requirement Date');    
         } 
    }
}