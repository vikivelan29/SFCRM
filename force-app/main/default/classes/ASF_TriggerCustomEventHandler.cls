public virtual class ASF_TriggerCustomEventHandler {
    
    // BEFORE INSERT CONTEXT
    public virtual void executeBeforeASFCodeInBeforeInsert(List<SObject> newItems){}
    public virtual void executeAfterASFCodeInBeforeInsert(List<SObject> newItems){}
    // BEFORE UPDATE CONTEXT
    public virtual void executeBeforeASFCodeInBeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){}
    public virtual void executeAfterASFCodeInBeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){}
    
    
    
    // AFTER INSERT CONTEXT    
    public virtual void executeBeforeASFCodeInAfterInsert(Map<Id, SObject> newItems){}
    public virtual void executeAfterASFCodeInAfterInsert(Map<Id, SObject> newItems){}
    // AFTER UPDATE CONTEXT        
    public virtual void executeBeforeASFCodeInAfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){}
    public virtual void executeAfterASFCodeInAfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){}
    public virtual void executeBeforeCaseDMLInAfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){}

}