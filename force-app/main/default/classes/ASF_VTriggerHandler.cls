/*
 * Base class for all the trigger handlers.
 * Every trigger handler class must extend this class and 
 * implement the required methods only. 
*/

public virtual class ASF_VTriggerHandler {
    public virtual void BeforeInsert(List<SObject> newItems){system.debug('Virtual');}
 
    public virtual void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){}
 
    public virtual void BeforeDelete(Map<Id, SObject> oldItems){}
 
    public virtual void AfterInsert(Map<Id, SObject> newItems){}
 
    public virtual void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){}
 
    public virtual void AfterDelete(Map<Id, SObject> oldItems){}
 
    public virtual void AfterUndelete(Map<Id, SObject> oldItems){}
    public virtual Boolean IsDisabled(){return false;} //Keeping the old method too as its used in TriggerDispatcher.
    public Boolean isDisabled(String objectName){
        ASF_TriggerDeactivationSettings__c instCS = ASF_TriggerDeactivationSettings__c.getInstance(UserInfo.getUserId());
        System.debug('objectName'+objectName);
        return instCS.get('ASF_Deactivate_'+objectName+'_Trigger__c')==null?false:(Boolean)instCS.get('ASF_Deactivate_'+objectName+'_Trigger__c');
    }
}