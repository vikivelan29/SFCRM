trigger ABCL_SurveyResponsesTrigger on Survey_Response__c (before insert, after insert) {
TriggerDispatcher.Run(new ABCL_SurveyResponseTriggerHandler());
}