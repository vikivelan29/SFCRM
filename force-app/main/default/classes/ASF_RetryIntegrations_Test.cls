@isTest
public class ASF_RetryIntegrations_Test {
    @TestSetup
    static void makeData(){
        List<sObject> ls = Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
        ASF_TestDataFactory.createC3IntegrationsAndCase();
        List<Case> cases = ASF_TestDataFactory.createCaseRecords(3);
        for(Case c : cases){
            c.Business_Unit__c = 'ABFL';
        }
        ASF_TriggerSkipperUtility.markTriggerRun('Case');
        update cases;
        ASF_TriggerSkipperUtility.resetTriggerRun('Case');
        
        List<ASF_Integration__c> prepIntegrations =  ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-05', 'Pending with Initiator');
        Case caseRec = [
            SELECT Id
            FROM Case
            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-05' LIMIT 1
        ];
        
        ASF_Integration__c prePopInt;
        for(ASF_Integration__c integ : prepIntegrations){
            if(integ.External_Id__c == 'ASF_INT_02'){
                prePopInt = integ;
            }
        }
        
        // For Testing purpose, Case record is not being passed, since the response is hard coded
        ASF_IntegrationsController.IntegrationWrapper retVal = ASF_IntegrationsController.runIntegration(prePopInt, caseRec);
        
    }
    
    @isTest
    private static void ASF_RetryIntegrationsTest_PROCESS(){
        List<ASF_Case_Integration__c> caseIntegrations = [SELECT Id, Status__c,Integration_Ext_Id__c,Case__c,
                                                          Type__c
                                                          FROM ASF_Case_Integration__c
                                                          WHERE Integration_Ext_Id__c='ASF_INT_02'                                          	
                                                          LIMIT 1];
        
        System.debug(caseIntegrations[0].Integration_Ext_Id__c);//ASF_INT_01
        
        Test.StartTest();
        ASF_RetryIntegrations.retryIntegration(caseIntegrations);
        Test.StopTest();
    }
    
    @isTest
    private static void ASF_RetryIntegrationsTest_EBOT(){
        Case newCase = new Case();
        newCase.Subject = 'Test Case Creation';
        newCase.CCC_External_Id__c ='' ;
        newCase.Source__c =  'Email';
        newCase.Stage__c = 'Email';
        newCase.SuppliedEmail = 'abcl.abfl@gmail.com';
        newCase.Business_Unit__c  = 'ABFL'; 
        insert newCase; 
        if(newCase.Id != null){
            EmailMessage eMsg = new EmailMessage();
            eMsg.ParentId = newCase.Id;
            eMsg.ToAddress = 'abcl.abfl@gmail.com';
            eMsg.CCAddress = 'test@test.com';
            eMsg.BCCAddress = 'test@test.com';
            insert eMsg;
            ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();    
            caseInt.Case__c =newCase.Id;
            caseInt.Status__c = 'Pending';
            caseInt.Type__c = 'eBOT';
            caseInt.Request__c = '{"attributes":{"type":"CRM_to_EBOT_Event__e","url":"/services/data/v60.0/sobjects/CRM_to_EBOT_Event__e/11308"},"Business_Unit__c":"ABFL","EventUuid":"0a1b334c-dab5-4aae-8522-6a106029e69a","Case_Number__c":"00005209","To_Address__c":"email2case.demo.abcl@gmail.com","From_Address__c":"santanu.halder@salesforce.com","CreatedById":"005Ny0000008bonIAA","Description__c":"Dummy Body","ReplayId":"11308","Subject__c":"Email2Case 9","CreatedDate":"2024-01-08T14:00:58.000+0000","Case_Integration_ID__c":"ASF_CInt_1223","Integration_Name__c":"EBOT API"}';
            insert caseInt;
            
            List<ASF_Case_Integration__c> caseIntegrations = [SELECT Id, Status__c,Integration_Ext_Id__c,Case__c,Request__c,
                                                              Type__c,Retry_Attempt__c
                                                              FROM ASF_Case_Integration__c
                                                              WHERE Id=: caseInt.Id
                                                              LIMIT 1];
            
            ASF_RetryIntegrations.retryIntegration(caseIntegrations);
        }
        
        
    }
}