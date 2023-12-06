/*********************************************************
*Class        :  UserQueueDetails_Test
*Author       :  Ankush Mundada
*Description  :  Test Class for CaseCommentTrigger
*********************************************************/
@isTest public class ASF_UserQueueDetails_Test {
    
    @testSetup static void setup() {
        list<User> u = ASF_SRTestData.createUsers('Super_Admin',1);
        System.runAs(u[0]){
            
            ASF_Case_Category_Config__c ccc = new ASF_Case_Category_Config__c();
            ccc.Type__c = 'tes';
            ccc.CCC_External_Id__c = '12345';
            ccc.Business_Unit__c = 'ABFL';
            ccc.Sub_Type__c = 'TDC Refund';
            ccc.Overall_Case_Closure_SLA__c = 10;
            insert ccc;
            ASF_Case_Stage_Config__c stage1 = new ASF_Case_Stage_Config__c();
            stage1.Case_Category_Config__c = ccc.Id;
            stage1.Order__c = 1;
            stage1.StageName__c = 'New';
            stage1.Stage_SLA_1__c = 1;
            stage1.Status_Mapping__c = 'New';
            stage1.SLA_Target_1_Type__c = 'Manager';
            stage1.Query_Fields__c = 'Id,Stage__c';
            stage1.Manual_Stage__c = false;
            
            insert stage1;
            insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                                Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                                Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
            Case caser = new Case();
            caser.Origin = 'Email';
            caser.Subject = 'SR Case';
            caser.Stage__c = 'New';
            caser.CCC_External_Id__c = '12345';
            insert caser;
            CaseComment cc = new CaseComment();
            cc.ParentId = caser.Id;
            cc.CommentBody = 'Test class comment';
            insert cc;
        }
        
    }
    
    @isTest static void testGetUserQueueDetails() {
        
        User u = [Select Id,Name from User WHERE LastName='TestUser5srDetail0' limit 1];
        Case c = [Select Id from Case limit 1];
        
        Task t = new Task();
        t.OwnerId = u.Id;
        t.Subject='Test Task';
        t.Status='Open';
        t.Priority='Normal';
        t.WhatId = c.Id;
        insert t;
        Test.startTest();
        	Boolean ownerFlag = ASF_UserQueueDetails.getUserQueueDetails(u.Id,c.Id);
        	Assert.areEqual(ownerFlag,true);
        Test.stopTest();
    }
    
    @isTest static void testGetUserQueueDetailsForCompletedTasks() {
        
        User u = [Select Id,Name from User WHERE LastName='TestUser5srDetail0' limit 1];
        Case c = [Select Id from Case limit 1];
        
        Task t = new Task();
        t.OwnerId = u.Id;
        t.Subject='Test Task';
        t.Status='Completed';
        t.Priority='Normal';
        t.WhatId = c.Id;
        insert t;
        
        Test.startTest();
        	Boolean ownerFlag = ASF_UserQueueDetails.getUserQueueDetails(u.Id,c.Id);
        	Assert.areEqual(ownerFlag,false);
        Test.stopTest();
    }
    
    @isTest static void testGetUserQueueDetailsNegative() {
        
        User u = [Select Id,Name from User WHERE LastName='TestUser5srDetail0' limit 1];
        Case c = [Select Id from Case limit 1];
        
        Task t = new Task();
        t.OwnerId = UserInfo.getUserId();
        t.Subject='Test Task';
        t.Status='Completed';
        t.Priority='Normal';
        t.WhatId = c.Id;
        insert t;
        Test.startTest();
        	Boolean ownerFlag = ASF_UserQueueDetails.getUserQueueDetails(u.Id,c.Id);
        	Assert.areEqual(ownerFlag,false);
        Test.stopTest();
    }
}