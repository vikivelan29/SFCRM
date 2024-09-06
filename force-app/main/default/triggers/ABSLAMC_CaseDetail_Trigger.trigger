/**
 * @description       : Trigger on ABSLAMC_Case_Detail__c Object
 * @author            : Neeraj Kumar
 * @createdDate       : 02-09-2024
 * Modifications Log
 * Ver      Date           Author            Modification
 * 1.0      02-09-2024     Neeraj Kumar      Initial Version
**/
trigger ABSLAMC_CaseDetail_Trigger on ABSLAMC_Case_Detail__c (after insert,after update) {
    TriggerDispatcher.Run(new ABSLAMC_CaseDetailTriggerHandler());
}