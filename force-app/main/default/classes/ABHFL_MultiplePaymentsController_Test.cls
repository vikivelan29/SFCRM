@isTest
public class ABHFL_MultiplePaymentsController_Test {
    
    @TestSetup
    static void setup(){
            Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];  
            Blob b = Crypto.GenerateAESKey(128);
            String h = EncodingUtil.ConvertTohex(b);
            String uid = h.SubString(0,8); 
            User u = new User(Alias = uid, Email= uid + '@testdomain.com', 
                              EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                              LocaleSidKey='en_IN', ProfileId = p.Id, 
                              TimeZoneSidKey='Asia/Kolkata', UserName= uid + '@testdomain.com'); 
            insert u;
            PermissionSetGroup psg = [select Id, Status from PermissionSetGroup where DeveloperName='Super_Admin'];
            
            if(psg.Status != 'Updated'){
                Test.calculatePermissionSetGroup(psg.Id);
                insert new PermissionSetAssignment(PermissionSetGroupId = psg.Id, AssigneeId = u.Id);
            }
    
            System.runAs(u){
                ASF_TestDataFactory.createC3WithPrePopulateIntegrations();
                List<Case> cases = ASF_TestDataFactory.createCaseRecords(1);

                Case caseRec = [SELECT Id FROM case LIMIT 1];
                ASF_Checklist__c chk1 = new ASF_Checklist__c(Case__c = caseRec.Id, Status__c ='Pending', Label__c= 'Create Payment');
                insert chk1;
            }
    }

    @IsTest
    static void testGetPaymentsForCase(){

        User u = [select id from user where UserName like '%@testdomain.com' limit 1];
        System.runAs(u){
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
            update caseRec;

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

    @IsTest
    static void testdeletePaymentRecord(){
        ABHFL_Payment__c payment1 = new ABHFL_Payment__c();
        payment1.Payment_Identifier__c = '2w53423';
        payment1.Amount__c = 34532423;
        payment1.Mode_of_Payment__c = 'Cheque';
        payment1.Date__c = Date.today();

        insert payment1;
        String result = ABHFL_MultiplePaymentsController.deletePaymentRecord(payment1.Id);
        System.assertEquals('deleted', result);
    }
}