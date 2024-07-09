/**
 * @description       : Class for delegating the business logic
 * @author            : Udit Singhal
 * @createdDate       : 25-06-2024
 * @last modified on  : 25-06-2024
 * @last modified by  : Udit Singhal 
 * Modifications Log
 * Ver      Date           Author            Modification
 * 1.0      25-06-2024     Udit Singhal      Initial Version
**/

public without sharing class ABFL_CaseDetailTriggerHandler extends ASF_VTriggerHandler {

    public override void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        try{
            //PR970457-2022 Auto-resolve that case once a UTR number is populated in Salesforce
            ABFL_Util.resolveCaseOnUTRPopulation((Map<Id, ABFL_Case_Detail__c>) newItems, (Map<Id, ABFL_Case_Detail__c>) oldItems);
        } catch(Exception e) {
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABFL_CaseDetailTriggerHandler.afterUpdate');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.message(e.getStackTraceString());
            ABCL_Logger.emit();
        }
    }
}