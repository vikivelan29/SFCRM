/*********************************************************
*@Class        :  ABHI_CaseDetailHelper_Test
*@Author       :  Sara Jaipuria
*@Created Date :  16-08-2024
*@Last Modified:  16-08-2024
*@description  :  Test Class for ABHI_CaseDetailHelper
*********************************************************/

@isTest
public class ABHI_CaseDetailHelper_Test {
    
    @testSetup
    static void setupTestData() {
        
        ASF_TestDataFactory.createCaseCategoryConfig();
        List<ASF_Case_Category_Config__c> caseCatConfig = [Select Id, Sub_Type__c FROM ASF_Case_Category_Config__c];
        caseCatConfig[0].Sub_Type__c = 'Test_SubType';
        caseCatConfig[0].Type__c = 'TestType';
        caseCatConfig[0].Business_Unit__c = 'ABHI';
        update caseCatConfig;
        
        // Create test ABHI_Case_Detail__c records
        List<ABHI_Case_Detail__c> caseDetailsList = new List<ABHI_Case_Detail__c>();
        // Create test Case records
        List<Case> caseRecList = new List<Case>();
        
        for (Integer i = 0; i < 2; i++) {
            caseDetailsList.add(new ABHI_Case_Detail__c(
                Claim_No__c  = '123' + i
            ));
        }
        insert caseDetailsList;

        for (Integer i = 0; i < 2; i++) {
            caseRecList.add(new Case(
                Business_Unit__c = 'ABHI',
                CCC_External_Id__c = 'CCC-CC-CCLTD-01',
                ABHI_Case_Detail__c = caseDetailsList[i].Id
            ));
        }
        insert caseRecList;
    }
    
    @isTest
    static void populateABHILCaseDetailFieldsTest(){

        List<Case> caseRecList = [SELECT Id, ABHI_Case_Detail__c, Business_Unit__c, CCC_External_Id__c FROM Case];

        ABHI_CaseDetailHelper abhiCaseDetHelpObj = new ABHI_CaseDetailHelper();
        abhiCaseDetHelpObj.populateABHILCaseDetailFields(caseRecList);

        ABHI_Case_Detail__c abhiCaseDetObj = [SELECT id, Sub_Type__c FROM ABHI_Case_Detail__c LIMIT 1];
        
        System.assertEquals(abhiCaseDetObj.Sub_Type__c, 'TestType:Test_SubType' ,'Value of Sub_Type__c is Test_SubType'); 
        system.debug('---');   
    }
}