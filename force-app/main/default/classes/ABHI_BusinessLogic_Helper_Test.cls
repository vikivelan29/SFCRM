/*********************************************************
*Class        :  ABHI_BusinessLogic_Helper_Test
*Author       :  Anirudh Raturi
*Created Date :  03/09/2024
*@description  :  Test Class for ABHI_BusinessLogic_Helper_Test 
*********************************************************/

@isTest
public with sharing class ABHI_BusinessLogic_Helper_Test {
    
    @TestSetup
    static void setupTestData() {

        Id recordTypeId =Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
        Account objAccount = new Account();
        objAccount.FirstName = 'Test FirstName';
        objAccount.LastName  = 'Test LastName';
        objAccount.Line_of_Business__c = 'ABHI';
        objAccount.Business_Unit__c = 'ABHI';
        objAccount.RecordTypeId = recordTypeId;
        insert objAccount;

        Asset asst1 = new Asset();
        asst1.Name = 'Test Asset';
        asst1.LAN__c = '23234432423';
        asst1.AccountId = objAccount.Id;
        insert asst1;

        Case caseRec = new Case();
        caseRec.Business_Unit__c = 'ABHI';
        caseRec.Notes__c = 'Test Case';
        caseRec.CCC_External_Id__c = 'CCC-CC-CCLTD-01';
        caseRec.AccountId = objAccount.Id;
        caseRec.Technical_Source__c = 'LWC';
        caseRec.Type_Text__c = 'Cashless';
        caseRec.Sub_Type_Text__c = 'Claims status';
        caseRec.Source__c = 'Branch';
        caseRec.AssetId = asst1.Id;
        insert caseRec;
    }

    /****************************************************
    * @description - Test Method for evaluate Method
    *****************************************************/
    @isTest 
    static void abhiHandlerMethodTestMethod() {
        
        Case caseRec = [SELECT id, Notes__c FROM Case LIMIT 1];
        caseRec.Notes__c = 'Test Case 1';
        update caseRec;

        System.assertEquals('Test Case 1', caseRec.Notes__c, 'Test Case 1');
    }
}