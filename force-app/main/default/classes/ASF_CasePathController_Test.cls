@isTest
public class ASF_CasePathController_Test {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    @testSetup
    static void testSetup() {
        // Setup test data
        insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                            Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                            Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
        
        User userRecord = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                                   EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
                                   TimeZoneSidKey='America/Los_Angeles', UserName='abcdefghijk56@gmail.com');
        insert userRecord;
        User userRecord1 = new User(Alias = 'standt', Email='stanrduser@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
                                    TimeZoneSidKey='America/Los_Angeles', UserName='cdefghijk56@gmail.com');
        insert userRecord1;
        User userRecord2 = new User(Alias = 'standt', Email='stadarduser@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
                                    TimeZoneSidKey='America/Los_Angeles', UserName='defghijk56@gmail.com');
        insert userRecord2;
        System.runAs(userRecord) {
            
            PermissionSet ps1 = [SELECT Id FROM PermissionSet WHERE Name = 'Manage_Case_Config'];
            PermissionSetAssignment psa1 = new PermissionSetAssignment();
            psa1.AssigneeId = userRecord.Id;
            psa1.PermissionSetId = ps1.Id;
            insert psa1;
            
            PermissionSet ps2 = [SELECT Id FROM PermissionSet WHERE Name = 'Create_Case'];
            PermissionSetAssignment psa2 = new PermissionSetAssignment();
            psa2.AssigneeId = userRecord.Id;
            psa2.PermissionSetId = ps2.Id;
            insert psa2;
            
        }
        String RecordTypeId = (String)Schema.SObjectType.Account.getRecordTypeInfosByName().get('Non-Individual').getRecordTypeId(); 
        Account acc= new Account(
            Name ='Test FName',
            RecordTypeId=RecordTypeId
        );
        insert acc;  
        
        Contact con = new Contact();
        con.Lastname ='Test con';
        con.AccountId = acc.Id;
        con.Email = 'test@test.com';
        con.Phone = '8329673314';
        insert con;
        
        LOB_Master__c lob = new LOB_Master__c(LOB_Code__c = 'ABC', BusinessUnit__c = 'Wealth Management');
        insert lob;
        Asset ast = new Asset(Name='AccountFinacial',AccountId=acc.Id, LOB_Code__c = lob.Id,Price=100);
        insert ast;
        ASF_Case_Category_Config__c  ccc = new ASF_Case_Category_Config__c (CCC_External_Id__c ='CCC-CC-RC-01',Nature__c = 'Query',Product__c= 'CEC',Type__c= 'Testing',
                                                                            Business_Unit__c = 'Wealth Management',Sub_Type__c = 'CreditCard',Overall_Case_Closure_SLA__c = 24,First_Stage__c = 'In Progress with CEC');
        insert ccc;
        ASF_Case_Stage_Config__c  caseconfig =  new ASF_Case_Stage_Config__c (Order__c=1, Manual_Stage__c= True,Is_Approval_Stage__c = False,
                                                                              Default_Queue__c='', StageName__c = 'In Progress with CEC', 
                                                                              Case_Category_Config__c= ccc.Id, Optional_Stage__c = true,
                                                                             Stage_Help_Text__c = 'Testing');
        insert caseconfig;
        
        ASF_Case_Stage_Config__c  caseconfig2 =  new ASF_Case_Stage_Config__c (Order__c=2, Manual_Stage__c= True,Is_Approval_Stage__c = False,
                                                                               Default_Queue__c='', StageName__c = 'Closed', Case_Category_Config__c= ccc.Id,
                                                                               Optional_Stage__c = true,Stage_Help_Text__c = 'Testing');
        insert caseconfig2;
        
        ASF_Case_Field_Config__c   caseFieldconfig1 =  new ASF_Case_Field_Config__c  (Case_Main_Config__c  =ccc.Id,Display_Order__c=1, FieldAPIName__c = 'Cash_Back_Amount__c',ObjectAPIName__c = 'PAY_Payment_Detail__c',Default_Value__c = 'Digital',Default_Type__c = 'STRING',
                                                                                      ReadOnly__c = 'In Progress with CEC,Closed',Mandatory__c = 'Closed', Update__c = 'New,Closed,Pending');
        insert caseFieldconfig1;
        
        ASF_Case_Field_Config__c   caseFieldconfig2 =  new ASF_Case_Field_Config__c  (Case_Main_Config__c  =ccc.Id,Display_Order__c=2, FieldAPIName__c = 'Merchant_Biller_Name__c',ObjectAPIName__c = 'PAY_Payment_Detail__c',Default_Value__c = 'Asset.Price',Default_Type__c = 'Reference',
                                                                                      ReadOnly__c = 'Closed',Update__c='In Progress with CEC',Mandatory__c = 'Closed', Controlling_field__c  = 'Mode__c',Controlling_Experssion__c = 'Physical');
        insert caseFieldconfig2;
        
        ASF_Case_Field_Config__c   caseFieldconfig3 =  new ASF_Case_Field_Config__c  (Case_Main_Config__c  =ccc.Id,Display_Order__c=3, FieldAPIName__c = 'Subject',ObjectAPIName__c = 'Case',Default_Value__c = 'case.Account.Home_Branch__c',Default_Type__c = 'Reference',
                                                                                      ReadOnly__c = 'Closed',Mandatory__c = 'Closed', Controlling_field__c  = 'Mode__c',Controlling_Experssion__c = 'Physical', Use_Controlling_Formula__c = false);
        insert caseFieldconfig3;
        
        
        ASF_Case_Category_Config__c  ccc1 = new ASF_Case_Category_Config__c (CCC_External_Id__c ='CCC-CC-RC-0',Nature__c = 'Query',Product__c= 'CEC',Type__c= 'Testing',
                                                                             Overall_Case_Closure_SLA__c = 10 ,Business_Unit__c = 'Wealth Management',Sub_Type__c = 'CreditCard');
        insert ccc1;  
        
        PAY_Payment_Detail__c wmd = new PAY_Payment_Detail__c();
        insert wmd;
        List<Case> caseList = new List<Case>();
        Case c = new Case(AccountId=acc.Id,Subject='Test Case',CCC_External_Id__c='CCC-CC-RC-01',PAY_Payment_Detail__c=wmd.id,Stage__c='In Progress with CEC',AssetId = ast.Id);
        Case c1 = new Case(AccountId=acc.Id,Subject='Test Case',CCC_External_Id__c='CCC-CC-RC-01',PAY_Payment_Detail__c=wmd.id,Stage__c='Rejected',AssetId = ast.Id);
        caseList.add(c);
        caseList.add(c1);
        insert caseList;
        
    }
    @isTest
    static void testGetCasePath() {
        // Create a test Case record
        List<Case> testCaseLst =[select id,CCC_External_Id__c from case];
        
        
        
        
        ASF_CasePathController.StageWrapper wrapper = new ASF_CasePathController.StageWrapper();
        wrapper.HelpText ='tes';
        wrapper.isManual =false;        
        // Call the method being tested
        Test.startTest();
        List<ASF_CasePathController.StageWrapper> result = ASF_CasePathController.getCasePath(testCaseLst[0].Id);
        List<ASF_CasePathController.StageWrapper> result2 = ASF_CasePathController.getCasePath(testCaseLst[1].Id);
        
        List<ASF_CasePathController.StageWrapper> result3 = ASF_CasePathController.getCasePath1(testCaseLst[0].Id);
        List<ASF_CasePathController.StageWrapper> result4 = ASF_CasePathController.getCasePath1(testCaseLst[1].Id);
        System.assertEquals('tes', wrapper.HelpText);
        Test.stopTest();
    }
    
    
    
}