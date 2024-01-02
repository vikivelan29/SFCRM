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
        Group SLAGroup = new Group();
        
        SLAGroup = new Group(
            Name = 'SLAManagerGroup', 
            DeveloperName = 'SLAManagerGroup'
        );
        insert SLAGroup;
        
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
            managerGroupId__c = SLAGroup.Id
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
            
            List<ASF_Integration__c> intConfigList = ABFL_TestDataFactory.createIntegration(caseStage[0].Id, true, 'ABFL_InvokeSTPProcess', 'GetDemandAdvice_Corp');
            
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
    static void testSFlowWithCaseSource_RM_NoEmail(){
        User userRecord = [SELECT Id
                           FROM User
                           WHERE UserName = 'cdefghijk567@gmail.com'];
        System.runAs(userRecord){
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
    static void testSFlowWithCaseSource_Branch(){
        User userRecord = [SELECT Id
                           FROM User
                           WHERE UserName = 'cdefghijk567@gmail.com'];
        System.runAs(userRecord){
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
            ABFL_Constants constTemp = new ABFL_Constants();
            Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUnTyped(constTemp.tempGetDemandAdviceResponse);
            ABFL_GenericFileCreation.ContentWrapper wrapper = new ABFL_GenericFileCreation.ContentWrapper();
            wrapper.fileName = 'Demand_Advice.pdf';
            wrapper.title = 'Demand Advice';
            wrapper.data = EncodingUtil.base64Decode((String)jsonMap.get('PDFData'));
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
}