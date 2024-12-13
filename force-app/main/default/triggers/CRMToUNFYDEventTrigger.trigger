trigger CRMToUNFYDEventTrigger on CRM_to_UNFYD_EVA_Event__e (after insert) {
	ABFL_CRMToUNFYDEventTriggerHelper.afterInsertMethod(Trigger.New);
}