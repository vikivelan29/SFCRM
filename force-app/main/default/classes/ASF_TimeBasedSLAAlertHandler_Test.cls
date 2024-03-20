@SuppressWarnings('PMD.MethodNamingConventions')
@isTest
public class ASF_TimeBasedSLAAlertHandler_Test {
    
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    
    @testSetup
    static void setupTestData(){
        
        Group SLAGroup = new Group();
        
        SLAGroup = new Group(Name='SLAManagerGroup', DeveloperName='SLAManagerGroup');
        insert SLAGroup;
        
        group q = new group();
        q.name = 'OCC-Test-Group';
        q.type = 'Queue';
        insert q;
        
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Payment Base Profile'];
        PermissionSetGroup  ps = [SELECT Id, Status FROM PermissionSetGroup WHERE DeveloperName ='Super_Admin'];
        UserRole ur = [SELECT ID FROM UserRole WHERE DeveloperName='Payments_Service_Agent' LIMIT 1];
        if (ps.Status != 'Updated') {
            Test.calculatePermissionSetGroup(ps.Id);
        }
        
        list<user> userList = new list<User>();
        for(integer i=0;i<3;i++){
            User u = new User(Alias = 'standt', Email='standarduser'+i+'@testorg.com', 
                              EmailEncodingKey='UTF-8', LastName='TestUser5srDetail'+i, LanguageLocaleKey='en_US', 
                              LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles',
                              UserName='standarduser@test5srDetail'+i+'.com'+System.now().millisecond(), UserRoleId = ur.Id);
            userList.add(u);
            
        }
        
        insert userList;
        List<PermissionSetAssignment> psAssign = new List<PermissionSetAssignment>();
        for(User u : userList){
            psAssign.add(new PermissionSetAssignment(AssigneeId = u.id, PermissionSetGroupId = ps.Id));
        }
        Insert psAssign;
        
        for(integer i=0;i<3;i++){
            GroupMember gm = new GroupMember(GroupId = SLAGroup.Id, UserOrGroupId = userList.get(i).Id);
            insert gm;
        }
        
        User userRecord1 = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,
                                    TimeZoneSidKey='America/Los_Angeles', UserName='cdefghijk56@gmail.com',
                                    managerGroupId__c=SLAGroup.Id);
        insert userRecord1;
        
        
        system.runAs(userRecord1){
            Account acc= new Account(
                FirstName='Test FName',
                LastName='Test LName',
                PersonMailingStreet='test@yahoo.com',
                PersonMailingPostalCode='12345',
                PersonMailingCity='SFO',
                PersonEmail='test@yahoo.com',
                PersonHomePhone='1234567',
                PersonMobilePhone='12345678',
                RecordTypeId = Schema.sObjectType.Account.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId(),
                Client_Code__c= 'abcd',
                Line_Of_Business__c = 'Payments',
                Business_Unit__c = 'Payments'
            );
            insert acc;  
            LOB_Master__c lob = new LOB_Master__c(LOB_Code__c = 'ABC', BusinessUnit__c = 'Wealth Management');
            insert lob;
            Asset ast = new Asset(Name='AccountFinacial',AccountId=acc.Id, LOB_Code__c = lob.Id,Price=100);
            insert ast;
            
            ASF_TestDataFactory.createCaseCategoryConfig(); 
        }
        
        
    }
    
    @isTest
    public static void SLATestCase(){
        
        Group g = [SELECT ID FROM Group WHERE DeveloperName='SLAManagerGroup'];
        
        User userRecord1 = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,
                                    TimeZoneSidKey='America/Los_Angeles', UserName='cdefghijk567@gmail.com',
                                    managerGroupId__c=g.Id);
        insert userRecord1;
        
        
        system.runAs(userRecord1){
            
            List<Case> caseList = ASF_TestDataFactory.createCaseRecords(1);
            Case c = CaseList.get(0);
            c.ownerid = userInfo.getuserId();
            DateTime cv = System.now();
            update c; 
            List<Id> cList = new List<Id>();
            cList.add(c.Id);
            ASF_CaseSLABroken.sendEmailSLABroke(cList);
            Test.startTest();
            
            System.schedule('TimeBasedSLAHandlerTest', '0 0 * * * ?', new ASF_TimeBasedSLAAlertHandler() ); 
            
            ASF_TimeBasedSLAAlertHandler uca = new ASF_TimeBasedSLAAlertHandler();
            Id batchId = Database.executeBatch(uca);
            c.Stage_SLA_1__c = cv.addHours(-3);
            c.Stage_SLA_2__c = cv.addHours(-2);
            c.Stage_SLA_3__c = cv.addHours(1);
            c.SLA_Target_3__c = 'stanrduserEmails@testorg.com';
            c.SLA_Target_1__c = 'stanrduserEmails@testorg.com';
            c.SLA_Target_2__c = 'stanrduserEmails@testorg.com';
            update c;
            batchId = Database.executeBatch(uca); 
            batchId = Database.executeBatch(uca);
            c.Stage_SLA_1__c = cv.addHours(-3);
            c.Stage_SLA_2__c = cv.addHours(-2);
            c.Stage_SLA_3__c = cv.addHours(-1);
            update c;  
            Test.stopTest();
            
            List<Case> caseLists = [SELECT Id,SLA_Target_2__c FROM Case];
            Assert.areEqual(caseLists[0].SLA_Target_2__c, 'stanrduserEmails@testorg.com');
        }
        
    }    
    
    
    @isTest
    public static void ManagerGroupSLA3Test(){
        Group g = [SELECT ID FROM Group WHERE DeveloperName='SLAManagerGroup'];
        
        User userRecord1 = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,
                                    TimeZoneSidKey='America/Los_Angeles', UserName='cdefghijk567@gmail.com',
                                    managerGroupId__c=g.Id);
        insert userRecord1;
        
        
        system.runAs(userRecord1){
            
            List<Case> caseList = ASF_TestDataFactory.createCaseRecords(1);
            Case c = CaseList.get(0);
            c.ownerid = userInfo.getuserId();
            DateTime cv = System.now();
            BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault=true];
            update c; 
            
            ASF_Case_SLA_History__c his = new ASF_Case_SLA_History__c();
            his.Case__c = c.Id;
            his.Stage_Start_Date__c = cv.addDays(-2);
            his.Stage_End_Date__c = null;
            his.BusinessHoursId__c = bh.Id;
            his.Breached_User_Id__c = c.OwnerId;
            his.Stage__c = 'New';
            his.is_Running_Record__c = true;
            insert his;
            
            List<Id> cList = new List<Id>();
            cList.add(c.Id);
            ASF_CaseSLABroken.sendEmailSLABroke(cList);
            Test.startTest();
            
            System.schedule('TimeBasedSLAHandlerTest', '0 0 * * * ?', new ASF_TimeBasedSLAAlertHandler() ); 
            
            ASF_TimeBasedSLAAlertHandler uca = new ASF_TimeBasedSLAAlertHandler();
            Id batchId = Database.executeBatch(uca);
            c.Stage_SLA_1__c = cv.addHours(-3);
            c.Stage_SLA_2__c = cv.addHours(-2);
            c.Stage_SLA_3__c = cv.addHours(1);
            c.SLA_Target_3__c = 'stanrduserEmails@testorg.com';
            c.SLA_Target_1__c = 'stanrduserEmails@testorg.com';
            c.SLA_Target_2__c = 'stanrduserEmails@testorg.com';
            update c;
            batchId = Database.executeBatch(uca); 
            batchId = Database.executeBatch(uca);
            c.Stage_SLA_1__c = cv.addHours(-3);
            c.Stage_SLA_2__c = cv.addHours(-2);
            c.Stage_SLA_3__c = cv.addHours(-1);
            update c;  
            Test.stopTest();
            
            List<Case> caseLists = [SELECT Id,SLA_Target_2__c FROM Case];
            Assert.areEqual(caseLists[0].SLA_Target_2__c, 'stanrduserEmails@testorg.com');
        }
    }
    
    @isTest
    public static void ManagerGroupSLA2Test(){
        Test.startTest();
        
        User u = [Select Id from User where LastName ='Testing' LIMIT 1];
        
        List<Case> caseList = ASF_TestDataFactory.createCaseRecords(1);
        Case c = CaseList.get(0);
        //c.status = 'Closed';
        c.ownerid = u.Id;
        DateTime cv = System.now();
        c.Stage_SLA_1__c = cv.addHours(-3);
        c.Stage_SLA_2__c = cv.addHours(2);
        c.Stage_SLA_3__c = cv.addHours(1);
        update c; 
        List<Id> cList = new List<Id>();
        cList.add(c.Id);
        
        ASF_TimeBasedSLAAlertHandler uca = new ASF_TimeBasedSLAAlertHandler();
        Id batchId = Database.executeBatch(uca);
        c.Stage_SLA_1__c = cv.addHours(-3);
        c.Stage_SLA_2__c = cv.addHours(-2);
        c.Stage_SLA_3__c = cv.addHours(1);
        
        batchId = Database.executeBatch(uca); 
        batchId = Database.executeBatch(uca);
        c.Stage_SLA_1__c = cv.addHours(-3);
        c.Stage_SLA_2__c = cv.addHours(-2);
        c.Stage_SLA_3__c = cv.addHours(3);
        
        Test.stopTest();
        
        List<Case> caseLists = [SELECT Id,Stage_SLA_3__c FROM Case];
        Assert.areEqual(caseLists[0].Stage_SLA_3__c, cv.addHours(1));
    }
}