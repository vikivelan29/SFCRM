@SuppressWarnings('PMD.MethodNamingConventions')
@isTest
public class ASF_Case360ParaTamperingHelper_Test {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    @TestSetup
    private static void dataSetup(){
        
        insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                           Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                           Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
         
        Account acc= new Account(
            FirstName='Test FName',
            LastName='Test LName',
            PersonMailingStreet='test1@yahoo.com',
            PersonMailingPostalCode='12345',
            PersonMailingCity='SFO',
            PersonEmail='test@yahoo.com',
            PersonHomePhone='1234567',
            PersonMobilePhone='12345678',
            Client_Code__c= 'abcd',
            RecordTypeId = Schema.sObjectType.Account.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId()
        );
        insert acc;
        User userRecord = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                                   EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
                                   TimeZoneSidKey='America/Los_Angeles', UserName='abcdefghik56@gmail.com');
        insert userRecord;
        Account acc_b = new Account(recordTypeId = Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Non_Individual').getRecordTypeId(),Name = 'TestCompanyName',Client_Code__c = '2144');
        insert acc_b;
        
        Contact contact1 = new Contact(AccountId = acc_b.Id,FirstName='Test FName',LastName='Test LName');
        insert contact1;
        
        PAY_Payment_Detail__c wmd = new PAY_Payment_Detail__c();
        insert wmd;
        
        Asset ast = new Asset(Name='AccountFinacial',AccountId=acc.Id, Price=100);
        insert ast;
        
        Test.startTest();
        
        
        
        ASF_Case_Category_Config__c  ccc = new ASF_Case_Category_Config__c (CCC_External_Id__c ='CCC-CC-RC-01',Nature__c = 'Query',Product__c= 'CEC',Type__c= 'Testing',
                                                                Business_Unit__c = 'Wealth Management',Sub_Type__c = 'CreditCard',Overall_Case_Closure_SLA__c = 24,First_Stage__c = 'In Progress with CEC');
        insert ccc;
        
        ASF_Case_Stage_Config__c  caseconfig =  new ASF_Case_Stage_Config__c (Order__c=1, Manual_Stage__c= True,Is_Approval_Stage__c = False,Default_Queue__c='', StageName__c = 'In Progress with CEC', Case_Category_Config__c= ccc.Id);
        insert caseconfig;
        
        ASF_Case_Stage_Config__c  caseconfig2 =  new ASF_Case_Stage_Config__c (Order__c=2, Manual_Stage__c= True,Is_Approval_Stage__c = False,Default_Queue__c='', StageName__c = 'In Progress with CEC', Case_Category_Config__c= ccc.Id);
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
        
        
        
        ASF_TriggerSkipperUtility.markTriggerRun('Case');
        Case c = new Case(AccountId=acc.Id,Subject='Test Case',CCC_External_Id__c='CCC-CC-RC-01',PAY_Payment_Detail__c=wmd.id,Stage__c='In Progress with CEC',AssetId = ast.Id);
        insert c;
        
        ASF_Case_Approv__c approver = new ASF_Case_Approv__c(Approver_01__c  = userRecord.Id,
                                                     SR__c =c.Id, 
                                                     Approval_Type__c ='Sequential', Requestor_Comments__c = 'approver created');
        insert approver;

        Test.stopTest();
        
    }
    @isTest
    private static void CaseTriggerHelperValidation(){
        List<Case> cases = [SELECT ID,CCC_External_Id__c,Stage__c,PAY_Payment_Detail__c FROM Case WHERE CCC_External_Id__c='CCC-CC-RC-01'];
        Map<String,String> record = new Map<String,String>();
        record.put('id',cases[0].PAY_Payment_Detail__c);
        record.put('Cash_Back_Amount__c','2123123');
        Test.startTest();
        try{
            ASF_Case360ParaTamperingHelper.executeValidation(cases[0].CCC_External_Id__c, cases[0].Stage__c, cases[0].Id, record, new List<String>(), new List<String>(), cases[0].PAY_Payment_Detail__c, true);
        }
        catch(exception e){
            System.assertEquals(e.getMessage(),'Cash Back Amount','Expected...');
        }
        Test.stopTest();
            
    }
    @isTest
    private static void CaseTriggerHelperValidation_withDefaultValue(){
        List<Case> cases = [SELECT ID,CCC_External_Id__c,Stage__c,PAY_Payment_Detail__c FROM Case WHERE CCC_External_Id__c='CCC-CC-RC-01'];
        Map<String,String> record = new Map<String,String>();
        record.put('id',cases[0].PAY_Payment_Detail__c);
        record.put('Request_for_Modification__c','ABC');
        record.put('Mode__c','XYZ');
        Test.startTest();
        List<String> fieldName = new List<String>{'Request_for_Modification__c'};
            List<String> fieldValue = new List<String>{'Physical'};
        try{
            ASF_Case360ParaTamperingHelper.executeValidation(cases[0].CCC_External_Id__c, cases[0].Stage__c, cases[0].Id, record, fieldName, fieldValue, cases[0].PAY_Payment_Detail__c, false);
        }
        catch(exception e){
            
            System.assertEquals(e.getMessage(),'Request for Modification','Expected...');
        }
        
        
        try{
            ASF_Case360ParaTamperingHelper.executeValidation(cases[0].CCC_External_Id__c, cases[0].Stage__c, cases[0].Id, record, new List<String>(), new List<String>(), cases[0].PAY_Payment_Detail__c, false);
        }
        catch(exception e){
            System.assertEquals(e.getMessage(),'Request for Modification','Expected...');
        }
        Test.stopTest();
    }
    @isTest
    private static void CaseTriggerHelperValidation_withoutUseExpression(){
        List<Case> cases = [SELECT ID,CCC_External_Id__c,Stage__c,PAY_Payment_Detail__c FROM Case WHERE CCC_External_Id__c='CCC-CC-RC-01'];
        Map<String,String> record = new Map<String,String>();
        record.put('id',cases[0].Id);
        record.put('Subject','TEST_SUBJECT');
        List<String> fieldName = new List<String>{'Subject'};
            List<String> fieldValue = new List<String>{'XYZ'};
                Test.startTest();
        try{
            ASF_Case360ParaTamperingHelper.executeValidation(cases[0].CCC_External_Id__c, cases[0].Stage__c, cases[0].Id, record, fieldName, fieldValue, cases[0].PAY_Payment_Detail__c, false);
        }
        catch(exception e){
            System.assertEquals(e.getMessage(),'Subject','Expected...');
        }
        
        try{
            ASF_Case360ParaTamperingHelper.executeValidation(cases[0].CCC_External_Id__c, cases[0].Stage__c, cases[0].Id, record, new List<String>(), new List<String>(), cases[0].PAY_Payment_Detail__c, false);
        }
        catch(exception e){
            System.assertEquals(e.getMessage(),'Subject','Expected...');
        }
        Test.stopTest();
    }
    
}