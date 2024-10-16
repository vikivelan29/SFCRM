/****************************************************************************************************************
* Author       - Anirudh Raturi
* Date         - 16-Oct-2024
* @BU         - ABHI
* @description -  Test class for ABHI_Repeated_Case_Batch class.
*****************************************************************************************************************/

@isTest
public with sharing class ABHI_Repeated_Case_Batch_Test {

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
        objAccount.Line_of_Business__c = 'ABHI';
        objAccount.RecordTypeId = recordTypeId;
        insert objAccount;

        ABHI_Case_Detail__c abhiCaseDetRec = new ABHI_Case_Detail__c();
        abhiCaseDetRec.City__c = 'Mumbai';
        insert abhiCaseDetRec;
        
        Asset asst1 = new Asset();
        asst1.Name = 'Test Asset For IC';
        asst1.LAN__c = '23234432423';
        asst1.AccountId = objAccount.Id;

        insert asst1;

        List<Case> caseList = new List<Case>();
        Case caseRec1 = new Case();
        caseRec1.Notes__c = 'Test Case 1';
        caseRec1.CCC_External_Id__c = 'CCC-CC-CCLTD-01';
        caseRec1.Business_Unit__c = 'ABHI';
        caseRec1.AssetId = asst1.Id;
        caseRec1.AccountId = objAccount.Id;
        caseRec1.Nature__c = 'Request';
        caseRec1.Type_Text__c = 'Endorsement';
        caseRec1.Sub_Type_Text__c = 'Update Alternate Email ID - member';
        caseRec1.ABHI_Case_Detail__c = abhiCaseDetRec.Id;
        caseRec1.Source__c = 'Social Media';
        caseRec1.Stage__c = 'Resolved';
        caseList.add(caseRec1);

        Case caseRec2 = new Case();
        caseRec2.Notes__c = 'Test Case 2';
        caseRec2.CCC_External_Id__c = 'CCC-CC-CCLTD-01';
        caseRec2.Business_Unit__c = 'ABHI';
        caseRec2.AssetId = asst1.Id;
        caseRec2.AccountId = objAccount.Id;
        caseRec1.Nature__c = 'Request';
        caseRec2.Type_Text__c = 'Endorsement';
        caseRec2.Sub_Type_Text__c = 'Update Alternate Email ID - member';
        caseRec2.Source__c = 'Social Media';
        caseList.add(caseRec2);
        
        insert caseList;
    }

    /****************************************************
    * @description - Test Method for evaluate Method
    *****************************************************/
    @isTest 
    static void evaluateTestMethod() {

        Test.startTest();
            ABHI_Repeated_Case_Batch repeatCaseBatchJob = new ABHI_Repeated_Case_Batch();
            Database.executeBatch(repeatCaseBatchJob);
        Test.stopTest();

        ABHI_Case_Detail__c abhiCaseDetObj = [SELECT id, Repeated__c FROM ABHI_Case_Detail__c Limit 1];
        Assert.areEqual('Yes', abhiCaseDetObj.Repeated__c);
    }
}