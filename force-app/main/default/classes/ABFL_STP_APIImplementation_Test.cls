/*********************************************************
*Class        :  ABFL_STP_APIImplementation_Test
*Author       :  Udit Singhal
*Created Date :  02/01/2024
*Last Modified:
*Description  :  Test Class for ABFL_STP_APIImplementation
*********************************************************/
@isTest
public class ABFL_STP_APIImplementation_Test{
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id
                                                        FROM Profile
                                                        WHERE name = 'System Administrator'
                                                        LIMIT 1];
    @TestSetup
    static void makeData(){
        Group slaGroup = new Group();
        
        slaGroup = new Group(
            Name = 'SLAManagerGroup', 
            DeveloperName = 'SLAManagerGroup'
        );
        insert slaGroup;
        
        User userRecord1 = new User(
            Alias = 'standt', 
            Email = 'stanrduserEmails@testorg.com', 
            EmailEncodingKey = 'UTF-8', 
            LastName = 'Testing', 
            LanguageLocaleKey = 'en_US', 
            LocaleSidKey = 'en_US', 
            ProfileId = SYSTEMADMIN_PROFILE.Id, 
            TimeZoneSidKey = 'America/Los_Angeles', 
            UserName = 'cdefghijk567@gmail.com', 
            managerGroupId__c = slaGroup.Id
        );
        insert userRecord1;
        
        Test.startTest();
        PermissionSet ps = [SELECT Id 
                            FROM PermissionSet 
                            WHERE Name = 'Admin_User'];
        insert new PermissionSetAssignment(AssigneeId = userRecord1.Id, PermissionSetId = ps.Id);
        Test.stopTest();
        
        System.runAs(userRecord1){
            List<sObject> ls = Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
            List<ASF_Case_Category_Config__c> caseCat = ABFL_TestDataFactory.createCaseCategoryConfig(true);
            
            List<ASF_Case_Stage_Config__c> caseStage = ABFL_TestDataFactory.createCaseStageConfigWithTwoStages(caseCat[0].Id, true);
            ABFL_TestDataFactory.createCaseRuleEntry(caseStage);
            System.debug('caseStage size: '+caseStage.size());
            System.debug('caseStage: '+caseStage);
            Account acc = ABFL_TestDataFactory.createAccount();
            ABFL_TestDataFactory.createContact(acc.ID);
            List<ABFL_Case_Detail__c> caseDetList = ABFL_TestDataFactory.createCaseDetail('Corporate', true);

            List<Case> cases = ABFL_TestDataFactory.createCaseRecords(1, caseDetList[0].Id, true);
            Case c = cases.get(0);
            c.ownerid = userInfo.getuserId();
            c.AccountId = acc.ID;
            update c;
        }
    }
    
    @isTest
    static void testGetDemandAdviceCorpRMNoEmail(){
        User userRecord = [SELECT Id
                           FROM User
                           WHERE UserName = 'cdefghijk567@gmail.com'];
        System.runAs(userRecord){
            List<ASF_Case_Stage_Config__c> caseStageConfigList = [SELECT Id
                                                                  FROM ASF_Case_Stage_Config__c
                                                                  WHERE StageName__c = 'Open'];
            List<ASF_Integration__c> intConfigList = ABFL_TestDataFactory.createIntegration(caseStageConfigList[0].Id, true, 'ABFL_InvokeSTPProcess', 'GetDemandAdvice_Corp');
            List<ASF_Integration__c> prepIntegrations = ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-01', 'Open');
            System.debug('@@@prepIntegrations' + prepIntegrations);
            Case caseRec = [SELECT Id, ABFL_Case_Detail__c, Account.Name, Technical_Source__c, LAN__c, Business_Unit__c
                            FROM Case
                            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                            LIMIT 1];
            
            Test.startTest();
            ASF_IntegrationsController.IntegrationWrapper retVal = ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
            
            
            ASF_Case_Integration__c caseIntRec = [SELECT Id, Status__c
                                                  FROM ASF_Case_Integration__c
                                                  WHERE Case__c = :caseRec.Id AND Integration_Ext_Id__c = :prepIntegrations[0].External_Id__c];
            caseIntRec.Status__c = 'Success';
            caseIntRec.Response__c = '{\"STPFlag\":\"STP_SUCCESS\"}';
            update caseIntRec;
            Test.stopTest();
            
            ABFL_Case_Detail__c caseDetail = [SELECT Id, Closure_Time__c, Autoclosed__c
                                              FROM ABFL_Case_Detail__c
                                              LIMIT 1];
            
            Assert.areEqual(true, caseDetail.Autoclosed__c);
            Assert.isTrue(caseDetail.Closure_Time__c != null);
        }
    }
    
    @isTest
    static void testGetDemandAdviceCorpBranch(){
        User userRecord = [SELECT Id
                           FROM User
                           WHERE UserName = 'cdefghijk567@gmail.com'];
        System.runAs(userRecord){
            List<ASF_Case_Stage_Config__c> caseStageConfigList = [SELECT Id
                                                                  FROM ASF_Case_Stage_Config__c
                                                                  WHERE StageName__c = 'Open'];
            List<ASF_Integration__c> intConfigList = ABFL_TestDataFactory.createIntegration(caseStageConfigList[0].Id, true, 'ABFL_InvokeSTPProcess', 'GetDemandAdvice_Corp');
            List<ASF_Integration__c> prepIntegrations = ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-01', 'Open');
            System.debug('@@@prepIntegrations' + prepIntegrations);
            Case caseRec = [SELECT Id, ABFL_Case_Detail__c, Account.Name, Technical_Source__c, LAN__c, Business_Unit__c
                            FROM Case
                            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                            LIMIT 1];
            
            caseRec.Source__c = 'Branch';
            update caseRec;
            
            Test.startTest();
            ASF_IntegrationsController.IntegrationWrapper retVal = ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
            
            
            ASF_Case_Integration__c caseIntRec = [SELECT Id, Status__c
                                                  FROM ASF_Case_Integration__c
                                                  WHERE Case__c = :caseRec.Id AND Integration_Ext_Id__c = :prepIntegrations[0].External_Id__c];
            
            //Attach file on Case Integration record
            ABFL_GenericFileCreation.ContentWrapper wrapper = new ABFL_GenericFileCreation.ContentWrapper();
            wrapper.fileName = 'Demand_Advice.pdf';
            wrapper.title = 'Demand Advice';
            wrapper.data = Blob.valueOf('Test Data');
            wrapper.parentId = caseIntRec.Id;
            ABFL_GenericFileCreation.createDocument(wrapper);
            
            caseIntRec.Status__c = 'Success';
            caseIntRec.Response__c = '{\"STPFlag\":\"STP_SUCCESS\"}';
            update caseIntRec;
            Test.stopTest();
            
            Case caseRecord = [SELECT Id, IsClosed, Status
                               FROM Case
                               WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                               LIMIT 1];
            
            Assert.areEqual('Closed', caseRecord.Status);
            Assert.areEqual(true, caseRecord.IsClosed);
        }
    }
    
    @isTest
    static void testGetInterestResetLetterCorpRMNoEmail(){
        User userRecord = [SELECT Id
                           FROM User
                           WHERE UserName = 'cdefghijk567@gmail.com'];
        System.runAs(userRecord){
            List<ASF_Case_Stage_Config__c> caseStageConfigList = [SELECT Id
                                                                  FROM ASF_Case_Stage_Config__c
                                                                  WHERE StageName__c = 'Open'];
            List<ASF_Integration__c> intConfigList = ABFL_TestDataFactory.createIntegration(caseStageConfigList[0].Id, true, 'ABFL_InvokeSTPProcess', 'GetInterestResetLetter_Corp');
            List<ASF_Integration__c> prepIntegrations = ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-01', 'Open');
            System.debug('@@@prepIntegrations' + prepIntegrations);
            Case caseRec = [SELECT Id, ABFL_Case_Detail__c, Account.Name, Technical_Source__c, LAN__c, Business_Unit__c
                            FROM Case
                            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                            LIMIT 1];
            
            Test.startTest();
            ASF_IntegrationsController.IntegrationWrapper retVal = ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
            
            
            ASF_Case_Integration__c caseIntRec = [SELECT Id, Status__c
                                                  FROM ASF_Case_Integration__c
                                                  WHERE Case__c = :caseRec.Id AND Integration_Ext_Id__c = :prepIntegrations[0].External_Id__c];
            caseIntRec.Status__c = 'Success';
            caseIntRec.Response__c = '{\"STPFlag\":\"STP_SUCCESS\"}';
            update caseIntRec;
            Test.stopTest();
            
            ABFL_Case_Detail__c caseDetail = [SELECT Id, Closure_Time__c, Autoclosed__c
                                              FROM ABFL_Case_Detail__c
                                              LIMIT 1];
            
            Assert.areEqual(true, caseDetail.Autoclosed__c);
            Assert.isTrue(caseDetail.Closure_Time__c != null);
        }
    }
    
    @isTest
    static void testGetInterestResetLetterCorpBranch(){
        User userRecord = [SELECT Id
                           FROM User
                           WHERE UserName = 'cdefghijk567@gmail.com'];
        System.runAs(userRecord){
            List<ASF_Case_Stage_Config__c> caseStageConfigList = [SELECT Id
                                                                  FROM ASF_Case_Stage_Config__c
                                                                  WHERE StageName__c = 'Open'];
            List<ASF_Integration__c> intConfigList = ABFL_TestDataFactory.createIntegration(caseStageConfigList[0].Id, true, 'ABFL_InvokeSTPProcess', 'GetInterestResetLetter_Corp');
            List<ASF_Integration__c> prepIntegrations = ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-01', 'Open');
            System.debug('@@@prepIntegrations' + prepIntegrations);
            Case caseRec = [SELECT Id, ABFL_Case_Detail__c, Account.Name, Technical_Source__c, LAN__c, Business_Unit__c
                            FROM Case
                            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                            LIMIT 1];
            
            caseRec.Source__c = 'Branch';
            update caseRec;
            
            Test.startTest();
            ASF_IntegrationsController.IntegrationWrapper retVal = ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
            
            
            ASF_Case_Integration__c caseIntRec = [SELECT Id, Status__c
                                                  FROM ASF_Case_Integration__c
                                                  WHERE Case__c = :caseRec.Id 
                                                  AND Integration_Ext_Id__c = :prepIntegrations[0].External_Id__c];
            
            //Attach file on Case Integration record
            ABFL_GenericFileCreation.ContentWrapper wrapper = new ABFL_GenericFileCreation.ContentWrapper();
            wrapper.fileName = 'Demand_Advice.pdf';
            wrapper.title = 'Demand Advice';
            wrapper.data = Blob.valueOf('Test Data');
            wrapper.parentId = caseIntRec.Id;
            ABFL_GenericFileCreation.createDocument(wrapper);
            
            caseIntRec.Status__c = 'Success';
            caseIntRec.Response__c = '{\"STPFlag\":\"STP_SUCCESS\"}';
            update caseIntRec;
            Test.stopTest();
            
            Case caseRecord = [SELECT Id, IsClosed, Status
                               FROM Case
                               WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                               LIMIT 1];
            
            Assert.areEqual('Closed', caseRecord.Status);
            Assert.areEqual(true, caseRecord.IsClosed);
        }
    }
    
    @isTest
    static void testGetRepaymentScheduleCorpRMNoEmail(){
        User userRecord = [SELECT Id
                           FROM User
                           WHERE UserName = 'cdefghijk567@gmail.com'];
        System.runAs(userRecord){
            List<ASF_Case_Stage_Config__c> caseStageConfigList = [SELECT Id
                                                                  FROM ASF_Case_Stage_Config__c
                                                                  WHERE StageName__c = 'Open'];
            List<ASF_Integration__c> intConfigList = ABFL_TestDataFactory.createIntegration(caseStageConfigList[0].Id, true, 'ABFL_InvokeSTPProcess', 'GetRepaymentSchedule_Corp');
            List<ASF_Integration__c> prepIntegrations = ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-01', 'Open');
            System.debug('@@@prepIntegrations' + prepIntegrations);
            Case caseRec = [SELECT Id, ABFL_Case_Detail__c, Account.Name, Technical_Source__c, LAN__c, Business_Unit__c
                            FROM Case
                            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                            LIMIT 1];
            
            Test.startTest();
            ASF_IntegrationsController.IntegrationWrapper retVal = ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
            
            
            ASF_Case_Integration__c caseIntRec = [SELECT Id, Status__c
                                                  FROM ASF_Case_Integration__c
                                                  WHERE Case__c = :caseRec.Id AND Integration_Ext_Id__c = :prepIntegrations[0].External_Id__c];
            caseIntRec.Status__c = 'Success';
            caseIntRec.Response__c = '{\"STPFlag\":\"STP_SUCCESS\"}';
            update caseIntRec;
            Test.stopTest();
            
            ABFL_Case_Detail__c caseDetail = [SELECT Id, Closure_Time__c, Autoclosed__c
                                              FROM ABFL_Case_Detail__c
                                              LIMIT 1];
            
            Assert.areEqual(true, caseDetail.Autoclosed__c);
            Assert.isTrue(caseDetail.Closure_Time__c != null);
        }
    }
    
    @isTest
    static void testGetRepaymentScheduleCorpBranch(){
        User userRecord = [SELECT Id
                           FROM User
                           WHERE UserName = 'cdefghijk567@gmail.com'];
        System.runAs(userRecord){
            List<ASF_Case_Stage_Config__c> caseStageConfigList = [SELECT Id
                                                                  FROM ASF_Case_Stage_Config__c
                                                                  WHERE StageName__c = 'Open'];
            List<ASF_Integration__c> intConfigList = ABFL_TestDataFactory.createIntegration(caseStageConfigList[0].Id, true, 'ABFL_InvokeSTPProcess', 'GetRepaymentSchedule_Corp');
            List<ASF_Integration__c> prepIntegrations = ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-01', 'Open');
            System.debug('@@@prepIntegrations' + prepIntegrations);
            Case caseRec = [SELECT Id, ABFL_Case_Detail__c, Account.Name, Technical_Source__c, LAN__c, Business_Unit__c
                            FROM Case
                            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                            LIMIT 1];
            
            caseRec.Source__c = 'Branch';
            update caseRec;
            
            Test.startTest();
            ASF_IntegrationsController.IntegrationWrapper retVal = ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
            
            
            ASF_Case_Integration__c caseIntRec = [SELECT Id, Status__c
                                                  FROM ASF_Case_Integration__c
                                                  WHERE Case__c = :caseRec.Id AND Integration_Ext_Id__c = :prepIntegrations[0].External_Id__c];
            
            //Attach file on Case Integration record
            ABFL_GenericFileCreation.ContentWrapper wrapper = new ABFL_GenericFileCreation.ContentWrapper();
            wrapper.fileName = 'Demand_Advice.pdf';
            wrapper.title = 'Demand Advice';
            wrapper.data = Blob.valueOf('Test Data');
            wrapper.parentId = caseIntRec.Id;
            ABFL_GenericFileCreation.createDocument(wrapper);
            
            caseIntRec.Status__c = 'Success';
            caseIntRec.Response__c = '{\"STPFlag\":\"STP_SUCCESS\"}';
            update caseIntRec;
            Test.stopTest();
            
            Case caseRecord = [SELECT Id, IsClosed, Status
                               FROM Case
                               WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                               LIMIT 1];
            
            Assert.areEqual('Closed', caseRecord.Status);
            Assert.areEqual(true, caseRecord.IsClosed);
        }
    }
    
    @isTest
    static void testGetWelcomeLetterCorpRMNoEmail(){
        User userRecord = [SELECT Id
                           FROM User
                           WHERE UserName = 'cdefghijk567@gmail.com'];
        System.runAs(userRecord){
            List<ASF_Case_Stage_Config__c> caseStageConfigList = [SELECT Id
                                                                  FROM ASF_Case_Stage_Config__c
                                                                  WHERE StageName__c = 'Open'];
            List<ASF_Integration__c> intConfigList = ABFL_TestDataFactory.createIntegration(caseStageConfigList[0].Id, true, 'ABFL_InvokeSTPProcess', 'GetWelcomeLetter_Corp');
            List<ASF_Integration__c> prepIntegrations = ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-01', 'Open');
            System.debug('@@@prepIntegrations' + prepIntegrations);
            Case caseRec = [SELECT Id, ABFL_Case_Detail__c, Account.Name, Technical_Source__c, LAN__c, Business_Unit__c
                            FROM Case
                            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                            LIMIT 1];
            
            Test.startTest();
            ASF_IntegrationsController.IntegrationWrapper retVal = ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
            
            
            ASF_Case_Integration__c caseIntRec = [SELECT Id, Status__c
                                                  FROM ASF_Case_Integration__c
                                                  WHERE Case__c = :caseRec.Id AND Integration_Ext_Id__c = :prepIntegrations[0].External_Id__c];
            caseIntRec.Status__c = 'Success';
            caseIntRec.Response__c = '{\"STPFlag\":\"STP_SUCCESS\"}';
            update caseIntRec;
            Test.stopTest();
            
            ABFL_Case_Detail__c caseDetail = [SELECT Id, Closure_Time__c, Autoclosed__c
                                              FROM ABFL_Case_Detail__c
                                              LIMIT 1];
            
            Assert.areEqual(true, caseDetail.Autoclosed__c);
            Assert.isTrue(caseDetail.Closure_Time__c != null);
        }
    }
    
    @isTest
    static void testGetWelcomeLetterCorpBranch(){
        User userRecord = [SELECT Id
                           FROM User
                           WHERE UserName = 'cdefghijk567@gmail.com'];
        System.runAs(userRecord){
            List<ASF_Case_Stage_Config__c> caseStageConfigList = [SELECT Id
                                                                  FROM ASF_Case_Stage_Config__c
                                                                  WHERE StageName__c = 'Open'];
            List<ASF_Integration__c> intConfigList = ABFL_TestDataFactory.createIntegration(caseStageConfigList[0].Id, true, 'ABFL_InvokeSTPProcess', 'GetWelcomeLetter_Corp');
            List<ASF_Integration__c> prepIntegrations = ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-01', 'Open');
            System.debug('@@@prepIntegrations' + prepIntegrations);
            Case caseRec = [SELECT Id, ABFL_Case_Detail__c, Account.Name, Technical_Source__c, LAN__c, Business_Unit__c
                            FROM Case
                            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                            LIMIT 1];
            
            caseRec.Source__c = 'Branch';
            update caseRec;
            
            Test.startTest();
            ASF_IntegrationsController.IntegrationWrapper retVal = ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
            
            
            ASF_Case_Integration__c caseIntRec = [SELECT Id, Status__c
                                                  FROM ASF_Case_Integration__c
                                                  WHERE Case__c = :caseRec.Id AND Integration_Ext_Id__c = :prepIntegrations[0].External_Id__c];
            
            //Attach file on Case Integration record
            ABFL_GenericFileCreation.ContentWrapper wrapper = new ABFL_GenericFileCreation.ContentWrapper();
            wrapper.fileName = 'Demand_Advice.pdf';
            wrapper.title = 'Demand Advice';
            wrapper.data = Blob.valueOf('Test Data');
            wrapper.parentId = caseIntRec.Id;
            ABFL_GenericFileCreation.createDocument(wrapper);
            
            caseIntRec.Status__c = 'Success';
            caseIntRec.Response__c = '{\"STPFlag\":\"STP_SUCCESS\"}';
            update caseIntRec;
            Test.stopTest();
            
            Case caseRecord = [SELECT Id, IsClosed, Status
                               FROM Case
                               WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                               LIMIT 1];
            
            Assert.areEqual('Closed', caseRecord.Status);
            Assert.areEqual(true, caseRecord.IsClosed);
        }
    }
    
    @isTest
    static void testInterestDebitNoteCorpBranch(){
        User userRecord = [SELECT Id
                           FROM User
                           WHERE UserName = 'cdefghijk567@gmail.com'];
        System.runAs(userRecord){
            List<ASF_Case_Stage_Config__c> caseStageConfigList = [SELECT Id
                                                                  FROM ASF_Case_Stage_Config__c
                                                                  WHERE StageName__c = 'Open'];
            List<ASF_Integration__c> intConfigList = ABFL_TestDataFactory.createIntegration(caseStageConfigList[0].Id, true, 'ABFL_InvokeSTPProcess', 'InterestDebitNote_Corp');
            List<ASF_Integration__c> prepIntegrations = ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-01', 'Open');
            System.debug('@@@prepIntegrations' + prepIntegrations);
            Case caseRec = [SELECT Id, ABFL_Case_Detail__c, Account.Name, Technical_Source__c, LAN__c, Business_Unit__c
                            FROM Case
                            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                            LIMIT 1];
            
            caseRec.Source__c = 'Branch';
            update caseRec;
            
            ABFL_Case_Detail__c caseDetail = new ABFL_Case_Detail__c();
            caseDetail.Id = caseRec.ABFL_Case_Detail__c;
            caseDetail.From_Date__c = Datetime.now().dateGMT();
            caseDetail.To_Date__c = DateTime.now().addDays(2).dateGMT();
            update caseDetail;
            
            Test.startTest();
            ASF_IntegrationsController.IntegrationWrapper retVal = ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
            
            
            ASF_Case_Integration__c caseIntRec = [SELECT Id, Status__c
                                                  FROM ASF_Case_Integration__c
                                                  WHERE Case__c = :caseRec.Id AND Integration_Ext_Id__c = :prepIntegrations[0].External_Id__c];
            
            //Attach file on Case Integration record
            ABFL_GenericFileCreation.ContentWrapper wrapper = new ABFL_GenericFileCreation.ContentWrapper();
            wrapper.fileName = 'Demand_Advice.pdf';
            wrapper.title = 'Demand Advice';
            wrapper.data = Blob.valueOf('Test Data');
            wrapper.parentId = caseIntRec.Id;
            ABFL_GenericFileCreation.createDocument(wrapper);
            
            caseIntRec.Status__c = 'Success';
            caseIntRec.Response__c = '{\"STPFlag\":\"STP_SUCCESS\"}';
            update caseIntRec;
            Test.stopTest();
            
            Case caseRecord = [SELECT Id, IsClosed, Status
                               FROM Case
                               WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                               LIMIT 1];
            
            Assert.areEqual('Closed', caseRecord.Status);
            Assert.areEqual(true, caseRecord.IsClosed);
        }
    }
    
    @isTest
    static void testInterestDebitNoteCorpRMNoEmail(){
        User userRecord = [SELECT Id
                           FROM User
                           WHERE UserName = 'cdefghijk567@gmail.com'];
        System.runAs(userRecord){
            List<ASF_Case_Stage_Config__c> caseStageConfigList = [SELECT Id
                                                                  FROM ASF_Case_Stage_Config__c
                                                                  WHERE StageName__c = 'Open'];
            List<ASF_Integration__c> intConfigList = ABFL_TestDataFactory.createIntegration(caseStageConfigList[0].Id, true, 'ABFL_InvokeSTPProcess', 'InterestDebitNote_Corp');
            List<ASF_Integration__c> prepIntegrations = ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-01', 'Open');
            System.debug('@@@prepIntegrations' + prepIntegrations);
            Case caseRec = [SELECT Id, ABFL_Case_Detail__c, Account.Name, Technical_Source__c, LAN__c, Business_Unit__c
                            FROM Case
                            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                            LIMIT 1];
            
            ABFL_Case_Detail__c caseDetail = new ABFL_Case_Detail__c();
            caseDetail.Id = caseRec.ABFL_Case_Detail__c;
            caseDetail.From_Date__c = Datetime.now().dateGMT();
            caseDetail.To_Date__c = DateTime.now().addDays(2).dateGMT();
            update caseDetail;
            
            Test.startTest();
            ASF_IntegrationsController.IntegrationWrapper retVal = ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
            
            
            ASF_Case_Integration__c caseIntRec = [SELECT Id, Status__c
                                                  FROM ASF_Case_Integration__c
                                                  WHERE Case__c = :caseRec.Id AND Integration_Ext_Id__c = :prepIntegrations[0].External_Id__c];
            caseIntRec.Status__c = 'Success';
            caseIntRec.Response__c = '{\"STPFlag\":\"STP_SUCCESS\"}';
            update caseIntRec;
            Test.stopTest();
            
            ABFL_Case_Detail__c updatedCaseDetail = [SELECT Id, Closure_Time__c, Autoclosed__c
                                                     FROM ABFL_Case_Detail__c
                                                     LIMIT 1];
            
            Assert.areEqual(true, updatedCaseDetail.Autoclosed__c);
            Assert.isTrue(updatedCaseDetail.Closure_Time__c != null);
        }
    }
    
    @isTest
    static void testSOACorpBranch(){
        User userRecord = [SELECT Id
                           FROM User
                           WHERE UserName = 'cdefghijk567@gmail.com'];
        System.runAs(userRecord){
            List<ASF_Case_Stage_Config__c> caseStageConfigList = [SELECT Id
                                                                  FROM ASF_Case_Stage_Config__c
                                                                  WHERE StageName__c = 'Open'];
            List<ASF_Integration__c> intConfigList = ABFL_TestDataFactory.createIntegration(caseStageConfigList[0].Id, true, 'ABFL_InvokeSTPProcess', 'SOA_Corp');
            List<ASF_Integration__c> prepIntegrations = ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-01', 'Open');
            System.debug('@@@prepIntegrations' + prepIntegrations);
            Case caseRec = [SELECT Id, ABFL_Case_Detail__c, Account.Name, Technical_Source__c, LAN__c, Business_Unit__c
                            FROM Case
                            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                            LIMIT 1];
            
            caseRec.Source__c = 'Branch';
            update caseRec;
            
            ABFL_Case_Detail__c caseDetail = new ABFL_Case_Detail__c();
            caseDetail.Id = caseRec.ABFL_Case_Detail__c;
            caseDetail.From_Date__c = Datetime.now().dateGMT();
            caseDetail.To_Date__c = DateTime.now().addDays(2).dateGMT();
            update caseDetail;
            
            Test.startTest();
            ASF_IntegrationsController.IntegrationWrapper retVal = ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
            
            
            ASF_Case_Integration__c caseIntRec = [SELECT Id, Status__c
                                                  FROM ASF_Case_Integration__c
                                                  WHERE Case__c = :caseRec.Id AND Integration_Ext_Id__c = :prepIntegrations[0].External_Id__c];
            
            //Attach file on Case Integration record
            ABFL_GenericFileCreation.ContentWrapper wrapper = new ABFL_GenericFileCreation.ContentWrapper();
            wrapper.fileName = 'Demand_Advice.pdf';
            wrapper.title = 'Demand Advice';
            wrapper.data = Blob.valueOf('Test Data');
            wrapper.parentId = caseIntRec.Id;
            ABFL_GenericFileCreation.createDocument(wrapper);
            
            caseIntRec.Status__c = 'Success';
            caseIntRec.Response__c = '{\"STPFlag\":\"STP_SUCCESS\"}';
            update caseIntRec;
            Test.stopTest();
            
            Case caseRecord = [SELECT Id, IsClosed, Status
                               FROM Case
                               WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                               LIMIT 1];
            
            Assert.areEqual('Closed', caseRecord.Status);
            Assert.areEqual(true, caseRecord.IsClosed);
        }
    }
    
    @isTest
    static void testSOACorpRMNoEmail(){
        User userRecord = [SELECT Id
                           FROM User
                           WHERE UserName = 'cdefghijk567@gmail.com'];
        System.runAs(userRecord){
            List<ASF_Case_Stage_Config__c> caseStageConfigList = [SELECT Id
                                                                  FROM ASF_Case_Stage_Config__c
                                                                  WHERE StageName__c = 'Open'];
            List<ASF_Integration__c> intConfigList = ABFL_TestDataFactory.createIntegration(caseStageConfigList[0].Id, true, 'ABFL_InvokeSTPProcess', 'SOA_Corp');
            List<ASF_Integration__c> prepIntegrations = ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-01', 'Open');
            System.debug('@@@prepIntegrations' + prepIntegrations);
            Case caseRec = [SELECT Id, ABFL_Case_Detail__c, Account.Name, Technical_Source__c, LAN__c, Business_Unit__c
                            FROM Case
                            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                            LIMIT 1];
            
            ABFL_Case_Detail__c caseDetail = new ABFL_Case_Detail__c();
            caseDetail.Id = caseRec.ABFL_Case_Detail__c;
            caseDetail.From_Date__c = Datetime.now().dateGMT();
            caseDetail.To_Date__c = DateTime.now().addDays(2).dateGMT();
            update caseDetail;
            
            Test.startTest();
            ASF_IntegrationsController.IntegrationWrapper retVal = ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
            
            
            ASF_Case_Integration__c caseIntRec = [SELECT Id, Status__c
                                                  FROM ASF_Case_Integration__c
                                                  WHERE Case__c = :caseRec.Id AND Integration_Ext_Id__c = :prepIntegrations[0].External_Id__c];
            caseIntRec.Status__c = 'Success';
            caseIntRec.Response__c = '{\"STPFlag\":\"STP_SUCCESS\"}';
            update caseIntRec;
            Test.stopTest();
            
            ABFL_Case_Detail__c updatedCaseDetail = [SELECT Id, Closure_Time__c, Autoclosed__c
                                                     FROM ABFL_Case_Detail__c
                                                     LIMIT 1];
            
            Assert.areEqual(true, updatedCaseDetail.Autoclosed__c);
            Assert.isTrue(updatedCaseDetail.Closure_Time__c != null);
        }
    }
    
    @isTest
    static void testSOACorpException(){
        User userRecord = [SELECT Id
                           FROM User
                           WHERE UserName = 'cdefghijk567@gmail.com'];
        System.runAs(userRecord){
            List<ASF_Case_Stage_Config__c> caseStageConfigList = [SELECT Id
                                                                  FROM ASF_Case_Stage_Config__c
                                                                  WHERE StageName__c = 'Open'];
            List<ASF_Integration__c> intConfigList = ABFL_TestDataFactory.createIntegration(caseStageConfigList[0].Id, true, 'ABFL_InvokeSTPProcess', 'SOA_Corp');
            List<ASF_Integration__c> prepIntegrations = ASF_IntegrationsController.getAllIntegrations('CCC-CC-CCLTD-01', 'Open');
            System.debug('@@@prepIntegrations' + prepIntegrations);
            Case caseRec = [SELECT Id, ABFL_Case_Detail__c, Account.Name, Technical_Source__c, LAN__c, Business_Unit__c
                            FROM Case
                            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                            LIMIT 1];
            
            caseRec.Source__c = 'Branch';
            update caseRec;
            
            Test.startTest();
            ASF_IntegrationsController.IntegrationWrapper retVal = ASF_IntegrationsController.runIntegration(prepIntegrations[0], caseRec);
            Test.stopTest();
            
            Assert.areEqual('Error', retVal.status);
            Assert.areEqual(ABFL_Constants.BLANK_DATE_FIELD, retVal.response);
        }
    }
    
    @isTest
    static void testcloseSTPCaseFromFlow(){
        User userRecord = [SELECT Id
                           FROM User
                           WHERE UserName = 'cdefghijk567@gmail.com'];
        System.runAs(userRecord){
            Case caseRec = [SELECT Id, ABFL_Case_Detail__c, Account.Name, Technical_Source__c, LAN__c, Business_Unit__c
                            FROM Case
                            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                            LIMIT 1];
            Test.startTest();
            ABFL_InvokeSTPProcess.closeSTPCaseFromFlow(new List<Id>{caseRec.ABFL_Case_Detail__c});
            Test.stopTest();
            
            Case updatedCaseRecord = [SELECT Id, IsClosed, Stage__c
                                      FROM Case
                                      WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                                      LIMIT 1];
            
            Assert.isTrue(updatedCaseRecord.IsClosed);
            Assert.areEqual('Resolved', updatedCaseRecord.Stage__c);
        }
    }
}