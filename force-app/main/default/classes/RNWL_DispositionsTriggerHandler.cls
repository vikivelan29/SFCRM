public class RNWL_DispositionsTriggerHandler extends ASF_VTriggerHandler{
    
        private Boolean isTriggerDisabled(){
        return isDisabled('Dispositions');
    }
    
    public override void beforeInsert(List<Sobject> newItemsDispositions) {
        if(isTriggerDisabled()){return;}
        
       	RNWL_DispositionsTriggerHelper.setBeforeInsertDispositionsPriorityFieldValue(newItemsDispositions);
        RNWL_DispositionsTriggerHelper.setRenewalRequestOnDisposition(newItemsDispositions);

    }
    
        public override void afterInsert(Map<Id,SObject> newDispositionsMap) {
        if(isTriggerDisabled()){return;}
        
       	RNWL_DispositionsTriggerHelper.setAfterInsertDispositionsPriorityFieldValue(newDispositionsMap.values());
            
    }

}