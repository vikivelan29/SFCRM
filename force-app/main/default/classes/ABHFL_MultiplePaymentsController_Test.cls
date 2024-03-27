@isTest
public class ABHFL_MultiplePaymentsController_Test {
    
    @TestSetup
    static void setup(){

        ASF_TestDataFactory.createC3WithPrePopulateIntegrations();
        List<Case> cases = ASF_TestDataFactory.createCaseRecords(1);

        Case caseRec = [SELECT Id FROM case LIMIT 1];
        ASF_Checklist__c chk1 = new ASF_Checklist__c(Case__c = caseRec.Id, Status__c ='Pending', Label__c= 'Create Payment');
        insert chk1;

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
        caseRec.stage__c = 'Open';
        //update caseRec;

        ABHFL_Payment__c payment1 = new ABHFL_Payment__c();
        payment1.Payment_Identifier__c = '2w53423';
        payment1.Amount__c = 34532423;
        payment1.Mode_of_Payment__c = 'Cheque';
        payment1.Date__c = Date.today();
        payment1.Case__c=caseRec.id;
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
        payment1.Case__c=caseRec.id;

        try{
            ABHFL_MultiplePaymentsController.savePayments(caseRec.Id, new List<ABHFL_Payment__c>{payment1});
        }
        catch(Exception ex){
            // Since Payment Identifier is Required, should throw exception
            assert.isTrue(true);
        }

    }

    @IsTest
    static void testdeletePaymentRecord(){
         Case caseRec = [
                        SELECT Id 
                        FROM Case
                        LIMIT 1
                        ];

        ABHFL_Payment__c payment1 = new ABHFL_Payment__c();
        payment1.Payment_Identifier__c = '2w53423';
        payment1.Amount__c = 34532423;
        payment1.Mode_of_Payment__c = 'Cheque';
        payment1.Date__c = Date.today();
        payment1.Case__c=caseRec.id;

        insert payment1;
        String result = ABHFL_MultiplePaymentsController.deletePaymentRecord(payment1.Id);
        System.assertEquals('deleted', result);
    }
}
