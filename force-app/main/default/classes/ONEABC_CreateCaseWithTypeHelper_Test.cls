/******************************************************  
* Author           - Salesforce
* Date             - 24-Dec-2024
* Description      - Test class for ONEABC_CreateCaseWithTypeHelper
********************************************************
*/

@isTest
public class ONEABC_CreateCaseWithTypeHelper_Test {
	@testSetup
    static void setUpData(){
        ASF_TestDataFactory.createCaseCategoryConfig();
    }
    
    @isTest
    static void filterCTSTBasedOnBULogicTest(){
        Test.startTest();
        List<ASF_Case_Category_Config__c> caseCatConfig = [select Id,Business_Unit__c,LOB__c from ASF_Case_Category_Config__c];
        caseCatConfig[0].Business_Unit__c = 'ONEABC';
        caseCatConfig[0].LOB__c = 'ABFL';
        update caseCatConfig[0];
        
        ONEABC_CreateCaseWithTypeHelper.filterCTSTBasedOnBULogic(caseCatConfig,'{"accountLOB":"ABFL","businessUnit":"ABFL"}');
        ONEABC_CreateCaseWithTypeHelper.filterCTSTBasedOnBULogic(caseCatConfig,'{"requestFrom":"Lead"}');
        Test.stopTest();
    }
}