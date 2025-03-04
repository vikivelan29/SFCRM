/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 04-24-2024
 * @last modified by  : rsinghnagar@salesforce.com 
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   04-24-2024   rsinghnagar@salesforce.com   Initial Version
**/
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
                //newPayment.Case__c = caseId;
            }
            upsert payments;
            Case caseRec = [SELECT Id,Stage__c FROM Case WHERE Id =: caseId];
            if (caseRec.Stage__c == 'Open') {
            List<ASF_Checklist__c> paymentChecklists = [SELECT Id, Status__c FROM ASF_Checklist__c WHERE Case__c = :caseId AND Label__c = 'Create Payment' LIMIT 1];

            if (!paymentChecklists.isEmpty()) {
                // Checklist found, update checklist status to 'Completed'
                ASF_Checklist__c paymentChecklist = paymentChecklists[0];
                paymentChecklist.Status__c = 'Completed';

                try {
                    update paymentChecklist;
                } catch (Exception e) {
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
    public static string deletePaymentRecord(String paymentId) {
        try {
            // Query the payment record by Id
            ABHFL_Payment__c paymentToDelete = [SELECT Id FROM ABHFL_Payment__c WHERE Id = :paymentId LIMIT 1]; 
            // Delete the payment record
            delete paymentToDelete;
            return 'deleted';
        } catch (Exception ex) {
            // Handle any exceptions and log the error
            return 'Error deleting payment record: ' + ex.getMessage();
        }
    }

}