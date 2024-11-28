trigger ASF_CaseIntegration on ASF_Case_Integration__c (before insert, after update) {

    TriggerDispatcher.Run(new ASF_CaseIntegrationTriggerHandler());

}