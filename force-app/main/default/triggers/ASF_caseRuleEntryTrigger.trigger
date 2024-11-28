trigger ASF_caseRuleEntryTrigger on ASF_Case_Rule_Entry__c (after insert, after update) {
    TriggerDispatcher.Run(new ASF_CaseRuleEntryTriggerHandler());
}