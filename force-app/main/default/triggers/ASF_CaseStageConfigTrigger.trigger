trigger ASF_CaseStageConfigTrigger on ASF_Case_Stage_Config__c (before insert, Before update) {
    TriggerDispatcher.Run(new ASF_CaseStageConfgTriggerHandler());
}