/**
 * @description       : Trigger on ABFL_Case_Detail__c Object
 * @author            : Udit Singhal
 * @createdDate       : 25-06-2024
 * @last modified on  : 25-06-2024
 * @last modified by  : Udit Singhal
 * Modifications Log
 * Ver      Date           Author            Modification
 * 1.0      25-06-2024     Udit Singhal      Initial Version
**/

trigger ABFL_Case_Detail_Trigger on ABFL_Case_Detail__c (before insert, after insert, before update, after update, before delete, after delete, after undelete) { // NOPMD

    TriggerDispatcher.Run(new ABFL_CaseDetailTriggerHandler());
}