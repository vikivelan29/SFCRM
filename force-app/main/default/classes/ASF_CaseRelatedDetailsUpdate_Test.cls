@istest
public class ASF_CaseRelatedDetailsUpdate_Test {
    
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    @testSetup
    static void setupTestData(){
        User userRecord = new User(Alias = 'standt', Email='standarduser1@testorg.com', 
                                   EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_IN', ProfileId = SYSTEMADMIN_PROFILE.Id, 
                                   TimeZoneSidKey='Asia/Kolkata', UserName='abcdefghijk5612@gmail.com');
        insert userRecord;
        User userRecord1 = new User(Alias = 'standt', Email='stanrduser12@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_IN', ProfileId = SYSTEMADMIN_PROFILE.Id, 
                                    TimeZoneSidKey='Asia/Kolkata', UserName='cdefghijk562@gmail.com');
        insert userRecord1;
        User userRecord2 = new User(Alias = 'standt', Email='stadarduser123@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_IN', ProfileId = SYSTEMADMIN_PROFILE.Id, 
                                    TimeZoneSidKey='Asia/Kolkata', UserName='defghijk562@gmail.com');
        insert userRecord2;
        System.runAs(userRecord) {
            
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Manage_Case_Config'];
            PermissionSetAssignment psa = new PermissionSetAssignment();
            psa.AssigneeId = userRecord.Id;
            psa.PermissionSetId = ps.Id;
            insert psa;
            PermissionSet ps1 = [SELECT Id FROM PermissionSet WHERE Name = 'Create_Case'];
            PermissionSetAssignment psa1 = new PermissionSetAssignment();
            psa1.AssigneeId = userRecord.Id;
            psa1.PermissionSetId = ps1.Id;
            insert psa1;
        }
        
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
        ASF_Case_Category_Config__c ccc = new ASF_Case_Category_Config__c();
        ccc.Type__c = 'Loan Closure Related';
        ccc.Sub_Type__c='Foreclosure Statement - HF/LAP';
        ccc.CCC_External_Id__c = 'CCC-CASA-ALM-003R1';
        ccc.Apex_Class_Name__c = 'RAHandler';
        ccc.Apex_Method_Name__c = 'processSRDataBulk';
        insert ccc;
        
        ASF_Case_Category_Config__c ccc1 = new ASF_Case_Category_Config__c();
        ccc1.Type__c = 'Transaction Related Complaints';
        ccc1.Sub_Type__c='Issue regarding IMPS reversal';
        ccc1.CCC_External_Id__c = 'CCC-CASA-ALM-003R1';
        ccc1.Apex_Class_Name__c = 'RAHandler';
        ccc1.Apex_Method_Name__c = 'processSRDataBulk';
        insert ccc1;
        
        ASF_Case_Category_Config__c ccc2 = new ASF_Case_Category_Config__c();
        ccc2.Type__c = 'Transaction Related Complaints';
        ccc2.Sub_Type__c='Cash Dispute - Other Bank ATM';
        ccc2.CCC_External_Id__c = 'CCC-CASA-ALM-003R3';
        ccc2.Apex_Class_Name__c = 'RAHandler';
        ccc2.Apex_Method_Name__c = 'processSRDataBulk';
        insert ccc2;
        
        ASF_Case_Category_Config__c ccc3 = new ASF_Case_Category_Config__c();
        ccc3.Type__c = 'Transaction Related Complaints';
        ccc3.Sub_Type__c='Cash Dispute - Other Bank ATM';
        ccc3.CCC_External_Id__c = 'CCC-CASA-ALM-003R4';
        ccc3.Apex_Class_Name__c = 'RAHandler';
        ccc3.Apex_Method_Name__c = 'processSRDataBulk';
        insert ccc3; 
        
        list<Case> lstCases = new list<Case>();
        Case newCase = new Case( Type_Text__c = 'Testing', Sub_Type_Text__c  = 'CreditCard', Stage__c='In Progress with CEC', CCC_External_Id__c ='CCC-CASA-ALM-003R1');
        lstCases.add(newCase);
        Case newCase2 = new Case( Type_Text__c = 'Testing', Sub_Type_Text__c  = 'CreditCard', Stage__c='Pending Clarification', CCC_External_Id__c ='CCC-CASA-ALM-003R3');
        lstCases.add(newCase2);
        Case newCase3 = new Case( Type_Text__c = 'Testing',Status='New', Sub_Type_Text__c  = 'CreditCard', Stage__c='In Progress with CEC', CCC_External_Id__c ='CCC-CASA-ALM-003R2');
        lstCases.add(newCase3);
        Case newCase4 = new Case( Type_Text__c = 'Testing',Status='New', Sub_Type_Text__c  = 'CreditCard', Stage__c='In Progress with CEC', CCC_External_Id__c ='CCC-CASA-ALM-003R4');
        lstCases.add(newCase4);
        
        insert lstCases;
        
        Id frameworkId = Schema.Sobjecttype.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
        
        newCase4.RecordTypeId = frameworkId;
        update newCase4;
        
        ASF_Case_Stage_Config__c  caseconfig =  new ASF_Case_Stage_Config__c (Order__c=1, Manual_Stage__c= True,Is_Approval_Stage__c = False,Default_Queue__c='', StageName__c = 'In Progress with CEC', Case_Category_Config__c= ccc.Id);
        insert caseconfig;
        
        ASF_Case_Stage_Config__c  caseconfig2 =  new ASF_Case_Stage_Config__c (Order__c=2, Manual_Stage__c= True,Is_Approval_Stage__c = False,Default_Queue__c='', StageName__c = 'In Progress with CEC', Case_Category_Config__c= ccc.Id);
        insert caseconfig2;
        ASF_Case_Stage_Config__c  caseconfig3 =  new ASF_Case_Stage_Config__c (Order__c=1, Manual_Stage__c= True,Is_Approval_Stage__c = False,Default_Queue__c='', StageName__c = 'Pending Clarification', Case_Category_Config__c= ccc1.Id);
        insert caseconfig3;
        ASF_Case_Stage_Config__c  caseconfig4 =  new ASF_Case_Stage_Config__c (Order__c=2, Manual_Stage__c= True,Is_Approval_Stage__c = False,Default_Queue__c='', StageName__c = 'In Progress with CEC', Case_Category_Config__c= ccc1.Id);
        insert caseconfig4;
        ASF_Case_Stage_Config__c  caseconfig5 =  new ASF_Case_Stage_Config__c (Order__c=4, Manual_Stage__c= True,Is_Approval_Stage__c = False,Default_Queue__c='', StageName__c = ' Clarification', Case_Category_Config__c= ccc1.Id);
        insert caseconfig5;
        ASF_Case_Stage_Config__c  caseconfig6 =  new ASF_Case_Stage_Config__c (Order__c=2, Manual_Stage__c= True,Is_Approval_Stage__c = False,Default_Queue__c='', StageName__c = 'Clarification', Case_Category_Config__c= ccc1.Id);
        insert caseconfig6;
        
        ASF_Case_Stage_Config__c  caseconfig7 =  new ASF_Case_Stage_Config__c (Order__c=2, Manual_Stage__c= True,Is_Approval_Stage__c = False,Default_Queue__c='test', StageName__c = 'In Progress with CEC', Case_Category_Config__c= ccc1.Id);
        insert caseconfig7;
        
        ASF_Case_Rule__c csaRule = new ASF_Case_Rule__c ( Logical_Condition__c = 'test',Case_Stage_Config__c = caseconfig2.Id,Order__c = 1,Type__c ='Assignment');
        insert csaRule;
    }
    
    @isTest
    public static void wbgSubTypeUpdate(){
        /*ASF_Case_Category_Config__c caseRecord = [SELECT Id,CCC_External_Id__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c = 'CCC-CASA-ALM-003R1' LIMIT 1];
system.debug('caseRecordquey'+caseRecord); */
        Case c = [Select Id,CCC_External_Id__c,Stage__c,Source__c from Case where CCC_External_Id__c =: 'CCC-CASA-ALM-003R1' ];
        /*WBG_Details__c wbg = new WBG_Details__c();
wbg.Name = 'test';
insert wbg;
c.WBG_Details__c = wbg.Id;
update c; */
        List<Case> caseList = new List<Case>();
        caseList.add(c);
        
        Test.startTest(); 
        ASF_CaseRelatedDetailsUpdate relatedObject = new ASF_CaseRelatedDetailsUpdate();
        relatedObject.updateRelatedObjectDetailsBulk(caseList);
        System.assertEquals('CCC-CASA-ALM-003R1', c.CCC_External_Id__c);
        // ASF_CaseRelatedDetailsUpdate.updateRelatedObjectDetails(new List<Case>(c));
        
        // Ksc_CaseManualStageController.fetchManualStages(caseRecord.CCC_External_Id__c);
        Test.stopTest();     
        
    } 
    @isTest
    public static void wmDetailsSubTypeUpdate(){
        
        Case c = [Select Id,CCC_External_Id__c,Stage__c,Source__c from Case where CCC_External_Id__c =: 'CCC-CASA-ALM-003R2' ];
        List<Case> caseList = new List<Case>();
        caseList.add(c);
        
        Test.startTest(); 
        ASF_CaseRelatedDetailsUpdate relatedObject = new ASF_CaseRelatedDetailsUpdate();
        relatedObject.updateRelatedObjectDetailsBulk(caseList);
        // ASF_CaseRelatedDetailsUpdate.updateRelatedObjectDetails(c.Id);
        // Ksc_CaseManualStageController.fetchManualStages(caseRecord.CCC_External_Id__c);
        Test.stopTest();     
        System.assertEquals('CCC-CASA-ALM-003R2', c.CCC_External_Id__c);
    } 
    
    @isTest
    public static void ccDetailsUpdate(){
        
        Case c = [Select Id,CCC_External_Id__c,Stage__c,Source__c
                  from Case where CCC_External_Id__c =: 'CCC-CASA-ALM-003R4' ];
        List<Case> caseList = new List<Case>();
        caseList.add(c);
        
        Test.startTest(); 
        ASF_CaseRelatedDetailsUpdate relatedObject = new ASF_CaseRelatedDetailsUpdate();
        relatedObject.updateRelatedObjectDetailsBulk(caseList);
        Test.stopTest();     
        System.assertEquals('CCC-CASA-ALM-003R4', c.CCC_External_Id__c);
        
    } 
    
    @isTest
    public static void beforeInsertUpdateCaseTest() {
        Case c = [Select Id,CCC_External_Id__c,Stage__c,Source__c
                  from Case where CCC_External_Id__c =: 'CCC-CASA-ALM-003R4' ];
        List<Case> caseList = new List<Case>();
        caseList.add(c);
        System.debug('case case case'+c);
        
        Test.startTest(); 
            ASF_CaseRelatedDetailsUpdate related = new ASF_CaseRelatedDetailsUpdate();
            related.beforeInsertUpdateCase(caseList);
        System.assertEquals('CCC-CASA-ALM-003R4', c.CCC_External_Id__c);
        Test.stopTest();
    }
     @isTest
    static void removeAccountIdtest(){
        User usr = [SELECT Id FROM User WHERE Username = 'abcdefghijk5612@gmail.com' LIMIT 1];
        system.runAs(usr)
        { 
            Test.startTest(); 
            Id rtId = Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
            Id caseRecId = Schema.Sobjecttype.Case.getRecordTypeInfosByDeveloperName().get('Interaction').getRecordTypeId();
            Account acc= new Account(
            FirstName='Test FName',
            RecordTypeId = rtId,
            LastName='Test LName',
            Business_Unit__c = 'ABHFL',
            PersonMailingStreet='test@yahoo.com',
            PersonMailingPostalCode='12345',
            PersonMailingCity='SFO',
            PersonEmail='test@yahoo.com',
            PersonHomePhone='1234567',
            PersonMobilePhone='12345678'
        );
        insert acc;
             Case newCase = new Case();
                newCase.Subject = 'Test Case Creation';
                newCase.Business_Unit__c  = 'ABFL';
                newCase.RecordTypeId = caseRecId;
                newCase.AccountId = acc.Id;
                insert newCase;
             System.assertEquals('ABFL', newCase.Business_Unit__c,'value found');          
             Test.stopTest();            
         }
    } 
    @isTest
    static void findAndAssociateAssetToCaseTest(){
        User usr = [SELECT Id FROM User WHERE Username = 'abcdefghijk5612@gmail.com' LIMIT 1];
        system.runAs(usr)
        { 
            Test.startTest(); 
            Id rtId = Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
            Id caseRecId = Schema.Sobjecttype.Case.getRecordTypeInfosByDeveloperName().get('Interaction').getRecordTypeId();
            Account acc= new Account(
            FirstName='Test FName',
            RecordTypeId = rtId,
            LastName='Test LName',
            Business_Unit__c = 'ABSLI',
            PersonMailingStreet='test@yahoo.com',
            PersonMailingPostalCode='12345',
            PersonMailingCity='SFO',
            PersonEmail='test@yahoo.com',
            PersonHomePhone='1234567',
            PersonMobilePhone='12345678'
        );
        insert acc;
            
            Asset policy = new Asset();
            policy.Name = 'TEST00001';
            policy.Policy_No__c = 'TEST00001';
            policy.LAN__c='ABSLI_TEST00001';
            policy.AccountId = acc.Id;
            policy.Business_Unit__c= 'ABSLI';
            insert policy;
            
             Case newCase = new Case();
                newCase.Subject = 'Test Case Creation';
                newCase.Business_Unit__c  = 'ABSLI';
                newCase.RecordTypeId = caseRecId;
                newCase.AccountId = acc.Id;
                insert newCase;
             System.assertEquals('ABSLI', newCase.Business_Unit__c,'value found');          
             Test.stopTest();            
         }
    } 
}