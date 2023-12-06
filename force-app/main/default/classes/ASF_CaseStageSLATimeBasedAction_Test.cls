/*********************************************************
*Class        :  ASF_CaseStageSLATimeBasedAction_Test
*Author       :  Aditee Churiwala
*Description  :  Class to cover test cases ASF_CaseStageSLATimeBasedAction
*********************************************************/

@isTest
public class ASF_CaseStageSLATimeBasedAction_Test {
    
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];

    @testSetup
    static void setupTestData(){
    
        List<sObject> ls = Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
        ASF_TestDataFactory.createCaseCategoryConfig();
        ASF_TestDataFactory.createC3WithPrePopulateIntegrations();
        ASF_TestDataFactory.createCaseRecords(0);

            // Add users in a Group
        list<user> userList = new list<User>();
        for(integer i=0;i<3;i++){
            User userRecord1 = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='GroupTesting', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,
            TimeZoneSidKey='America/Los_Angeles', UserName='cdefghijk'+i+'56a@gmail.com');
            userList.add(userRecord1);
        }

        insert userList;

        // Creating a Group to add User's Managers
        Group SLAGroup = new Group();
        system.runAs(userList.get(0)){
            
            SLAGroup = new Group(Name='SLAManagerGroup', DeveloperName='SLAManagerGroup2');
            insert SLAGroup;
            
            List<GroupMember> gmList = new List<GroupMember>();
            for(integer i=0;i<3;i++){
                GroupMember gm = new GroupMember(GroupId = SLAGroup.Id, UserOrGroupId = userList.get(i).Id);
                gmList.add(gm);
            }      
            insert gmList;
        }

        userList[0].managerGroupId__c = SLAGroup.Id;
        update userList[0];

        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case LIMIT 1]; 
        caseRecord.OwnerId = userList[0].Id;
        caseRecord.SLA_Target_1__c = userList[0].Email;
        caseRecord.SLA_Target_2__c = userList[0].Email;
        update caseRecord;
        
    }

    @isTest
    public static void testSendEmailSLABroke(){

        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, Stage_SLA_1__c, OwnerId from case LIMIT 1]; 
        ASF_CaseStageSLATimeBasedAction.sendEmailSLABroke(new List<Id>{caseRecord.Id});

        // Check is SLA History has been set properly for Stage 1 Violation
        List<ASF_Case_SLA_History__c> hist = [
                SELECT Id, Stage_Violation_Start_Date__c, Level__c , Current_Owner_Id__c
                FROM ASF_Case_SLA_History__c 
                WHERE Case__c =: caseRecord.Id
                ];
        
        System.assertEquals('1', hist[0].Level__c);
        System.assertEquals(caseRecord.Stage_SLA_1__c, hist[0].Stage_Violation_Start_Date__c);
        
    }
    
    
}