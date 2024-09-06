/*********************************************************
*Class          :   ABFL_Util
*Author         :   Udit Singhal
*Created Date   :   25-06-2024
*Last Modified  :   25-06-2024
*@description   :   Test class for ABFL_Util 1
*********************************************************/
@isTest
public with sharing class ABFL_Util_Test{
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
            Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
            SLA_Threshold_Warning__c  thresholdController = SLA_Threshold_Warning__c.getOrgDefaults();
            thresholdController.Customer_Email_buffer_hours__c=56;
            update thresholdController;
            
            List<ASF_Case_Category_Config__c> caseCat = ABFL_TestDataFactory.createCaseCategoryConfig(true);
            
            List<ASF_Case_Stage_Config__c> caseStage = ABFL_TestDataFactory.createCaseStageConfigWithTwoStages(caseCat[0].Id, true);
            ABFL_TestDataFactory.createCaseRuleEntry(caseStage);
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
    static void testResolveCaseOnUTRPopulation(){
        User userRecord = [SELECT Id
                           FROM User
                           WHERE UserName = 'cdefghijk567@gmail.com'];
        System.runAs(userRecord){
            Case caseRec = [SELECT Id, ABFL_Case_Detail__c, ABFL_Case_Detail__r.UTRNo__c, Account.Name, Technical_Source__c, LAN__c, Business_Unit__c
                            FROM Case
                            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                            LIMIT 1];
            
            caseRec.Source__c = 'Branch';
            update caseRec;
            
            Test.startTest();
            ABFL_Case_Detail__c caseDetail = new ABFL_Case_Detail__c(Id = caseRec.ABFL_Case_Detail__c);
            caseDetail.UTRNo__c = '1234';
            update caseDetail;
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