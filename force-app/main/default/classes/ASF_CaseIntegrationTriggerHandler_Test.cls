@IsTest
public class ASF_CaseIntegrationTriggerHandler_Test {
    
    @TestSetup
    static void setUpData(){
         ASF_TestDataFactory.createC3WithPrePopulateIntegrations();
        List<Case> cases = ASF_TestDataFactory.createCaseRecords(3);
        List<ABML_Daily_Report_Sender__c> listOfReportSender = new List<ABML_Daily_Report_Sender__c>();
        ABML_Daily_Report_Sender__c objReportSenderTwo = new ABML_Daily_Report_Sender__c( Name = 'ordWideAddress', Email__c = 'care.digital@adityabirlacapital.com');
        listOfReportSender.add(objReportSenderTwo);
        insert listOfReportSender;
    }
   
    @isTest
    static void testCancelPendingCaseIntegrations(){
    
        // Run the Integration Once to create Pending First
        List<ASF_Integration__c> prepIntegrations =  ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-01', 'Pending with Initiator');
        Case caseRec = [
            SELECT Id
            FROM Case
            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01' LIMIT 1
        ];
        
        Object retVal = ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
        
       
        ASF_Case_Integration__c caseIntRec = [
            SELECT Id, Status__c
            FROM ASF_Case_Integration__c
            WHERE Case__c =: caseRec.Id
            AND Integration_Ext_Id__c =: prepIntegrations[0].External_Id__c
        ];
        //system.assertEquals('Success', retVal);
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
    
    @isTest
    static void testReportIntegration(){
        Test.startTest();
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Status__c = 'Pending';
        caseInt.Business_External_Id__c = 'ABML_Report_Integration';
        insert caseInt;
        
        system.assertEquals('Pending', caseInt.Status__c);
        caseInt.Status__c = 'Success';
        update caseInt;
        system.assertEquals('Success', caseInt.Status__c); 
        Test.stopTest();
    }
}
