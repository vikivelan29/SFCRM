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
            
            ASF_Case_Stage_Config__c stage1 = new ASF_Case_Stage_Config__c();
            stage1.Case_Category_Config__c = ccc.Id;
            stage1.Order__c = 1;
            stage1.StageName__c = 'New';
            stage1.Stage_SLA_1__c = 1;
            stage1.Status_Mapping__c = 'New';
            stage1.SLA_Target_1_Type__c = 'Manager';
            stage1.Query_Fields__c = 'Id,Stage__c';
            stage1.Manual_Stage__c = false;
            stage1.Default_Queue__c = g1.Id;
            insert stage1;
            
            Account accRec = ASF_TestDataFactory.insertPersonAccount('test', 'test', '100');
            accRec.Client_Code__c = 'ABHI123';
            update accRec;

            Asset assetRec = ASF_TestDataFactory.createAsset(accRec.Id, 'Loans');
            assetRec.Policy_No__c = '12345678';
            update assetRec;
        
            Case newCase = new Case();
            newCase.Subject = 'Test Case Creation';
            newCase.CCC_External_Id__c = '' ;
            newCase.Source__c = 'Email';
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
                caseInt.Case__c = newCase.Id;
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
        List<Case> objCase = [SELECT Id FROM Case WHERE Subject = 'Test Case Creation' LIMIT 1];

        User usr = [SELECT Id FROM User WHERE Username = 'cdefghijk5657123456@gmail.com' LIMIT 1];
        system.runAs(usr) {
            Test.startTest(); 
            List<ASF_Case_Integration__c> asfCaseInteg = [SELECT Id, Response__c, Status__c FROM ASF_Case_Integration__c WHERE Status__c = 'Pending' LIMIT 1];
            
            // Simulating ebot response in JSON format
            asfCaseInteg[0].Status__c = 'Success';
            asfCaseInteg[0].Response__c = '{"UpdateCase":{"UpdateCaseInput":{"CALLERCALLEE":"","CASENO":"00463058","CASESUBTYPECODE":"ABHI_Sequence_Request6","CASETYPECODE":"","CONFSCORE":0,"ISSUCCESS":"Yes","AlternateContact":"","PrimaryContact":"","Email":"","NomineeName":"","NomineeRelationship":"","NomineeContact":"","PanNo":"","AadharNo":"","Country":"","InternationalContactNo":"","InternationalAddress":"","PolicyNumber":"","CancellationDate":"","CancellationReason":"","SendEmail":false},"table":{"EmailInput":[{"AttachmentData":[{"ATTACHEMNTBODY":"","ATTACHEMNTEXT":"","ATTACHEMNTFILENAME":""}],"DESCRIPTION":" ","SUBJECT":"ebot abhi 1","ToEmailId":"abhicl.carehealthinsuranceuat@adityabirlacapital.com"}]}}}';
            update asfCaseInteg;
            
            // Assert that the status is updated to 'Success'
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
        
        updateCaseInput.CALLERCALLEE = '';
        updateCaseInput.CASENO = '00463058';
        updateCaseInput.CASESUBTYPECODE = 'ABHI_Sequence_Request6';
        updateCaseInput.CASETYPECODE = '';
        updateCaseInput.CONFSCORE = '0';
        updateCaseInput.ISSUCCESS = 'Yes';
        updateCaseInput.AlternateContact = '';
        updateCaseInput.PrimaryContact = '';
        updateCaseInput.Email = '';
        updateCaseInput.NomineeName = '';
        updateCaseInput.NomineeRelationship = '';
        updateCaseInput.NomineeContact = '';
        updateCaseInput.PanNo = '';
        updateCaseInput.AadharNo = '';
        updateCaseInput.Country = '';
        updateCaseInput.InternationalContactNo = '';
        updateCaseInput.InternationalAddress = '';
        updateCaseInput.PolicyNumber = '';
        updateCaseInput.CancellationDate = '';
        updateCaseInput.CancellationReason = '';
        updateCaseInput.SendEmail = false;
        
        table.EmailInput = new List<ABHI_EBOTCaseLogics.EmailInput>();
        table.EmailInput.add(emailInput);
        
        emailInput.AttachmentData = new List<ABHI_EBOTCaseLogics.AttachmentData>();
        emailInput.AttachmentData.add(attachmentData);
        emailInput.DESCRIPTION = ' ';
        emailInput.SUBJECT = 'ebot abhi 1';
        emailInput.ToEmailId = 'abhicl.carehealthinsuranceuat@adityabirlacapital.com';
        
        attachmentData.ATTACHEMNTBODY = '';
        attachmentData.ATTACHEMNTEXT = '';
        attachmentData.ATTACHEMNTFILENAME = '';
        
        // Add assertions to verify the values set in the wrapper classes
        System.assertNotEquals(null, updateCaseWrapper.UpdateCase, 'UpdateCaseWrapper.UpdateCase should not be null');
        System.assertNotEquals(null, updateCase.UpdateCaseInput, 'UpdateCase.UpdateCaseInput should not be null');
        System.assertEquals('00463058', updateCaseInput.CASENO, 'CASENO should be 00463058');
        System.assertEquals('0', updateCaseInput.CONFSCORE, 'CONFSCORE should be 0');
        System.assertEquals('', updateCaseInput.Country, 'Country should be empty');
        System.assertNotEquals(null, table.EmailInput, 'EmailInput list should not be null');
        System.assertEquals('ebot abhi 1', emailInput.SUBJECT, 'SUBJECT should be set correctly');
        System.assertEquals('', attachmentData.ATTACHEMNTFILENAME, 'ATTACHEMNTFILENAME should be empty');
    }
}