public class ASF_CaseTriggerBUSpecificHandler extends ASF_TriggerCustomEventHandler {
    // INSERT CONTEXT - START HERE
    public override void executeBeforeASFCodeInBeforeInsert(List<SObject> newItems){
        ABFL_CreateCaseProspectHelper.beforeInsertMethod((List<Case>)newItems);
        
    }
    public override void executeAfterASFCodeInBeforeInsert(List<SObject> newItems){
        ABCL_CaseDuplicateCheck dupeChecker = new ABCL_CaseDuplicateCheck();
        dupeChecker.runDuplicateCheck((List<Case>)newItems);
        
        if(System.Label.PAY_SkipCustomerCreationOnCaseCreationAPI != 'true'){
            PAY_CaseTriggerHelper.createCustomerForCreateCaseAPI((List<Case>)newItems);
        }
        
    }
    public override void executeBeforeASFCodeInAfterInsert(Map<Id, SObject> newItems){
        
    }
    public override void executeAfterASFCodeInAfterInsert(Map<Id, SObject> newItems){
        if(System.Label.PAY_SkipCustomerCreationOnCaseCreationAPI != 'true'){
            PAY_CaseTriggerHelper.fetchCustomerInfoExt((List<Case>)newItems.values());
        }
    }
    // INSERT CONTEXT - ENDS HERE
    
    // UPDATE CONTEXT - ENDS HERE
    public override void executeBeforeASFCodeInBeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        System.debug('Inside executeBeforeASFCodeInBeforeUpdate');
    }
    public override void executeAfterASFCodeInBeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        System.debug('Inside executeAfterASFCodeInBeforeUpdate');
    }
    public override void executeBeforeASFCodeInAfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        System.debug('Inside executeBeforeASFCodeInAfterUpdate');
    }
    public override void executeAfterASFCodeInAfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        System.debug('Inside executeAfterASFCodeInAfterUpdate');
    }
    
}