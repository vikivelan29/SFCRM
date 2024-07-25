/**
 * @description Case trigger handler class for BU specific
 */
public class ASF_CaseTriggerBUSpecificHandler extends ASF_TriggerCustomEventHandler {
    /**
     * @description - Executes befor the ASF code runs in before insert context
     * @param newItems - list of new cases
     */
    // INSERT CONTEXT - START HERE
    public override void executeBeforeASFCodeInBeforeInsert(List<SObject> newItems){
        
        ABFL_BUSpecificCaseHandler.executeBeforeASFCodeInBeforeInsert((List<Case>)newItems);
        
        ABSLI_BeforeInsertTriggerLogic.executeBeforeASFCodeInBeforeInsert((List<Case>)newItems);
    }
      
     /**
     * @description - Executes after the ASF code runs in before insert context
     * @param newItems - list of new cases
     */
    public override void executeAfterASFCodeInBeforeInsert(List<SObject> newItems){
        
        List<Case> newCaseList = (List<Case>)newItems;
        List<Case> newFrameworkCaseList = new List<Case>();
        
        
        
        ABSLI_BeforeInsertTriggerLogic.executeBeforeInsertLogic((List<Case>)newItems);
        for(Case caseRec : newCaseList) {
            String caseRecordTypeId = caseRec.RecordTypeId;
            Id frameworkRTId = ASF_Constants.RT_FRAMEWORK;
            if(caseRecordTypeId == frameworkRTId) {
                newFrameworkCaseList.add(caseRec);
            }
        }

        if(newFrameworkCaseList.size() > 0) {
            ABCL_CaseDuplicateCheck dupeChecker = new ABCL_CaseDuplicateCheck();
            dupeChecker.runDuplicateCheck(newFrameworkCaseList);
            
            ABHFL_BUSpecificCaseHandler.executeAfterASFCodeInBeforeInsert(newFrameworkCaseList);
            
            if(System.Label.PAY_SkipCustomerCreationOnCaseCreationAPI != 'true'){
                PAY_CaseTriggerHelper.createCustomerForCreateCaseAPI((List<Case>)newItems);
            }
        }
        ABCL_CommonCLass commonCLssObj = new ABCL_CommonCLass();
        commonCLssObj.prepopulateCaseFlds(newCaseList);

    }

    /**
     * @description  Executes before the ASF code runs in after insert context
     * @param newItems - map of new cases
     */
    public override void executeBeforeASFCodeInAfterInsert(Map<Id, SObject> newItems){
        ABHFL_BUSpecificCaseHandler.executeBeforeASFCodeInAfterInsert((List<Case>)newItems.values());
        ABSLI_AfterInsertLogic.executeAfterInsertLogic((List<Case>)newItems.values());
    }

    /**
     * @description  Executes after the ASF code runs in after insert context
     * @param newItems - map of new cases
     */
    public override void executeAfterASFCodeInAfterInsert(Map<Id, SObject> newItems){

        ABHFL_BUSpecificCaseHandler.executeAfterASFCodeInAfterInsert((List<Case>) newItems.values());

        ABSLIG_CaseDetailHelperClass absligCaseDetHelperObj = new ABSLIG_CaseDetailHelperClass();

        if(System.Label.PAY_SkipCustomerCreationOnCaseCreationAPI != 'true'){
            PAY_CaseTriggerHelper.fetchCustomerInfoExt((List<Case>)newItems.values());
        }
        
        ABFL_BUSpecificCaseHandler.executeAfterASFCodeInAfterInsert((Map<Id, Case>) newItems);

        absligCaseDetHelperObj.populateABSLIGCaseDetailFields((List<Case>)newItems.values());
    }
    // INSERT CONTEXT - ENDS HERE
    
    // UPDATE CONTEXT - ENDS HERE
    /**
     * @description  Executes before the ASF code runs in before update context
     * @param newItems - map of new cases
     * @param oldItems - map of old cases
     */
    public override void executeBeforeASFCodeInBeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        ABFL_OwnerChangeWithLocation.updateSpocWrtLocation((List<Case>)newItems.values(),(Map<Id, Case>)oldItems);
        ABSLI_BeforeUpdateTriggerLogic.executeBeforeLogic((Map<Id, Case>)newItems, (Map<Id, Case>)oldItems);
        ABSLI_BeforeUpdateTriggerLogic.checkCreateCaseValidations((List<Case>)newItems.values(), (Map<Id, Case>)oldItems);
    }
    
    /**
     * @description  Executes after the ASF code runs in before update context
     * @param newItems - map of new cases
     * @param oldItems - map of old cases
     */
    public override void executeAfterASFCodeInBeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        
        ABHFL_BUSpecificCaseHandler.executeAfterASFCodeInBeforeUpdate((Map<Id, Case>)newItems,(Map<Id, Case>)oldItems);
        
        //ABFL_OwnerChangeWithLocation.updateCaseOwnerAtVerificationStage((Map<Id, Case>)newItems,(Map<Id, Case>)oldItems);
        ABSLI_BeforeUpdateAfterASFTriggerLogic.executeBeforeLogic((Map<Id, Case>)newItems, (Map<Id, Case>)oldItems);
    }

    /**
     * @description  Executes before the ASF code runs in after update context
     * @param newItems - map of new cases
     * @param oldItems - map of old cases
     */
    public override void executeBeforeASFCodeInAfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        ABCL_CommonCLass.populateResolutionCommentOnCaseDetail((List<Case>)newItems.values(), (Map<Id, Case>)oldItems);
    }

    /**
     * @description  Executes after the ASF code runs in after update context
     * @param newItems - map of new cases
     * @param oldItems - map of old cases
     */
    public override void executeAfterASFCodeInAfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        ABHFL_BUSpecificCaseHandler.executeAfterASFCodeInAfterUpdate((List<Case>)newItems.values(),(Map<Id,Case>)oldItems);

        ABSLIG_CaseDetailHelperClass absligCaseDetaHelpObj = new ABSLIG_CaseDetailHelperClass();
        

        ABFL_BUSpecificCaseHandler.executeAfterASFCodeInAfterUpdate((Map<Id, Case>) newItems, (Map<Id, Case>) oldItems);
        ABCL_InvokeOneABC.evaluateCasesForOneABC((Map<Id, Case>) newItems, (Map<Id, Case>) oldItems);

        absligCaseDetaHelpObj.populateABSLIGCaseDetailFieldsAfterCaseUpdate((List<Case>)newItems.values());
        
        ABSLI_AfterUpdateLogic.executeAfterInsertLogic((List<Case>)newItems.values(),(Map<Id,Case>)oldItems);
    }
}