/**
 * @description       : Test Class to validate ABFL_UserTeamDataUpdateBatch
 * @author            : SaiRahul
 * @group             : 
 * @last modified on  : 07-12-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   05-13-2024   rsinghnagar@salesforce.com   Initial Version
**/
@isTest
private class ABFL_UserTeamDataUpdateBatchTest {

    @TestSetup
    static void makeData(){
        //Creating Users
        Profile p = [SELECT Id FROM Profile WHERE Name='ABFL Base Profile' LIMIT 1]; 
        List<User> userList = new List<User>();
        
        for(integer i = 0;i<2;i++){        
        User abflUser = new User(Alias = 'standt'+i, Email='standarduser@testorg.com'+i, 
             EmailEncodingKey='UTF-8', LastName='Testing'+i, LanguageLocaleKey='en_US',
             LocaleSidKey='en_US', ProfileId = p.Id, 
             TimeZoneSidKey='America/Los_Angeles', UserName='adminUserabcl@gmail.com'+i, Business_Unit__c = 'ABFL');
             userList.add(abflUser);     
        }
        insert userList;
        //Admin user creation for Creating Groups and it's assignments
        Profile p1 = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1]; 
        User adminUser = new User(Alias = 'stadmin', Email='standardadminuser@testorg.com', 
             EmailEncodingKey='UTF-8', LastName='AdminTesting', LanguageLocaleKey='en_US', 
             LocaleSidKey='en_US', ProfileId = p1.Id, 
             TimeZoneSidKey='America/Los_Angeles', UserName='adminabcl@gmail.com');
        insert adminUser;
        
        System.runAs(adminUser) {
            //Creating QUEUE
            Group testQueue = new Group(Name='ABFL Test QUEUE', DeveloperName = 'ABFL_Test_Queue', Type='Queue');
            insert testQueue;
            //Creating Public Group
            Group testGroup = new Group(Name='ABFL Test Group', DeveloperName = 'ABFL_Test_Group', Type='Regular');
            insert testGroup;
            //Creating Public group and queue assignments
            List<GroupMember> gmList = new List<GroupMember>();
            for(User u : userList){
            GroupMember gm = new GroupMember(GroupId = testGroup.Id, UserOrGroupId = u.Id);
            gmList.add(gm);
            }
            GroupMember gmQ = new GroupMember(GroupId = testQueue.Id, UserOrGroupId = testGroup.Id);
            gmList.add(gmQ);

            if(gmList.size() > 0)
            {
                insert gmList;
            }
        }
    }

    @isTest
    static void checkUserQueueDataUpdate() {

        Group queue = [Select id, Name from Group WHERE Name ='ABFL Test QUEUE' LIMIT 1];
        
        Test.startTest();
        ABFL_UserTeamDataUpdateBatch batchJob = new ABFL_UserTeamDataUpdateBatch();
        Database.executeBatch(batchJob);
        Test.stopTest();
        
        User updatedUser = [SELECT Id, managerGroupId__c, IsActive FROM User WHERE Name LIKE 'Testing%' LIMIT 1];
        
        System.assert(!String.isBlank(updatedUser.managerGroupId__c), 'field is not empty');
        
    }

    @isTest
    static void checkUserQueueDataUpdate2() {

        ABFL_UserTeamDataUpdateBatchScheduler scheduler = new ABFL_UserTeamDataUpdateBatchScheduler();
        scheduler.execute(null);
        
    }

}