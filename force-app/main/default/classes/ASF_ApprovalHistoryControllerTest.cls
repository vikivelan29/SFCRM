@isTest
private class ASF_ApprovalHistoryControllerTest {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    @testSetup static void methodName() {
        
        UserRole role1 = new UserRole(DeveloperName = 'MyCustomRole1', Name = 'My Role 1');
        insert role1;
        
        UserRole role2 = new UserRole(DeveloperName = 'MyCustomRole2', Name = 'My Role 2', ParentRoleId = role1.Id);
        insert role2;
        
        User userRecord = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                                   EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
                                   TimeZoneSidKey='America/Los_Angeles', UserName='abcdefghijk56@gmail.com', UserRoleId = role2.Id);
        insert userRecord;
        id currentUserId = UserInfo.getUserId();
        System.runAs(userRecord){
            insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                                Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                                Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
            
            Account acc =new Account();
            acc.Name= 'TestAcc';
            //  acc.CRN__c ='32122';
            Insert acc;
            
            ASF_Case_Category_Config__c ccc = new ASF_Case_Category_Config__c();
            ccc.Type__c = 'tes';
            ccc.CCC_External_Id__c = '12345';
            ccc.Business_Unit__c = 'ABFL';
            ccc.Sub_Type__c = 'TDC Refund';
            ccc.Overall_Case_Closure_SLA__c = 10;
            insert ccc;
            
            Asset ast = new Asset();
            ast.accountId = acc.id;
            //ast.Financial_Account_Number__c ='2333423';
            ast.Name = 'aas';
            insert ast;
            
            Contact con = new Contact();
            con.Lastname ='Test con';
            con.AccountId = acc.Id;
            con.Email = 'test@test.com';
            con.Phone = '8329673314';
            insert con;
            
            ASF_Case_Stage_Config__c stage1 = new ASF_Case_Stage_Config__c();
            stage1.Case_Category_Config__c = ccc.Id;
            stage1.Order__c = 1;
            stage1.StageName__c  = 'New';
            stage1.Stage_SLA_1__c = 1;
            stage1.Status_Mapping__c = 'New';
            // stage1.Stage_SLA_3__c = 3;
            stage1.SLA_Target_1_Type__c = 'Manager';
            stage1.Query_Fields__c = 'Id,Stage__c';
            stage1.Manual_Stage__c = false;
            
            insert stage1;
            
            list<Case> cList =new List<Case>();
            Case caseRec = new Case();
            caseRec.AccountId =acc.Id;
            caseRec.Subject ='testSubject';
            caseRec.Description ='testdescription';
            caseRec.Stage__c ='New';
            caseRec.Status ='New';
            caseRec.CCC_External_Id__c = '12345';
            //caseRec.City__c ='Mumbai';
            Insert caseRec;
            
            ASF_Case_Approv__c ca = new ASF_Case_Approv__c();
            ca.Approver_01__c  = currentUserId;
            ca.Approver_02__c  = currentUserId;
            ca.Approver_03__c  = currentUserId;
            ca.Approver_04__c  = currentUserId;
            ca.Approver_05__c  = currentUserId;
            ca.Approval_Type__c  = 'Parallel - All to approve';
            ca.SR__c  = caseRec.Id;
            try{
                insert ca;
            }
            catch(exception e){
                throw e;
            }
            
            Group grp = new Group();
            grp.Name = 'Test GRP';
            grp.Type='Queue';
            insert grp;
            
            QueuesObject qs = new QueuesObject();
            qs.QueueId = grp.Id;
            qs.SobjectType = 'ASF_Case_Approv__c';
            insert qs;
            
            GroupMember gm = new GroupMember();
            gm.GroupId = grp.Id;
            gm.UserOrGroupId = userRecord.Id;
            insert gm;
            
        }
        
        
        
    }
    
    @isTest static void searchUsersEmptyListTest(){
        List<ASF_LookupSearchResult> result = ASF_ApprovalHistoryController.searchUsers(null);
        System.assertEquals(0,result.size());
    }
    @isTest static void searchQueuesTest(){
        Group grp = [SELECT ID,Name FROM Group WHERE Type='Queue' LIMIT 1];
        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = grp.Id;
        Test.setFixedSearchResults(fixedSearchResults);
        List<ASF_LookupSearchResult> result = ASF_ApprovalHistoryController.searchQueues(grp.Name);
        System.assertNotEquals(0,result.size());
    }
    
    @isTest static void searchUsersNotEmptyListTest(){
        List<User> users = [SELECT Id, FirstName, LastName FROM User WHERE UserRole.ParentRoleId != null LIMIT 1];
        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = users.get(0).Id;
        Test.setFixedSearchResults(fixedSearchResults);
        List<ASF_LookupSearchResult> result = ASF_ApprovalHistoryController.searchUsers(users.get(0).LastName);
        System.assertNotEquals(0,result.size());
    }
    
    @isTest static void getApprovalHistoryTest(){
        List<ASF_Case_Approv__c> cas = [SELECT Id FROM ASF_Case_Approv__c LIMIT 1];
        ASF_ApprovalHistoryController.getApprovalHistory(cas.get(0).Id);
        ASF_ApprovalHistoryController.getCaseApprovalRecord(cas.get(0).Id);
        System.assertEquals(1,cas.size());
    }
    @isTest static void processStepTest_Rejected(){
        List<User> users = [select Id, FirstName, LastName FROM User LIMIT 1];
        List<ASF_Case_Approv__c> cas = [SELECT Id FROM ASF_Case_Approv__c LIMIT 1];
        
        ASF_ApprovalHistoryController.processStep(cas.get(0).Id, 'comments', null, 'Reject');
        
        List<ProcessInstance> processInstances = [SELECT Id,SubmittedById, ProcessDefinition.Name , (SELECT ID, ProcessNodeId,  
                                                                                                     StepStatus,Comments,TargetObjectId,ActorId,CreatedById,IsDeleted,IsPending  
                                                                                                     ,OriginalActorId,ProcessInstanceId,RemindersSent,CreatedDate, Actor.Name,  
                                                                                                     OriginalActor.Name , ProcessNode.Name FROM StepsAndWorkitems order by IsPending DESC, CreatedDate DESC )   
                                                  FROM ProcessInstance  order by CreatedDate DESC LIMIT 1];
        
        try{
            ASF_ApprovalHistoryController.getStepIdAfterApproval(processInstances.get(0).Id,cas.get(0).Id,'Rejected');
            
            ASF_ApprovalHistoryController.ApprovalHistory retVal = ASF_ApprovalHistoryUtil.populateApprovalHistorySteps(processInstances, cas.get(0).Id);
            System.assertEquals(1,processInstances.size());
        }
        catch(exception e){
            throw e;
        }
        
        
    }
    @isTest static void processStepTest_Recalled(){
        List<User> users = [select Id, FirstName, LastName FROM User LIMIT 1];
        List<ASF_Case_Approv__c> cas = [SELECT Id FROM ASF_Case_Approv__c LIMIT 1];
        
        ASF_ApprovalHistoryController.processStep(cas.get(0).Id, 'comments', null, 'Removed');
        
        List<ProcessInstance> processInstances = [SELECT Id,SubmittedById, ProcessDefinition.Name , (SELECT ID, ProcessNodeId,  
                                                                                                     StepStatus,Comments,TargetObjectId,ActorId,CreatedById,IsDeleted,IsPending  
                                                                                                     ,OriginalActorId,ProcessInstanceId,RemindersSent,CreatedDate, Actor.Name,  
                                                                                                     OriginalActor.Name , ProcessNode.Name FROM StepsAndWorkitems order by IsPending DESC, CreatedDate DESC )   
                                                  FROM ProcessInstance  order by CreatedDate DESC LIMIT 1];
        
        try{
            ASF_ApprovalHistoryController.getStepIdAfterApproval(processInstances.get(0).Id,cas.get(0).Id,'Removed');
            
            ASF_ApprovalHistoryController.ApprovalHistory retVal = ASF_ApprovalHistoryUtil.populateApprovalHistorySteps(processInstances, cas.get(0).Id);
            System.assertEquals(1,processInstances.size());
        }
        catch(exception e){
            throw e;
        }
        
        
    }
    
    @isTest static void processStepTest(){
        List<User> users = [select Id, FirstName, LastName FROM User LIMIT 1];
        List<ASF_Case_Approv__c> cas = [SELECT Id FROM ASF_Case_Approv__c LIMIT 1];
        
        ASF_ApprovalHistoryController.processStep(cas.get(0).Id, 'comments', null, 'Approve');
        
        List<ProcessInstance> processInstances = [SELECT Id,SubmittedById, ProcessDefinition.Name , (SELECT ID, ProcessNodeId,  
                                                                                                     StepStatus,Comments,TargetObjectId,ActorId,CreatedById,IsDeleted,IsPending  
                                                                                                     ,OriginalActorId,ProcessInstanceId,RemindersSent,CreatedDate, Actor.Name,  
                                                                                                     OriginalActor.Name , ProcessNode.Name FROM StepsAndWorkitems order by IsPending DESC, CreatedDate DESC )   
                                                  FROM ProcessInstance  order by CreatedDate DESC LIMIT 1];
        
        try{
            ASF_ApprovalHistoryController.getStepIdAfterApproval(processInstances.get(0).Id,cas.get(0).Id,'Approved');
            
            ASF_ApprovalHistoryController.ApprovalHistory retVal = ASF_ApprovalHistoryUtil.populateApprovalHistorySteps(processInstances, cas.get(0).Id);
            System.assertEquals(1,processInstances.size());
        }
        catch(exception e){
            throw e;
        }
        
        
    } 
    @isTest static void reassign_to_OtherUser(){
        List<User> users = [SELECT ID FROM User LIMIT 1 OFFSET 3];
        List<ASF_Case_Approv__c> cas = [SELECT Id FROM ASF_Case_Approv__c LIMIT 1];
        
        List<ProcessInstanceWorkItem> items = [SELECT Id,ActorId,ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = : cas.get(0).Id];
        ProcessInstanceWorkItem piwi = new ProcessInstanceWorkItem(Id = items.get(0).Id);
        piwi.ActorId  = users.get(0).Id;
        update piwi;
        
        List<ProcessInstance> processInstances = [SELECT Id,SubmittedById, ProcessDefinition.Name , (SELECT ID, ProcessNodeId,  
                                                                                                     StepStatus,Comments,TargetObjectId,ActorId,CreatedById,IsDeleted,IsPending  
                                                                                                     ,OriginalActorId,ProcessInstanceId,RemindersSent,CreatedDate, Actor.Name,  
                                                                                                     OriginalActor.Name , ProcessNode.Name FROM StepsAndWorkitems order by IsPending DESC, CreatedDate DESC )   
                                                  FROM ProcessInstance  order by CreatedDate DESC LIMIT 1];
        
        ASF_ApprovalHistoryController.ApprovalHistory retVal = ASF_ApprovalHistoryUtil.populateApprovalHistorySteps(processInstances, cas.get(0).Id);
        System.assertEquals(1,processInstances.size());
    }
    @isTest static void processStepTest_OtherUser(){
        List<User> users = [select Id, FirstName, LastName FROM User LIMIT 1];
        User u = [SELECT ID FROM User WHERE Email='standarduser@testorg.com' LIMIT 1];
        System.runAs(u){
            List<ASF_Case_Approv__c> cas = [SELECT Id FROM ASF_Case_Approv__c LIMIT 1];
            
            ASF_ApprovalHistoryController.processStep(cas.get(0).Id, 'comments', null, 'Approve');
            
            List<ProcessInstance> processInstances = [SELECT Id,SubmittedById, ProcessDefinition.Name , (SELECT ID, ProcessNodeId,  
                                                                                                         StepStatus,Comments,TargetObjectId,ActorId,CreatedById,IsDeleted,IsPending  
                                                                                                         ,OriginalActorId,ProcessInstanceId,RemindersSent,CreatedDate, Actor.Name,  
                                                                                                         OriginalActor.Name , ProcessNode.Name FROM StepsAndWorkitems order by IsPending DESC, CreatedDate DESC )   
                                                      FROM ProcessInstance  order by CreatedDate DESC LIMIT 1];
            
            try{
                ASF_ApprovalHistoryController.getStepIdAfterApproval(processInstances.get(0).Id,cas.get(0).Id,'Approved');
                
                ASF_ApprovalHistoryController.ApprovalHistory retVal = ASF_ApprovalHistoryUtil.populateApprovalHistorySteps(processInstances, cas.get(0).Id);
                System.assertEquals(1,processInstances.size());
            }
            catch(exception e){
                throw e;
            }
        }
        
        
        
    }
    /*
@isTest static void reassignStepTest(){
try{
List<User> users = [SELECT Id, FirstName, LastName FROM User LIMIT 1];
List<Account> accounts = [SELECT Id FROM Account LIMIT 1];
ApprovalHistoryController.reassignStep(accounts.get(0).Id,users.get(0).Id );
}catch(Exception e){
}

}*/
    @isTest static void approvalHighlightedPanelTest(){
        ProcessInstanceWorkItem piwi = [SELECT ID,ProcessInstanceId,OriginalActor.Name,Actor.Name FROM ProcessInstanceWorkItem LIMIT 1];
        ASF_ApprovalHistoryController.getHighlightedPanelFields(piwi.Id);
    }
    @isTest static void populateApprovalHistoryStepsTest(){
        List<ProcessInstance> processInstances = [SELECT Id,SubmittedById, ProcessDefinition.Name , (SELECT ID, ProcessNodeId,  
                                                                                                     StepStatus,Comments,TargetObjectId,ActorId,CreatedById,IsDeleted,IsPending  
                                                                                                     ,OriginalActorId,ProcessInstanceId,RemindersSent,CreatedDate, Actor.Name,  
                                                                                                     OriginalActor.Name , ProcessNode.Name FROM StepsAndWorkitems order by IsPending DESC, CreatedDate DESC )   
                                                  FROM ProcessInstance  order by CreatedDate DESC LIMIT 1];
        ASF_Case_Approv__c ca = [SELECT ID FROM ASF_Case_Approv__c ORDER BY CreatedDate DESC LIMIT 1];
        ASF_ApprovalHistoryController.ApprovalHistory retVal = ASF_ApprovalHistoryUtil.populateApprovalHistorySteps(processInstances, ca.Id);
        System.assertEquals(1,processInstances.size());
    }
    @isTest static void getStepIdAfterApprovalTest(){
        List<ProcessInstance> processInstances = [SELECT Id,SubmittedById, ProcessDefinition.Name , (SELECT ID, ProcessNodeId,  
                                                                                                     StepStatus,Comments,TargetObjectId,ActorId,CreatedById,IsDeleted,IsPending  
                                                                                                     ,OriginalActorId,ProcessInstanceId,RemindersSent,CreatedDate, Actor.Name,  
                                                                                                     OriginalActor.Name , ProcessNode.Name FROM StepsAndWorkitems order by IsPending DESC, CreatedDate DESC )   
                                                  FROM ProcessInstance  order by CreatedDate DESC LIMIT 1];
        
    }
    @isTest static void getIdTest(){
        List<ASF_LookupSearchResult> clsArr = new List<ASF_LookupSearchResult>();
        ASF_LookupSearchResult cls = new ASF_LookupSearchResult(UserInfo.getUserId(),'','','','');
        clsArr.add(cls);
        clsArr.add(new ASF_LookupSearchResult(UserInfo.getUserId(),'TEST','','',''));
        clsArr.sort();
        cls.getId();
        cls.getSObjectType();
        cls.getIcon();
        cls.getTitle();
        cls.getSubtitle();
        
    }
}