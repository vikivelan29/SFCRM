public class RNWL_DispositionsTriggerHandler extends ASF_VTriggerHandler{
    private Boolean isTriggerDisabled(){
        return isDisabled('Dispositions');
    }
    
    public override void beforeInsert(List<Sobject> newItemsDispositions) {
        if(isTriggerDisabled()){return;}
       	RNWL_DispositionsTriggerHelper.setBeforeInsertDispositionsPriorityFieldValue(newItemsDispositions);
        RNWL_DispositionsTriggerHelper.setRenewalRequestOnDisposition(newItemsDispositions);
    }

    public override void afterInsert(Map<Id,Sobject> newDispositionsMap) {
        if(isTriggerDisabled()){return;}
       	RNWL_DispositionsTriggerHelper.setAfterInsertDispositionsPriorityFieldValue(newDispositionsMap.values());
        RNWL_DispositionsTriggerHelper.updateDispositionsOnOpportunity((List<Dispositions__c>)newDispositionsMap.values() , null);
    }

    public override void afterUpdate(Map<Id, Sobject> newItems, Map<Id, Sobject> oldItems) {
        if(isTriggerDisabled()){return;}
        RNWL_DispositionsTriggerHelper.updateDispositionsOnOpportunity((List<Dispositions__c>)newItems.values(), (Map<Id,Dispositions__c>)oldItems);
    }
}