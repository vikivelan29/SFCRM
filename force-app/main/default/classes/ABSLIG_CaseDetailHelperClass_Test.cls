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

        ASF_TestDataFactory.createCaseCategoryConfig();
        List<ASF_Case_Category_Config__c> caseCatConfig = [Select Id, Fins_Non_Fins__c FROM ASF_Case_Category_Config__c];
        caseCatConfig[0].Fins_Non_Fins__c = 'Financial';
        update caseCatConfig;

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
                CCC_External_Id__c = 'CCC-CC-CCLTD-01',
                ABSLIG_Case_Detail__c = caseDetailsList[i].Id
            ));
        }
        insert caseRecList;     
    }

    @isTest
    static void beforeUpdateContainsABSLIGLTest(){

        List<Case> caseRecList = [SELECT Id, ABSLIG_Case_Detail__r.Requirement_Met_Date__c, CreatedDate FROM Case];

        for(Case caseRec : caseRecList) {
            System.assert(caseRec.ABSLIG_Case_Detail__r.Requirement_Met_Date__c != null, 
                                'Created Date value populate to Requirement Date');  
         } 
    }

    @isTest
    static void populateABSLIGCaseDetailFieldsAfterCaseUpdateTest(){

        List<Case> caseRecList = [SELECT Id, ABSLIG_Case_Detail__c, Business_Unit__c, CCC_External_Id__c FROM Case];

        ABSLIG_CaseDetailHelperClass absligCaseDetHelObj = new ABSLIG_CaseDetailHelperClass();
        absligCaseDetHelObj.populateABSLIGCaseDetailFieldsAfterCaseUpdate(caseRecList);

        ABSLIG_Case_Detail__c absligCaseDetObj = [SELECT id, Financial_Non_Financial__c FROM ABSLIG_Case_Detail__c LIMIT 1];
        
        System.assertEquals(absligCaseDetObj.Financial_Non_Financial__c, 'Financial' ,'Value of Financial/Non-Financial is Financial');    
    }
}