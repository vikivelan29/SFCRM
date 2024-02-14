@isTest
public class ABHFL_LeadCreationAPI_Test {

    @isTest
    static void testSendLead() {
        // Create a test lead
        Lead testLead = new Lead(
            Company = 'Test Company',
            Email = 'test@example.com',
            FirstName = 'John',
            LastName = 'Doe'
           
        );
        insert testLead;

        Test.startTest();

        // Call the sendLead method with the test lead Id
        String result = ABHFL_LeadCreationAPI.sendLead(testLead.Id);

        Test.stopTest();
    }
}