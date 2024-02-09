@isTest
public class ABHFL_ODPAlerts_Test {

    @isTest
    static void testGetOdpAlerts() {
        // Test data setup
        Account testAccount = new Account(Name = 'Test Acc',Client_Code__c = 'TestClientCode');
        insert testAccount;

        // Test the getOdpAlerts method
        List<ODPAlertResponse> result = ABHFL_ODPAlerts.getOdpAlerts(testAccount.Id,true);

        System.assertNotEquals(null, result);
        
    }
}