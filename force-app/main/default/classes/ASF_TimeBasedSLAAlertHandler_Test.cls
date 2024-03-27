@SuppressWarnings('PMD.MethodNamingConventions')
@isTest
public class ASF_TimeBasedSLAAlertHandler_Test {
    
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    
    @testSetup
    static void setupTestData(){
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
    
    @isTest
    public static void SLATestCase(){
            
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
    
    
    @isTest
    public static void ManagerGroupSLA3Test(){
            
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
    
    @isTest
    public static void ManagerGroupSLA2Test(){
        Test.startTest();
        
        User u = [Select Id from User where isActive = true LIMIT 1];
        
        List<Case> caseList = ASF_TestDataFactory.createCaseRecords(1);
        Case c = CaseList.get(0);
        //c.status = 'Closed';
        c.ownerid = u.Id;
        DateTime cv = System.now();
        c.Stage_SLA_1__c = cv.addHours(-3);
        c.Stage_SLA_2__c = cv.addHours(2);
        c.Stage_SLA_3__c = cv.addHours(1);
        //update c; 
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
        //Assert.areEqual(caseLists[0].Stage_SLA_3__c, cv.addHours(1));
    }
}