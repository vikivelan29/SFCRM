/******************************************************  
* Author           - Salesforce
* Date             - 24-Dec-2024
* Description      - Test class for ABCD_CaseTriggerHelper
********************************************************
*/
@isTest
public class ABCD_CaseTriggerHelper_Test {
	@testSetup
    static void setUpData(){
        ASF_TestDataFactory.createCaseRecords(1);
    }
    
    @isTest
    static void populateCaseBusinessHrsTest(){
        Test.startTest();
        List<Case> caseList = [select Id,Business_Unit__c from Case];
        caseList[0].Business_Unit__c = 'ONEABC';
        update caseList[0];

        Test.stopTest();
    }
}