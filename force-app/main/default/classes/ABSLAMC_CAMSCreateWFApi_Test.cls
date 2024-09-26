/*********************************************************
*Class        :  ABSLAMC_CAMSCreateWFApi_Test
*Author       :  Asmita Mathur
*Created Date :  08/11/2024
*Last Modified:  08/11/2024
*Description  :  Test Class for CAMS-CreateWorkflow Integration
*********************************************************/

@isTest
public with sharing class ABSLAMC_CAMSCreateWFApi_Test {
    
    @testSetup
    static void setupTestData(){ 
        
        ABSLAMC_Case_Detail__c caseDetail = new ABSLAMC_Case_Detail__c(
            CAMS_Ticket_Reference_Number__c = '',
            CAMS_Ticket_Status__c = 'Closed'
         
        );
        insert caseDetail;
        
         Case cs = new Case(
            Business_Unit__c = 'ABSLAMC',
            Stage__c = 'Pending with CAMS',
           Pending_Clarification__c = true,
           ABSLAMC_Case_Detail__c = caseDetail.Id
        );
        insert cs;

    }
    
        @isTest 
        static void evaluateTestMethod() {
        ABSLAMC_CAMSCreateWFApi ABSLAMC_CAMSCreateWFApiObj = new ABSLAMC_CAMSCreateWFApi();
        List <ABSLAMC_Case_Detail__c> caseDetail = [SELECT Id, CAMS_Ticket_Status__c FROM  ABSLAMC_Case_Detail__c];
        List<Case> caseLst = [SELECT Id, CaseNumber, CCC_External_Id__c,ABSLAMC_Case_Detail__c, Source__c, Business_Unit__c, Nature__c, Stage__c,
                          Pending_Clarification__c,MoveToNext__c FROM CASE WHERE ABSLAMC_Case_Detail__c =:caseDetail[0].Id];        
        Test.startTest();
        ASF_IntegrationsController.IntegrationWrapper result = ABSLAMC_CAMSCreateWFApiObj.evaluate(caseLst[0]);
        System.assertEquals('Success', result.status);	
        Test.stopTest();
      }
    
      @isTest 
      static void runTestMethod() {
          
        ABSLAMC_CAMSCreateWFApi ABSLAMC_CAMSCreateWFApiObj = new ABSLAMC_CAMSCreateWFApi();
        ASF_Integration__c integ = new ASF_Integration__c();
        List<Case> caseLst = [SELECT Id, CaseNumber, CCC_External_Id__c, Source__c, Business_Unit__c, Nature__c, LAN__c FROM CASE];
        Test.startTest();
        ASF_IntegrationsController.IntegrationWrapper res = ABSLAMC_CAMSCreateWFApiObj.run(integ, caseLst[0]);
     	System.assertEquals('Success', res.status);   
        Test.stopTest();
      }

    @isTest 
    static void evaluateTestMethodBulk() {
    
        ABSLAMC_CAMSCreateWFApi ABSLAMC_CAMSCreateWFApiObj = new ABSLAMC_CAMSCreateWFApi();
        List <ABSLAMC_Case_Detail__c> caseDetail = [SELECT Id, CAMS_Ticket_Status__c FROM  ABSLAMC_Case_Detail__c];
        List<Case> caseLst = [SELECT Id, CaseNumber, CCC_External_Id__c,ABSLAMC_Case_Detail__c, Source__c, Business_Unit__c, Nature__c, Stage__c,
                          Pending_Clarification__c,MoveToNext__c FROM CASE WHERE ABSLAMC_Case_Detail__c =:caseDetail[0].Id];        
        Test.startTest();
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> result = ABSLAMC_CAMSCreateWFApiObj.evaluate(new List<Case>{caseLst[0]});
        Test.stopTest();
    }

      @isTest 
      static void runTestMethodBulk() {
          
        ABSLAMC_CAMSCreateWFApi ABSLAMC_CAMSCreateWFApiObj = new ABSLAMC_CAMSCreateWFApi();
        ASF_Integration__c integ = new ASF_Integration__c();
        List <ABSLAMC_Case_Detail__c> caseDetail = [Select Id, CAMS_Ticket_Status__c FROM  ABSLAMC_Case_Detail__c];
        List<Case> caseLst = [SELECT Id, CaseNumber, CCC_External_Id__c,ABSLAMC_Case_Detail__c, Source__c, Business_Unit__c, Nature__c, Stage__c,
                          Pending_Clarification__c,MoveToNext__c FROM CASE WHERE ABSLAMC_Case_Detail__c =:caseDetail[0].Id];        
        Test.startTest();
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> res = ABSLAMC_CAMSCreateWFApiObj.run(new Map<Id, List<ASF_Integration__c>>{caseLst[0].Id => new List<ASF_Integration__c>{integ}}, new List<Case>{caseLst[0]});
        Test.stopTest();
      }

}