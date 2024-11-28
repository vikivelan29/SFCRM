trigger ASF_CaseApprovalTrigger on ASF_Case_Approv__c (before insert,After insert , before update, after update) {
    TriggerDispatcher.Run(new ASF_CaseApprovalTriggerHandler());
}