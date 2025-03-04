@isTest
public class ABHFL_ODPAlerts_Test {

    @isTest
    static void testGetOdpAlerts() {
        // Test data setup
        Account testAccount = new Account(Name = 'Test Acc',Client_Code__c = 'TestClientCode');
        insert testAccount;

        // Test the getOdpAlerts method
        List<ODPAlertResponse> result = ABHFL_ODPAlerts.getOdpAlerts(testAccount.Id,true);
        testAccount.Client_Code__c = '';
        update testAccount;
        try{
            List<ODPAlertResponse> result1 = ABHFL_ODPAlerts.getOdpAlerts(testAccount.Id,false);
        }catch(Exception e){
            System.debug('exception e=> '+e);
            System.AssertEquals('System.AuraHandledException: Script-thrown exception', e.toString());
        }
		
        System.assertNotEquals(null, result);
        
        
    }
}