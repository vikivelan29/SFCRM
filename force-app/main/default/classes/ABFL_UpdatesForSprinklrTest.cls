@isTest
public class ABFL_UpdatesForSprinklrTest {
     @testSetup
    static void setupTestData(){ 
        
         Case cs = new Case(
            Business_Unit__c = 'ABFL',
            Stage__c = 'Open',
            Source__c ='Social Media',
            Sprinklr_Case_Reference_Number__c = 'ABFL12345',
            CCC_External_Id__c = 'MF01'
        );
        insert cs;
        
        CaseComment cm = new CaseComment(
            ParentId = cs.Id,
           CommentBody = 'TestBody'
        );
        insert cm;
        
        list<ASF_Case_Category_Config__c> ccclist = ABFL_TestDataFactory.createCaseCategoryConfig(false);
        ccclist[0].CCC_External_Id__c = 'MF01';
        
        insert ccclist[0];

    }
    
        @isTest 
        static void evaluateTestMethod() {
        ABFL_UpdatesForSprinklr ABFL_UpdatesForSprinklrObj = new ABFL_UpdatesForSprinklr();
        List<Case> caseLst = [SELECT Id, CaseNumber, CCC_External_Id__c, Source__c, Business_Unit__c, Nature__c, Stage__c,
                          Sprinklr_Case_Reference_Number__c FROM CASE];        
        Test.startTest();
        ASF_IntegrationsController.IntegrationWrapper result = ABFL_UpdatesForSprinklrObj.evaluate(caseLst[0]);
        System.assertEquals('Success', result.status);	
        Test.stopTest();
      }
    
      @isTest 
      static void runTestMethod() {
          
        ABFL_UpdatesForSprinklr ABFL_UpdatesForSprinklrObj = new ABFL_UpdatesForSprinklr();
        ASF_Integration__c integ = new ASF_Integration__c();
        List<Case> caseLst = [SELECT Id, CaseNumber, CCC_External_Id__c, Source__c, Business_Unit__c, Nature__c, LAN__c,Sprinklr_Case_Reference_Number__c FROM CASE];
       // List<CaseComment> casComm = [SELECT Id , CommentBody , parentId from CaseComment where ParentId =:caseLst[0].Id];
        List<ASF_Case_Category_Config__c> caseCategory = [Select Type__c, Sub_Type__c from ASF_Case_Category_Config__c where CCC_External_Id__c =:caseLst[0].CCC_External_Id__c];
        Test.startTest();
        ASF_IntegrationsController.IntegrationWrapper res = ABFL_UpdatesForSprinklrObj.run(integ, caseLst[0]);
     	System.assertEquals('Success', res.status);   
        Test.stopTest();
      }
      
      @isTest 
    static void evaluateTestMethodBulk() {
    
        ABFL_UpdatesForSprinklr ABFL_UpdatesForSprinklrObj = new ABFL_UpdatesForSprinklr();
        List<Case> caseLst = [SELECT Id, CaseNumber, CCC_External_Id__c, Source__c, Business_Unit__c, Nature__c, Stage__c,
                          Sprinklr_Case_Reference_Number__c FROM CASE];        
        Test.startTest();
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> result = ABFL_UpdatesForSprinklrObj.evaluate(new List<Case>{caseLst[0]});
        Test.stopTest();
    }

      @isTest 
      static void runTestMethodBulk() {
          
        ABFL_UpdatesForSprinklr ABFL_UpdatesForSprinklrObj = new ABFL_UpdatesForSprinklr();
        ASF_Integration__c integ = new ASF_Integration__c();
        List<Case> caseLst = [SELECT Id, CaseNumber, CCC_External_Id__c, Source__c, Business_Unit__c, Nature__c, Stage__c,
                          Sprinklr_Case_Reference_Number__c FROM CASE];        
        Test.startTest();
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> res = ABFL_UpdatesForSprinklrObj.run(new Map<Id, List<ASF_Integration__c>>{caseLst[0].Id => new List<ASF_Integration__c>{integ}}, new List<Case>{caseLst[0]});
        Test.stopTest();
      }    
   
}