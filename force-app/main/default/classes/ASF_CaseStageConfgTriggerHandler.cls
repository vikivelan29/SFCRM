public class ASF_CaseStageConfgTriggerHandler extends ASF_VTriggerHandler {
    
    public static Boolean TriggerDisabled = false;
    
    public override void BeforeInsert(list<SObject> newItems) {
        ASF_CaseStageConfigTriggerHelper v = new ASF_CaseStageConfigTriggerHelper();
        v.prepopulateQueueIdFromNames((List<ASF_Case_Stage_Config__c>)newItems);
        
    }
    
    public override void Afterinsert(map<Id, sObject> newItems) {
        
    }
    
    public override void BeforeUpdate(map<Id, sObject> newItems,map<Id, sObject> oldItems) {
        ASF_CaseStageConfigTriggerHelper v = new ASF_CaseStageConfigTriggerHelper();
        v.prepopulateQueueIdFromNames((List<ASF_Case_Stage_Config__c>)newItems.values());
        v.validateStageNames((List<ASF_Case_Stage_Config__c>)newItems.values());
    }
    
    public override void AfterUpdate(map<Id, sObject> newItems,map<Id, sObject> oldItems) {
        
    }    
    
    
    
}