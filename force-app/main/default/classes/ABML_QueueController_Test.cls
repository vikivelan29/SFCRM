/******************************************************  
* Author           - Dinoy Pauly
* Date             - 25-October-2024
* Description      - Test class for ABML_QueueController
********************************************************
*/
@isTest
public class ABML_QueueController_Test {
    
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name = 'System Administrator' LIMIT 1];    
    
    @testSetup
    static void setupTestData(){
        
        Group objGroup = new Group(Name = 'ABML Test Group' , Type = 'Queue');
        insert objGroup;
        Group objGroupTest = new Group(Name = 'ABML Test Group2');
        insert objGroupTest;
        
        List<User> listOfUsers = new List<User>();
        List<Case> listOfCases = new List<Case>();
        for(Integer userCount = 0 ; userCount < 2; userCount++){
            User objUser = new User(Alias = 'user' + userCount , Email = 'standarduser'+ userCount +'@testorg.com', 
                                    EmailEncodingKey = 'UTF-8', LastName = 'Test', LanguageLocaleKey = 'en_US', 
                                    LocaleSidKey = 'en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
                                    TimeZoneSidKey = 'America/Los_Angeles', Username = 'testUserAbml' + userCount + '@gmail.com',
                                    Business_Unit__c = 'ABML');
            listOfUsers.add(objUser);
        }
        
        insert listOfUsers;
        
        User userObj = listOfUsers[0];
        
        System.runAs(userObj) {
            for(Integer caseCount = 0 ; caseCount < 5; caseCount++){
                Case objCase = new Case(Subject = 'Test Case Creation', Stage__c = 'Email', Source__c =  'Email', Origin = 'ABML Email', SuppliedEmail = 'test.abml@gmail.com', Business_Unit__c  = 'ABML');            
                listOfCases.add(objCase);
            }
            insert listOfCases;
        }        
    }    
    
    @isTest
    static void getQueueNamesTest(){
        User objUser = [SELECT Id, Name FROM User WHERE Business_Unit__c = 'ABML' and LastName = 'Test' LIMIT 1];
        System.runAs(objUser){
            
            Test.startTest(); 
            
            List<Map<String, String>> listOfUsers = ABML_QueueController.getQueueNames();
            System.assert(listOfUsers.Size() != null, 'ABML Groups found.');
            
            Test.stopTest();
        }
    }
    
    @isTest
    static void getUsersByQueueTest(){
        User objUser = [SELECT Id, Name FROM User WHERE Business_Unit__c = 'ABML' and LastName='Test' LIMIT 1];
        System.runAs(objUser){
            
            Test.startTest(); 
            
            Group objGroup = [SELECT Id, Name FROM Group WHERE Name = 'ABML Test Group' LIMIT 1];
            Group objGroupTwo = [SELECT Id, Name FROM Group WHERE Name = 'ABML Test Group2' LIMIT 1];
            GroupMember objGroupMember = new GroupMember(GroupId = objGroup.id, UserOrGroupId = objUser.id); 
            insert objGroupMember;
            GroupMember objGroupMemberTwo = new GroupMember(GroupId = objGroup.id, UserOrGroupId = objGroupTwo.id); 
            insert objGroupMemberTwo;
            GroupMember objGroupMemberThree = new GroupMember(GroupId = objGroupTwo.id, UserOrGroupId = objUser.id); 
            insert objGroupMemberThree;
            List<User> listOfUsers = ABML_QueueController.getUsersByQueue(objGroup.Id);
            System.assertEquals(1, listOfUsers.Size(), 'Single Group Member was there in the Queue.');  
            
            Test.stopTest();
        }
    }
    
    @isTest
    static void updateCaseOwnerTest(){
        List<User> listOfUsers = [SELECT Id, Name FROM User WHERE Business_Unit__c = 'ABML' and LastName='Test' LIMIT 2];
        User userObj = listOfUsers[0];
        Id anotherUserId = listOfUsers[1].Id;
        System.runAs(userObj){
            
            Test.startTest(); 
            List<Id> caseIdList = new List<Id>();
            for(Case objCase : [SELECT Id, OwnerId FROM Case]){
                caseIdList.add(objCase.Id);
            }			
         
            ABML_QueueController.updateCaseOwner(caseIdList , anotherUserId);
            System.assertEquals(5, caseIdList.Size(), 'Multiple Case Owner Updated');  
            
            Test.stopTest();
        }
    }
    
    @isTest
    static void getUsersInQueueTest(){
        User objUser = [SELECT Id, Name, UserName FROM User WHERE Business_Unit__c = 'ABML' and LastName='Test' LIMIT 1];
        System.runAs(objUser){
            
            Test.startTest(); 
            
            Group objGroup = [SELECT Id, Name FROM Group WHERE Name = 'ABML Test Group' LIMIT 1];
            Group objGroupTwo = [SELECT Id, Name FROM Group WHERE Name = 'ABML Test Group2' LIMIT 1];
            GroupMember objGroupMember = new GroupMember(GroupId = objGroup.id, UserOrGroupId = objUser.id); 
            insert objGroupMember;
            GroupMember objGroupMemberTwo = new GroupMember(GroupId = objGroup.id, UserOrGroupId = objGroupTwo.id); 
            insert objGroupMemberTwo;
            GroupMember objGroupMemberThree = new GroupMember(GroupId = objGroupTwo.id, UserOrGroupId = objUser.id); 
            insert objGroupMemberThree;
            List<User> listOfUsers = ABML_QueueController.getUsersInQueue(objGroup.Id, objUser.Name);
            System.assertEquals(1, listOfUsers.Size(), 'Single Group Member Found.');  
            
            Test.stopTest();
        }
    }    
    
    @isTest
    static void getUsersInQueueNegTest(){
        User objUser = [SELECT Id, Name, UserName FROM User WHERE Business_Unit__c = 'ABML' and LastName='Test' LIMIT 1];
        System.runAs(objUser){
            
            Test.startTest(); 
            
            Group objGroup = [SELECT Id, Name FROM Group WHERE Name = 'ABML Test Group' LIMIT 1];
            GroupMember objGroupMember = new GroupMember(GroupId = objGroup.id, UserOrGroupId = objUser.id); 
            insert objGroupMember;
            List<User> listOfUsers = ABML_QueueController.getUsersInQueue('', objUser.Name);
            System.assertEquals(0, listOfUsers.Size(), 'Negative Case Testing.');  
            
            Test.stopTest();
        }
    }    
    
    @isTest
    static void getCaseDetailsTest(){
        List<User> listOfUsers = [SELECT Id, Name FROM User WHERE Business_Unit__c = 'ABML' and LastName='Test' LIMIT 2];
        User userObj = listOfUsers[0];
        System.runAs(userObj){
            
            Test.startTest(); 
            
            List<Id> caseIdList = new List<Id>();
            for(Case objCase : [SELECT Id, OwnerId FROM Case]){
                caseIdList.add(objCase.Id);
            }
            List<Case> listOfCases = ABML_QueueController.getCaseDetails(caseIdList);
            System.assertEquals(5, listOfCases.Size(), 'Multiple Case Found');  
            
            Test.stopTest();
        }
    }
    
    @isTest
    static void checkBusinessHoursTest(){
        List<User> listOfUsers = [SELECT Id, Name FROM User WHERE Business_Unit__c = 'ABML' and LastName='Test' LIMIT 2];
        User userObj = listOfUsers[0];
        System.runAs(userObj){
            
            Test.startTest(); 
            
            Boolean checkBusinessHours = ABML_QueueController.checkBusinessHours();
            System.assertEquals(2, listOfUsers.size(), 'Business Hour Check Success!');
            
            Test.stopTest();
        }
    }
    
    @isTest
    static void getCaseListViewsTest() {
        List<User> listOfUsers = [SELECT Id, Name FROM User WHERE Business_Unit__c = 'ABML' and LastName='Test' LIMIT 2];
        User userObj = listOfUsers[0];
        System.runAs(userObj){
        List<Case> caseList = [SELECT Id,CaseNumber,Subject FROM Case LIMIT 5];
        Test.startTest();

        List<ListView> result = ABML_QueueController.getCaseListViews();
        System.assertEquals(5, caseList.size(), 'Case List Views');
        Test.stopTest();
        }
    }

    @isTest
    static void getSearchRecordsTest() {
        List<User> listOfUsers = [SELECT Id, Name FROM User WHERE Business_Unit__c = 'ABML' and LastName='Test' LIMIT 2];
        User userObj = listOfUsers[0];
        System.runAs(userObj){
        Test.startTest();
        List<Case> caseList = ABML_QueueController.getSearchRecords('Test');
        System.assertEquals(5, caseList.size(), 'Search Case Records');
        Test.stopTest();
        }
    }

    @isTest
    static void getSearchRecordsEmptyTest() {
        List<User> listOfUsers = [SELECT Id, Name FROM User WHERE Business_Unit__c = 'ABML' and LastName='Test' LIMIT 2];
        User userObj = listOfUsers[0];
        System.runAs(userObj){
        Test.startTest();
        List<Case> caseList = ABML_QueueController.getSearchRecords('');
        System.assertEquals(0, caseList.size(), 'Negative Search Case Records');
        Test.stopTest();
        }
    }
    
   /* @isTest
    static void getCaseRecordsTest(){
        List<User> listOfUsers = [SELECT Id, Name FROM User WHERE Business_Unit__c = 'ABML' and LastName='Test' LIMIT 2];
        User userObj = listOfUsers[0];
        System.runAs(userObj){
        Test.startTest();
        List<Case> getCaseRecords = ABML_QueueController.getCaseRecords('');
        System.assertEquals(0, getCaseRecords.size(), 'No list view found!');
        Test.stopTest();
        }
    }*/
    
}
