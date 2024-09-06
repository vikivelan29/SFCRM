/*********************************************************
*Class        :  ABSLAMC_CAMSUpdateWFApi_Test
*Author       :  Asmita Mathur
*Created Date :  08/11/2024
*Last Modified:  08/11/2024
*Description  :  Test Class for CAMS-UpdateWorkflow Integration
*********************************************************/
@isTest
public with sharing class ABSLAMC_CAMSUpdateWFApi_Test {
    
    @testSetup
    static void setupTestData(){ 
        
        ABSLAMC_Case_Detail__c caseDetail = new ABSLAMC_Case_Detail__c(
            CAMS_Ticket_Reference_Number__c = '1234',
            CAMS_Ticket_Status__c = 'Open',
            Additional_Remarks_for_CAMS__c = 'Case in progress',
            Reply_Type_for_CAMS__c = 'MIR1'
         
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
    
       ABSLAMC_CAMSUpdateWFApi ABSLAMC_CAMSUpdateWFApiObj = new ABSLAMC_CAMSUpdateWFApi();
       List <ABSLAMC_Case_Detail__c> caseDetail = [Select Id, CAMS_Ticket_Status__c,Reply_Type_for_CAMS__c,CAMS_Ticket_Reference_Number__c,
                                                Additional_Remarks_for_CAMS__c from  ABSLAMC_Case_Detail__c];
       List<Case> caseLst = [Select Id, CaseNumber, CCC_External_Id__c,ABSLAMC_Case_Detail__c, Source__c, Business_Unit__c, Nature__c, Stage__c,
                          Pending_Clarification__c,MoveToNext__c From Case where ABSLAMC_Case_Detail__c =:caseDetail[0].Id];        
       Test.startTest();
       ASF_IntegrationsController.IntegrationWrapper result = ABSLAMC_CAMSUpdateWFApiObj.evaluate(caseLst[0]);
       System.assertEquals('Success', result.status);	
       Test.stopTest();
     }
    
     @isTest 
     static void runTestMethod() {
          
        ABSLAMC_CAMSUpdateWFApi ABSLAMC_CAMSUpdateWFApiObj = new ABSLAMC_CAMSUpdateWFApi();
        ASF_Integration__c integ = new ASF_Integration__c();
          
        List<Case> caseLst = [Select Id, CaseNumber, CCC_External_Id__c, Source__c, Business_Unit__c, Nature__c, LAN__c From Case];
          
        Test.startTest();
          	ASF_IntegrationsController.IntegrationWrapper res = ABSLAMC_CAMSUpdateWFApiObj.run(integ, caseLst[0]);
		  	System.assertEquals('Success', res.status);   
        Test.stopTest();
     }

     @isTest 
     static void evaluateTestMethodBulk() {
    
        ABSLAMC_CAMSUpdateWFApi ABSLAMC_CAMSUpdateWFApiObj = new ABSLAMC_CAMSUpdateWFApi();
        List <ABSLAMC_Case_Detail__c> caseDetail = [SELECT Id, CAMS_Ticket_Status__c,Reply_Type_for_CAMS__c,CAMS_Ticket_Reference_Number__c,
                                                Additional_Remarks_for_CAMS__c FROM  ABSLAMC_Case_Detail__c];
        List<Case> caseLst = [SELECT Id, CaseNumber, CCC_External_Id__c,ABSLAMC_Case_Detail__c, Source__c, Business_Unit__c, Nature__c, Stage__c,
                          Pending_Clarification__c,MoveToNext__c FROM CASE WHERE ABSLAMC_Case_Detail__c =:caseDetail[0].Id];        
            
        Test.startTest();
            Map<Id, ASF_IntegrationsController.IntegrationWrapper> result = ABSLAMC_CAMSUpdateWFApiObj.evaluate(new List<Case>{caseLst[0]});
        Test.stopTest();
      }

      @isTest 
      static void runTestMethodBulk() {
          
        ABSLAMC_CAMSUpdateWFApi ABSLAMC_CAMSUpdateWFApiObj = new ABSLAMC_CAMSUpdateWFApi();
        ASF_Integration__c integ = new ASF_Integration__c();
        List <ABSLAMC_Case_Detail__c> caseDetail = [SELECT Id, CAMS_Ticket_Status__c,Reply_Type_for_CAMS__c,CAMS_Ticket_Reference_Number__c,
                                                Additional_Remarks_for_CAMS__c FROM  ABSLAMC_Case_Detail__c];
        List<Case> caseLst = [SELECT Id, CaseNumber, CCC_External_Id__c,ABSLAMC_Case_Detail__c, Source__c, Business_Unit__c, Nature__c, Stage__c,
                              Pending_Clarification__c,MoveToNext__c FROM CASE WHERE ABSLAMC_Case_Detail__c =:caseDetail[0].Id];        
          
        Test.startTest();
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> res = ABSLAMC_CAMSUpdateWFApiObj.run(new Map<Id, List<ASF_Integration__c>>{caseLst[0].Id => new List<ASF_Integration__c>{integ}}, new List<Case>{caseLst[0]});
        Test.stopTest();
      }

}