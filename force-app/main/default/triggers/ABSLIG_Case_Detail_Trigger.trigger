/**
 * @description       : Trigger on ABSLIG_Case_Detail__c Object
 * @author            : Anirudh Raturi
 * @createdDate       : 08-06-2024
 * @last modified on  : 08-06-2024
 * @last modified by  : Anirudh Raturi 
 * Modifications Log
 * Ver   Date         Author           Modification
 * 1.0   08-06-2024   Anirudh Raturi   Initial Version
**/

trigger ABSLIG_Case_Detail_Trigger on ABSLIG_Case_Detail__c (before insert,after insert,before update,after update,before delete,after delete, after undelete) {
    
    TriggerDispatcher.Run(new ABSLIG_CaseDetailTriggerHandler());
}