@isTest
public class ABCL_EmailMessageTriggerHandler_Test {
    
    // Helper method to create a test EmailMessage record
    private static EmailMessage createTestEmailMessage(Boolean isIncoming, Id parentId) {
        EmailMessage email = new EmailMessage(
            Subject = 'Test Email',
            FromAddress = 'test@example.com',
            ToAddress = 'recipient@example.com',
            Incoming = isIncoming,
            ParentId = parentId
        );
        return email;
    }

    // Test setup method
    @testSetup
    static void setup() {
        // Create test Case
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'New',
            RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId()
        );
        insert testCase;

        // Create test EmailMessage
        EmailMessage testEmailMessage = createTestEmailMessage(true, testCase.Id);
        insert testEmailMessage;
    }

    @isTest
    static void testBeforeInsert() {
        // Create test EmailMessage records
        List<EmailMessage> emailMessages = new List<EmailMessage>();
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        emailMessages.add(createTestEmailMessage(true, testCase.Id));
        
        Test.startTest();
        insert emailMessages;
        Test.stopTest();

        // Validate outcomes using assertions
        for (EmailMessage email : [SELECT Id, FromAddress, Status FROM EmailMessage WHERE Id IN :emailMessages]) {
            System.assertEquals('test@example.com', email.FromAddress, 'FromAddress should be set correctly.');
        }
    }

    @isTest
    static void testAfterInsert() {
        // Create test EmailMessage records
        List<EmailMessage> emailMessages = new List<EmailMessage>();
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        emailMessages.add(createTestEmailMessage(true, testCase.Id));
        
        Test.startTest();
        insert emailMessages;
        Test.stopTest();

        // Validate outcomes using assertions
        for (EmailMessage email : [SELECT Id, FromAddress, Status FROM EmailMessage WHERE Id IN :emailMessages]) {
            System.assertEquals('test@example.com', email.FromAddress, 'FromAddress should be set correctly.');
        }
    }

    @isTest
    static void testBeforeUpdate() {
        // Retrieve test EmailMessage
        EmailMessage emailMessage = [SELECT Id, ParentId, Incoming FROM EmailMessage LIMIT 1];
        emailMessage.subject = 'Test Subject';

        Test.startTest();
        update emailMessage;
        Test.stopTest();

        // Validate outcomes using assertions
        EmailMessage updatedEmail = [SELECT Id, subject FROM EmailMessage WHERE Id = :emailMessage.Id];
        System.assert(updatedEmail != null, 'Not Null');
    }
}