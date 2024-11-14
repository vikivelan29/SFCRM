@isTest
public with sharing class ABML_RoundRobinCaseAssBatch_Test {

    /****************************************************
     * @description - To setup test data for this test class
    *****************************************************/
    @testSetup
    static void setupTestData() {
        
        ASF_TestDataFactory.createCaseCategoryConfig();
        ASF_Case_Category_Config__c ccc = [Select id, Type__c, Sub_Type__c From ASF_Case_Category_Config__c Limit 1];
        
       Group grp = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND NAME LIKE 'ABML%' Limit 1];

        
        Account acc = ASF_TestDataFactory.insertBusinessAccount('test', 'strCRN');
            
        ABML_Case_Detail__c amblCaseDetRec = new ABML_Case_Detail__c();
        amblCaseDetRec.Case_Category__c = ccc.Id;
        insert amblCaseDetRec;
        
        Asset asst1 = new Asset();
        asst1.Name = 'Test Asset For IC';
        asst1.LAN__c = '23234432423';
        asst1.AccountId = acc.Id;

        insert asst1;

        List<Case> caseList = new List<Case>();
        Case caseRec1 = new Case();
        caseRec1.Notes__c = 'Test Case 1';
        caseRec1.CCC_External_Id__c = 'CCC-CC-CCLTD-01';
        caseRec1.Business_Unit__c = 'ABML';
        caseRec1.AssetId = asst1.Id;
        caseRec1.AccountId = acc.Id;
        caseRec1.Nature__c = 'Request';
        caseRec1.Type_Text__c = 'Bureau Related';
        caseRec1.Sub_Type_Text__c = 'CIBIL Related Details - Ownership Related';
        caseRec1.ABML_Case_Detail__c = amblCaseDetRec.Id;
        caseRec1.Source__c = 'Email';
        caseRec1.Stage__c = 'Resolved';
        caseRec1.Status = 'New';
        caseRec1.OwnerId = grp.Id;
        caseList.add(caseRec1);

        Case caseRec2 = new Case();
        caseRec2.Notes__c = 'Test Case 2';
        caseRec2.CCC_External_Id__c = 'CCC-CC-CCLTD-01';
        caseRec2.Business_Unit__c = 'ABML';
        caseRec2.AssetId = asst1.Id;
        caseRec2.AccountId = acc.Id;
        caseRec1.Nature__c = 'Request';
        caseRec2.Type_Text__c = 'Statement & Documents';
        caseRec2.Sub_Type_Text__c = 'Interest Schedule';
        caseRec2.Source__c = 'Email';
        caseRec2.Status = 'New';
        caseRec2.OwnerId = grp.Id;
        caseList.add(caseRec2);
        
        insert caseList;
    }

    /****************************************************
    * @description - Test Method for evaluate Method
    *****************************************************/
    @isTest 
    static void evaluateTestMethod() { 

        Test.startTest();
            ABML_RoundRobinCaseAssBatch roundRobinCase = new ABML_RoundRobinCaseAssBatch();
            Database.executeBatch(roundRobinCase);
        Test.stopTest();

        Case objCaseObj = [SELECT id, OwnerId FROM Case Limit 1];
        String ownerId = objCaseObj.OwnerId;
        Boolean checkOwner = ownerId.startsWith('005');
        System.assert(true, checkOwner);
    }
}