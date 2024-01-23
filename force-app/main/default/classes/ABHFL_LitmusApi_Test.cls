/*********************************************************
*Class        :  ABHFL_LitmusApi_Test
*Author       :  Anirudh Raturi
*Created Date :  08/11/2024
*Last Modified:  08/11/2024
*Description  :  Test Class for Litmus Integration
*********************************************************/

@isTest
public with sharing class ABHFL_LitmusApi_Test {

    /****************************************************
     * @description - To setup test data for this test class
    *****************************************************/
    @testSetup
    static void setupTestData(){ 

        List<Case> caseRecList = ASF_TestDataFactory.createCaseRecords(1);
        ASF_TestDataFactory.createCaseCategoryConfig();

        ASF_Case_Category_Config__c cccRec = [Select id from ASF_Case_Category_Config__c LIMIT 1];
        cccRec.Business_Unit__c = 'ABHFL';
        cccRec.Litmus_Trigger__c = true;
        cccRec.Litmus_Project__c = 'g4s1_touchpoint';
        update cccRec;
    }

    /****************************************************
     * @description - Test Method for evaluate Method
     *****************************************************/
    @isTest 
    static void evaluateTestMethod() {
    
    ABHFL_LitmusApi litmusApiObj = new ABHFL_LitmusApi();
    List<Case> caseLst = [Select id, Sub_Type_Text__c, Status, Nature__c, Notes__c From Case];
    caseLst[0].Status = 'Resolved';
    update caseLst;
        
    Test.startTest();
        ASF_IntegrationsController.IntegrationWrapper result = litmusApiObj.evaluate(caseLst[0]);
        System.assertEquals('Success', result.status);	
    Test.stopTest();
    }

    /****************************************************
       * @description - Test Method for run Method
      *****************************************************/
      @isTest 
      static void runTestMethod() {
          
        ABHFL_LitmusApi litmusApiObj = new ABHFL_LitmusApi();
        ASF_Integration__c integ = new ASF_Integration__c();
          
        List<Case> caseLst = [Select id, Notes__c From Case];
          
        Test.startTest();
          	ASF_IntegrationsController.IntegrationWrapper res = litmusApiObj.run(integ, caseLst[0]);
		  	System.assertEquals('Success', res.status);   
        Test.stopTest();
      }
}