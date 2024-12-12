trigger ABFL_CRM_To_UNFYDEmailTrigger on CRM_to_UNFYD_Email_Event__e (after insert) {
	ABFL_CRMToUNFYDEmailTriggerHelper.afterInsertMethod(Trigger.New);
}