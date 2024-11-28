public class ASF_CaseRuleTriggerHandler extends ASF_VTriggerHandler {
    
    public static Boolean TriggerDisabled = false;
    
    public override void BeforeInsert(list<SObject> newItems) {
        ASF_CaseRuleTriggerHelper v = new ASF_CaseRuleTriggerHelper();  
        v.prepopulateQueueIdFromNames((List<ASF_Case_Rule__c>)newItems);
        
    }
    
    public override void Afterinsert(map<Id, sObject> newItems) {
        
    }
    
    public override void BeforeUpdate(map<Id, sObject> newItems,map<Id, sObject> oldItems) {
        ASF_CaseRuleTriggerHelper v = new ASF_CaseRuleTriggerHelper();
        v.prepopulateQueueIdFromNames((List<ASF_Case_Rule__c>)newItems.values());
    }
    
    public override void AfterUpdate(map<Id, sObject> newItems,map<Id, sObject> oldItems) {
        
    }    
    
}