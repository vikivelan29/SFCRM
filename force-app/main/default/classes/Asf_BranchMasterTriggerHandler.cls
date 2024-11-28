public with sharing class Asf_BranchMasterTriggerHandler extends ASF_VTriggerHandler{
    public static Boolean TriggerDisabled = false;
    
    public override void BeforeInsert(list<SObject> newItems) {
        Asf_BranchMasterTriggerHelper v = new Asf_BranchMasterTriggerHelper();  
        v.prepopulateQueueIdFromNames((List<Branch_Master__c>)newItems);
        
    }
    
    public override void Afterinsert(map<Id, sObject> newItems) {
        
    }
    
    public override void BeforeUpdate(map<Id, sObject> newItems,map<Id, sObject> oldItems) {
        Asf_BranchMasterTriggerHelper v = new Asf_BranchMasterTriggerHelper();
        v.prepopulateQueueIdFromNames((List<Branch_Master__c>)newItems.values());
    }
    
    public override void AfterUpdate(map<Id, sObject> newItems,map<Id, sObject> oldItems) {
        
    }    
}