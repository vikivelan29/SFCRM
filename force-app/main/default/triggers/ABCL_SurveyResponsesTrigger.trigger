trigger ABCL_SurveyResponsesTrigger on Survey_Response__c (before insert) {
TriggerDispatcher.Run(new ABCL_SurveyResponseTriggerHandler());
}