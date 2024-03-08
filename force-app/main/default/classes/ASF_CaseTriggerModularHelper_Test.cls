@isTest
public class ASF_CaseTriggerModularHelper_Test {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];

    @TestSetup
    public static void setup(){
        
        

        User manager1 = new User(profileId = SYSTEMADMIN_PROFILE.Id, email = 'manager1@salesforce.com',
        Username = 'manager1'+String.valueOf(Integer.valueof((Math.random() * 10)))+'@mock.com',
        alias = 'manager1', lastname = 'lastname', emailencodingkey = 'UTF-8', localesidkey = 'en_US',
        languagelocalekey = 'en_US', timezonesidkey = 'GMT',IsActive = true);
        
        insert manager1;

        User objUser = new User(profileId = SYSTEMADMIN_PROFILE.Id, email = 'test0@salesforce.com',
                           Username = 'Test'+String.valueOf(Integer.valueof((Math.random() * 10)))+'@mock.com',
                           alias = 'uqusr', lastname = 'lastname', emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                           languagelocalekey = 'en_US', timezonesidkey = 'GMT',IsActive = true,ManagerId=manager1.Id,Business_Unit__c='ABHFL');
        insert objUser;
        
        insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
        Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
        Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
        ASF_TestDataFactory.createCaseRecords(1);
    }
    
    @isTest
    public static void test_populateFrameworkFieldsForCase1(){
        ASF_TestDataFactory.createCaseCategoryConfig();
        Test.startTest();
        List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsert();
        casesList[0].Technical_Source__c = 'LWC';
        ASF_BulkCaseProcessorUtility.isBulkProcessing = true;
        insert casesList;

        ASF_TestDataFactory.createCaseCategoryConfigWithSTP();
        List<Case> casesListAPI = ASF_TestDataFactory.createCaseRecordsWithoutInsert();
        //casesListAPI[0].Technical_Source__c = 'API';
        casesListAPI[0].Attachment_Status__c = 'Completed';
        casesListAPI[0].CCC_External_Id__c = 'CCC-CC-CCLTD-02-STP';
        insert casesListAPI;

        casesList[0].CCC_External_Id__c = 'CCC-CC-CCLTD-02-STP';
        update casesList;
        Test.stopTest();
        List<Case> frameworkCase2 = [Select Id, Subject from Case where RecordType.Name = 'Framework'];
        Assert.areEqual(4, frameworkCase2.size(), 'Expected 4, Not found');
    }

    @IsTest
    static void test_checkAndProcessReopenCase1(){
        ASF_TestDataFactory.createCaseCategoryConfigWithSTP();
        ASF_Case_Category_Config__c config = [Select Id from ASF_Case_Category_Config__c limit 1];
        config.Reopen_Style__c = 'Move To First Stage';
        update config;
        List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsertSTP();
        casesList[0].Technical_Source__c = 'LWC';
        insert casesList;
        casesList[0].Stage__c = 'Closed';
        update casesList;
        Test.startTest();
        casesList[0].Reopened_DateTime__c = System.now();
        casesList[0].Reopened__c = true;
        ASF_TriggerSkipperUtility.resetTriggerRun('Case');
        update casesList;
        Test.stopTest();
        Case caseRec = [Select Id, Stage__c from Case LIMIT 1];
        //Assert.areEqual('Pending with Initiator', caseRec.Stage__c, 'Stage is not Pending with initiator');
    }
    @IsTest
    static void test_checkAndProcessReopenCase2(){
        ASF_TestDataFactory.createCaseCategoryConfigWithSTP();
        ASF_Case_Category_Config__c config = [Select Id from ASF_Case_Category_Config__c limit 1];
        config.Reopen_Style__c = 'Reopen Stage With Movement';
        update config;
        List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsertSTP();
        casesList[0].Technical_Source__c = 'LWC';
        insert casesList;
        Test.startTest();
        //casesList[0].Stage__c = 'Resolved';
        //update casesList;
        casesList[0].Reopened_DateTime__c = System.now();
        casesList[0].Reopened__c = true;
        ASF_TriggerSkipperUtility.resetTriggerRun('Case');
        update casesList;
        Test.stopTest();
        Case caseRec = [Select Id, Stage__c from Case LIMIT 1];
        //Assert.areEqual('Reopened', caseRec.Stage__c, 'Stage is not Reopened');
    }

    @IsTest
    static void test_checkAndProcessMoveToNextStage(){
        ASF_TestDataFactory.createCaseCategoryConfigWithSTP();
        Test.startTest();
        List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsertSTP();
        //casesList[0].Technical_Source__c = 'API';
        casesList[0].MoveToNext__c = true;
        insert casesList;

        ASF_TriggerSkipperUtility.markTriggerRun('Case');
        casesList[0].MoveToNext__c = false;
        update casesList;
        ASF_TriggerSkipperUtility.resetTriggerRun('Case');

        casesList[0].MoveToNext__c = true;
        update casesList;

        Test.stopTest();
    }

    @IsTest
    static void test_checkAndProcessManualStageMovement(){
        ASF_TestDataFactory.createCaseCategoryConfigWithSTP();
        Test.startTest();
        List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsertSTP();
        //casesList[0].Technical_Source__c = 'API';
        insert casesList;

        casesList[0].Stage__c = 'In Progress with Recovery';
        casesList[0].pending_clarification__c = true;
        update casesList;

        casesList[0].Stage__c = 'Pending with Initiator';
        ASF_TriggerSkipperUtility.resetTriggerRun('Case');
        update casesList;
        Test.stopTest();
        Case caseRec = [Select Id, Stage__c from Case LIMIT 1];
        Assert.areEqual('Pending with Initiator', caseRec.Stage__c, 'Stage should come back to Pending with initator');
    }

    @IsTest
    static void test_checkAndPopulateOwnerOnCaseCreation(){
        Test.startTest();
        Case newCase = new Case(Origin = 'Web', Subject = 'Test Case Creation', Stage__c = 'Pending with Initiator',
                                SLA_Target_1__c = 'test@salesforce.com', CSAT__c = 20, DB_Hours__c = 5, has_CheckLists__c=TRUE, Reopen_Days__c=30 );
            newCase.Stage_SLA_1__c = System.now();
            newCase.Stage_SLA_2__c = System.now()+1;
            newCase.Stage_SLA_3__c = System.now()+2;
            newCase.CCC_External_Id__c = 'CCC-CC-CCLTD-01';
        	newCase.Technical_Source__c = 'API';
        	newCase.Source__c = 'Branch';
        	newCase.Is_Approval_Stage__c = true;
            newCase.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
            insert newCase;
        
            newCase.Is_Approval_Stage__c = true;
            ASF_TriggerSkipperUtility.resetTriggerRun('Case');
            update newCase;
        
        Test.stopTest();
        Case caseRec = [Select Id, Stage__c, OwnerId from Case LIMIT 1];
        //Assert.isTrue(String.valueOf(caseRec.OwnerId).startsWith('00G'), 'should be assigned to a queue');
    }

    @IsTest
    static void test_onCreateCloseServiceRequest(){
        ASF_TestDataFactory.createCaseCategoryConfigWithSTP();
        Test.startTest();
        List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsertSTP();
        //casesList[0].Technical_Source__c = 'API';
        casesList[0].OnCreateCloseSR__c = true;
        insert casesList;
        
        Test.stopTest();
    }

    @IsTest
    static void test_rejectFrameworkCaseBeforeUpdate(){
        ASF_TestDataFactory.createCaseCategoryConfigWithSTP();
        Test.startTest();
        List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsertSTP();
        //casesList[0].Technical_Source__c = 'API';
        insert casesList;
        casesList[0].Reject_Case__c = true;
        ASF_TriggerSkipperUtility.resetTriggerRun('Case');
        update casesList;
        Test.stopTest();
    }
    @IsTest
    static void test_rejectFrameworkCaseBeforeUpdate2(){
        ASF_TestDataFactory.createCaseCategoryConfigWithSTP();
        Test.startTest();
        List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsertSTP();
        //casesList[0].Technical_Source__c = 'API';
        insert casesList;
        casesList[0].Is_Duplicate__c = true;
        casesList[0].Is_Approval_Stage__c = true;
        ASF_TriggerSkipperUtility.resetTriggerRun('Case');
        update casesList;
        
        Test.stopTest();
    }

    @IsTest
    static void test_validateOwnerCheckerStage(){
        ASF_TestDataFactory.createCaseCategoryConfig();
        ASF_Case_Stage_Config__c caseStgConfig = [Select Id from ASF_Case_Stage_Config__c where Order__c = 1 LIMIT 1];
        caseStgConfig.Has_Same_Owner_Check__c = true;
        caseStgConfig.Owner_Check_Stages__c = 'Pending with Initiator';
        update caseStgConfig;
        Test.startTest();
        List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsert();
        casesList[0].Technical_Source__c = 'LWC';
        casesList[0].CCC_External_Id__c = 'CCC-CC-CCLTD-11';
        insert casesList;

        casesList[0].OwnerId = UserInfo.getUserId();
        ASF_TriggerSkipperUtility.resetTriggerRun('Case');
        try{
            update casesList;
        }catch(DMLException e){
            Assert.isTrue(e.getDmlMessage(0) == Label.Maker_Owner_Error_Message, 'Should encounter error');
        }
        Test.stopTest();
        
    }

    @IsTest
    static void test_caseOwnerChangeValidation(){
        User objUser = [select id from user where email = 'test0@salesforce.com'];
        insert new PermissionSetAssignment(AssigneeId=objUser.Id,
                                   PermissionSetId=[Select Id from PermissionSet where Name = 'Admin_User' LIMIT 1].Id);
        
        
        Test.startTest();
        System.runAs(objUser){
            ASF_TestDataFactory.createCaseCategoryConfigWithSTP();
            List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsertSTP();
            //casesList[0].Technical_Source__c = 'API';
            insert casesList;

            casesList[0].OwnerId = UserInfo.getUserId();
            ASF_TriggerSkipperUtility.resetTriggerRun('Case');
            try{
                update casesList;
            }catch(DMLException e){
                Assert.isTrue(e.getDmlMessage(0) != null, 'Should encounter error');
            }
        }
        Test.stopTest();
        
    } 
    @IsTest
    static void test_caseOwnerChangeAccessValidation(){
        
        Test.startTest();
        List<Case> casesList = [select id, ownerId from case LIMIT 1];
        User objUser = [select Id, managerGroupId__c,managerId,manager.Id,manager.manager.Id,
                                                   manager.manager.manager.id,manager.manager.manager.manager.id,
                                                   manager.manager.manager.manager.manager.id 
                                                   from user where id !=: casesList[0].ownerId LIMIT 1];
        User objUser1 = new User(profileId = SYSTEMADMIN_PROFILE.Id, email = 'test0@salesforce.com',
                           Username = 'Test1'+String.valueOf(Integer.valueof((Math.random() * 10)))+'@mock.com',
                           alias = 'uquss', lastname = 'lastname', emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                           languagelocalekey = 'en_US', timezonesidkey = 'GMT',IsActive = true);
        insert objUser1;
        
        //casesList[0].ownerId = objUser.Id;
         Group queue = new Group(Name = 'Test Case Queue', Type = 'Queue');
        insert queue;
        casesList[0].ownerId = queue.Id;
        ASF_TriggerSkipperUtility.resetTriggerRun('Case');
        try{
            System.runAs(objUser1){
                update casesList;
            }
        }catch(DMLException e){
           	Assert.isTrue(e.getDmlMessage(0) == Label.ASF_Owner_Change_Access_Val_Msg, 'Should encounter error');
        }
        Test.stopTest();        
    }
    
    @IsTest
    static void test_caseOwnerChangeAccessValidation2(){
         Group queue = new Group(Name = 'Test Case Queue', Type = 'Queue');
        insert queue;
        
    	QueueSobject queueSobject = new QueueSobject(
            QueueId = queue.Id,
            SobjectType = 'Case'
        );
        insert queueSobject;
        
        Test.startTest();

        User objUser1 = new User(profileId = SYSTEMADMIN_PROFILE.Id, email = 'test0@salesforce.com',
                           Username = 'Test1'+String.valueOf(Integer.valueof((Math.random() * 10)))+'@mock.com',
                           alias = 'uquss', lastname = 'lastname', emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                           languagelocalekey = 'en_US', timezonesidkey = 'GMT',IsActive = true);
        insert objUser1;
        
        ASF_TriggerSkipperUtility.resetTriggerRun('Case');
        try{
            System.runAs(objUser1){
                List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsert();
                casesList[0].Technical_Source__c = 'LWC';
                casesList[0].CCC_External_Id__c = 'CCC-CC-CCLTD-11';
                casesList[0].ownerId = queue.Id;
                insert casesList;
                
                casesList[0].ownerId = objUser1.Id;
                
                update casesList;
                Map<Id, Case> oldMap = new Map<Id, Case>([select id, ownerId from case]);
                ASF_CaseTriggerModularHelper.caseOwnerChangeValidation(casesList, oldMap);
                casesList[0].ownerId = queue.Id;
                update casesList;
                casesList[0].ownerId = objUser1.Id;
                update casesList;
                
            }
        }catch(DMLException e){
            //Assert.isTrue(e.getDmlMessage(0) == Label.ASF_Owner_Change_Access_Val_Msg, 'Should encounter error');
        }
        Test.stopTest();        
    }

    @IsTest
    static void test_validateCCCOnUpdate(){
        ASF_TestDataFactory.createCaseCategoryConfig();
        List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsert();
        casesList[0].Technical_Source__c = 'LWC';
        insert casesList;
        ASF_TestDataFactory.createCaseCategoryConfigWithSTP();
        Test.startTest();
        ASF_TriggerSkipperUtility.resetTriggerRun('Case');
        casesList[0].CCC_External_Id__c = 'CCC-CC-CCLTD-02-STP';
        update casesList;
        Test.stopTest();
        
    }

    /*
    @IsTest
    static void test_lwcCaseValidationBeforeInsertUpdate(){
        ASF_TestDataFactory.createCaseCategoryConfigWithSTP();
        
        List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsertSTP();
        casesList[0].Technical_Source__c = 'API';
        insert casesList;
        Test.startTest();
        casesList[0].Stage__c = 'In Progress with Recovery';
        ASF_TriggerSkipperUtility.resetTriggerRun('Case');
        try{
            update casesList;
        }catch(DMLException e){
            Assert.isTrue(e.getDmlMessage(0) == 'Stage entry rule not meeting', 'Should encounter error');
        }
        Test.stopTest();
        
    }
    */


}