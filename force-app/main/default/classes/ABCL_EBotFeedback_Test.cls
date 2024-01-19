/****************************************************************************************************************
  * Author       - Anirudh Raturi
  * Date         - 21-December-2023
  * @LOB         - ABHFL
  * @Description -  Test class for EBotFeedback class.
  *****************************************************************************************************************/

  @isTest
  public with sharing class ABCL_EBotFeedback_Test {
      
      /*******************************************************
       * @Description - To setup test data for this test class
      *******************************************************/
      @testSetup
      static void setupTestData(){
  		  
        SLA_Threshold_Warning__c slaThreshold = SLA_Threshold_Warning__c.getOrgDefaults();
        slaThreshold.Stage_SLA_Threshold_1__c = .5;
        slaThreshold.Stage_SLA_Threshold_2__c = .75;
        slaThreshold.Stage_SLA_Threshold_3__c = 1;
        slaThreshold.Case_SLA_Threshold_1_Label__c = '50%';
        slaThreshold.Case_SLA_Threshold_2_Label__c = '75%';
        slaThreshold.Case_SLA_Threshold_3_Label__c = '100%';
        slaThreshold.Case_SLA_Threshold_1__c = .5;
        slaThreshold.Case_SLA_Threshold_2__c = .75;
        slaThreshold.Case_SLA_Threshold_3__c = 1;
        upsert slaThreshold SLA_Threshold_Warning__c.Id;
          
        ASF_Integration__c integ = new ASF_Integration__c();
        integ.External_Id__c = 'ASF_INT_01';
        integ.Display_Name__c = 'NDC';
        insert integ;
          
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('Test Company', '');
        Case caseRec   = ASF_TestDataFactory.createInteractionCaseRecords()[0];
        caseRec.Source__c = 'Email';
        caseRec.Business_Unit__c = 'ABHFL';
        update caseRec;
  
      }
  
      /****************************************************
       * @Description - Test Method for evaluate Method
       *****************************************************/
      @isTest 
      static void evaluate_Test_Method() {
  
          ABCL_EBotFeedback ebotFeedbackObj = new ABCL_EBotFeedback();
          Case caseRec = [SELECT id FROM Case LIMIT 1];
  
          Test.startTest();
              ASF_IntegrationsController.IntegrationWrapper result = ebotFeedbackObj.evaluate(caseRec);
              System.assertEquals('Success', result.status);
          Test.stopTest();
      }
  
      /****************************************************
         * @Description - Test Method for run Method
        *****************************************************/
        @isTest 
        static void run_Test_Method() {
            
          ABCL_EBotFeedback ebotFeedbackObj = new ABCL_EBotFeedback();
          ASF_Integration__c integ = new ASF_Integration__c();
  
          Case caseRec = [SELECT id FROM Case LIMIT 1];
            
          Test.startTest();
            ASF_IntegrationsController.IntegrationWrapper res = ebotFeedbackObj.run(integ, caseRec);
            System.assertEquals('Success', res.status);          
          Test.stopTest();
        }
  }