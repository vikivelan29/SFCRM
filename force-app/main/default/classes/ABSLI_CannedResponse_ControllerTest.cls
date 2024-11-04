@isTest
private class ABSLI_CannedResponse_ControllerTest {

    @testSetup
    static void setup() {

        ASF_TestDataFactory.createCaseCategoryConfig();
        // Create test data for Case
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = testAccount.Id);
        insert testContact;

        List<Case> csList = new List<Case>();

        Case testCase1 = new Case(
            AccountId = testAccount.Id,
            ContactId = testContact.Id,
            CCC_External_Id__c = 'CCC-CC-CCLTD-01',
            Issue_Type__c = 'Duplicate Policy Document Related',
            No_Auto_Communication__c = 'Email',
            Business_Unit__c = 'ABSLI'
        );
        csList.add(testCase1);

        Case testCase2 = new Case(
            AccountId = testAccount.Id,
            ContactId = testContact.Id,
            CCC_External_Id__c = 'ExternalId456',
            Issue_Type__c = 'Leakage Salvage'
        );
        csList.add(testCase2);

        insert csList;
        
        // Create test data for ASF_Case_Email_Config__c
        ASF_Case_Email_Config__c emailConfig = new ASF_Case_Email_Config__c(
            Canned_Response_Email_Template__c = 'Duplicate Policy Document Related Email Template',
            Case_Category_Config__c = [Select id From ASF_Case_Category_Config__c].Id,
            Type__c = 'Canned Response',
            Issue_Type__c = 'Duplicate Policy Document Related'
        );
        insert emailConfig;
    }

    @isTest
    static void testSendEmailForCannedResponseSuccess() {
        // Retrieve the test Case
        Case testCase = [SELECT Id FROM Case WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'];
        
        // Test the sendEmailForCannedResponse method
        Test.startTest();
        ABSLI_CannedResponse_Controller.CannedResponseWrapper result = ABSLI_CannedResponse_Controller.sendEmailForCannedResponse(testCase.Id);
        Test.stopTest();
        
        // Verify the result
        System.assert(result.isSuccess, 'The email sending should be successful.');
        System.assertEquals(System.Label.ABSLI_Canned_Response_Success_Message, result.successMessage, 'The success message should match.');
        System.assert(result.errorMessage == null, 'There should be no error message.');
    }

    @isTest
    static void testSendEmailForCannedResponseWithNoTemplate() {

        // Retrieve the test Case
        Case testCase = [SELECT Id FROM Case WHERE CCC_External_Id__c = 'ExternalId456'];

        // Test the sendEmailForCannedResponse method
        Test.startTest();
        ABSLI_CannedResponse_Controller.CannedResponseWrapper result = ABSLI_CannedResponse_Controller.sendEmailForCannedResponse(testCase.Id);
        Test.stopTest();

        System.assertEquals(System.Label.ABSLI_Canned_Response_Error_Message, result.errorMessage, 'The Error message should match.');
    }
}