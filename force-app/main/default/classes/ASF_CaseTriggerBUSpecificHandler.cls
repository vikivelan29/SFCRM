public class ASF_CaseTriggerBUSpecificHandler extends ASF_TriggerCustomEventHandler {
    // INSERT CONTEXT - START HERE
    public override void executeBeforeASFCodeInBeforeInsert(List<SObject> newItems){

        ABFL_CreateCaseProspectHelper.beforeInsertMethod((List<Case>)newItems);
        ABFL_OwnerChangeWithLocation.beforeInsertupdateSpoc(newItems);
    }
    public override void executeAfterASFCodeInBeforeInsert(List<SObject> newItems){
        
        List<Case> newCaseList = (List<Case>)newItems;
        List<Case> newFrameworkCaseList = new List<Case>();
        ABCL_CommonCLass commonCLssObj = new ABCL_CommonCLass();
        ABHFL_CTSTHelper ctstHelperObj = new ABHFL_CTSTHelper();
        ABCL_CaseDuplicateCheck dupeChecker = new ABCL_CaseDuplicateCheck();

        for(Case caseRec : newCaseList) {
            String caseRecordTypeId = caseRec.RecordTypeId;
            Id frameworkRTId = ASF_Constants.RT_FRAMEWORK;
            if(caseRecordTypeId == frameworkRTId) {
                newFrameworkCaseList.add(caseRec);
            }
        }

        if(newFrameworkCaseList.size() > 0) {
            dupeChecker.runDuplicateCheck(newFrameworkCaseList);
            ctstHelperObj.prePopulateFields(newFrameworkCaseList);
            if(System.Label.PAY_SkipCustomerCreationOnCaseCreationAPI != 'true'){
                PAY_CaseTriggerHelper.createCustomerForCreateCaseAPI((List<Case>)newItems);
            }
        }
        commonCLssObj.prepopulateCaseFlds(newCaseList);

    }

    public override void executeBeforeASFCodeInAfterInsert(Map<Id, SObject> newItems){
        ABHFL_CTSTHelper ctstHelperObj = new ABHFL_CTSTHelper();
        ctstHelperObj.populateFieldsInAfterContext((List<Case>)newItems.values());
    }

    public override void executeAfterASFCodeInAfterInsert(Map<Id, SObject> newItems){

        if(System.Label.PAY_SkipCustomerCreationOnCaseCreationAPI != 'true'){
            PAY_CaseTriggerHelper.fetchCustomerInfoExt((List<Case>)newItems.values());
        }
        ABHFL_CTSTHelper.executeSpecificIntegrations((List<Case>)newItems.values(), new List<Case>());
        ABFL_OwnerChangeWithLocation.afterInsertupdateSpoc((List<Case>)newItems.values());
        //ABHFL_CTSTHelper.populateLANonDetail((List<Case>)newItems.values());
    }
    // INSERT CONTEXT - ENDS HERE
    
    // UPDATE CONTEXT - ENDS HERE
    public override void executeBeforeASFCodeInBeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        System.debug('Inside executeBeforeASFCodeInBeforeUpdate');
        ABFL_OwnerChangeWithLocation.updateSpocWrtLocation((List<Case>)newItems.values(),(Map<Id, Case>)oldItems);
    }
    public override void executeAfterASFCodeInBeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        System.debug('Inside executeAfterASFCodeInBeforeUpdate');
        ABHFL_CTSTHelper.preClosureStopAtCPUBanking((List<Case>)newItems.values(),(Map<Id, Case>)oldItems); 
        
        
    }
    public override void executeBeforeASFCodeInAfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        System.debug('Inside executeBeforeASFCodeInAfterUpdate');
        ABCL_CommonCLass.populateResolutionCommentOnCaseDetail((List<Case>)newItems.values(), (Map<Id, Case>)oldItems);
    }
    public override void executeAfterASFCodeInAfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        System.debug('Inside executeAfterASFCodeInAfterUpdate');
        ABHFL_CTSTHelper.executeSpecificIntegrations((List<Case>)newItems.values(), (List<Case>)oldItems.values());

        ABHFL_CTSTHelper ctstHelperObj = new ABHFL_CTSTHelper();
        ctstHelperObj.callLitmusApi((List<Case>) newItems.values(), (Map<Id, Case>) oldItems);

        //PR970457-417 ABFL - Customer survey through LITMUS
        ABFL_InvokeLitmusProcess invokeLitmusProcessObj = new ABFL_InvokeLitmusProcess();
        invokeLitmusProcessObj.evaluateCasesForLitmus((Map<Id, Case>) newItems, (Map<Id, Case>) oldItems);

        ABHFL_CTSTHelper.OpenStageOwnershipChange((List<Case>)newItems.values(),(Map<Id, Case>)oldItems);
        ABHFL_CTSTHelper.backwardMovementEmail((List<Case>)newItems.values(),(Map<Id, Case>)oldItems);
        ABFL_OwnerChangeWithLocation.updateSpocWrtLocation((List<Case>)newItems.values(),(Map<Id, Case>)oldItems);
        ABCL_InvokeOneABC.evaluateCasesForOneABC((Map<Id, Case>) newItems, (Map<Id, Case>) oldItems);

    }
    
}
