/*********************************************************
*Class        :  ABCL_CaseIntegratnOutEvntTriggerHelpTest
*Author       :  Udit Singhal
*Created Date :  19/01/2024
*Last Modified:
*Description  :  Test Class for ABCL_CaseIntegratnOutEventTriggerHelper
*********************************************************/
@isTest
public class ABCL_CaseIntegratnOutEvntTriggerHelpTest{
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
        insert new PermissionSetAssignment(
            AssigneeId = userRecord1.Id, 
            PermissionSetId = ps.Id
        );
        Test.stopTest();
        
        System.runAs(userRecord1){
            List<sObject> ls = Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
            List<ASF_Case_Category_Config__c> caseCat = ABFL_TestDataFactory.createCaseCategoryConfig(true);
            
            List<ASF_Case_Stage_Config__c> caseStage = ABFL_TestDataFactory.createCaseStageConfigWithTwoStages(caseCat[0].Id, true);
            
            Account acc = ABFL_TestDataFactory.createAccount();
            ABFL_TestDataFactory.createContact(acc.ID);
            List<ABFL_Case_Detail__c> caseDetList = ABFL_TestDataFactory.createCaseDetail('Corporate', true);
            
            List<ASF_Case_Rule__c> caseRuleList = new List<ASF_Case_Rule__c>();
            ASF_Case_Rule__c stage1StageMovementRule = new ASF_Case_Rule__c();
            
            stage1StageMovementRule.Case_Stage_Config__c = caseStage[0].Id;
            stage1StageMovementRule.Logical_Condition__c = '1';
            stage1StageMovementRule.Order__c = 1;
            stage1StageMovementRule.Type__c = 'Stage Movement';
            caseRuleList.add(stage1StageMovementRule);
            
            
            ASF_Case_Rule__c stage2AssignmentMovementRule = new ASF_Case_Rule__c();
            stage2AssignmentMovementRule.Case_Stage_Config__c = caseStage[0].Id;
            stage2AssignmentMovementRule.Logical_Condition__c = '1';
            stage2AssignmentMovementRule.Order__c = 2;
            stage2AssignmentMovementRule.Type__c = 'Assignment';
            caseRuleList.add(stage2AssignmentMovementRule);
            
            insert caseRuleList;
            
            List<ASF_Case_Rule_Entry__c> caseRuleEntryList = new List<ASF_Case_Rule_Entry__c>();
            ASF_Case_Rule_Entry__c stage1MovementRuleEntry = new ASF_Case_Rule_Entry__c();
            stage1MovementRuleEntry.Number__c = 1;
            stage1MovementRuleEntry.Case_Rule__c = stage1StageMovementRule.Id;
            stage1MovementRuleEntry.Field_Api_Name__c = 'CCC_External_Id__c';
            stage1MovementRuleEntry.Operator__c = '=';
            stage1MovementRuleEntry.Data_Type__c = 'STRING';
            stage1MovementRuleEntry.Value__c = '12345';
            stage1MovementRuleEntry.External_ID__c = 'CRE-STAGEMV-OD-010';
            caseRuleEntryList.add(stage1MovementRuleEntry);
            
            ASF_Case_Rule_Entry__c stage2AssignmentRuleEntry = new ASF_Case_Rule_Entry__c();
            stage2AssignmentRuleEntry.Number__c = 1;
            stage2AssignmentRuleEntry.Case_Rule__c = stage2AssignmentMovementRule.Id;
            stage2AssignmentRuleEntry.Field_Api_Name__c = 'CCC_External_Id__c';
            stage2AssignmentRuleEntry.Operator__c = '=';
            stage2AssignmentRuleEntry.Data_Type__c = 'STRING';
            stage2AssignmentRuleEntry.Value__c = '12345';
            stage2AssignmentRuleEntry.External_ID__c = 'CRE-STAGEMV-OD-020';
            
            
            caseRuleEntryList.add(stage2AssignmentRuleEntry);
            
            insert caseRuleEntryList;
            
            List<Case> cases = ABFL_TestDataFactory.createCaseRecords(1, caseDetList[0].Id, true);
            Case c = cases.get(0);
            c.ownerid = userInfo.getuserId();
            c.AccountId = acc.ID;
            update c;
        }
    }
    
    @isTest
    static void testafterInsertMethod(){
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
            Test.stopTest();
            
            ASF_Case_Integration__c caseIntRec = [SELECT Id, Status__c, Request__c
                                                  FROM ASF_Case_Integration__c
                                                  WHERE Case__c = :caseRec.Id 
                                                  AND Integration_Ext_Id__c = :prepIntegrations[0].External_Id__c];
            Assert.isTrue(String.isNotBlank(caseIntRec.Request__c), 'The request field on the case integration record should not be blank');
        }
    }
    
    @isTest
    static void testafterInsertMethodException(){
        Test.startTest();
        ABCL_CaseIntegratnOutEventTriggerHelper.afterInsertMethod(null);
        Test.stopTest();
        
        List<ABCLLogRecording__c> abclLogsList = [SELECT Id
                                                  FROM ABCLLogRecording__c];
        
        Assert.isTrue(abclLogsList.size() > 0, 'ABCL log recording records should have been created');
    }
    
}