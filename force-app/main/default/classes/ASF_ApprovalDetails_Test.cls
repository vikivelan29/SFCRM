/******************************************************  
* Author           - Shubham Sinha
* Date             - 13- March-2023
* Description      - Test class for ApprovalDetails
********************************************************
*/
    @isTest
    public class ASF_ApprovalDetails_Test {
        private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    @testSetup
    static void setupTestData(){
        insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                           Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                           Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);

        User userRecord = new User(Alias = 'standt', Email='standarduser@testorg.com', 
             EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
             LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
             TimeZoneSidKey='America/Los_Angeles', UserName='abcdefghik562@gmail.com');
                insert userRecord;
        User userRecord1 = new User(Alias = 'standt', Email='standarduser@testorg.com', 
             EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
             LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
             TimeZoneSidKey='America/Los_Angeles',managerID = userRecord.Id, UserName='abcdefghijk562@gmail.com');
                insert userRecord1;
     User userRecord2 = new User(Alias = 'standt', Email='standarduser@testorg.com', 
             EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
             LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
             TimeZoneSidKey='America/Los_Angeles',managerID = userRecord.Id, UserName='abdehijk562@gmail.com');
                insert userRecord2; 
     User userRecord3 = new User(Alias = 'standt', Email='standarduser@testorg.com', 
             EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
             LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
             TimeZoneSidKey='America/Los_Angeles', UserName='abefghijk5@gmail.com');
                insert userRecord3;
    User userRecord4 = new User(Alias = 'standt', Email='standarduser@testorg.com', 
             EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
             LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
             TimeZoneSidKey='America/Los_Angeles', UserName='cdefghijk562@gmail.com');
                insert userRecord4;
        
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
      /*  CaseCategoryConfig__c  ccc = new CaseCategoryConfig__c (CCC_External_Id__c ='CCC-CC-RC-01',Nature__c = 'Query',Product__c= 'CEC',Type__c= 'Testing',
                                     Business_Unit__c = 'Wealth Management',Sub_Type__c = 'CreditCard');
        insert ccc;  */
        
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
    public static void testApproverDetail(){
        Case caseRecord = [SELECT Id,Type_Text__c,Sub_Type_Text__c FROM Case WHERE CCC_External_Id__c = 'CCC-CC-RC-01' LIMIT 1];
            system.debug('caseRecordquey'+caseRecord);
        User usr = [SELECT Id FROM User WHERE Username = 'abcdefghijk562@gmail.com'];
        ASF_Case_Approv__c app = [Select Id,Approval_Type__c ,Approver_01__c from ASF_Case_Approv__c where Approval_Type__c = 'Parallel - All to approve' LIMIT 1];
        system.runAs(usr)
        {
            Test.startTest();          
            ASF_ApprovalDetails.getApprovalHistory(caseRecord.Id);
            Test.stopTest();     
            System.assertEquals('Parallel - All to approve', app.Approval_Type__c);        
        }
    }    


}