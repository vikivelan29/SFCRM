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
        
        SLAGroup = new Group(Name='SLAManagerGroup', DeveloperName='SLAManagerGroup', Type = 'Queue');
        insert SLAGroup;
        
        User superManagerUser = new User(
            IsActive = true,
            Business_Unit__c='ABFL',
            FirstName = 'Test',
            LastName='Super Manager User Test 12',
            Username='supermanageruserTest12@test.com',
            Email='supermanageruserTest12@test.com',
            Alias = 'mgrt',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', 
            ProfileId = SYSTEMADMIN_PROFILE.Id, 
            TimeZoneSidKey='America/Los_Angeles', managerGroupId__c=SLAGroup.Id
        );
        insert superManagerUser;
        
        User userRecord1 = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,
                                    TimeZoneSidKey='America/Los_Angeles', UserName='Testcdefghijk567@gmail.com',
                                    managerGroupId__c=SLAGroup.Id, managerID = superManagerUser.Id
                                    );
        insert userRecord1;
        // ASF_TestDataFactory.createC3IntegrationsAndCase();
        
        Test.startTest();
        List<PermissionSetAssignment> psa = new List<PermissionSetAssignment>();
        PermissionSet ps = [SELECT Id 
                            FROM PermissionSet 
                            WHERE Name = 'Admin_User' ];
        psa.add(new PermissionSetAssignment(AssigneeId = userRecord1.Id, PermissionSetId = ps.Id));
        psa.add(new PermissionSetAssignment(AssigneeId = superManagerUser.Id, PermissionSetId = ps.Id));
        
        
        insert psa;
        Test.stopTest();
        System.runAs(userRecord1) {
            List<sObject> ls = Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
            SLA_Threshold_Warning__c  thresholdController = SLA_Threshold_Warning__c.getOrgDefaults();
            decimal thirdStageThreshold = thresholdController.Stage_SLA_Threshold_3__c ; 
            thresholdController.Customer_Email_buffer_hours__c=56;
            update thresholdController;
                        
            GroupMember gm = new GroupMember(GroupId = SLAGroup.Id, UserOrGroupId = userRecord1.Id);
            insert gm;
            GroupMember gm1 = new GroupMember(GroupId = SLAGroup.Id, UserOrGroupId = userRecord1.Id);
            insert gm1;
            
            List<ASF_Case_Category_Config__c> caseCat =  ABFL_TestDataFactory.createCaseCategoryConfig(true);
            
            List<ASF_Case_Stage_Config__c> caseStage = ABFL_TestDataFactory.createCaseStageConfig(caseCat[0].Id, true);
            ABFL_TestDataFactory.createCaseRuleEntry(caseStage);
            List<ASF_Integration__c> intConfigList = ABFL_TestDataFactory.createIntegration(caseStage[0].Id,true,'ABFL_InvokeBREProcess', 'BRE_BalanceConfirmation_Retail');
            /*for(ASF_Integration__c integ : intConfigList){
                integ.Query_Fields__c = 'Id,ABFL_Case_Detail__c, Account.Name, Technical_Source__c, Source__c';
            }*/
            update intConfigList;
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
            c.OwnerId = superManagerUser.Id;
            update c;
        }
        
    }
    
    @isTest
    static void testUpdateSTPFlowBulk(){
        List<ASF_Integration__c> prepIntegrations =  ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-01', 'Open');
        Map<Id, List<ASF_Integration__c>> mapIntegrations = new Map<Id, List<ASF_Integration__c>>();
        System.debug('@@@prepIntegrations'+prepIntegrations);
        Case caseRec = [
            SELECT Id, ABFL_Case_Detail__c, Account.Name, Technical_Source__c
            FROM Case
            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01' LIMIT 1
        ];
        mapIntegrations.put(caseRec.Id, prepIntegrations);
        Test.startTest();
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> retVal = ASF_IntegrationsController.runIntegration(mapIntegrations, new List<Case>{caseRec});
        
        
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
       // //Assert.areEqual('DocumentURL', caseDet.Document_URL__c);
       Case caseRecord = [SELECT Id, IsClosed, Status
                               FROM Case
                               WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                               LIMIT 1];
            
       Assert.areEqual('In Progress', caseRecord.Status, 'Case status should be Resolved');
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
        
        Map<Id, List<ASF_Integration__c>> mapIntegrations = new Map<Id, List<ASF_Integration__c>>();
        mapIntegrations.put(caseRec.Id, prepIntegrations);
        Test.startTest();
        ASF_IntegrationsController.IntegrationWrapper retVal = ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> retValBulk = ASF_IntegrationsController.runIntegration(mapIntegrations, new List<Case>{caseRec});
        
        List<ASF_Case_Integration__c> listCaseIntRec = new List<ASF_Case_Integration__c>();
        
        for(ASF_Case_Integration__c caseIntRec : [SELECT Id, Status__c
                                    FROM ASF_Case_Integration__c
                                    WHERE Case__c =: caseRec.Id AND Integration_Ext_Id__c =: prepIntegrations[0].External_Id__c]) {
                                        caseIntRec.Status__c = 'Success';
                                        caseIntRec.Response__c = '{\"STPFlag\":\"SUCCESS\", \"STPDescription\":\"STPDescription\", \"DocumentURL\":\"DocumentURL\"}';                                     
                                 		listCaseIntRec.add(caseIntRec);
                                                  }
       
        update listCaseIntRec;
        Test.stopTest();
        Integer caseDetCount = [SELECT count() FROM ABFL_Case_Detail__c];
        ////Assert.areEqual(2, caseDetCount);
        Case caseRecord = [SELECT Id, IsClosed, Status
                               FROM Case
                               WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                               LIMIT 1];
            
       Assert.areEqual('Resolved', caseRecord.Status, 'Case status should be Resolved');
    }
    
    @isTest
    static void testUpdateSTPFlowBranch(){
      User userRecord = [SELECT Id
                           FROM User
                           WHERE UserName = 'Testcdefghijk567@gmail.com'];
        System.runAs(userRecord){
        	ASF_Constants.bypassOwnerChangeValidation = true;
            ASF_Integration__c intg = [SELECT Id,STP_API_Identifier__c FROM ASF_Integration__c LIMIT 1];
            intg.STP_API_Identifier__c = 'BRE_Foreclosure_Retail';
            intg.STP_Config_External_Id__c = 'CCC-CC-CCLTD-01';
            update intg;
            List<ASF_Integration__c> prepIntegrations =  ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-01', 'Open');
            System.debug('@@@prepIntegrations'+prepIntegrations);
            Case caseRec = [
                SELECT Id, ABFL_Case_Detail__c, Account.Name, Source__c,OWner.username
                FROM Case
                WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01' LIMIT 1
            ];
            caseRec.Source__c = 'Branch';
            update caseRec;
			System.debug('@@@caseRec.OWner.usernam'+caseRec.OWner.username);
            Map<Id, List<ASF_Integration__c>> mapIntegrations = new Map<Id, List<ASF_Integration__c>>();
            mapIntegrations.put(caseRec.Id, prepIntegrations);
            Test.startTest();
            ASF_IntegrationsController.IntegrationWrapper retVal = ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
            Map<Id, ASF_IntegrationsController.IntegrationWrapper> retValBulk = ASF_IntegrationsController.runIntegration(mapIntegrations, new List<Case>{caseRec});
            
            List<ASF_Case_Integration__c> listCaseIntRec = new List<ASF_Case_Integration__c>();
            
            for(ASF_Case_Integration__c caseIntRec : [SELECT Id, Status__c
                                        FROM ASF_Case_Integration__c
                                        WHERE Case__c =: caseRec.Id AND Integration_Ext_Id__c =: prepIntegrations[0].External_Id__c]) {
                                            caseIntRec.Status__c = 'Success';
                                            caseIntRec.Response__c = '{\"STPFlag\":\"SUCCESS\", \"STPDescription\":\"STPDescription\", \"DocumentURL\":\"DocumentURL\"}';                                     
                                            listCaseIntRec.add(caseIntRec);
                                                      }
           
            update listCaseIntRec;
            Test.stopTest();
            Integer caseDetCount = [SELECT count() FROM ABFL_Case_Detail__c];
            //Assert.areEqual(2, caseDetCount);
            Case caseRec1 = [
                SELECT Id, Status
                FROM Case
                WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01' LIMIT 1
            ];
            System.debug('@@status'+caseRec1);
        }    
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
        
        //Assert.areEqual(ABFL_Constants.EVALUATION_FAILED_IS_REGIS_ERROR,retVal.response);
        
        det.Autoclosure_IN_RR__c = true;
        update det;
        ASF_IntegrationsController.IntegrationWrapper retVals = ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
        
        //Assert.areEqual(ABFL_Constants.EVALUATION_FAILED_IS_REGIS_ERROR,retVal.response);
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
        
        Map<Id, List<ASF_Integration__c>> mapIntegrations = new Map<Id, List<ASF_Integration__c>>();
        mapIntegrations.put(caseRec.Id, prepIntegrations);
        Test.startTest();
        ASF_IntegrationsController.IntegrationWrapper retVal = ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> retValBulk = ASF_IntegrationsController.runIntegration(mapIntegrations, new List<Case>{caseRec});
        
        List<ASF_Case_Integration__c> listCaseIntRec = new List<ASF_Case_Integration__c>();
        
        for(ASF_Case_Integration__c caseIntRec : [SELECT Id, Status__c
                                    FROM ASF_Case_Integration__c
                                    WHERE Case__c =: caseRec.Id AND Integration_Ext_Id__c =: prepIntegrations[0].External_Id__c]) {
                                        caseIntRec.Status__c = 'Success';
                                        caseIntRec.Response__c = '{\"STPFlag\":\"SUCCESS\", \"STPDescription\":\"STPDescription\", \"DocumentURL\":\"DocumentURL\"}';                                     
                                 		listCaseIntRec.add(caseIntRec);
                                                  }
       
        update listCaseIntRec;
        Test.stopTest();
        ABFL_Case_Detail__c caseDet = [SELECT Id,Document_URL__c FROM ABFL_Case_Detail__c LIMIT 1];
        //Assert.areEqual('DocumentURL', caseDet.Document_URL__c);
    }
    /*@isTest
    static void testUpdateSTPFlowWithDateResponseBulk () {
        ASF_Integration__c intg = [SELECT Id,STP_API_Identifier__c FROM ASF_Integration__c LIMIT 1];
        intg.STP_API_Identifier__c = 'BRE_ProInterestCert_Retail';
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
        
        Map<Id, List<ASF_Integration__c>> mapIntegrations = new Map<Id, List<ASF_Integration__c>>();
        mapIntegrations.put(caseRec.Id, prepIntegrations);
        Test.startTest();
        ASF_IntegrationsController.IntegrationWrapper retVal = ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> retValBulk = ASF_IntegrationsController.runIntegration(mapIntegrations, new List<Case>{caseRec});
        
        List<ASF_Case_Integration__c> listCaseIntRec = new List<ASF_Case_Integration__c>();
        
        for(ASF_Case_Integration__c caseIntRec : [SELECT Id, Status__c
                                    FROM ASF_Case_Integration__c
                                    WHERE Case__c =: caseRec.Id AND Integration_Ext_Id__c =: prepIntegrations[0].External_Id__c]) {
                                        caseIntRec.Status__c = 'Success';
                                        caseIntRec.Response__c = '{\"STPFlag\":\"SUCCESS\", \"STPDescription\":\"STPDescription\", \"DocumentURL\":\"DocumentURL\"}';                                     
                                 		listCaseIntRec.add(caseIntRec);
                                                  }
       
        update listCaseIntRec;
        Test.stopTest();
        ABFL_Case_Detail__c caseDet = [SELECT Id,Document_URL__c FROM ABFL_Case_Detail__c LIMIT 1];
        Case caseRecord = [SELECT Id, IsClosed, Status
                               FROM Case
                               WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                               LIMIT 1];
            
            Assert.areEqual('Resolved', caseRecord.Status, 'Case status should be Resolved');
        //Assert.areEqual('DocumentURL', caseDet.Document_URL__c);
    }*/
    @isTest
    static void testUpdateSTPFlowWithoutStatusResponseBulk () {
        ASF_Integration__c intg = [SELECT Id,STP_API_Identifier__c FROM ASF_Integration__c LIMIT 1];
        intg.STP_API_Identifier__c = 'BRE_SanctionLetter_Retail';
        update intg;
        List<ASF_Integration__c> prepIntegrations =  ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-01', 'Open');
        Map<Id, List<ASF_Integration__c>> mapIntegrations = new Map<Id, List<ASF_Integration__c>>();
        System.debug('@@@prepIntegrations'+prepIntegrations);
        Case caseRec = [
            SELECT Id, ABFL_Case_Detail__c, Account.Name, Technical_Source__c
            FROM Case
            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01' LIMIT 1
        ];
        caseRec.Source__c = ABFL_Constants.IVR_NO_EMAIL;
        update caseRec;
        
        mapIntegrations.put(caseRec.Id, prepIntegrations);
        Test.startTest();
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> retVal = ASF_IntegrationsController.runIntegration(mapIntegrations, new List<Case>{caseRec});
        
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
        Case caseRecord = [SELECT Id, IsClosed, Status
                               FROM Case
                               WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                               LIMIT 1];
            
       Assert.areEqual('Resolved', caseRecord.Status, 'Case status should be Resolved');
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
        Case caseRecord = [SELECT Id, IsClosed, Status
                               FROM Case
                               WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                               LIMIT 1];
            
       Assert.areEqual('Resolved', caseRecord.Status, 'Case status should be Resolved');
    }
    @isTest
    static void testUpdateSTPFlowWithBusinessDateResponseBulk () {
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
        
        Map<Id, List<ASF_Integration__c>> mapIntegrations = new Map<Id, List<ASF_Integration__c>>();
        mapIntegrations.put(caseRec.Id, prepIntegrations);
        Test.startTest();
        ASF_IntegrationsController.IntegrationWrapper retVal = ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> retValBulk = ASF_IntegrationsController.runIntegration(mapIntegrations, new List<Case>{caseRec});
        
        List<ASF_Case_Integration__c> listCaseIntRec = new List<ASF_Case_Integration__c>();
        
        for(ASF_Case_Integration__c caseIntRec : [SELECT Id, Status__c
                                    FROM ASF_Case_Integration__c
                                    WHERE Case__c =: caseRec.Id AND Integration_Ext_Id__c =: prepIntegrations[0].External_Id__c]) {
                                        caseIntRec.Status__c = 'Success';
                                        caseIntRec.Response__c = '{\"STPFlag\":\"SUCCESS\", \"STPDescription\":\"STPDescription\", \"DocumentURL\":\"DocumentURL\"}';                                     
                                 		listCaseIntRec.add(caseIntRec);
                                                  }
       
        update listCaseIntRec;
        Test.stopTest();
        ABFL_Case_Detail__c caseDet = [SELECT Id,Document_URL__c FROM ABFL_Case_Detail__c LIMIT 1];
        //Assert.areEqual('DocumentURL', caseDet.Document_URL__c);
        Case caseRecord = [SELECT Id, IsClosed, Status
                               FROM Case
                               WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                               LIMIT 1];
            
       Assert.areEqual('Resolved', caseRecord.Status, 'Case status should be Resolved');
    }
    
}
