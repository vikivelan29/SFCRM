/****************************************************************************************************************
* Author       - Anirudh Raturi
* Date         - 13-March-2024
* @LOB         - ABHFL
* @description -  Test class for ABHFL_Repeated_Case_Batch class.
*****************************************************************************************************************/

@isTest
public with sharing class ABHFL_Repeated_Case_Batch_Test {

    /****************************************************
     * @description - To setup test data for this test class
    *****************************************************/
    @testSetup
    static void setupTestData() {
        
        ASF_TestDataFactory.createCaseCategoryConfig();
        ASF_Case_Category_Config__c ccc = [Select id, Type__c, Sub_Type__c From ASF_Case_Category_Config__c Limit 1];
        
        Id recordTypeId =Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
        Account objAccount = new Account();
        objAccount.FirstName = 'TestFirstName';
        objAccount.LastName  = 'TestFirstName';
        objAccount.Line_of_Business__c = 'ABHFL';
        objAccount.RecordTypeId = recordTypeId;
        insert objAccount;

        ABHFL_Case_Detail__c abhflCaseDetRec = new ABHFL_Case_Detail__c();
        abhflCaseDetRec.Financial_Year__c = '2015-16';
        insert abhflCaseDetRec;
        
        Asset asst1 = new Asset();
        asst1.Name = 'Test Asset For IC';
        asst1.LAN__c = '23234432423';
        asst1.AccountId = objAccount.Id;

        insert asst1;

        List<Case> caseList = new List<Case>();
        Case caseRec1 = new Case();
        caseRec1.Notes__c = 'Test Case 1';
        caseRec1.CCC_External_Id__c = 'CCC-CC-CCLTD-01';
        caseRec1.Business_Unit__c = 'ABHFL';
        caseRec1.AssetId = asst1.Id;
        caseRec1.AccountId = objAccount.Id;
        caseRec1.Nature__c = 'Request';
        caseRec1.Type_Text__c = 'Bureau Related';
        caseRec1.Sub_Type_Text__c = 'CIBIL Related Details - Ownership Related';
        caseRec1.ABHFL_Case_Detail__c = abhflCaseDetRec.Id;
        caseRec1.Source__c = 'Branch';
        caseRec1.Stage__c = 'Resolved';
        caseList.add(caseRec1);

        Case caseRec2 = new Case();
        caseRec2.Notes__c = 'Test Case 2';
        caseRec2.CCC_External_Id__c = 'CCC-CC-CCLTD-01';
        caseRec2.Business_Unit__c = 'ABHFL';
        caseRec2.AssetId = asst1.Id;
        caseRec2.AccountId = objAccount.Id;
        caseRec1.Nature__c = 'Request';
        caseRec2.Type_Text__c = 'Statement & Documents';
        caseRec2.Sub_Type_Text__c = 'Interest Schedule';
        caseRec2.Source__c = 'Branch';
        caseList.add(caseRec2);
        
        insert caseList;
    }

    /****************************************************
    * @description - Test Method for evaluate Method
    *****************************************************/
    @isTest 
    static void evaluateTestMethod() {

        Test.startTest();
            ABHFL_Repeated_Case_Batch repeatCaseBatchJob = new ABHFL_Repeated_Case_Batch();
            Database.executeBatch(repeatCaseBatchJob);
        Test.stopTest();

        ABHFL_Case_Detail__c abhflCaseDetObj = [SELECT id, Repeated__c FROM ABHFL_Case_Detail__c Limit 1];
        Assert.areEqual('Yes', abhflCaseDetObj.Repeated__c);
    }
}