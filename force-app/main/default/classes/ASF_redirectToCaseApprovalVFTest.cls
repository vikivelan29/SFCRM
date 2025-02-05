@isTest
public class ASF_redirectToCaseApprovalVFTest {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];

    @testSetup static void methodName() {
        User userRecord = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                                   EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
                                   TimeZoneSidKey='America/Los_Angeles', UserName='abcdefghijk56@gmail.com', isActive = true);
        insert userRecord;
        id currentUserId = UserInfo.getUserId();
        System.runAs(userRecord){
            Account acc =new Account();
            acc.Name= 'TestAcc';
            acc.Client_Code__c ='32122';
            Insert acc;
            // list<Case> cList =new List<Case>();
        	Case caseRec = new Case();
            caseRec.AccountId =acc.Id;
            caseRec.Subject ='testSubject';
            caseRec.Description ='testdescription';
            caseRec.Stage__c ='New';
            caseRec.Stage__c ='New';
            //caseRec.City__c ='Mumbai';
            Insert caseRec;
            
            ASF_Case_Approv__c ca = new ASF_Case_Approv__c ();
            ca.Approver_01__c = currentUserId;
            ca.Approver_02__c = currentUserId;
            ca.Approver_03__c = currentUserId;            
            ca.Approver_04__c = currentUserId;
            ca.Approver_05__c = currentUserId;
            ca.Approval_Type__c = 'Parallel - All to approve';
            ca.SR__c = caseRec.Id;
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
            
            ASF_Case_Category_Config__c ccc = new ASF_Case_Category_Config__c();
            ccc.Type__c = 'tes';
            ccc.CCC_External_Id__c = '12345';
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
            stage1.Stage_External_Id__c = 'STG_1';
            stage1.Default_Queue_user_Name__c = 'ABHFL Email Non-Financial Team';
    
            insert stage1;         
        }
       
    }
    @isTest
    private static void inittest(){
        User objUser = [Select Id from User WHERE ProfileId = :SYSTEMADMIN_PROFILE.Id AND ISACTIVE = true LIMIT 1];
        system.runAs(objUser){
            test.startTest();
            ASF_Case_Approv__c ca = [SELECT ID FROM ASF_Case_Approv__c LIMIT 1];
            List<ProcessInstanceWorkItem> items = [SELECT Id,ActorId,ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = : ca.Id];
            PageReference pageRef = Page.ASF_redirectToCaseApprovalVF;
            pageRef.getParameters().put('id', String.valueOf(items[0].Id));
            Test.setCurrentPage(pageRef);
            ASF_redirectToCaseApprovalVFController cls = new ASF_redirectToCaseApprovalVFController();
            cls.init();
            
            
            pageRef = Page.ASF_redirectToCaseApprovalVF;
            pageRef.getParameters().put('id', String.valueOf(ca.Id));
            Test.setCurrentPage(pageRef);
            cls = new ASF_redirectToCaseApprovalVFController();
            cls.init();
            Test.StopTest();
        }
        
    }
    @isTest
    private static void approvalTestReject(){
        User objUser = [Select Id from User WHERE ProfileId = :SYSTEMADMIN_PROFILE.Id AND ISACTIVE = true LIMIT 1];
        system.runAs(objUser){
            test.startTest();
            
            Case caseRec = new Case();
      
            caseRec.Subject ='testSubject';
            caseRec.Description ='testdescription';
            caseRec.Stage__c ='New';
            caseRec.Stage__c ='New';
            //caseRec.City__c ='Mumbai';
            Insert caseRec;
            
            Id currentUserId = UserInfo.getUserId();
            ASF_Case_Approv__c ca = new ASF_Case_Approv__c ();
            ca.Approver_01__c = currentUserId;
            ca.Approval_Type__c = 'Parallel - All to approve';
            ca.SR__c = caseRec.Id;
            try{
                insert ca;
            }
            catch(exception e){
                throw e;
            }
            
            ca.Parent_Record_Id_For_Update__c = [select Id from case LIMIT 1].Id;
            ca.RejectedFieldUpdates__c = 'Comments=test';
            ca.SR__c = caseRec.Id;
            update ca;
        
        ASF_ApprovalHistoryController.processStep(ca.Id, 'comments', null, 'Reject');
        
        List<ProcessInstance> processInstances = [SELECT Id,SubmittedById, ProcessDefinition.Name , (SELECT ID, ProcessNodeId,  
                                                                                                     StepStatus,Comments,TargetObjectId,ActorId,CreatedById,IsDeleted,IsPending  
                                                                                                     ,OriginalActorId,ProcessInstanceId,RemindersSent,CreatedDate, Actor.Name,  
                                                                                                     OriginalActor.Name , ProcessNode.Name FROM StepsAndWorkitems order by IsPending DESC, CreatedDate DESC )   
                                                  FROM ProcessInstance  order by CreatedDate DESC LIMIT 1];
        
        try{
            ASF_ApprovalHistoryController.getStepIdAfterApproval(processInstances.get(0).Id,ca.Id,'Rejected');
            
            ASF_ApprovalHistoryController.ApprovalHistory retVal = ASF_ApprovalHistoryUtil.populateApprovalHistorySteps(processInstances, ca.Id);
            //System.assertEquals(1,processInstances.size());
        }
        catch(exception e){
            throw e;
        }
            Test.StopTest();
        }
    }
    
    @isTest
    private static void approvalTestApprove(){
        User objUser = [Select Id from User WHERE ProfileId = :SYSTEMADMIN_PROFILE.Id AND ISACTIVE = true LIMIT 1];
        system.runAs(objUser){
            test.startTest();
            
            Case caseRec = new Case();
      
            caseRec.Subject ='testSubject';
            caseRec.Description ='testdescription';
            caseRec.Stage__c ='New';
            caseRec.Stage__c ='New';
            //caseRec.City__c ='Mumbai';
            Insert caseRec;
            
            Id currentUserId = UserInfo.getUserId();
            ASF_Case_Approv__c ca = new ASF_Case_Approv__c ();
            ca.Approver_01__c = currentUserId;
            ca.Approval_Type__c = 'Parallel - All to approve';
            ca.SR__c = caseRec.Id;
            try{
                insert ca;
            }
            catch(exception e){
                throw e;
            }
            
            ca.Parent_Record_Id_For_Update__c = [select Id from case LIMIT 1].Id;
            ca.SuccessFieldsUpdate__c = 'Comments=test';
            ca.SR__c = caseRec.Id;
            update ca;
        
        ASF_ApprovalHistoryController.processStep(ca.Id, 'comments', null, 'Approve');
        
        List<ProcessInstance> processInstances = [SELECT Id,SubmittedById, ProcessDefinition.Name , (SELECT ID, ProcessNodeId,  
                                                                                                     StepStatus,Comments,TargetObjectId,ActorId,CreatedById,IsDeleted,IsPending  
                                                                                                     ,OriginalActorId,ProcessInstanceId,RemindersSent,CreatedDate, Actor.Name,  
                                                                                                     OriginalActor.Name , ProcessNode.Name FROM StepsAndWorkitems order by IsPending DESC, CreatedDate DESC )   
                                                  FROM ProcessInstance  order by CreatedDate DESC LIMIT 1];
        
        try{
            ASF_ApprovalHistoryController.getStepIdAfterApproval(processInstances.get(0).Id,ca.Id,'Approved');
            
            ASF_ApprovalHistoryController.ApprovalHistory retVal = ASF_ApprovalHistoryUtil.populateApprovalHistorySteps(processInstances, ca.Id);
            //System.assertEquals(1,processInstances.size());
        }
        catch(exception e){
            throw e;
        }
            Test.StopTest();
        }
    }
    @isTest
    private static void caseruleEntryUpdate(){
        User objUser = [Select Id from User WHERE ProfileId = :SYSTEMADMIN_PROFILE.Id AND ISACTIVE = true LIMIT 1];
        system.runAs(objUser){
            test.startTest();
            Id stageToUpdate = [Select Id from ASF_Case_Stage_Config__c limit 1].Id;
            Id groupId = [Select Id from group limit 1].Id;
            ASF_Case_Rule__c caseRule = new ASF_Case_Rule__c(Case_Stage_Config__c = stageToUpdate, 
                                                         Order__c = 1, Type__c = 'Assignment',
                                                         Assignment_Queue_Name__c = 'ABFL Test Group(G)',
                                                         Assigned_Queue_Id__c=groupId,
                                                         Logical_Condition__c = '1');
            insert caseRule;
            ASF_Case_Rule_Entry__c caseRuleEntry = new ASF_Case_Rule_Entry__c(Number__c = 1, Case_Rule__c = caseRule.Id,
                                                                         Field_Api_Name__c = 'Stage__c',
                                                                         Operator__c = '=',
                                                                         Data_Type__c = 'STRING',
                                                                         Value__c = 'Open');
            insert caseRuleEntry;
            caseRuleEntry.Operator__c = '!=';
            update caseRuleEntry;
            Test.StopTest();
        }
    }
    
}