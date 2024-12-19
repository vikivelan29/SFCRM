trigger CRMToUNFYDFeedbackEventTrigger on CRM_to_UNFYD_Feedback_Event__e (after insert) {
	ABFL_CRMToUNFYDFeedbackTriggerHelper.afterInsertMethod(Trigger.New);
}