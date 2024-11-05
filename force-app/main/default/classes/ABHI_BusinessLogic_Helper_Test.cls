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
        asst1.Calling_Source__c = 'Ubona BOT';//RNWL
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
        
       // Opportunity oppRec = RNWL_TestDataFactory.createOpportunityRecords(objAccount.Id, asst1.Id);//RNWL
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
    
    @isTest
    static void test_populateFieldsOnCase(){
        Case caseRec = [SELECT Id, AccountId, AssetId FROM Case LIMIT 1];
        Asset asst2 = new Asset();
        asst2.Name = 'Test Asset';
        asst2.AccountId = caseRec.AccountId;
        asst2.Calling_Source__c = 'CRM (In-House)';
        insert asst2;
        
        Test.startTest();
        	caseRec.AssetId = asst2.Id;
        	update caseRec;
        Test.stopTest();
        
        caseRec = [SELECT Id, Calling_Source__c FROM Case WHERE Id = :caseRec.Id ];
        System.assertEquals(asst2.Calling_Source__c, caseRec.Calling_Source__c, 'Case is NOT UPDATED!!!!');
    }
}