public class ASF_CaseRuleEntryTriggerHandler extends ASF_VTriggerHandler {
    public static Boolean TriggerDisabled = false;
    
    public override void BeforeInsert(list<SObject> newItems) {
        
    }
    
    public override void Afterinsert(map<Id, sObject> newItems) {
        ASF_CaseRuleEntryTriggerHelper creHandler = new ASF_CaseRuleEntryTriggerHelper();
        creHandler.updateCaseStageQueryCache((map<id,ASF_Case_Rule_Entry__c>)newItems);
    }
    
    public override void BeforeUpdate(map<Id, sObject> newItems,map<Id, sObject> oldItems) {
        
    }
    
    public override void AfterUpdate(map<Id, sObject> newItems,map<Id, sObject> oldItems) {
        ASF_CaseRuleEntryTriggerHelper creHandler = new ASF_CaseRuleEntryTriggerHelper();
        creHandler.updateCaseStageQueryCache((map<id,ASF_Case_Rule_Entry__c>)newItems);
    }    
}