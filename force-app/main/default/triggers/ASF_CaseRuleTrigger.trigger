trigger ASF_CaseRuleTrigger on ASF_Case_Rule__c (before insert, before update) {
    TriggerDispatcher.Run(new ASF_CaseRuleTriggerHandler());
}