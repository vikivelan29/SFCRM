@isTest
public with sharing class ABSLIG_SendCaseCreationEmail_Test {
    @testSetup
    static void setup() {
        // Test case
        Case testCase = new Case(
            Origin = 'Web',
            Status = 'New',
            Subject = 'Test Case',
            SuppliedEmail = 'test@example.com'
        );
        insert testCase;
        
        // Test EmailMessage
        EmailMessage testEmailMessage1 = new EmailMessage(
            ParentId = testCase.Id,
            Incoming = true,
            Subject = 'Test Email',
            ToAddress = 'test@example.com',
            FromAddress = 'customer@example.com',
            TextBody = 'Test email',
            Headers = 'In-Reply-To:'
        );
        insert testEmailMessage1;
        
        EmailMessage testEmailMessage2 = new EmailMessage(
            ParentId = testCase.Id,
            Incoming = true,
            Subject = 'Test Email 2',
            ToAddress = 'test@example.com',
            FromAddress = 'customer@example.com',
            TextBody = 'Test email 2'
        );
        insert testEmailMessage2;
        
        EmailMessage testEmailMessage3 = new EmailMessage(
            ParentId = testCase.Id,
            Incoming = true,
            Subject = 'Test Email 3',
            ToAddress = 'test@example.com',
            FromAddress = 'customer@example.com',
            TextBody = 'Test email 3',
            Headers = 'In-Reply-To:',
            ReplyToEmailMessageId = testEmailMessage2.Id
        );
        insert testEmailMessage3;
    }
    
    @isTest
    static void testSendEmailOnCaseCreation() {
        List<EmailMessage> emailMessageList = [SELECT Id, ParentId, Incoming, Headers, ReplyToEmailMessageId, Winning_Email__c FROM EmailMessage];
        Test.startTest();
        ABSLIG_SendCaseCreationEmail.sendEmailOnCaseCreation(emailMessageList);
        Test.stopTest();
        
        List<Case> updatedCases = [SELECT Id, Origin FROM Case WHERE Id IN (SELECT ParentId FROM EmailMessage)];
        System.assertEquals(1, updatedCases.size());
        
        List<EmailMessage> emailMessages = [SELECT Id, ParentId FROM EmailMessage WHERE ParentId IN :updatedCases];
        System.assertEquals(3, emailMessages.size());
    }
}