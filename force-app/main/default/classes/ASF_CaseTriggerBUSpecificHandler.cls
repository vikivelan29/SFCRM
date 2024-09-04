/**
 * @description Case trigger handler class for BU specific
 */
public class ASF_CaseTriggerBUSpecificHandler extends ASF_TriggerCustomEventHandler {

    public ABHI_BusinessLogic_Helper abhiBusinessLogicHlprClass = new ABHI_BusinessLogic_Helper();

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
    public void executeAfterASFCodeInBeforeInsert(List<SObject> newItems){

        ABHI_BusinessLogic_Helper abhiBusLogicHelperObj = new ABHI_BusinessLogic_Helper();
        Map<String,List<Case>> mapOfBUToCases = getBUSpecificCaseRecords((List<Case>)newItems);
        Map<ID,List<Case>> mRecordTypeVsCases = ASF_CaseDistributionBasedOnRT.getCaseByRecordType((List<Case>)newItems);
        
        if(mRecordTypeVsCases.containsKey(frameworkRTId)){
            if(mRecordTypeVsCases.get(frameworkRTId).size()>0){
                ABCL_CaseDuplicateCheck dupeChecker = new ABCL_CaseDuplicateCheck();
                dupeChecker.runDuplicateCheck(mRecordTypeVsCases.get(frameworkRTId));
                
                for(String businessUnit : mapOfBUToCases.keySet()){
                    if(businessUnit == 'ABHFL'){
                        ABHFL_CTSTHelper ctstHelperObj = new ABHFL_CTSTHelper();
                        ctstHelperObj.prePopulateFields(mapOfBUToCases.get(businessUnit));
                    }
                    else if(businessUnit == 'Payments'){
                        if(System.Label.PAY_SkipCustomerCreationOnCaseCreationAPI != 'true'){
                            PAY_CaseTriggerHelper.createCustomerForCreateCaseAPI(mapOfBUToCases.get(businessUnit));
                        }
                    }
                    else if(businessUnit == 'ABHI'){
                        if(Label.ABHI_Case_Dedupe_Active == 'Active'){ // Story No: PR1030924-30
                            abhiBusLogicHelperObj.abhiHandlerMethod(mapOfBUToCases, new Map<Id, Case>(), 'AfterASFCodeInBeforeInsert');  
                        }
                         ABHI_IGMSHelperMethods.associateAssetIgms(mapOfBUToCases.get(businessUnit));
                         ABHI_IGMSHelperMethods.associateCustomerForAPIFromPhoneNumber(mapOfBUToCases.get(businessUnit));
                    }
                    if(businessUnit == 'ONEABC'){
                        ABCD_CaseDeDupeCheck.runDuplicateCheck(mRecordTypeVsCases.get(frameworkRTId), new List<Case>());
                    }
                                    }
                ABCL_CommonCLass commonCLssObj = new ABCL_CommonCLass();
                commonCLssObj.prepopulateCaseFlds(mRecordTypeVsCases.get(frameworkRTId));
            }
        }

    }
    
    public void executeBeforeASFCodeInAfterInsert(Map<Id, SObject> newItems){
        Map<String,List<Case>> mapOfBUToCases = getBUSpecificCaseRecords((List<Case>)newItems.values());
        Map<ID,List<Case>> mRecordTypeVsCases = ASF_CaseDistributionBasedOnRT.getCaseByRecordType((List<Case>)newItems.values());
        
        if(mRecordTypeVsCases.containsKey(frameworkRTId)){
            for(String businessUnit : mapOfBUToCases.keySet()){
                if(businessUnit == 'ABSLI'){
                    ABSLI_AfterInsertLogic.checkCreateCaseValidations(mapOfBUToCases.get(businessUnit)); 
                    ABSLI_AfterInsertLogic.executeAfterInsertLogic(mapOfBUToCases.get(businessUnit));
                }
                else if(businessUnit == 'ABHI'){
                    ABHI_BusinessLogic_Helper abhiBusinessLogicHlprClass = new ABHI_BusinessLogic_Helper();
                    abhiBusinessLogicHlprClass.checkAndBypassValidationFromAPICaseMember(mapOfBUToCases.get(businessUnit));
                   // ABHI_IGMSHelperMethods.associateAssetIgms(mapOfBUToCases.get(businessUnit)); 
                }
                else if(businessUnit == 'ABHFL'){
                    ABHFL_CTSTHelper ctstHelperObj = new ABHFL_CTSTHelper();
                    ctstHelperObj.populateFieldsInAfterContext(mapOfBUToCases.get(businessUnit));
                }
            }
        }
    }
    
    /**
     * @description  Executes after the ASF code runs in before update context
     * @param newItems - map of new cases
     * @param oldItems - map of old cases
     */
    public override void executeAfterASFCodeInBeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Map<String,List<Case>> mapOfBUToNewCs = initializeBUSpecificCases((Map<Id, Case>)newItems, (Map<Id, Case>)oldItems);
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
        abhiBusinessLogicHlprClass.abhiHandlerMethod(mapOfBUToNewCs, (Map<Id, Case>)oldItems, 'AfterASFCodeBeforeUpdate');
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
        
    }
    
    public void executeBeforeASFCodeInBeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Map<String,List<Case>> mapOfBUToCases = getBUSpecificCaseRecords((List<Case>)newItems.values());
        Map<ID,List<Case>> mRecordTypeVsCases = ASF_CaseDistributionBasedOnRT.getCaseByRecordType((List<Case>)newItems.values());
        
             
        if(mRecordTypeVsCases.containsKey(frameworkRTId)){
            for(String businessUnit : mapOfBUToCases.keySet()){
                if(businessUnit == 'ABFL'){
                   //ABFL_OwnerChangeWithLocation.updateSpocWrtLocation(mapOfBUToCases.get(businessUnit),(Map<Id, Case>)oldItems);
                }
                else if(businessUnit =='ABSLI'){
                    ABSLI_BeforeUpdateTriggerLogic.executeBeforeLogic(new Map<Id, Case>(mapOfBUToCases.get(businessUnit)), (Map<Id, Case>)oldItems);
                    ABSLI_BeforeUpdateTriggerLogic.checkCreateCaseValidations(mapOfBUToCases.get(businessUnit), (Map<Id, Case>)oldItems);
                }else if(businessUnit == 'ABHI'){
                    ABHI_BusinessLogic_Helper objHelper = new ABHI_BusinessLogic_Helper();
                    objHelper.abhiHandlerMethod(mapOfBUToCases, (Map<Id, Case>)oldItems, 'BeforeASFCodeInBeforeUpdate');
                }
            }
        }
    }

    /**
     * @description  Executes before the Case DML code runs in after update context
     * @param newItems - map of new cases
     * @param oldItems - map of old cases
     */
    public override void executeBeforeCaseDMLInAfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        ABSLI_AfterUpdateLogic.changeOwnerOnAutoResolve((List<Case>)newItems.values(),(Map<Id,Case>)oldItems);
    }

     /**
     * @description  handler method for interaction Cases
     * @param newItems - map of new cases
     * @param oldItems - map of old cases
     */
    public void beforeUpdateInteractionCases(Map<Id,Case> newItems, Map<Id, Case> oldItems){
        
        Map<String,List<Case>> mapOfBUToNewCs = initializeBUSpecificCases(newItems, oldItems);
        abhiBusinessLogicHlprClass.abhiHandlerMethod(mapOfBUToNewCs, oldItems, 'AfterASFCodeBeforeUpdate');
    }

    /**
     * @description  initialize BU specific Cases
     * @param newItems - map of new cases
     * @param oldItems - map of old cases
     * @return mapOfBUToCases - map of BU to Cases
     */
    public Map<String,List<Case>> initializeBUSpecificCases(Map<Id,Case> newItems, Map<Id, Case> oldItems){

        Map<String,List<Case>> mapOfBUToCases = new Map<String,List<Case>>();

        for(Case newCs : newItems.values()) {
            String businessUnit = newCs?.Business_Unit__c;

            if(mapOfBUToCases.containsKey(businessUnit)) {
                mapOfBUToCases.get(businessUnit).add(newCs);
            }
            else {
                mapOfBUToCases.put(businessUnit, new List<Case>{newCs});
            }
        }
        return mapOfBUToCases;
    }
}