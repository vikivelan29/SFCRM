public class ASF_CaseApprovalTriggerHandler extends ASF_VTriggerHandler { 
    
    
    public static Boolean TriggerDisabled = false;
    
    public override void BeforeInsert(list<SObject> newItems) {
        if(!TriggerDisabled){
            ASF_CaseApprovalTriggerHelper v  = new ASF_CaseApprovalTriggerHelper();
            v.prepopupateUnpassedUserNames((List<ASF_Case_Approv__c>)newItems);
        }
    }
    
    public override void Afterinsert(map<Id, sObject> newItems) {
        if(!TriggerDisabled){
            ASF_CaseApprovalTriggerHelper v  = new ASF_CaseApprovalTriggerHelper();
            v.handleSubmitForApproval(newItems.values()); 
        }
    }
    
    public override void BeforeUpdate(map<Id, sObject> newItems,map<Id, sObject> oldItems) {
        if(!TriggerDisabled){
            ASF_CaseApprovalTriggerHelper v  = new ASF_CaseApprovalTriggerHelper();
            v.handleApprovalActions((Map<Id,ASF_Case_Approv__c>)oldItems,(Map<Id,ASF_Case_Approv__c>)newItems); 
        } 
    }
    
    public override void AfterUpdate(map<Id, sObject> newItems,map<Id, sObject> oldItems) {
        ASF_CaseApprovalTriggerHelper v  = new ASF_CaseApprovalTriggerHelper();
        v.moveToSuccessStage((Map<Id,ASF_Case_Approv__c>)newItems,(Map<Id,ASF_Case_Approv__c>)oldItems); 
    }    
    
}