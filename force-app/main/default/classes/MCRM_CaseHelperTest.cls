/*********************************************************
*Class        :  MCRM_CaseHelperTest 
*Author       :  Rohan Kosandal
*Created Date :  13/11/2024
*@description  : Test class for MCRM_CaseHelper
***********************************************************/ 
@isTest
public without sharing class MCRM_CaseHelperTest {
    @TestSetup
    static void makeData(){
        WellnessCaseDetail__c caseDetail = new WellnessCaseDetail__c();
        insert caseDetail;
        Case testCase = new Case(
            Origin = 'Web',
            Stage__c = 'New',
            Subject = 'Test Case',
            Business_Unit__c = 'Wellness',
            WellnessCaseDetail__c = caseDetail.Id
        );
        insert testCase;       
    }

    @isTest
    static void testCalculateBillableTimeOnCaseClose(){
        
        Case testCase = [SELECT Id FROM Case WHERE Stage__c = 'New' LIMIT 1];
        testCase.Stage__c = 'Resolved';
        Test.startTest();
        update testCase; // Will execute MCRM_CaseHelper.calculateBillableTimeOnCaseClose()
        Test.stopTest();
    }
}