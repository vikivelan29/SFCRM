trigger Asf_BranchMasterTrigger on Branch_Master__c  (before insert, before update) {
    TriggerDispatcher.Run(new Asf_BranchMasterTriggerHandler());
}