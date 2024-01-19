/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 01-20-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   01-20-2024   rsinghnagar@salesforce.com   Initial Version
**/
public class ASF_CaseTriggerBUSpecificHandler extends ASF_TriggerCustomEventHandler {
    // INSERT CONTEXT - START HERE
    public override void executeBeforeASFCodeInBeforeInsert(List<SObject> newItems){
        ABFL_CreateCaseProspectHelper.beforeInsertMethod((List<Case>)newItems);
        ABFL_OwnerChangeWithLocation.beforeInsertupdateSpoc(newItems);
    }
    public override void executeAfterASFCodeInBeforeInsert(List<SObject> newItems){

        ABHFL_CTSTHelper ctstHelperObj = new ABHFL_CTSTHelper();
        ABCL_CaseDuplicateCheck dupeChecker = new ABCL_CaseDuplicateCheck();
        dupeChecker.runDuplicateCheck((List<Case>)newItems);
        ctstHelperObj.prePopulateFields((List<Case>)newItems);
        
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
        // ABHFL_CTSTHelper.executeSpecificIntegrations((List<Case>)newItems.values());
    }
    // INSERT CONTEXT - ENDS HERE
    
    // UPDATE CONTEXT - ENDS HERE
    public override void executeBeforeASFCodeInBeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        System.debug('Inside executeBeforeASFCodeInBeforeUpdate');
        ABFL_OwnerChangeWithLocation.updateSpocWrtLocation((List<Case>)newItems.values(),(Map<Id, Case>)oldItems);
    }
    public override void executeAfterASFCodeInBeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        System.debug('Inside executeAfterASFCodeInBeforeUpdate');
        // ABHFL_CTSTHelper.OpenStageOwnershipChange((List<Case>)newItems.values(),(Map<Id, Case>)oldItems);
    }
    public override void executeBeforeASFCodeInAfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        System.debug('Inside executeBeforeASFCodeInAfterUpdate');
    }
    public override void executeAfterASFCodeInAfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        System.debug('Inside executeAfterASFCodeInAfterUpdate');
        ABHFL_CTSTHelper ctstHelperObj = new ABHFL_CTSTHelper();
        ctstHelperObj.callLitmusApi((List<Case>) newItems.values(), (Map<Id, Case>) oldItems);
    }
    
}