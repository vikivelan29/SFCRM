public with sharing class ABHFL_MultiplePaymentsController {


    @AuraEnabled(cacheable=true)
    public static List<ABHFL_Payment__c> getPaymentsForCase(Id caseId){
        try {
            List<ABHFL_Payment__c> payments = [
                SELECT Id, Amount__c, Date__c, Mode_of_Payment__c, Payment_Identifier__c, Realization_Status__c
                FROM ABHFL_Payment__c
                WHERE Case__c =: caseId
            ];
            return payments;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * This method will Save the changes made to payment records (UPSERT)
     * This method will also check for validations to be applied, and accordingly
     * update the checklist on Case for this stage
     */
    @AuraEnabled
    public static string savePayments(Id caseId, List<ABHFL_Payment__c> payments){
        String result = 'Success';
        try {
            for(ABHFL_Payment__c newPayment : payments){
                newPayment.Case__c = caseId;
            }
            upsert payments;
            Case caseRec = [SELECT Id,Stage__c FROM Case WHERE Id =: caseId];
            if(caseRec.Stage__c == 'Open'){
                ASF_Checklist__c paymentChecklist = [SELECT Id, Status__c FROM ASF_Checklist__c WHERE Case__c = :caseId AND Label__c = 'Create Payment' LIMIT 1];
                if(paymentChecklist != null){
                    // Update checklist status to 'Completed'
                    paymentChecklist.Status__c = 'Completed';
                    try {
                        update paymentChecklist;
                    } catch(Exception e) {
                        throw new AuraHandledException('Error updating checklist: ' + e.getMessage());
                    }
                } 
            }
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void deletePaymentRecord(String paymentId) {
        try {
            // Query the payment record by Id
            ABHFL_Payment__c paymentToDelete = [SELECT Id FROM ABHFL_Payment__c WHERE Id = :paymentId LIMIT 1];

            // Check if the record exists before attempting to delete
            if (paymentToDelete != null) {
                // Delete the payment record
                delete paymentToDelete;
            } else {
                // Handle the case where the record was not found
                throw new AuraHandledException('Payment record not found.');
            }
        } catch (Exception ex) {
            // Handle any exceptions and log the error
            throw new AuraHandledException('Error deleting payment record: ' + ex.getMessage());
        }
    }

}