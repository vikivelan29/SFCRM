@isTest
public class ABCL_EmailMessageHelper_Test {

    @isTest
    static void testEbotHandler() {
        Case testCase = new Case(
            Origin = 'ABFL Email',
            Business_Unit__c = 'ABFL',
            Technical_Source__c = 'Email'
        );
        insert testCase;

        EmailMessage testEmail = new EmailMessage(
            ParentId = testCase.Id,
            Subject = 'Test Subject',
            Incoming = true,
            Send_To_Ebot__c = true
        );
        insert testEmail;

        Test.startTest();
        ABCL_EmailMessageHelper.ebotHandler(new Map<Id, sObject>{ testEmail.Id => testEmail });
        Test.stopTest();

        List<Case >testCasse = [SELECT Id, Sent_to_EBOT__c FROM Case WHERE Id = :testCase.Id];
        System.assertEquals(1, testCasse.size(),'record found');          
    }

    // Test method for getEligibles
    @isTest
    static void testGetEligibles() {
        // Creating test data: List of EmailMessages
        List<EmailMessage> emails = new List<EmailMessage>();

        Case testCase = new Case();
        insert testCase;

        EmailMessage eligibleEmail = new EmailMessage(
            ParentId = testCase.Id,
            Subject = 'Eligible Subject',
            Incoming = true
        );
        EmailMessage ineligibleEmail = new EmailMessage(
            ParentId = testCase.Id,
            Subject = 'Ineligible Subject',
            Headers = 'In-Reply-To: xyz',
            Incoming = true,
            ReplyToEmailMessageId = '02sBi000001DjQ0AIK'
        );

        emails.add(eligibleEmail);
        emails.add(ineligibleEmail);

        List<EmailMessage> eligibleMessages = ABCL_EmailMessageHelper.getEligibles(emails);

        System.assertEquals(1, eligibleMessages.size(), 'Only one email should be eligible');
        System.assertEquals('Eligible Subject', eligibleMessages[0].Subject, 'Incorrect eligible email subject');
    }
}