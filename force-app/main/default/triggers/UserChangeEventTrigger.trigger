trigger UserChangeEventTrigger on UserChangeEvent(after insert){
    ABSLAMC_IDAMHelperClass.updateSLATargetsOnUserEmailChange(Trigger.New);
}