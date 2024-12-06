/*********************************************************
*Class        :  ABFL_WealthChatGeneratedCases_Test
*Author       :  Salesforce 
*Created Date :  14/04/2024
*Last Modified:  14/04/2024
*Description  :  Test class for  ABFL_WealthChatGeneratedCases class
*********************************************************/

@isTest
public class ABFL_WealthChatGeneratedCases_Test {
    @isTest 
    public static void testWealthChatGeneratedCases(){
        
        Case newCase = new Case();
        newCase.Subject = 'Test Wealth Chat Cases';
        newCase.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Interaction').getRecordTypeId();
        newCase.Origin = ABFL_Constants.WMCHATCASEORIGIN;
        insert newCase;
        
        String[] toAddresses = new String[] {'test@test.com.invalid'}; 
            EmailMessage email = new EmailMessage();
        email.FromAddress = 'test@abc.org';
        email.Incoming = True;
        email.ToAddress= 'test@test.com.invalid';
        email.CcAddress='test2@test.com';
        email.Subject = 'Test Wealth Chat Cases';
        email.HtmlBody = 'This is test email with new name.. Email ID: test@gmail.com 8309u90 Mobile No . 9722392312  thanks ';
        email.ParentId = newCase.Id; 
        email.Headers = '';
        insert email;
        
        Case currentCase = [select Id, SuppliedEmail, SuppliedPhone from Case where Id =:newCase.Id ];
        System.assertEquals('test@gmail.com', currentCase.SuppliedEmail, 'Email should Match');
    }
    @isTest
    public static void testWealthChatGeneratedCasesNegative(){
        
        Case newCase = new Case();
        newCase.Subject = 'Test case';
        newCase.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Interaction').getRecordTypeId();
        
        insert newCase;
        String[] toAddresses = new String[] {'test@test.com.invalid'}; 
            EmailMessage email = new EmailMessage();
        email.FromAddress = 'test@abc.org';
        email.Incoming = True;
        email.ToAddress= 'test@test.com.invalid';
        email.Subject = 'Test case';
        email.HtmlBody = 'This is test email with new name..';
        email.ParentId = newCase.Id; 
        email.Headers = 'teestheader';
        insert email;
        
        Case currentCase = [select Id, SuppliedEmail, SuppliedPhone from Case where Id =:newCase.Id ];
        System.assertNotEquals('test@gmail.com', currentCase.SuppliedEmail, 'Email should Match');
        System.assertEquals(null, currentCase.SuppliedPhone, 'Phone should be null');
    }
    
    @isTest
    Public static void testsendEmailWhenNotRegisteredCustomer(){
        Case newCase = new Case();
        newCase.Subject = 'Test case';
        newCase.Origin = 'ABFL Email';
        newCase.Business_unit__c = 'ABFL';
        newCase.SuppliedEmail='test21@test.com';
        newCase.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Interaction').getRecordTypeId();
        insert newCase;
        
        ABFL_Case_Detail__c caseDetail = new ABFL_Case_Detail__c();
        caseDetail.case__c = newCase.id;
        caseDetail.IsRegisteredCustomer__c = 'No';
        insert caseDetail;
        
        List<contact> con = [select id from contact limit 1];
        
        Test.startTest();
        String[] toAddresses = new String[] {'test@test.com.invalid'}; 
            EmailMessage email = new EmailMessage();
        email.FromAddress = 'test@abc.org';
        email.Incoming = True;
        email.ToAddress= 'test@test.com.invalid';
        email.CcAddress='test2@test.com';
        email.Subject = 'Test case';
        email.HtmlBody = 'This is test email with new name..';
        email.ParentId = newCase.Id; 
        email.Headers = 'teestheader';
        email.ReplyToEmailMessageId = null;
        insert email;
        Test.stopTest();
        
        System.debug('+++3'+[SELECT id , Case__c FROM PE_Logger__c Where Case__c =: newCase.Id]);
        System.assertEquals(1, [SELECT COUNT() FROM ABFL_Case_Detail__c WHERE Case__c = :newCase.Id]);
        System.assertNotEquals(null, [SELECT Id FROM EmailMessage WHERE ParentId = :newCase.Id]);
    }
    
    @isTest
    public static void testSendEmailWhenNotRegisteredCustomerNew() {
        Case testCase = new Case();
        testCase.Subject = 'Test case';
        testCase.Origin = 'ABFL Email';
        testCase.Business_unit__c = 'ABFL';
        testCase.SuppliedEmail='test21@test.com';
        testCase.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Interaction').getRecordTypeId();
        insert testCase;
        
        ABFL_Case_Detail__c caseDetail = new ABFL_Case_Detail__c(
            Case__c = testCase.Id,
            IsRegisteredCustomer__c = 'No'
        );
        insert caseDetail; 
        
        String[] toAddresses = new String[] {'test@test.com.invalid'}; 
            EmailMessage email = new EmailMessage();
        email.FromAddress = 'test@abc.org';
        email.Incoming = True;
        email.ToAddress= 'test@test.com.invalid';
        email.CcAddress='test2@test.com';
        email.Subject = 'Test case';
        email.HtmlBody = 'This is test email with new name..';
        email.ParentId = testCase.Id; 
        email.Headers = 'teestheader';
        email.ReplyToEmailMessageId = null;
        insert email;
        Map<String, String> emailTemplateMap = new Map<String, String>();
        emailTemplateMap.put('winning@example.com', 'ABFL_FIRST_TAT_COMMUNICATION_DIGITAL');
        
        Test.startTest();
        List<EmailMessage> emailMessageList = [SELECT Id, ParentId, Incoming, Headers, Winning_Email__c, ReplyToEmailMessageId FROM EmailMessage];
        Boolean isAccPresent = false;
        ABFL_WealthChatGeneratedCases.sendEmailWhenNotRegisteredCustomer(emailMessageList, isAccPresent);
        Test.stopTest();
        Case updatedCase = [SELECT Id, SuppliedEmail FROM Case WHERE Id = :testCase.Id LIMIT 1];
    }   
}