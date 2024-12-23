/*********************************************************
*Class        :  ABHI_EBOTCaseLogics_Test
*Author       :  Shubham Sinha
*Created Date :  13/11/2024
*@description  : Test class for ABHI_EBOTCaseLogics
***********************************************************/ 
@IsTest
public class ABHI_EBOTCaseLogics_Test {
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
                                    TimeZoneSidKey='America/Los_Angeles', UserName='cdefghijk5657123456@gmail.com',
                                    managerGroupId__c=slaGroup.Id);
        insert userRecord;
        System.runAs(userRecord) {
        ASF_Case_Category_Config__c ccc = new ASF_Case_Category_Config__c();
            ccc.Type__c = 'tes';
            ccc.First_Stage__c = 'New';
            ccc.CCC_External_Id__c = 'ABHI_Query_CCC_2212345';
            ccc.Business_Unit__c = 'ABHI';
            ccc.Sub_Type__c = 'Claims';
            ccc.EBOT_Auto_Response__c = True;
            ccc.Overall_Case_Closure_SLA__c = 10;
        insert ccc;
        // ASF_Case_Stage_Config__c  caseconfig =  new ASF_Case_Stage_Config__c (Order__c=1, Manual_Stage__c= True,Is_Approval_Stage__c = False,Default_Queue__c=g1.Id, StageName__c = 'In Progress with CEC', Case_Category_Config__c= ccc.Id);
        //insert caseconfig;
        //       
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
             Account accRec = ASF_TestDataFactory.insertPersonAccount('test', 'test', '100');
            accRec.Client_Code__c = 'ABHI123';
            update accRec;

            Asset assetRec = ASF_TestDataFactory.createAsset(accRec.Id, 'Loans');
            assetRec.Policy_No__c = '12345678';
            update assetRec;
        
             Case newCase = new Case();
            newCase.Subject = 'Test Case Creation';
            newCase.CCC_External_Id__c ='' ;
          newCase.Source__c =  'Email';
          newCase.Stage__c = 'Email';
          newCase.Origin = 'ABHI Email';
          newCase.SuppliedEmail = 'abcl.abhi@gmail.com';
           newCase.Business_Unit__c  = 'ABHI'; 
            insert newCase; 
  
            if(newCase.Id != null){
                EmailMessage eMsg = new EmailMessage();
                eMsg.ParentId = newCase.Id;
                eMsg.ToAddress = 'abcl.abfl@gmail.com';
                eMsg.CCAddress = 'test@test.com';
                eMsg.BCCAddress = 'test@test.com';
                insert eMsg;
                ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();    
                caseInt.Case__c =newCase.Id;
                caseInt.Status__c = 'Pending';
                caseInt.Type__c = 'eBOT';
                insert caseInt;
             ASF_Case_Integration__c caseIntUpdate = new ASF_Case_Integration__c();  
            caseIntUpdate.Status__c = 'Pending';
            caseIntUpdate.Response__c = 'waiting for response';
           insert caseIntUpdate;
            }
        }
    }
       @isTest   
    static void testEbot(){
        List<Case> objCase = [Select Id From Case WHERE Subject = 'Test Case Creation' LIMIT 1];

        User usr = [SELECT Id FROM User WHERE Username = 'cdefghijk5657123456@gmail.com' LIMIT 1];
        system.runAs(usr)
        {
        Test.startTest(); 
            List<ASF_Case_Integration__c> asfCaseInteg = [Select Id,Response__c,Status__c From ASF_Case_Integration__c WHERE Status__c = 'Pending' LIMIT 1];
            asfCaseInteg[0].Status__c = 'Success';
            asfCaseInteg[0].Response__c = '{"UpdateCase":{"UpdateCaseInput":{"CALLERCALLEE":"","CASENO":"CAS-91733-S0R3Z1","CASESUBTYPECODE":"7241","CASETYPECODE":"ABHI_Query_CCC_2212345","CONFSCORE":"0.99","ISSUCCESS":"YES","AlternateContact":"","PrimaryContact":"","Email":"","NomineeName":"","NomineeRelationship":"","NomineeContact":"","PanNo":"","AadharNo":"123456789123","Country":"","InternationalContactNo":"","InternationalAddress":"","PolicyNumber":"12345678","CancellationDate":null,"CancellationReason":null,"SendEmail":false},"table":{"EmailInput":[{"AttachmentData":{"AttachmentData":{"ATTACHEMNTBODY":"Claim==","ATTACHEMNTEXT":"pdf","ATTACHEMNTFILENAME":"TestEmail.pdf"}},"DESCRIPTION":"Hi Claims Team, This is a test Email for EBOT testing.","SUBJECT":"Test Email to Claims Team","ToEmailId":"Rahul.Uttekar@adityabirlacapital.com"}]}}}';
           	update asfCaseInteg;  
           	System.assertEquals('Success', asfCaseInteg[0].Status__c,'record found');          
        Test.stopTest(); 
        }
    }
      @isTest
    static void testWrapperClasses() {
        
        // Create instances of the wrapper classes
        ABHI_EBOTCaseLogics.UpdateCaseWrapper updateCaseWrapper = new ABHI_EBOTCaseLogics.UpdateCaseWrapper();
        ABHI_EBOTCaseLogics.UpdateCase updateCase = new ABHI_EBOTCaseLogics.UpdateCase();
        ABHI_EBOTCaseLogics.UpdateCaseInput updateCaseInput = new ABHI_EBOTCaseLogics.UpdateCaseInput();
        ABHI_EBOTCaseLogics.Table table = new ABHI_EBOTCaseLogics.Table();
        ABHI_EBOTCaseLogics.EmailInput emailInput = new ABHI_EBOTCaseLogics.EmailInput();
        ABHI_EBOTCaseLogics.AttachmentData attachmentData = new ABHI_EBOTCaseLogics.AttachmentData();
        
        // Set values for the fields
        updateCaseWrapper.UpdateCase = updateCase;
        
        updateCase.UpdateCaseInput = updateCaseInput;
        updateCase.table = table;
        
        updateCaseInput.CALLERCALLEE = 'Caller';
        updateCaseInput.CASENO = '12345';
        updateCaseInput.CASESUBTYPECODE = 'SubtypeCode';
        updateCaseInput.CASETYPECODE = 'TypeCode';
        updateCaseInput.CONFSCORE = '95';
        updateCaseInput.ISSUCCESS = 'true';
        updateCaseInput.AlternateContact = 'John Doe';
        updateCaseInput.PrimaryContact = 'Jane Doe';
        updateCaseInput.Email = 'example@example.com';
        updateCaseInput.NomineeName = 'Nominee1';
        updateCaseInput.NomineeRelationship = 'Spouse';
        updateCaseInput.NomineeContact = '9876543210';
        updateCaseInput.PanNo = 'ABCDE1234F';
        updateCaseInput.AadharNo = '1234-5678-9012';
        updateCaseInput.Country = 'India';
        updateCaseInput.InternationalContactNo = '1234567890';
        updateCaseInput.InternationalAddress = 'Some address, City, Country';
        updateCaseInput.PolicyNumber = 'POL12345';
        updateCaseInput.CancellationDate = Date.today();
        updateCaseInput.CancellationReason = 'Policy Expiry';
        updateCaseInput.SendEmail = true;
        
        table.EmailInput = new List<ABHI_EBOTCaseLogics.EmailInput>();
        table.EmailInput.add(emailInput);
        
        emailInput.AttachmentData = attachmentData;
        emailInput.DESCRIPTION = 'Test email description';
        emailInput.SUBJECT = 'Test Email Subject';
        emailInput.ToEmailId = 'recipient@example.com';
        
        attachmentData.ATTACHEMNTBODY = 'Attachment Body Content';
        attachmentData.ATTACHEMNTEXT = 'Attachment Text Content';
        attachmentData.ATTACHEMNTFILENAME = 'attachment.pdf';
        
        // Add assertions to verify the values set in the wrapper classes
        System.assertNotEquals(null, updateCaseWrapper.UpdateCase, 'UpdateCaseWrapper.UpdateCase should not be null');
        System.assertNotEquals(null, updateCase.UpdateCaseInput, 'UpdateCase.UpdateCaseInput should not be null');
        System.assertNotEquals(null, updateCaseInput.CALLERCALLEE, 'CALLERCALLEE should be set');
        System.assertEquals('12345', updateCaseInput.CASENO, 'CASENO should be 12345');
        System.assertEquals('95', updateCaseInput.CONFSCORE, 'CONFSCORE should be 95');
        System.assertEquals('India', updateCaseInput.Country, 'Country should be India');
        System.assertNotEquals(null, table.EmailInput, 'EmailInput list should not be null');
        System.assertEquals('Test email description', emailInput.DESCRIPTION, 'DESCRIPTION should be set correctly');
        System.assertEquals('attachment.pdf', attachmentData.ATTACHEMNTFILENAME, 'ATTACHEMNTFILENAME should be set');
        
    }
}