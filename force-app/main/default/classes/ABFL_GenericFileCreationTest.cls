/*********************************************************
*Class        :  ABFL_GenericFileCreationTest
*Author       :  Rajender Kumar
*Created Date :  14/05/2024
*Last Modified:
*Description  :  Test Class for ABFL_GenericFileCreation
*********************************************************/
@isTest
public class ABFL_GenericFileCreationTest{
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
            UserName = 'cdefghijk5657123456@gmail.com', 
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
            SLA_Threshold_Warning__c  thresholdController = SLA_Threshold_Warning__c.getOrgDefaults();
            decimal thirdStageThreshold = thresholdController.Stage_SLA_Threshold_3__c ; 
            thresholdController.Customer_Email_buffer_hours__c=56;
            update thresholdController;
            
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
    static void testGetInterestResetLetterCorpBranch(){
        User userRecord = [SELECT Id
                           FROM User
                           WHERE UserName = 'cdefghijk5657123456@gmail.com'];
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
            caseIntRec.Response__c = '{\"STPFlag\":\"SUCCESS\"}';
            update caseIntRec;
            Test.stopTest();
            
            Case caseRecord = [SELECT Id, IsClosed, Status
                               FROM Case
                               WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                               LIMIT 1];
            
            Assert.areEqual('Resolved', caseRecord.Status, 'Case status should be Resolved');
            Assert.areEqual(true, caseRecord.IsClosed, 'Is closed field should have been marked as True');
        }
    }
}