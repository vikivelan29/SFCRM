trigger CRMToEBOTEventTrigger  on CRM_to_EBOT_Event__e (after insert) {
    // There is only one context - after insert
    ABCL_CRMToEBOTEventTriggerHelper.afterInsertMethod(Trigger.New);

}