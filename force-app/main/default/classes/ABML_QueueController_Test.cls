/******************************************************  
* Author           - Dinoy Pauly
* Date             - 25-October-2024
* Description      - Test class for ABML_QueueController
********************************************************
*/
@isTest
public class ABML_QueueController_Test {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    
    @testSetup
    static void setupTestData(){
        
        Group g = new Group();
        g.Name = 'Test Group';
        g.Type = 'Queue';
        Insert g;
        
        List<User> lstUser = new List<User>();
    User userRecord = new User(Alias = 'usr1', Email='standarduser@testorg.com', 
                               EmailEncodingKey='UTF-8', LastName='Test', LanguageLocaleKey='en_US', 
                               LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
                               TimeZoneSidKey='America/Los_Angeles', UserName='abcdefghijk561123@gmail.com', Business_Unit__c = 'ABML');//LOB__c='ABHFL',
    lstUser.add(userRecord);
    
    User userRecord2 = new User(Alias = 'usr2', Email='standarduser2@testorg.com', 
                                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
                                TimeZoneSidKey='America/Los_Angeles', UserName='abcdefghijk781234@gmail.com', Business_Unit__c = 'ABML');//LOB__c='ABHFL',
    lstUser.add(userRecord2);
    insert lstUser;
        
    System.runAs(userRecord) {
        List<Case> caseList = new List<Case>();
        
             Case newCase = new Case();
            newCase.Subject = 'Test Case Creation';
            newCase.CCC_External_Id__c ='' ;
          	newCase.Source__c =  'Email';
          	newCase.Stage__c = 'Email';
          	newCase.Origin = 'ABML Email';
          	newCase.SuppliedEmail = 'test.abml@gmail.com';
           	newCase.Business_Unit__c  = 'ABML'; 
          insert newCase;
          caseList.add(newCase);
    }
    }
    
    @isTest
    static void testGetQueues(){
        User userRecord = [SELECT Id,Name 
                          FROM User 
                          WHERE Business_Unit__c = 'ABML' and LastName='Test' 
                          LIMIT 1];
        System.runAs(userRecord){
            List<User> lstUsers = new List<User>();
            
            User userRecordd = new User(Alias = 'usr3', Email='standarduserrr@testorg.com', 
                               EmailEncodingKey='UTF-8', LastName='Test', LanguageLocaleKey='en_US', 
                               LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
                               TimeZoneSidKey='America/Los_Angeles', UserName='abcdefghijjk561123@gmail.com', Business_Unit__c = 'ABML');//LOB__c='ABHFL',
            lstUsers.add(userRecordd);
            insert lstUsers;
        
    List<User> lstUser = [SELECT Id,Name 
                          FROM User 
                          WHERE Business_Unit__c = 'ABML']; 
    Group g = [SELECT Id, Name
            FROM Group
            WHERE Type = 'Queue' 
            LIMIT 1];
    List<GroupMember>listGroupMember =new List<GroupMember>();  

    for (User user : lstUser){
            GroupMember gm= new GroupMember(); 
            gm.GroupId=g.id;
            gm.UserOrGroupId = user.id;
            listGroupMember.add(gm);    
    } 
    insert listGroupMember;
        
        Group grp = [SELECT Id, Name,Type 
                     FROM Group 
                     WHERE Id=:g.Id limit 1];
        
        Id queueId = grp.Id;
        Id userId;
        Id currUserId = userRecord.Id;
        Id uid;
        String queId = grp.Id;
        String emptyQueue;
        String userName;
        String queueName = grp.Name;
        /*List<User> userList = [
            SELECT Id, Name, Email
            FROM User
            WHERE Id IN (SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :queueId)
        ];*/
        
        User us = [SELECT Id,Name 
                          FROM User 
                          WHERE Business_Unit__c = 'ABML' and LastName='Testing' 
                          LIMIT 1];
            userId = us.Id;
            userName = us.Name;
        
        
        List <Case> caseList = [SELECT Id,Subject 
                    FROM Case 
                    WHERE Business_Unit__c  = 'ABML'];
        List<id> caseIds = new List<id>(); 
        for(Case c:caseList){
            caseIds.add(c.Id);
        }
        
        Test.startTest();
        
        ABML_QueueController.getUsersByQueue(queueId);
        ABML_QueueController.UpdateCaseOwner(caseIds, userId);
        ABML_QueueController.getUsersInQueue(queId,userName);
        ABML_QueueController.searchQueuesByName(queueName);  
        
        
        
        ABML_QueueController.getUsersInQueue(emptyQueue,userName);
        //ABML_QueueController.UpdateCaseOwner(caseIds,uid); 
        Test.stopTest();
        System.assertEquals(1,caseIds.Size(),'A case need to be selected');
        //System.assertEquals(2,userList.Size(),'User must be assigned to a queue');
        }
        }
    
     @isTest
    static void testGetQueueNames(){
        Test.startTest();
        ABML_QueueController.getQueues();
        ABML_QueueController.getQueueNames();
        Test.stopTest();
    }
    
    @isTest
    static void testGetCaseDetails(){
        
        //System.runAs(userRecord){
            
        
        List <Case> caseList = [SELECT Id,Subject 
                    FROM Case 
                    WHERE Business_Unit__c  = 'ABML'];
        List<id> caseIds = new List<id>(); 
        for(Case c:caseList){
            caseIds.add(c.Id);
        }
        
        Test.startTest();
        
        ABML_QueueController.getCaseDetails(caseIds);
        Boolean bool = ABML_QueueController.checkBusinessHours();
        Boolean checkProfile = ABML_QueueController.checkProfile();
        Test.stopTest();
        System.assertEquals(True,bool,'checkBusinessHours');
        //}
    }

}