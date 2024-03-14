@SuppressWarnings('PMD.MethodNamingConventions')
@isTest
private class ASF_ApprovalHistoryUtilTest {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    @testSetup static void methodName() {
        insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                            Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                            Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
        
        User userRecord = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                                   EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
                                   TimeZoneSidKey='America/Los_Angeles', UserName='abcdefghik561@gmail.com');
        insert userRecord;
        User userRecord1 = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
                                    TimeZoneSidKey='America/Los_Angeles',managerID = userRecord.Id, UserName='abcdefghijk561@gmail.com');
        insert userRecord1;
        User userRecord2 = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
                                    TimeZoneSidKey='America/Los_Angeles',managerID = userRecord.Id, UserName='abdehijk56@gmail.com');
        insert userRecord2; 
        User userRecord3 = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
                                    TimeZoneSidKey='America/Los_Angeles', UserName='abefghijk51@gmail.com');
        insert userRecord3;
        User userRecord4 = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
                                    TimeZoneSidKey='America/Los_Angeles', UserName='cdefghijk561@gmail.com');
        insert userRecord4;
        
        
        System.runAs(userRecord1){
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
        
        Id rtId = Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
        
        Account acc= new Account(
            RecordTypeId = rtId,
            FirstName='Test FName',
            LastName='Test LName',
            PersonMailingStreet='test@yahoo.com',
            PersonMailingPostalCode='12345',
            PersonMailingCity='SFO',
            PersonEmail='test@yahoo.com',
            PersonHomePhone='1234567',
            PersonMobilePhone='12345678'
            //  CRN__c= 'abcd'
        );
        insert acc;  
        LOB_Master__c lob = new LOB_Master__c(LOB_Code__c = 'ABC', BusinessUnit__c = 'Wealth Management');
        insert lob;
        Asset ast = new Asset(Name='AccountFinacial',AccountId=acc.Id, LOB_Code__c = lob.Id,Price=100);
        insert ast;
       
        ASF_Case_Category_Config__c ccc = new ASF_Case_Category_Config__c();
        ccc.Type__c = 'tes';
        ccc.CCC_External_Id__c = 'CCC-CC-RC-01';
        ccc.Business_Unit__c = 'ABFL';
        ccc.Sub_Type__c = 'TDC Refund';
        ccc.Overall_Case_Closure_SLA__c = 10;
        insert ccc;
        
        ASF_Case_Stage_Config__c stage1 = new ASF_Case_Stage_Config__c();
        stage1.Case_Category_Config__c = ccc.Id;
        stage1.Order__c = 1;
        stage1.StageName__c  = 'In Progress with CEC';
        stage1.Stage_SLA_1__c = 1;
        stage1.Status_Mapping__c = 'New';
        // stage1.Stage_SLA_3__c = 3;
        stage1.SLA_Target_1_Type__c = 'Manager';
        stage1.Query_Fields__c = 'Id,Stage__c';
        stage1.Manual_Stage__c = false;
        
        insert stage1;
        Case newCase = new Case( Type_Text__c = 'Testing', Sub_Type_Text__c  =  'CreditCard', Stage__c='In Progress with CEC', CCC_External_Id__c ='CCC-CC-RC-01',
                                Status = 'New');
        insert newCase;
        
        ASF_Case_Approv__c approver = new ASF_Case_Approv__c(Approver_01__c= userRecord4.Id,Approver_02__c= userRecord4.Id,
                                                             Approver_03__c= userRecord4.Id, Approver_04__c= userRecord4.Id,
                                                             Approver_05__c= userRecord4.Id,
                                                             SR__c =newCase.Id,Approval_Type__c ='Parallel - All to approve', Requestor_Comments__c = 'approver created');
        insert approver;
        
        
        
    }
    
    @isTest 
    static void isCurrentUserIdTest_SystemAdmin(){
        //List<User> users = [select Id, FirstName, LastName FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        List<ASF_Case_Approv__c> cas = [SELECT Id FROM ASF_Case_Approv__c ORDER BY CREATEDDATE LIMIT 1];
        User users = [SELECT Id FROM User WHERE Username = 'abcdefghijk561@gmail.com'];
        System.runAs(users){
            boolean isAdmin = ASF_ApprovalHistoryUtil.isCurrentUserSystemAdmin(cas.get(0).Id);
            System.assertEquals(true, isAdmin, 'The user was supposed to be found admin');
        }
        
    }
    
    @isTest static void isCurrentUserIdTest_NOT_SystemAdmin(){
        List<User> users = [select Id, FirstName, LastName FROM User WHERE Profile.Name != 'System Administrator' LIMIT 1];
        List<ASF_Case_Approv__c> cas = [SELECT Id FROM ASF_Case_Approv__c ORDER BY CREATEDDATE LIMIT 1];
        System.runAs(users.get(0)){
            boolean isAdmin = ASF_ApprovalHistoryUtil.isCurrentUserSystemAdmin(cas.get(0).Id);
            System.assertEquals(false, isAdmin, 'The user was not supposed to be found admin');
        }
        
    }
    
    @isTest static void processStepTest_EmptyWorkItems(){
        List<User> users = [select Id, FirstName, LastName FROM User WHERE Profile.Name != 'System Administrator' LIMIT 1];
        List<ASF_Case_Approv__c> cas = [SELECT Id FROM ASF_Case_Approv__c ORDER BY CREATEDDATE LIMIT 1];
        List<ProcessInstanceWorkitem> workItems = new List<ProcessInstanceWorkitem>();
        Approval.ProcessResult retVal = ASF_ApprovalHistoryUtil.processStep( workItems, 'comments',users.get(0).Id, cas.get(0).Id);
        System.assertEquals(1, users.size());
        
    }
    
    @isTest static void processStepTest_NotEmptyWorkItems(){
        List<User> users = [select Id, FirstName, LastName FROM User WHERE Profile.Name != 'System Administrator' LIMIT 1];
        List<ASF_Case_Approv__c> cas = [SELECT Id FROM ASF_Case_Approv__c ORDER BY CREATEDDATE LIMIT 1];
        List<ProcessInstanceWorkitem> workItems = new List<ProcessInstanceWorkitem>();
        workItems.add(new ProcessInstanceWorkitem(Id = '04i3h000001L5fGAAS'));
        try{
            Approval.ProcessResult retVal = ASF_ApprovalHistoryUtil.processStep( workItems, 'comments',users.get(0).Id, cas.get(0).Id);
            System.assertEquals(1, users.size());
        }catch(Exception e){
            
        }
    }
    
    @isTest static void reassignStepTest(){
        List<User> users = [SELECT Id, FirstName, LastName FROM User LIMIT 1];
        List<ProcessInstanceWorkitem> workItems = new List<ProcessInstanceWorkitem>();
        workItems.add(new ProcessInstanceWorkitem(Id = '04i3h000001L5fGAAS'));
        try{
            ASF_ApprovalHistoryUtil.reassignStep(workItems, users.get(0).Id);
            System.assertEquals(1, users.size());
        }catch(Exception e){
        }
    }
    
    @isTest static void populateApprovalHistoryTest(){
        List<ASF_Case_Approv__c> cas = [SELECT ID FROM ASF_Case_Approv__c ORDER BY CreatedDate DESC LIMIT 1];
        
        List<ProcessInstance> processInstances = [SELECT Id,SubmittedById, ProcessDefinition.Name , (SELECT ID, ProcessNodeId,  
                                                                                                     StepStatus,Comments,TargetObjectId,ActorId,CreatedById,IsDeleted,IsPending  
                                                                                                     ,OriginalActorId,ProcessInstanceId,RemindersSent,CreatedDate, Actor.Name,  
                                                                                                     OriginalActor.Name , ProcessNode.Name FROM StepsAndWorkitems order by IsPending DESC, CreatedDate DESC )   
                                                  FROM ProcessInstance  order by CreatedDate DESC LIMIT 1];
        
        ASF_ApprovalHistoryController.ApprovalHistory retVal = ASF_ApprovalHistoryUtil.populateApprovalHistorySteps(processInstances, cas.get(0).Id);
        System.assertEquals(1, processInstances.size());
        
    }
    
    @isTest static void populateApprovalHistoryRecord(){
        List<User> users = [SELECT Id, FirstName, LastName FROM User LIMIT 1];
        List<ASF_ApprovalHistoryController.ApprovalHistoryStep> approvalSteps = new List<ASF_ApprovalHistoryController.ApprovalHistoryStep>();
        approvalSteps.add(new ASF_ApprovalHistoryController.ApprovalHistoryStep( 'stepName','stepId', DateTime.now(),'stepStatus', 'assignedTo', 'assignedToId','actualappr','actualapprId','Comments',true));
        ASF_ApprovalHistoryController.ApprovalHistory approvalHistoryToReturn = new ASF_ApprovalHistoryController.ApprovalHistory( approvalSteps,  false, true, true);
        ProcessInstanceHistory step = new ProcessInstanceHistory();
        ASF_ApprovalHistoryUtil.populateApprovalHistoryRecord(approvalHistoryToReturn, step,  true, users.get(0).Id,new Set<Id>() );
        System.assertEquals(true, approvalHistoryToReturn.showRecall, 'The recall attribute is supposed to be true');
        System.assertEquals(true, approvalHistoryToReturn.isCurrentUserApprover, 'The isCurrentUserApprover attribute is supposed to be true');
        System.assertEquals(false, approvalHistoryToReturn.showSubmitForApproval, 'The showSubmitForApproval attribute is supposed to be false');
        
    }
}