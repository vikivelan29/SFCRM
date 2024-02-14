@isTest
public class ABFL_E2C_CreationRulesTest {

    @isTest
    static void testCheckCreationRulesWithValidEmail() {
        Case testCase = new Case(Origin = 'ABFL Email');
        insert testCase;

        EmailMessage testEmail = new EmailMessage(
            Incoming = true,
            ToAddress = 'abcl.abfl@gmail.com',
            Subject = 'Auto-Reply',
        	FromAddress = 'invalid@from.address');
        testEmail.ParentId = testCase.Id;
        insert testEmail;

        Test.startTest();
        ABFL_E2C_CreationRules.checkCreationRules(new List<EmailMessage>{testEmail});
        Test.stopTest();

    }
}