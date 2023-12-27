@isTest
private class ASF_IntegrationsControllerTest {
    
    @TestSetup
    static void makeData(){
        List<sObject> ls = Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
        ASF_TestDataFactory.createC3IntegrationsAndCase();
        //ASF_TestDataFactory.createC3WithPrePopulateIntegrations();
        List<Case> cases = ASF_TestDataFactory.createCaseRecords(3);
        //ASF_TestDataFactory.createCaseIntegration(cases[0].Id, 'ASF_INT_01');
    }

    @isTest
    static void testGetAllIntegrations(){
    
        List<ASF_Integration__c> prepIntegrations =  ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-05', 'Pending with Initiator');
        system.assertEquals(2, prepIntegrations.size());
    }

    @isTest
    static void testGetAllUIIntegrations(){
    
        List<ASF_Integration__c> prepIntegrations =  ASF_IntegrationsController.getAllUIIntegrations('CCC-CC-CCLTD-05', 'Pending with Initiator');
        system.assertEquals(1, prepIntegrations.size());

    }

    @isTest
    static void testRunIntegrations(){
    
        List<ASF_Integration__c> prepIntegrations =  ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-05', 'Pending with Initiator');
        Case caseRec = [
            SELECT Id
            FROM Case
            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-05' LIMIT 1
        ];

        ASF_Integration__c prePopInt;
        for(ASF_Integration__c integ : prepIntegrations){
            if(integ.External_Id__c == 'ASF_INT_01'){
                prePopInt = integ;
            }
        }

        // For Testing purpose, Case record is not being passed, since the response is hard coded
        ASF_IntegrationsController.IntegrationWrapper retVal = ASF_IntegrationsController.runIntegration(prePopInt, caseRec);
        
        ASF_Case_Integration__c caseIntRec = [
            SELECT Id, Status__c
            FROM ASF_Case_Integration__c
            WHERE Case__c =: caseRec.Id
            AND Integration_Ext_Id__c =: prepIntegrations[0].External_Id__c
        ];
        system.assertEquals('Success', retVal.status);
        system.assertEquals(caseIntRec.Status__c, 'Pending');

    }

    @isTest
    static void testGetAllCaseIntegrations(){
    
        List<ASF_Integration__c> prepIntegrations =  ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-05', 'Pending with Initiator');
        Case caseRec = [
            SELECT Id
            FROM Case
            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-05' LIMIT 1
        ];
        
        ASF_IntegrationsController.IntegrationWrapper retVal = ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
        List<ASF_Case_Integration__c> caseIntegrations =  ASF_IntegrationsController.getAllCaseIntegrations(caseRec.Id, new list<string>{prepIntegrations[0].External_Id__c});
        system.assertEquals(1, caseIntegrations.size());

    }   

    @isTest
    static void testCancelPendingCaseIntegrations(){
    
        // Run the Integration Once to create Pending First
        List<ASF_Integration__c> prepIntegrations =  ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-05', 'Pending with Initiator');
        Case caseRec = [
            SELECT Id
            FROM Case
            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-05' LIMIT 1
        ];
        
        ASF_IntegrationsController.IntegrationWrapper retVal = ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
        
       
        ASF_Case_Integration__c caseIntRec = [
            SELECT Id, Status__c
            FROM ASF_Case_Integration__c
            WHERE Case__c =: caseRec.Id
            AND Integration_Ext_Id__c =: prepIntegrations[0].External_Id__c
        ];
        system.assertEquals('Success', retVal.status);
        system.assertEquals('Pending', caseIntRec.Status__c);

        // Now Cancel the Integration
        ASF_IntegrationsController.cancelPendingCaseIntegrations(caseRec.Id, prepIntegrations[0].External_Id__c);
        
        caseIntRec = [
            SELECT Id, Status__c
            FROM ASF_Case_Integration__c
            WHERE Id =: caseIntRec.Id
        ];

        system.assertEquals('Canceled', caseIntRec.Status__c);
    }   


}