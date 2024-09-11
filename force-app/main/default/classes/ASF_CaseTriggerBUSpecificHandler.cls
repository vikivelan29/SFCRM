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
        Id frameworkRTId = ASF_Constants.RT_FRAMEWORK;
        ABFL_OwnerChangeWithLocation.checkCCCExternalIdAndAddRTId((List<Case>)newItems);
        Map<ID,List<Case>> mRecordTypeVsCases1 = ASF_CaseDistributionBasedOnRT.getCaseByRecordType((List<Case>)newItems);
        if(mRecordTypeVsCases1.containsKey(frameworkRTId)){
            ABFL_CreateCaseProspectHelper.beforeInsertMethod(mRecordTypeVsCases1.get(frameworkRTId));
            ABFL_OwnerChangeWithLocation.beforeInsertupdateSpoc(mRecordTypeVsCases1.get(frameworkRTId));
            ABSLI_BeforeInsertTriggerLogic.executeBeforeASFCodeInBeforeInsert((List<Case>)newItems);
        }
    }
      
     /**
     * @description - Executes after the ASF code runs in before insert context
     * @param newItems - list of new cases
     */
    public override void executeAfterASFCodeInBeforeInsert(List<SObject> newItems){
        
        List<Case> newCaseList = (List<Case>)newItems;
        List<Case> newFrameworkCaseList = new List<Case>();
        ABCL_CommonCLass commonCLssObj = new ABCL_CommonCLass();
        ABHFL_CTSTHelper ctstHelperObj = new ABHFL_CTSTHelper();
        ABCL_CaseDuplicateCheck dupeChecker = new ABCL_CaseDuplicateCheck();
        ABSLI_BeforeInsertTriggerLogic.executeBeforeInsertLogic((List<Case>)newItems);
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

    /**
     * @description  Executes before the ASF code runs in after insert context
     * @param newItems - map of new cases
     */
    public override void executeBeforeASFCodeInAfterInsert(Map<Id, SObject> newItems){
        ABHFL_CTSTHelper ctstHelperObj = new ABHFL_CTSTHelper();
        ctstHelperObj.populateFieldsInAfterContext((List<Case>)newItems.values());
        
        Id frameworkRTId = ASF_Constants.RT_FRAMEWORK;
        Map<ID,List<Case>> mRecordTypeVsCases1 = ASF_CaseDistributionBasedOnRT.getCaseByRecordType((List<Case>)newItems.values());
        if(mRecordTypeVsCases1.containsKey(frameworkRTId)){
        	//AM-Validating case creation for different CTSTs against policy statuses for ABSLI.
        	ABSLI_AfterInsertLogic.checkCreateCaseValidations(mRecordTypeVsCases1.get(frameworkRTId)); 
        ABSLI_AfterInsertLogic.executeAfterInsertLogic((List<Case>)newItems.values());
    }
    }

    /**
     * @description  Executes after the ASF code runs in after insert context
     * @param newItems - map of new cases
     */
    public override void executeAfterASFCodeInAfterInsert(Map<Id, SObject> newItems){
        ABHFL_CTSTHelper ctstHelperObj = new ABHFL_CTSTHelper();
        ABSLIG_CaseDetailHelperClass absligCaseDetHelperObj = new ABSLIG_CaseDetailHelperClass();
        ABHI_CaseDetailHelper abhilCaseDetailHelperObj = new ABHI_CaseDetailHelper();
        
        if(System.Label.PAY_SkipCustomerCreationOnCaseCreationAPI != 'true'){
            PAY_CaseTriggerHelper.fetchCustomerInfoExt((List<Case>)newItems.values());
        }
        ABHFL_CTSTHelper.executeSpecificIntegrations((List<Case>)newItems.values(), new List<Case>());
        ABFL_OwnerChangeWithLocation.afterInsertupdateSpoc((List<Case>)newItems.values());
        //ABHFL_CTSTHelper.populateLANonDetail((List<Case>)newItems.values());
        
        // Create Comment if the case is closed while creation.[through api]
        ABFL_OwnerChangeWithLocation.createCaseCommentWhenClosedAfterInsert((List<Case>)newItems.values());
        ctstHelperObj.ICAndPICEvaluationOnApiCall((List<Case>)newItems.values());
        absligCaseDetHelperObj.populateABSLIGCaseDetailFields((List<Case>)newItems.values());
        abhilCaseDetailHelperObj.populateABHILCaseDetailFields((List<Case>)newItems.values());
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
        if(Label.ABHFL_Case_Dedupe_Active=='Active'){
            ABHFL_CTSTHelper.runDuplicateCheckForUpdate((List<Case>)newItems.values(),(Map<Id, Case>)oldItems);    
        }
        ABHFL_CTSTHelper.preClosureStopAtCPUBanking((List<Case>)newItems.values(),(Map<Id, Case>)oldItems); 
        ABHFL_CTSTHelper.updateSlaBrokenCheckOnStageMovement((List<Case>)newItems.values(),(Map<Id, Case>)oldItems);
        ABFL_OwnerChangeWithLocation.updateCaseOwnerAtVerificationStage((Map<Id, Case>)newItems,(Map<Id, Case>)oldItems);
        ABSLI_BeforeUpdateAfterASFTriggerLogic.executeBeforeLogic((Map<Id, Case>)newItems, (Map<Id, Case>)oldItems);
        ABSLAMC_CaseAssignmentHelper.updateAssignmentOnStageChange((Map<Id, Case>)newItems, (Map<Id, Case>)oldItems);
        // Restrict Backward Stage movement from Stage 3 to Stage 1 - ABSLAMC Journey 5
        ABSLAMC_BU_CTSTHelper.restrictBackStageMovementFromStage3ToSatage1((Map<Id, Case>)newItems, (Map<Id, Case>)oldItems);
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
        ABHFL_CTSTHelper.executeSpecificIntegrations((List<Case>)newItems.values(), (List<Case>)oldItems.values());
        ABSLIG_CaseDetailHelperClass absligCaseDetaHelpObj = new ABSLIG_CaseDetailHelperClass();
        ABHI_CaseDetailHelper abhilCaseDetailHelperObj = new ABHI_CaseDetailHelper();
        
        ABHFL_CTSTHelper ctstHelperObj = new ABHFL_CTSTHelper();
        ctstHelperObj.callLitmusApi((List<Case>) newItems.values(), (Map<Id, Case>) oldItems);

        //PR970457-417 ABFL - Customer survey through LITMUS
        ABFL_InvokeLitmusProcess invokeLitmusProcessObj = new ABFL_InvokeLitmusProcess();
        invokeLitmusProcessObj.evaluateCasesForLitmus((Map<Id, Case>) newItems, (Map<Id, Case>) oldItems);

        ABHFL_CTSTHelper.OpenStageOwnershipChange((List<Case>)newItems.values(),(Map<Id, Case>)oldItems);
        ABHFL_CTSTHelper.backwardMovementEmail((List<Case>)newItems.values(),(Map<Id, Case>)oldItems);
        //AM-PR970457-1295
        ABHFL_CTSTHelper.sendGrievanceDetailsEmail((List<Case>)newItems.values(),(Map<Id, Case>)oldItems);
        //AM-call method to delete existing asset detail records on customer change
        ABHFL_CTSTHelper.deleteExistingAssetDetails((List<Case>)newItems.values(),(Map<Id, Case>)oldItems);
        ABFL_OwnerChangeWithLocation.updateSpocWrtLocation((List<Case>)newItems.values(),(Map<Id, Case>)oldItems);
        ABCL_InvokeOneABC.evaluateCasesForOneABC((Map<Id, Case>) newItems, (Map<Id, Case>) oldItems);

        absligCaseDetaHelpObj.populateABSLIGCaseDetailFieldsAfterCaseUpdate((List<Case>)newItems.values());
        
        ABSLI_AfterUpdateLogic.executeAfterInsertLogic((List<Case>)newItems.values(),(Map<Id,Case>)oldItems);
        abhilCaseDetailHelperObj.populateABHILCaseDetailFields((List<Case>)newItems.values());
        //ABSLAMC_CaseAssignmentHelper.dummyMethod((Map<Id, Case>) newItems, (Map<Id, Case>) oldItems);
        ABSLAMC_CaseAssignmentHelper.updateCaseExtensionFields((Map<Id, Case>) newItems, (Map<Id, Case>) oldItems);
    }
   
    /**
     * @description  Executes before the Case DML code runs in after update context
     * @param newItems - map of new cases
     * @param oldItems - map of old cases
     */
    public override void executeBeforeCaseDMLInAfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        ABSLI_AfterUpdateLogic.changeOwnerOnAutoResolve((List<Case>)newItems.values(),(Map<Id,Case>)oldItems);
    }
}