trigger ABCL_CaseIntegratnOutEventTrigger on Case_Integration_Outbound__e (after insert) {
    ABCL_CaseIntegratnOutEventTriggerHelper.afterInsertMethod(Trigger.New);
}