/*********************************************************
*Class        :  ABHFL_BalanceConfirmationLetterIntegration
*Author       :  Aditee Churiwala
*Created Date :  22/12/2023
*Last Modified:  
*Description  :  Test Class for ABFL_BRE_InterestCert_Retail
*********************************************************/
@isTest
public class ABFL_BRE_APIImplementation_Test {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    @TestSetup
    static void makeData(){
        Group SLAGroup = new Group();
        
        SLAGroup = new Group(Name='SLAManagerGroup', DeveloperName='SLAManagerGroup');
        insert SLAGroup;
        
        User userRecord1 = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,
                                    TimeZoneSidKey='America/Los_Angeles', UserName='cdefghijk567@gmail.com',
                                    managerGroupId__c=SLAGroup.Id);
        insert userRecord1;
        // ASF_TestDataFactory.createC3IntegrationsAndCase();
        
        Test.startTest();
        PermissionSet ps = [SELECT Id 
                            FROM PermissionSet 
                            WHERE Name = 'Admin_User'];
        insert new PermissionSetAssignment(AssigneeId = userRecord1.Id, PermissionSetId = ps.Id);
        Test.stopTest();
        System.runAs(userRecord1) {
            List<sObject> ls = Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
            SLA_Threshold_Warning__c  thresholdController = SLA_Threshold_Warning__c.getOrgDefaults();
            decimal thirdStageThreshold = thresholdController.Stage_SLA_Threshold_3__c ; 
            thresholdController.Customer_Email_buffer_hours__c=56;
            update thresholdController;
            
            List<ASF_Case_Category_Config__c> caseCat =  ABFL_TestDataFactory.createCaseCategoryConfig(true);
            
            List<ASF_Case_Stage_Config__c> caseStage = ABFL_TestDataFactory.createCaseStageConfig(caseCat[0].Id, true);
            ABFL_TestDataFactory.createCaseRuleEntry(caseStage);
            List<ASF_Integration__c> intConfigList = ABFL_TestDataFactory.createIntegration(caseStage[0].Id,true,'ABFL_InvokeBREProcess', 'BRE_BalanceConfirmation_Retail');
            
            Account acc = ABFL_TestDataFactory.createAccount();
            ABFL_TestDataFactory.createContact(acc.ID);
            List<ABFL_Case_Detail__c> caseDetList = ABFL_TestDataFactory.createCaseDetail('Corporate', true);
            caseDetList[0].From_Date__c = Date.Today();
            caseDetList[0].To_Date__c = Date.Today()+1;
            update caseDetList;
            
            Asset assetObj = new Asset();
            assetObj.Name = 'LAN-145';
            assetObj.LAN__c = 'LAN-145';
            assetObj.AccountId = acc.Id;
            assetObj.Business_Unit__c ='ABFL';
            insert assetObj;
            
            // List<Case> cases = ABFL_TestDataFactory.createCaseRecords(1, caseDetList[0].Id, true);
            List<Case> cases = ASF_TestDataFactory.createCaseRecords(1);
            
            Case c = cases.get(0);
            c.ownerid = userInfo.getuserId();
            c.AccountId = acc.ID;
            c.LAN__c = 'LAN-145';
            c.AssetId = assetObj.Id;
            c.Source__c = ABFL_Constants.RM_NO_EMAIL;
            c.ABFL_Case_Detail__c = caseDetList[0].Id;
            update c;
        }
        
    }
    
    @isTest
    static void testUpdateSTPFlow(){
        List<ASF_Integration__c> prepIntegrations =  ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-01', 'Open');
        System.debug('@@@prepIntegrations'+prepIntegrations);
        Case caseRec = [
            SELECT Id, ABFL_Case_Detail__c, Account.Name, Technical_Source__c
            FROM Case
            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01' LIMIT 1
        ];
        
        Test.startTest();
        ASF_IntegrationsController.IntegrationWrapper retVal = ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
        
        
        ASF_Case_Integration__c caseIntRec = [
            SELECT Id, Status__c
            FROM ASF_Case_Integration__c
            WHERE Case__c =: caseRec.Id
            AND Integration_Ext_Id__c =: prepIntegrations[0].External_Id__c
        ];
        caseIntRec.Status__c = 'Success';
        caseIntRec.Response__c = '{\"STPFlag\":\"SUCCESS\", \"STPDescription\":\"STPDescription\", \"DocumentURL\":\"DocumentURL\"}';
        update caseIntRec;
        System.debug('@@@'+Schema.sObjectType.ABFL_Case_Detail__c.isUpdateable());
        Test.stopTest();
        ABFL_Case_Detail__c caseDet = [SELECT Id,Document_URL__c FROM ABFL_Case_Detail__c LIMIT 1];
        Assert.areEqual('DocumentURL', caseDet.Document_URL__c);
    }
    
    @isTest
    static void testUpdateSTPFlowIVR_NoEmail(){
        ASF_Integration__c intg = [SELECT Id,STP_API_Identifier__c FROM ASF_Integration__c LIMIT 1];
        intg.STP_API_Identifier__c = 'BRE_Foreclosure_Retail';
        intg.STP_Config_External_Id__c = 'CCC-CC-CCLTD-01';
        update intg;
        List<ASF_Integration__c> prepIntegrations =  ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-01', 'Open');
        System.debug('@@@prepIntegrations'+prepIntegrations);
        Case caseRec = [
            SELECT Id, ABFL_Case_Detail__c, Account.Name, Source__c
            FROM Case
            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01' LIMIT 1
        ];
        caseRec.Source__c = ABFL_Constants.IVR_NO_EMAIL;
        update caseRec;
        
        Test.startTest();
        ASF_IntegrationsController.IntegrationWrapper retVal = ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
        
        
        ASF_Case_Integration__c caseIntRec = [
            SELECT Id, Status__c
            FROM ASF_Case_Integration__c
            WHERE Case__c =: caseRec.Id
            AND Integration_Ext_Id__c =: prepIntegrations[0].External_Id__c
        ];
        caseIntRec.Status__c = 'Success';
        caseIntRec.Response__c = '{\"STPFlag\":\"SUCCESS\", \"STPDescription\":\"STPDescription\", \"DocumentURL\":\"DocumentURL\"}';
        update caseIntRec;
        Test.stopTest();
        Integer caseDetCount = [SELECT count() FROM ABFL_Case_Detail__c];
        Assert.areEqual(2, caseDetCount);
    }
    
    @isTest
    static void testUpdateSTPFlowBranch(){
        ASF_Integration__c intg = [SELECT Id,STP_API_Identifier__c FROM ASF_Integration__c LIMIT 1];
        intg.STP_API_Identifier__c = 'BRE_Foreclosure_Retail';
        intg.STP_Config_External_Id__c = 'CCC-CC-CCLTD-01';
        update intg;
        List<ASF_Integration__c> prepIntegrations =  ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-01', 'Open');
        System.debug('@@@prepIntegrations'+prepIntegrations);
        Case caseRec = [
            SELECT Id, ABFL_Case_Detail__c, Account.Name, Source__c
            FROM Case
            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01' LIMIT 1
        ];
        caseRec.Source__c = 'Branch';
        update caseRec;
        
        Test.startTest();
        ASF_IntegrationsController.IntegrationWrapper retVal = ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
        
        
        ASF_Case_Integration__c caseIntRec = [
            SELECT Id, Status__c
            FROM ASF_Case_Integration__c
            WHERE Case__c =: caseRec.Id
            AND Integration_Ext_Id__c =: prepIntegrations[0].External_Id__c
        ];
        caseIntRec.Status__c = 'Success';
        caseIntRec.Response__c = '{\"STPFlag\":\"SUCCESS\", \"STPDescription\":\"STPDescription\", \"DocumentURL\":\"DocumentURL\"}';
        update caseIntRec;
        Test.stopTest();
        Integer caseDetCount = [SELECT count() FROM ABFL_Case_Detail__c];
        Assert.areEqual(2, caseDetCount);
        Case caseRec1 = [
            SELECT Id, Status
            FROM Case
            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01' LIMIT 1
        ];
        System.debug('@@status'+caseRec1);
    }
    @isTest
    static void testError(){
        List<ASF_Integration__c> prepIntegrations =  ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-01', 'Open');
        System.debug('@@@prepIntegrations'+prepIntegrations);
        Case caseRec = [
            SELECT Id, ABFL_Case_Detail__c, Account.Name, LAN__c, Source__c
            FROM Case
            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01' LIMIT 1
        ];
        caseRec.Source__c = ABFL_Constants.IVR_NO_EMAIL;
        update caseRec;
        
        ABFL_Case_Detail__c det = [SELECT Id,IsRegisteredCustomer__c,Autoclosure_IN_RR__c FROM ABFL_Case_Detail__c LIMIT 1];
        det.IsRegisteredCustomer__c = 'No';
        update det;
        
        Test.startTest();
        ASF_IntegrationsController.IntegrationWrapper retVal = ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
        
        Assert.areEqual(ABFL_Constants.EVALUATION_FAILED_IS_REGIS_ERROR,retVal.response);
        
        det.Autoclosure_IN_RR__c = true;
        update det;
        ASF_IntegrationsController.IntegrationWrapper retVals = ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
        
        Assert.areEqual(ABFL_Constants.EVALUATION_FAILED_IS_REGIS_ERROR,retVal.response);
        Test.stopTest();
    }
    @isTest
    static void testUpdateSTPFlowWithDateResponse () {
        ASF_Integration__c intg = [SELECT Id,STP_API_Identifier__c FROM ASF_Integration__c LIMIT 1];
        intg.STP_API_Identifier__c = 'BRE_InterestCert_Retail';
        update intg;
        List<ASF_Integration__c> prepIntegrations =  ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-01', 'Open');
        System.debug('@@@prepIntegrations'+prepIntegrations);
        Case caseRec = [
            SELECT Id, ABFL_Case_Detail__c, Account.Name, Source__c
            FROM Case
            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01' LIMIT 1
        ];
        caseRec.Source__c = ABFL_Constants.IVR_NO_EMAIL;
        update caseRec;
        
        Test.startTest();
        ASF_IntegrationsController.IntegrationWrapper retVal = ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
        
        
        ASF_Case_Integration__c caseIntRec = [
            SELECT Id, Status__c
            FROM ASF_Case_Integration__c
            WHERE Case__c =: caseRec.Id
            AND Integration_Ext_Id__c =: prepIntegrations[0].External_Id__c
        ];
        caseIntRec.Status__c = 'Success';
        caseIntRec.Response__c = '{\"STPFlag\":\"SUCCESS\", \"STPDescription\":\"STPDescription\", \"DocumentURL\":\"DocumentURL\"}';
        update caseIntRec;
        Test.stopTest();
        ABFL_Case_Detail__c caseDet = [SELECT Id,Document_URL__c FROM ABFL_Case_Detail__c LIMIT 1];
        Assert.areEqual('DocumentURL', caseDet.Document_URL__c);
    }
    @isTest
    static void testUpdateSTPFlowWithoutStatusResponse () {
        ASF_Integration__c intg = [SELECT Id,STP_API_Identifier__c FROM ASF_Integration__c LIMIT 1];
        intg.STP_API_Identifier__c = 'BRE_SanctionLetter_Retail';
        update intg;
        List<ASF_Integration__c> prepIntegrations =  ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-01', 'Open');
        System.debug('@@@prepIntegrations'+prepIntegrations);
        Case caseRec = [
            SELECT Id, ABFL_Case_Detail__c, Account.Name, Source__c
            FROM Case
            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01' LIMIT 1
        ];
        caseRec.Source__c = ABFL_Constants.IVR_NO_EMAIL;
        update caseRec;
        
        Test.startTest();
        ASF_IntegrationsController.IntegrationWrapper retVal = ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
        
        
        ASF_Case_Integration__c caseIntRec = [
            SELECT Id, Status__c
            FROM ASF_Case_Integration__c
            WHERE Case__c =: caseRec.Id
            AND Integration_Ext_Id__c =: prepIntegrations[0].External_Id__c
        ];
        caseIntRec.Status__c = 'Success';
        caseIntRec.Response__c = '{\"STPFlag\":\"SUCCESS\", \"STPDescription\":\"STPDescription\", \"DocumentURL\":\"DocumentURL\"}';
        update caseIntRec;
        Test.stopTest();
        ABFL_Case_Detail__c caseDet = [SELECT Id,Document_URL__c FROM ABFL_Case_Detail__c LIMIT 1];
        Assert.areEqual('DocumentURL', caseDet.Document_URL__c);
    }
    @isTest
    static void testUpdateSTPFlowWithBusinessDateResponse () {
        ASF_Integration__c intg = [SELECT Id,STP_API_Identifier__c FROM ASF_Integration__c LIMIT 1];
        intg.STP_API_Identifier__c = 'BRE_MarginHolding_Corporate';
        update intg;
        List<ASF_Integration__c> prepIntegrations =  ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-01', 'Open');
        System.debug('@@@prepIntegrations'+prepIntegrations);
        Case caseRec = [
            SELECT Id, ABFL_Case_Detail__c, Account.Name, Source__c
            FROM Case
            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01' LIMIT 1
        ];
        caseRec.Source__c = ABFL_Constants.IVR_NO_EMAIL;
        update caseRec;
        
        Test.startTest();
        ASF_IntegrationsController.IntegrationWrapper retVal = ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
        
        
        ASF_Case_Integration__c caseIntRec = [
            SELECT Id, Status__c
            FROM ASF_Case_Integration__c
            WHERE Case__c =: caseRec.Id
            AND Integration_Ext_Id__c =: prepIntegrations[0].External_Id__c
        ];
        caseIntRec.Status__c = 'Success';
        caseIntRec.Response__c = '{\"STPFlag\":\"SUCCESS\", \"STPDescription\":\"STPDescription\", \"DocumentURL\":\"DocumentURL\"}';
        update caseIntRec;
        Test.stopTest();
        ABFL_Case_Detail__c caseDet = [SELECT Id,Document_URL__c FROM ABFL_Case_Detail__c LIMIT 1];
        Assert.areEqual('DocumentURL', caseDet.Document_URL__c);
    }
    
}