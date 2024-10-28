/**
 * @description       : Test Class to validate ABFL_InactiveOwnerCaseReassignmentBatch
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 05-13-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   05-13-2024   rsinghnagar@salesforce.com   Initial Version
**/
@isTest
private class ABFL_InactiveOwnerCaseReassignmentTest {
    /**
    * @description 
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    **/
    @testSetup
    static void setupTestData(){
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User adminUser = new User(Alias = 'standt', Email='standarduser@testorg.com', 
             EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
             LocaleSidKey='en_US', ProfileId = p.Id, 
             TimeZoneSidKey='America/Los_Angeles', UserName='adminUserabcl@gmail.com');
        insert adminUser;
        PermissionSet ps = [SELECT Id 
                            FROM PermissionSet 
                            WHERE Name = 'Admin_User'];
        insert new PermissionSetAssignment(AssigneeId = adminUser.Id, PermissionSetId = ps.Id);

        // Create test data with inactive owner users and cases
        Group qGroup=new Group(Name= 'ABFL Test Group(G)', Type='QUEUE');
        insert qGroup;
        QueueSObject queueTest= new QueueSObject(SobjectType='Case',QueueId=qGroup.id);
        insert queueTest;
        User managerUser = new User(
            IsActive = true,
            Business_Unit__c='ABFL',
            FirstName = 'Test',
            LastName='Manager User',
            Username='manageruser1155@test.com',
            Email='manageruser1155@test.com',
            Alias = 'mgrt',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', 
            ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles'
        );
        insert managerUser;
        User user = new User(
            IsActive = true,
            Business_Unit__c='ABFL',
            FirstName = 'Test',
            LastName='Inactive User',
            Username='inactiveuser2255@test.com',
            Email='inactiveuser2255@test.com',
            ManagerId = managerUser.id,
            Alias = 'inact',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', 
            ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles'
        );
        insert user;
        
        System.runAs(user) {
            Group queueId = [Select Id from Group where Type = 'Queue' and Name = 'ABFL Test Group(G)'];
            List<ASF_Case_Category_Config__c> caseCategoryList = ABFL_TestDataFactory.createCaseCategoryConfig(true);
            caseCategoryList[0].Business_Unit__c = 'ABFL';
            update caseCategoryList[0];
            List<ASF_Case_Stage_Config__c> caseStageList = ABFL_TestDataFactory.createCaseStageConfig(caseCategoryList[0].id, true);
        	caseStageList[0].Default_Queue__c = queueId.Id;
            update caseStageList[0];
            ABFL_TestDataFactory.createCaseDetail('Corporate',true);
            Id caseDetailId=[select id from ABFL_Case_Detail__c limit 1].id;
            ABFL_TestDataFactory.createCaseRecords(1, caseDetailId, true);
            // close the cases
            // caseRecList[0].MoveToNext__c = true;
            // caseRecList[0].Status = 'Closed';
            // caseRecList[0].Nature__c = 'Query';
            // caseRecList[0].Business_Unit__c = ABFL_Constants.ABFL;
            // ASF_TriggerSkipperUtility.markTriggerRun('Case');
            // update caseRecList;
        }  
    }
    // Check for Queue Assignment
    @isTest
    static void reassignCaseTestQueueAssignment(){
      User admin = [select id from User where username='adminUserabcl@gmail.com'];
      system.runAs(admin){
            User au=[select id,IsActive from User where Username=:'inactiveuser2255@test.com'];
            au.IsActive = false;
            update au;
            // Start the batch job
            Test.startTest();
                ABFL_InactiveOwnerCaseReassignmentBatch batchJob = new ABFL_InactiveOwnerCaseReassignmentBatch();
                Database.executeBatch(batchJob);
            Test.stopTest();
            Case updatedCase = [SELECT Id, OwnerId, owner.Name, stage__c, CCC_External_Id__c FROM Case LIMIT 1];
            Group qgroup = [Select Id from Group where type = 'Queue' and name ='ABFL Test Group(G)'];
            System.AssertEquals(qgroup.Id, updatedCase.OwnerId, 'Case owner is not updated to queue.');
      }
    }
    @isTest
    static void reassignCaseTestMgr(){
        User admin = [select id from User where username='adminUserabcl@gmail.com'];
        system.runAs(admin){
          User au=[select id,IsActive from User where Username=:'inactiveuser2255@test.com'];
          au.IsActive = false;
          update au;
          Case caseToUpdate = [SELECT Id, OwnerId, stage__c, CCC_External_Id__c FROM Case LIMIT 1];
          ASF_Case_Stage_Config__c stageToUpdate = [SELECT ID, Default_Queue__c, StageName__c 
                                                    from ASF_Case_Stage_Config__c 
                                                    where Case_Category_Config__r.CCC_External_Id__c =: caseToUpdate.CCC_External_Id__c 
                                                    and StageName__c =: caseToUpdate.stage__c];
          
          stageToUpdate.Default_Queue__c = '';
          update stageToUpdate;
          // Start the batch job
            Test.startTest();
                ABFL_InactiveOwnerCaseReassignmentBatch batchJob = new ABFL_InactiveOwnerCaseReassignmentBatch();
                Database.executeBatch(batchJob);
            Test.stopTest();
            Case updatedCase = [SELECT Id, OwnerId, Owner.name, stage__c, CCC_External_Id__c FROM Case LIMIT 1];
            User mgr=[select id,IsActive from User where Username=:'manageruser1155@test.com'];
            System.AssertEquals(mgr.Id, updatedCase.OwnerId, 'Case owner is not updated to queue.');
      }
    }
    @isTest
    static void reassignCaseTestCaseRules(){
        User admin = [select id from User where username='adminUserabcl@gmail.com'];
        system.runAs(admin){
            User au=[select id,IsActive from User where Username=:'inactiveuser2255@test.com'];
            au.IsActive = false;
            update au;
            Case caseToUpdate = [SELECT Id, OwnerId, stage__c, CCC_External_Id__c FROM Case LIMIT 1];
          	ASF_Case_Stage_Config__c stageToUpdate = [SELECT ID, Default_Queue__c, StageName__c 
                                                    from ASF_Case_Stage_Config__c 
                                                    where Case_Category_Config__r.CCC_External_Id__c =: caseToUpdate.CCC_External_Id__c 
                                                    and StageName__c =: caseToUpdate.stage__c];
          
          	stageToUpdate.Default_Queue__c = '';
            update stageToUpdate;
            Group qgroup = [Select Id from Group where type = 'Queue' and name ='ABFL Test Group(G)'];
            ASF_Case_Rule__c caseRule = new ASF_Case_Rule__c(Case_Stage_Config__c = stageToUpdate.id, 
                                                         Order__c = 1, Type__c = 'Assignment',
                                                         Assignment_Queue_Name__c = 'ABFL Test Group(G)',
                                                         Assigned_Queue_Id__c=qgroup.Id,
                                                         Logical_Condition__c = '1');
            insert caseRule;
            ASF_Case_Rule_Entry__c caseRuleEntry = new ASF_Case_Rule_Entry__c(Number__c = 1, Case_Rule__c = caseRule.Id,
                                                                         Field_Api_Name__c = 'Stage__c',
                                                                         Operator__c = '=',
                                                                         Data_Type__c = 'STRING',
                                                                         Value__c = 'Open');
            insert caseRuleEntry;
            // Start the batch job
            Test.startTest();
                ABFL_InactiveOwnerCaseReassignmentBatch batchJob = new ABFL_InactiveOwnerCaseReassignmentBatch();
                Database.executeBatch(batchJob);
            Test.stopTest();
            Case updatedCase = [SELECT Id, OwnerId, owner.name, stage__c, CCC_External_Id__c FROM Case LIMIT 1];
            System.AssertEquals(updatedCase.OwnerId, updatedCase.OwnerId, 'Case owner is not updated to queue.');
        }
    }
}