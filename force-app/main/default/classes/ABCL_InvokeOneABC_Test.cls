/*********************************************************
*Class        :  ABCL_InvokeOneABC
*Author       :  Shubham Sinha 
*Created Date :  16/02/2024
*Description  :  Test Class
*********************************************************/
@isTest
public class ABCL_InvokeOneABC_Test {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    @testSetup
    static void setUpData(){
        Group slaGroup = new Group();        
        slaGroup = new Group(Name='SLAManagerGroup', DeveloperName='SLAManagerGroup');
            insert slaGroup;
        Group g1 = new Group(Name='OCC-Test-Group', type='Queue');
            insert g1;
        User userRecord = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,
                                    TimeZoneSidKey='America/Los_Angeles', UserName='cdefghijk567@gmail.com',
                                    managerGroupId__c=slaGroup.Id);
        insert userRecord;
         User userRecord1 = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,
                                    TimeZoneSidKey='America/Los_Angeles', UserName='ookaycdefghijk567@gmail.com',
                                    managerGroupId__c=slaGroup.Id);
        insert userRecord1;
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'ABFL_User_PS'LIMIT 1];
        PermissionSetAssignment psa = new PermissionSetAssignment();
            psa.AssigneeId = userRecord1.Id;
            psa.PermissionSetId = ps.Id;
        insert psa;
        System.runAs(userRecord) {
            ASF_Case_Category_Config__c ccc = new ASF_Case_Category_Config__c();
                ccc.Type__c = 'tes';
                ccc.First_Stage__c = 'New';
                ccc.CCC_External_Id__c = '12345';
                ccc.Business_Unit__c = 'ABFL';
                ccc.Sub_Type__c = 'Paytm';
                ccc.EBOT_Auto_Response__c = True;
                ccc.Overall_Case_Closure_SLA__c = 10;
            insert ccc;
            ASF_Case_Stage_Config__c stage1 = new ASF_Case_Stage_Config__c();
            stage1.Case_Category_Config__c = ccc.Id;
            stage1.Order__c = 1;
            stage1.StageName__c = 'New';
            stage1.Stage_SLA_1__c = 1;
            stage1.Status_Mapping__c = 'New';
            // stage1.Stage_SLA_3__c = 3;
            stage1.SLA_Target_1_Type__c = 'Manager';
            stage1.Query_Fields__c = 'Id,Stage__c';
            stage1.Manual_Stage__c = false;
            stage1.Default_Queue__c =g1.Id;
            insert stage1;
            Case newCase = new Case();
                newCase.Subject = 'Test Case Creation';
                newCase.CCC_External_Id__c =ccc.CCC_External_Id__c ;
                newCase.Business_Unit__c  = 'ABFL';
                newCase.Source__c = 'OneABC';
                //newCase.OwnerId = queueRecord.Id;
            insert newCase; 
        }
    }
     @isTest
    static void oneAbcCalloutExceptionTest(){
        List<Case> objCase = [Select Id,Stage__c,OwnerId From Case WHERE Source__c = 'OneABC' LIMIT 1];
        User usr = [SELECT Id FROM User WHERE Username = 'cdefghijk567@gmail.com' LIMIT 1];
        system.runAs(usr)
        { 
            Test.startTest(); 
            objCase[0].Stage__c= 'Resolved';
            update objCase[0]; 
            System.assertEquals(1, objCase.size(),'record found');          
            Test.stopTest();            
            }
    }
      @isTest
    static void oneAbcCalloutTest(){
        List<Case> objCase = [Select Id,Stage__c,OwnerId From Case WHERE Source__c = 'OneABC' LIMIT 1];
        User usr = [SELECT Id FROM User WHERE Username = 'ookaycdefghijk567@gmail.com' LIMIT 1];
        system.runAs(usr)
        { 
            Test.startTest(); 
            objCase[0].Stage__c= 'Resolved';
            update objCase[0]; 
            System.assertEquals(1, objCase.size(),'record found');          
             Test.stopTest();            
            }
    }
}