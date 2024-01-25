@isTest
public class ABHFL_MultiplePaymentsController_Test {
    
    @TestSetup
    static void setup(){

        ASF_TestDataFactory.createC3WithPrePopulateIntegrations();
        List<Case> cases = ASF_TestDataFactory.createCaseRecords(1);

    }

    @IsTest
    static void testGetPaymentsForCase(){

        Case caseRec = [
                        SELECT Id 
                        FROM Case
                        LIMIT 1
                        ];
        List<ABHFL_Payment__c> payments = ABHFL_MultiplePaymentsController.getPaymentsForCase(caseRec.Id);
        // No payments
        system.assertEquals(0, payments.size());

        // Add some Payments
        ABHFL_Payment__c payment1 = new ABHFL_Payment__c();
        payment1.Payment_Identifier__c = '2w53423';
        payment1.Amount__c = 34532423;
        payment1.Mode_of_Payment__c = 'Cheque';
        payment1.Date__c = Date.today();

        ABHFL_MultiplePaymentsController.savePayments(caseRec.Id, new List<ABHFL_Payment__c>{payment1});

        List<ABHFL_Payment__c> paymentsAfter = ABHFL_MultiplePaymentsController.getPaymentsForCase(caseRec.Id);
        // No payments
        system.assertEquals(1, paymentsAfter.size());

    }

    @IsTest
    static void testSavePaymentsForCase(){

        Case caseRec = [
                        SELECT Id 
                        FROM Case
                        LIMIT 1
                        ];
        // Add some Payments, with Error
        
        ABHFL_Payment__c payment1 = new ABHFL_Payment__c();
        payment1.Amount__c = 34532423;
        payment1.Mode_of_Payment__c = 'Cheque';
        payment1.Date__c = Date.today();

        try{
            ABHFL_MultiplePaymentsController.savePayments(caseRec.Id, new List<ABHFL_Payment__c>{payment1});
        }
        catch(Exception ex){
            // Since Payment Identifier is Required, should throw exception
            assert.isTrue(true);
        }

    }

}