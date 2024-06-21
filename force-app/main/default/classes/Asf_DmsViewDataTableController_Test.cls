/*********************************************************
*Class        :  Asf_DmsViewDataTableController
*Author       :  Shubham Sinha 
*Created Date :  06/05/2024
@description  :  Test Class
*********************************************************/
@isTest
public class Asf_DmsViewDataTableController_Test {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    @testSetup
    static void setUpData(){
        Group g1 = new Group(Name='OCC-Test-Group', type='Queue');
            insert g1;
        User userRecord = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,
                                    TimeZoneSidKey='America/Los_Angeles', UserName='cdefghijk567@gmail.com'
                                    );
        insert userRecord;
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
                newCase.LAN__c = 'ABFLJOD';
                insert newCase; 
            
            DMS_Files__c dmsFile = new DMS_Files__c();
                dmsFile.DocumentID__c  = '1111';
                dmsFile.Status__c   = 'Pending';
                dmsFile.Business_Unit__c = 'ABFL';
                dmsFile.Case__c = newCase.Id;
                dmsFile.DMS_External_ID__c  = '777777';
            insert dmsFile;
        }
    }
        @isTest
    static void dmsFileTest(){
        List<Case> objCase = [Select Id,OwnerId,AssetId From Case WHERE LAN__c = 'ABFLJOD' LIMIT 1];
        User usr = [SELECT Id FROM User WHERE Username = 'cdefghijk567@gmail.com' LIMIT 1];
        system.runAs(usr)
        { 
            Test.startTest(); 
                Asf_DmsViewDataTableController.getColumns('abcd');
                Asf_DmsViewDataTableController.executeQuery(objCase[0].Id);
                Asf_DmsViewDataTableController.generateLinkParams('1111');
                System.assertEquals(1, objCase.size(),'record found');          
             Test.stopTest();            
         }
    }
}