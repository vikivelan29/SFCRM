public class RNWL_OpportunityTriggerHandler extends ASF_VTriggerHandler {

    private Boolean isTriggerDisabled(){
        return isDisabled('Opportunity');
    }
    
    /*public override void beforeInsert(List<Sobject> newItemsOpportunity) {
        if(isTriggerDisabled()){return;}
        RNWL_OpportunityTriggerHelper.setOpportunityFieldValues(newItemsOpportunity);
    }*/
    
    public override void afterInsert(Map<Id, SObject> newOpps) {
        if(isTriggerDisabled()){return;}
        RNWL_UbonaIntegrationController.firePlatformEventForUbona(newOpps.values(), null);
        RNWL_OpportunityTriggerHelper.tagOppOnDisposition(newOpps.values());
    }  
    
    public override void beforeUpdate(map<Id, Sobject> newOppMap, map<Id, Sobject> oldOppMap){
        if(isTriggerDisabled()){return;}
        system.debug('beforeUpdate');
        RNWL_OpportunityTriggerHelper.setBeforeUpdateOppFieldValues(newOppMap.values(), (Map<Id, Opportunity>)oldOppMap);
    }
    
    public override void afterUpdate(Map<Id, SObject> newOpps, Map<Id, SObject> oldOpps) {
        
        if(isTriggerDisabled()){return;}
        RNWL_UbonaIntegrationController.firePlatformEventForUbona(newOpps.values(), (Map<Id, Opportunity>)oldOpps);
        RNWL_OpportunityTriggerHelper.afterUpdateOpp(newOpps.values(), (Map<Id, Opportunity>)oldOpps);
    }

}