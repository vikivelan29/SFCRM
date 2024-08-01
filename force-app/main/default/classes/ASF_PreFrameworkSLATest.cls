@isTest
private class ASF_PreFrameworkSLATest {
    
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    
    @testSetup
    static void setup() {
        list<user> userList = new list<User>();
        for(integer i=0;i<3;i++){
            User userRecord1 = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                        EmailEncodingKey='UTF-8', LastName='GroupTesting', LanguageLocaleKey='en_US', 
                                        LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,
                                        ManagerId = userInfo.getuserId(),
                                        TimeZoneSidKey='America/Los_Angeles', UserName='cdefghijk'+i+'56@gmail.com');
            userList.add(userRecord1);
        }
        
        insert userList;
        
        Group SLAGroup = new Group();
        system.runAs(userList.get(0)){
            SLAGroup = new Group(Name='SLAManagerGroup', DeveloperName='SLAManagerGroup');
            insert SLAGroup;
            
            for(integer i=0;i<3;i++){
                GroupMember gm = new GroupMember(GroupId = SLAGroup.Id, UserOrGroupId = userList.get(i).Id);
                insert gm;
            }
        }
        
        User userRecord1 = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,
                                    ManagerId = userInfo.getuserId(),
                                    TimeZoneSidKey='America/Los_Angeles', UserName='cdefghijk56@gmail.com');
        insert userRecord1;
        
        Id arecordTypeId =Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
        
        Account acc= new Account(
            FirstName='Test FName',
            LastName='Test LName',
            PersonMailingStreet='test@yahoo.com',
            PersonMailingPostalCode='12345',
            PersonMailingCity='SFO',
            PersonEmail='test@yahoo.com',
            PersonHomePhone='1234567',
            PersonMobilePhone='12345678',
            RecordTypeId = arecordTypeId
        );
        insert acc;  
        
        LOB_Master__c lob = new LOB_Master__c(LOB_Code__c = 'ABC', BusinessUnit__c = 'Wealth Management');
        insert lob;
        
        Asset ast = new Asset(Name='AccountFinacial',AccountId=acc.Id, LOB_Code__c = lob.Id,Price=100);
        insert ast;
        
        group q = new group();
        q.email = 'stanrduserEmails@testorg.com';
        q.name = 'OCC-Test-Group';
        q.type = 'Queue';
        insert q;
        
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
        stage1.StageName__c  = 'New';
        stage1.Stage_SLA_1__c = 1;
        stage1.Status_Mapping__c = 'New';
        stage1.SLA_Target_1_Type__c = 'Manager';
        stage1.Query_Fields__c = 'Id,Stage__c';
        stage1.Manual_Stage__c = false;
        
        insert stage1;
        
        insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                            Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                            Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
        
        Case cs = new Case();
        cs.AccountId = acc.Id;
        cs.CCC_External_Id__c = '12345';
        cs.Status = 'New';
        cs.Stage__c='New';
        //cs.OwnerId=groupList[0].id;
        insert cs;
        
        BusinessHours bh = [SELECT Id FROM BusinessHours LIMIT 1];
        
        List<Case> caseList = ASF_TestDataFactory.createCaseRecords(1);
    }
    
    
    @isTest
    static void testGetDataOnLoad() {
        List<Case> caseList = [SELECT Id FROM Case where CCC_External_Id__c = '12345' LIMIT 1];
        Case c = CaseList[0];
        c.Pre_framework_SLA__c = DateTime.now().addHours(1);
        DateTime cv = System.now();
        c.status = 'New';
        c.stage__c='New';
        c.Stage_SLA_1__c = DateTime.now().addHours(2);
        c.Stage_SLA_2__c = DateTime.now().addHours(3);
        c.Stage_SLA_3__c = DateTime.now().addHours(4);
        update c; 
        List<Id> cList = new List<Id>();
        cList.add(c.Id);
        
        Test.startTest();
        
        c.Stage_SLA_1__c = cv.addHours(-3);
        c.Stage_SLA_2__c = cv.addHours(-2);
        c.Stage_SLA_3__c = cv.addHours(1);
        c.SLA_Target_3__c = 'stanrduserEmails@testorg.com';
        c.SLA_Target_1__c = 'stanrduserEmails@testorg.com';
        c.SLA_Target_2__c = 'stanrduserEmails@testorg.com';
        update c;
        
        c.Stage_SLA_1__c = cv.addHours(-3);
        c.Stage_SLA_2__c = cv.addHours(-2);
        c.Stage_SLA_3__c = cv.addHours(-1);
        update c; 
        
        System.assertNotEquals(null, caseList, 'Test case records not found');
        
        ASF_PreFrameworkSLA.TimerWrapperClass result = ASF_PreFrameworkSLA.getDataOnLoad(caseList[0].Id);
        System.assertNotEquals(null, result, 'Result should not be null');
        // System.assertEquals(false, result.businessHourWorking, 'Business hour working should be false');
        Test.stopTest();
    }
    
    @isTest
    static void testSendEmailSLA() {
        List<Id> caseList = new List<Id>();
        Id ownerId;
        for (Case cc : [SELECT Id, OwnerId FROM Case]) {
            caseList.add(cc.Id);
            if (cc.OwnerId != null)
                ownerId = cc.OwnerId;
        }
        
        Test.startTest();
        
        List<User> userList = [SELECT Id FROM User WHERE Id = :ownerId];
        System.assertNotEquals(null, userList, 'User records not found');
        System.assertNotEquals(0, userList.size(), 'User records not found');
        
        system.runAs(userList[0]) {
            ASF_PreFrameworkSLA.sendEmailSLA(caseList);
            Test.stopTest();
            List<Case> csList = [SELECT Id FROM Case];
            System.assertEquals(3, csList.size(), 'One case record should be present');
            ASF_PreFrameworkSLA.TimerWrapperClass wrapper = new ASF_PreFrameworkSLA.TimerWrapperClass();
            wrapper.caseObj = csList[0];
            wrapper.overdueTotalSec = 60 * 60 * 1000;
            wrapper.leftTotalSec = 60 * 60 * 1000;
            wrapper.todaysMilisec = 60 * 60 * 1000;
            // System.assertEquals(false, result);
        }
    }
    
    @isTest
    static void testSendEmailSLA2() {
        List<Id> caseList = new List<Id>();
        List<Case> caseToUpdate = new List<Case>();
        List<Group> groupList = [SELECT id From Group where type = 'Queue'];
        groupList[0].Email = 'stanrduserEmails@testorg.com';
        update groupList[0];
        List<Account> accountList = [SELECT id From Account];
        
        QueueSobject mappingObject = new QueueSobject(QueueId = groupList[0].Id, SobjectType = 'Case');
        System.runAs(new User(Id = UserInfo.getUserId())){
            insert mappingObject;
        }
        
        Id ownerId;
        Case cs = new Case();
        cs.AccountId = accountList[0].Id;
        cs.CCC_External_Id__c = '12345';
        cs.Status = 'New';
        cs.Stage__c='New';
        cs.OwnerId=groupList[0].id;
        insert cs;
        caseList.add(cs.id);
        Test.startTest();
        
        
        ASF_PreFrameworkSLA.sendEmailSLA(caseList);
        Test.stopTest();
        List<Case> csList = [SELECT Id FROM Case];
        System.assertEquals(4, csList.size(), 'One case record should be present');
        ASF_PreFrameworkSLA.TimerWrapperClass wrapper = new ASF_PreFrameworkSLA.TimerWrapperClass();
        wrapper.caseObj = csList[0];
        wrapper.overdueTotalSec = 60 * 60 * 1000;
        wrapper.leftTotalSec = 60 * 60 * 1000;
        wrapper.todaysMilisec = 60 * 60 * 1000;
        
    }
    
}