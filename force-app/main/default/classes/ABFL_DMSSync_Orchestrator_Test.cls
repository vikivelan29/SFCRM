/**
 * @description       :
 * @author            : rsinghnagar@salesforce.com
 * @group             :
 * @last modified on  : 07-01-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   06-28-2024   rsinghnagar@salesforce.com   Initial Version
**/
@isTest
public class ABFL_DMSSync_Orchestrator_Test {
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
            c.Type_Text__c = 'Test';
            c.Nature__c = 'Test';
            c.Sub_Type_Text__c = 'Test';
            update c;
        }
    }

    @isTest
    static void testTransferABFLCaseFilesToDMS(){
        User userRecord = [SELECT Id
                           FROM User
                           WHERE UserName = 'cdefghijk5657123456@gmail.com'];
        System.runAs(userRecord){
            Case caseRec = [SELECT Id, ABFL_Case_Detail__c, Account.Name, Technical_Source__c, LAN__c, Business_Unit__c, CCC_External_Id__c
                            FROM Case
                            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                            LIMIT 1];

            //Attach file on Case Integration record
            ABFL_GenericFileCreation.ContentWrapper wrapper = new ABFL_GenericFileCreation.ContentWrapper();
            wrapper.fileName = 'Demand_Advice.pdf';
            wrapper.title = 'Demand Advice';
            wrapper.data = Blob.valueOf('Test Data');
            wrapper.parentId = caseRec.Id;
            ABFL_GenericFileCreation.createDocument(wrapper);

            ABFL_InvokeSTPProcess.closeSTPCaseFromFlow(new List<Id>{caseRec.ABFL_Case_Detail__c});

            Case updatedCaseRecord = [SELECT Id, IsClosed, Stage__c
                                      FROM Case
                                      WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                                      LIMIT 1];

            Assert.isTrue(updatedCaseRecord.IsClosed, 'Case should have been closed');
            Assert.areEqual('Resolved', updatedCaseRecord.Stage__c, 'Case stage should have been marked as "Resolved"');

            Test.startTest();
            ABFL_DMSSync_Orchestrator.transferABFLCaseFilesToDMS(new List<Id>{updatedCaseRecord.Id});
            Test.stopTest();

            List<DMS_Files__c> dmsFilesList = [SELECT Id FROM DMS_Files__c];

            Assert.isTrue(dmsFilesList.size() > 0, 'DMS file record should have been inserted');
        }
    }

    @isTest
    static void testsyncDMSFilesManually(){
        User userRecord = [SELECT Id
                           FROM User
                           WHERE UserName = 'cdefghijk5657123456@gmail.com'];
        System.runAs(userRecord){
            Case caseRec = [SELECT Id, ABFL_Case_Detail__c, Account.Name, Technical_Source__c, LAN__c, Business_Unit__c, CCC_External_Id__c
                            FROM Case
                            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                            LIMIT 1];

            //Attach file on Case Integration record
            ABFL_GenericFileCreation.ContentWrapper wrapper = new ABFL_GenericFileCreation.ContentWrapper();
            wrapper.fileName = 'Demand_Advice.pdf';
            wrapper.title = 'Demand Advice';
            wrapper.data = Blob.valueOf('Test Data');
            wrapper.parentId = caseRec.Id;
            ABFL_GenericFileCreation.createDocument(wrapper);

            ABFL_InvokeSTPProcess.closeSTPCaseFromFlow(new List<Id>{caseRec.ABFL_Case_Detail__c});

            Case updatedCaseRecord = [SELECT Id, IsClosed, Stage__c
                                      FROM Case
                                      WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                                      LIMIT 1];

            ABFL_DMSSync_Orchestrator.transferABFLCaseFilesToDMS(new List<Id>{updatedCaseRecord.Id});

            List<DMS_Files__c> dmsFilesList = [SELECT Id FROM DMS_Files__c];

            Test.startTest();
            ABFL_DMSSync_Orchestrator.ResponseWrapper res = ABFL_DMSSync_Orchestrator.syncDMSFilesManually(new List<Id>{dmsFilesList[0].Id});
            Test.stopTest();

            Assert.isTrue(res.isSuccess == true, 'The response should be a success');

        }
    }

    @isTest
    static void testTransferABFLCaseFilesToDMSException(){
        Test.startTest();
        ABFL_DMSSync_Orchestrator.ResponseWrapper res = ABFL_DMSSync_Orchestrator.syncDMSFilesManually(new List<Id>{});
        Test.stopTest();

        Assert.isTrue(res.isSuccess == false, 'The response should not be a success');
        Assert.isTrue(res.errorMsg == ABFL_Constants.DMS_GENERIC_ERROR, 'The error msg should be:- '+ABFL_Constants.DMS_GENERIC_ERROR);
    }

    @isTest
    static void testsyncDMSFilesManuallyException2(){
        User userRecord = [SELECT Id
                           FROM User
                           WHERE UserName = 'cdefghijk5657123456@gmail.com'];
        System.runAs(userRecord){
            Case caseRec = [SELECT Id, ABFL_Case_Detail__c, Account.Name, Technical_Source__c, LAN__c, Business_Unit__c, CCC_External_Id__c
                            FROM Case
                            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                            LIMIT 1];

            //Attach file on Case Integration record
            ABFL_GenericFileCreation.ContentWrapper wrapper = new ABFL_GenericFileCreation.ContentWrapper();
            wrapper.fileName = 'Demand_Advice.pdf';
            wrapper.title = 'Demand Advice';
            wrapper.data = Blob.valueOf('Test Data');
            wrapper.parentId = caseRec.Id;
            ABFL_GenericFileCreation.createDocument(wrapper);

            ABFL_InvokeSTPProcess.closeSTPCaseFromFlow(new List<Id>{caseRec.ABFL_Case_Detail__c});
            ABFL_DMSSync_Orchestrator.transferABFLCaseFilesToDMS(new List<Id>{caseRec.Id});
            List<DMS_Files__c> dmsFilesList = [SELECT Id, status__c FROM DMS_Files__c];
            dmsFilesList[0].status__c = ABFL_Constants.CANCELED;

            update dmsFilesList;

            Test.startTest();
            ABFL_DMSSync_Orchestrator.ResponseWrapper res = ABFL_DMSSync_Orchestrator.syncDMSFilesManually(new List<Id>{dmsFilesList[0].Id});
            Test.stopTest();

            Assert.isTrue(res.isSuccess == false, 'The response should not be a success');
            Assert.isTrue(res.errorMsg == ABFL_Constants.INVALID_DMS_RECORD_ERROR, 'The error msg should be:- '+ABFL_Constants.INVALID_DMS_RECORD_ERROR);
        }
    }
}
