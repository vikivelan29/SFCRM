/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-20-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class ASF_CaseTriggerBUSpecificHandler {
    public static final Id frameworkRTId = ASF_Constants.RT_FRAMEWORK;
    
    public void executeBeforeASFCodeInBeforeInsert(List<SObject> newItems){
        Map<String,List<Case>> mapOfBUToCases = getBUSpecificCaseRecords((List<Case>)newItems);
        Map<ID,List<Case>> mRecordTypeVsCases = ASF_CaseDistributionBasedOnRT.getCaseByRecordType((List<Case>)newItems);
        // EXECUTE BELOW CODE FOR FRAMEWORK RECORDTYPE CASES - 
        if(mRecordTypeVsCases.containsKey(frameworkRTId)){
            for(String businessUnit : mapOfBUToCases.keySet()){
                if(businessUnit == 'ABFL'){
                    ABFL_OwnerChangeWithLocation.checkCCCExternalIdAndAddRTId(mapOfBUToCases.get(businessUnit));
                    ABFL_CreateCaseProspectHelper.beforeInsertMethod(mapOfBUToCases.get(businessUnit));
                }else if(businessUnit == 'ABHFL'){
                    ABHFL_CTSTHelper.skipOpenStageforAPIcases(mapOfBUToCases.get(businessUnit));    // Added method for EY_PR970457-2388,EY_PR970457-2288 by Yogesh EY(ABCL)
                }else if(businessUnit == 'ABSLI'){
                    ABSLI_BeforeInsertTriggerLogic.executeBeforeASFCodeInBeforeInsert(mapOfBUToCases.get(businessUnit));
                    ABSLI_BeforeInsertTriggerLogic.executeBeforeInsertLogic(mapOfBUToCases.get(businessUnit));
                }
            }
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
    
    public void executeAfterASFCodeInAfterInsert(Map<Id, SObject> newItems){
        Map<String,List<Case>> mapOfBUToCases = getBUSpecificCaseRecords((List<Case>)newItems.values());
        Map<ID,List<Case>> mRecordTypeVsCases = ASF_CaseDistributionBasedOnRT.getCaseByRecordType((List<Case>)newItems.values());
        
        
        if(mRecordTypeVsCases.containsKey(frameworkRTId)){
            for(String businessUnit : mapOfBUToCases.keySet()){
                if(businessUnit == 'Payments'){
                    if(System.Label.PAY_SkipCustomerCreationOnCaseCreationAPI != 'true'){
                        PAY_CaseTriggerHelper.fetchCustomerInfoExt(mapOfBUToCases.get(businessUnit));
                    } 
                }
                else if(businessUnit == 'ABHFL'){
                    ABHFL_CTSTHelper ctstHelperObj = new ABHFL_CTSTHelper();
                    ABHFL_CTSTHelper.executeSpecificIntegrations(mapOfBUToCases.get(businessUnit), new List<Case>());
                    ctstHelperObj.ICAndPICEvaluationOnApiCall(mapOfBUToCases.get(businessUnit));
                }
                else if(businessUnit == 'ABSLIG'){
                    ABSLIG_CaseDetailHelperClass absligCaseDetHelperObj = new ABSLIG_CaseDetailHelperClass();
                    absligCaseDetHelperObj.populateABSLIGCaseDetailFields(mapOfBUToCases.get(businessUnit));
                }
                else if(businessUnit == 'ABHI'){
                    ABHI_CaseDetailHelper abhilCaseDetailHelperObj = new ABHI_CaseDetailHelper();
                    ABHI_BusinessLogic_Helper abhiBusinessLogicHlprClass = new ABHI_BusinessLogic_Helper();
                    abhilCaseDetailHelperObj.populateABHILCaseDetailFields(mapOfBUToCases.get(businessUnit));
                    abhiBusinessLogicHlprClass.abhiHandlerMethod(mapOfBUToCases, new Map<Id, Case>(), 'AfterASFCodeInAfterInsert');
                    abhiBusinessLogicHlprClass.searchAndAssocFieldsForAPICases((List<Case>)newItems.values(), null);
                }
                else if(businessUnit == 'ABFL'){
                    ABFL_OwnerChangeWithLocation.afterInsertupdateSpoc((List<Case>)newItems.values());
                    ABFL_OwnerChangeWithLocation.createCaseCommentWhenClosedAfterInsert((List<Case>)newItems.values());
                }
                
            }
        }
        
    }
    
    public void executeBeforeASFCodeInBeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Map<String,List<Case>> mapOfBUToCases = getBUSpecificCaseRecords((List<Case>)newItems.values());
        Map<ID,List<Case>> mRecordTypeVsCases = ASF_CaseDistributionBasedOnRT.getCaseByRecordType((List<Case>)newItems.values());
        
             
        if(mRecordTypeVsCases.containsKey(frameworkRTId)){
            for(String businessUnit : mapOfBUToCases.keySet()){
                if(businessUnit == 'ABFL'){
                   //ABFL_OwnerChangeWithLocation.updateSpocWrtLocation(mapOfBUToCases.get(businessUnit),(Map<Id, Case>)oldItems);
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
    
    public void executeAfterASFCodeInBeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Map<String,List<Case>> mapOfBUToCases = getBUSpecificCaseRecords((List<Case>)newItems.values());
        Map<ID,List<Case>> mRecordTypeVsCases = ASF_CaseDistributionBasedOnRT.getCaseByRecordType((List<Case>)newItems.values());
        
        if(mRecordTypeVsCases.containsKey(frameworkRTId)){
            for(String businessUnit : mapOfBUToCases.keySet()){
                if(businessUnit == 'ABHFL'){
                    if(Label.ABHFL_Case_Dedupe_Active=='Active'){
                        ABHFL_CTSTHelper.runDuplicateCheckForRecat((List<Case>)newItems.values(),(Map<Id, Case>)oldItems); // added changes for PR970457-2474 by Yogesh
                        ABHFL_CTSTHelper.runDuplicateCheckForUpdate(mapOfBUToCases.get(businessUnit),(Map<Id, Case>)oldItems);    
                    }
                    ABHFL_CTSTHelper.preClosureStopAtCPUBanking(mapOfBUToCases.get(businessUnit),(Map<Id, Case>)oldItems);
                    ABHFL_CTSTHelper.updateSlaBrokenCheckOnStageMovement(mapOfBUToCases.get(businessUnit),(Map<Id, Case>)oldItems);
                }
                else if(businessUnit == 'ABFL'){
                    ABFL_OwnerChangeWithLocation.updateCaseOwnerAtVerificationStage(new Map<Id, Case>(mapOfBUToCases.get(businessUnit)),(Map<Id, Case>)oldItems);
                    ABSLAMC_SprinklrHelper.blankOutLatestNotes(new Map<Id, Case>(mapOfBUToCases.get(businessUnit)), (Map<Id, Case>)oldItems);
                }
                else if(businessUnit == 'ABSLI'){
                    ABSLI_BeforeUpdateAfterASFTriggerLogic.executeBeforeLogic(new Map<Id,Case>(mapOfBUToCases.get(businessUnit)), (Map<Id, Case>)oldItems);
                }
                else if(businessUnit == 'ABSLAMC'){
                    ABSLAMC_CaseAssignmentHelper.updateAssignmentOnStageChange(new Map<Id, Case>(mapOfBUToCases.get(businessUnit)), (Map<Id, Case>)oldItems);
                    ABSLAMC_CaseAssignmentHelper.updateCaseStage(new Map<Id, Case>(mapOfBUToCases.get(businessUnit)), (Map<Id, Case>)oldItems);
                    ABSLAMC_BU_CTSTHelper.restrictBackStageMovementFromStage3ToSatage1(new Map<Id, Case>(mapOfBUToCases.get(businessUnit)), (Map<Id, Case>)oldItems);
                    ABSLAMC_BU_CTSTHelper.validateManualApproval(new Map<Id, Case>(mapOfBUToCases.get(businessUnit)), (Map<Id, Case>)oldItems);
                    ABSLAMC_SprinklrHelper.blankOutLatestNotes(new Map<Id, Case>(mapOfBUToCases.get(businessUnit)), (Map<Id, Case>)oldItems);
                    ABSLAMC_BU_CTSTHelper.CheckQueueAssignementSpecificToLOB((Map<Id, Case>)newItems, (Map<Id, Case>)oldItems); // PMS Cases should not assign to MF queue                
                }
                else if(businessUnit == 'ABHI'){
                    ABHI_BusinessLogic_Helper abhiBusinessLogicHlprClass = new ABHI_BusinessLogic_Helper();
                    abhiBusinessLogicHlprClass.abhiHandlerMethod(mapOfBUToCases, (Map<Id, Case>)oldItems, 'AfterASFCodeBeforeUpdate'); 
                    ABSLAMC_SprinklrHelper.blankOutLatestNotes(new Map<Id, Case>(mapOfBUToCases.get(businessUnit)), (Map<Id, Case>)oldItems);
                    abhiBusinessLogicHlprClass.populateCustomerTextOnManualCase(mapOfBUToCases.get(businessUnit), (Map<Id, Case>)oldItems); 

                }
                else if(businessUnit == 'ONEABC'){
                    ABSLAMC_SprinklrHelper.blankOutLatestNotes(new Map<Id, Case>(mapOfBUToCases.get(businessUnit)), (Map<Id, Case>)oldItems);
                }
                if(businessUnit == 'ONEABC'){
                    ABCD_BeforeUpdateAfterASFTriggerLogic.executeBeforeLogic(new Map<Id, Case>(mapOfBUToCases.get(businessUnit)), (Map<Id, Case>)oldItems);
                    ABCD_CaseDeDupeCheck.runDuplicateCheck(new Map<Id, Case>(mapOfBUToCases.get(businessUnit)), (Map<Id, Case>)oldItems);
                }
            }
        }
        
    }
    
    public void executeBeforeASFCodeInAfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Map<String,List<Case>> mapOfBUToCases = getBUSpecificCaseRecords((List<Case>)newItems.values());
        Map<ID,List<Case>> mRecordTypeVsCases = ASF_CaseDistributionBasedOnRT.getCaseByRecordType((List<Case>)newItems.values());
        
        if(mRecordTypeVsCases.containsKey(frameworkRTId)){
            ABCL_CommonCLass.populateResolutionCommentOnCaseDetail((List<Case>)mRecordTypeVsCases.get(frameworkRTId), (Map<Id, Case>)oldItems);
                        for(String businessUnit : mapOfBUToCases.keySet()){
if(businessUnit == 'ABFL'){
                    ABFL_OwnerChangeWithLocation.updateSpocWrtLocation(mapOfBUToCases.get(businessUnit),(Map<Id, Case>)oldItems);
                    ABSLAMC_SprinklrHelper.createCaseComments(new Map<Id, Case>(mapOfBUToCases.get(businessUnit)), (Map<Id, Case>)oldItems);   

}
                if(businessUnit == 'ABSLAMC'){
                    ABSLAMC_SprinklrHelper.createCaseComments(new Map<Id, Case>(mapOfBUToCases.get(businessUnit)), (Map<Id, Case>)oldItems);
                }else if(businessUnit == 'ABHI'){
                    ABSLAMC_SprinklrHelper.createCaseComments(new Map<Id, Case>(mapOfBUToCases.get(businessUnit)), (Map<Id, Case>)oldItems);
                            } 
                else if(businessUnit == 'ONEABC'){
                        ABSLAMC_SprinklrHelper.createCaseComments(new Map<Id, Case>(mapOfBUToCases.get(businessUnit)), (Map<Id, Case>)oldItems);
                }  
}
        
        }
    }
    
    public void executeAfterASFCodeInAfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Map<String,List<Case>> mapOfBUToCases = getBUSpecificCaseRecords((List<Case>)newItems.values());
        Map<ID,List<Case>> mRecordTypeVsCases = ASF_CaseDistributionBasedOnRT.getCaseByRecordType((List<Case>)newItems.values());
        
        if(mRecordTypeVsCases.containsKey(frameworkRTId)){
            for(String businessUnit : mapOfBUToCases.keySet()){
                if(businessUnit == 'ABHFL'){
                    ABHFL_CTSTHelper.executeSpecificIntegrations((List<Case>)mapOfBUToCases.get(businessUnit), (List<Case>)oldItems.values());
                    ABHFL_CTSTHelper ctstHelperObj = new ABHFL_CTSTHelper();
                    ctstHelperObj.callLitmusApi((List<Case>) mapOfBUToCases.get(businessUnit), (Map<Id, Case>) oldItems);
                    ABHFL_CTSTHelper.OpenStageOwnershipChange((List<Case>)mapOfBUToCases.get(businessUnit),(Map<Id, Case>)oldItems);
                    ABHFL_CTSTHelper.backwardMovementEmail((List<Case>)mapOfBUToCases.get(businessUnit),(Map<Id, Case>)oldItems);
                    ABHFL_CTSTHelper.updateOwnerToRecatUsr((List<Case>)newItems.values(),(Map<Id, Case>)oldItems); // added changes for PR970457-2474 by Yogesh
                                        //AM-PR970457-1295
                    ABHFL_CTSTHelper.sendGrievanceDetailsEmail((List<Case>)mapOfBUToCases.get(businessUnit),(Map<Id, Case>)oldItems);
                    //AM-call method to delete existing asset detail records on customer change
                    ABHFL_CTSTHelper.deleteExistingAssetDetails((List<Case>)mapOfBUToCases.get(businessUnit),(Map<Id, Case>)oldItems);
                }
                else if(businessUnit == 'ABSLIG'){
                    ABSLIG_CaseDetailHelperClass absligCaseDetaHelpObj = new ABSLIG_CaseDetailHelperClass();
                    absligCaseDetaHelpObj.populateABSLIGCaseDetailFieldsAfterCaseUpdate((List<Case>)mapOfBUToCases.get(businessUnit));
                }
                else if(businessUnit == 'ABHI'){
                    ABHI_CaseDetailHelper abhilCaseDetailHelperObj = new ABHI_CaseDetailHelper();
                    ABHI_BusinessLogic_Helper abhiBusinessLogicHlprClass = new ABHI_BusinessLogic_Helper();
                    abhilCaseDetailHelperObj.populateABHILCaseDetailFields((List<Case>)mapOfBUToCases.get(businessUnit));
                    abhiBusinessLogicHlprClass.abhiHandlerMethod(mapOfBUToCases, (Map<Id, Case>)oldItems, 'AfterASFCodeInAfterUpdate');
                    abhiBusinessLogicHlprClass.searchAndAssocFieldsForAPICases((List<Case>)newItems.values(), (Map<Id, Case>)oldItems);
                }
                else if(businessUnit == 'ABFL'){
                    ABFL_InvokeLitmusProcess invokeLitmusProcessObj = new ABFL_InvokeLitmusProcess();
                    invokeLitmusProcessObj.evaluateCasesForLitmus(new Map<Id, Case>(mapOfBUToCases.get(businessUnit)), (Map<Id, Case>) oldItems);
                }
                else if(businessUnit == 'ABSLI'){
                    ABSLI_AfterUpdateLogic.executeAfterInsertLogic((List<Case>)mapOfBUToCases.get(businessUnit),(Map<Id,Case>)oldItems);
                }
                else if(businessUnit == 'ABSLAMC'){
                    ABSLAMC_CaseAssignmentHelper.updateCaseExtensionFields(new Map<Id, Case>(mapOfBUToCases.get(businessUnit)), (Map<Id, Case>) oldItems);
                    ABSLAMC_CaseAssignmentHelper.updateCaseExtensionFieldsForCams(new Map<Id, Case>(mapOfBUToCases.get(businessUnit)), (Map<Id, Case>) oldItems);
                    ABSLAMC_BU_CTSTHelper.checkAMCResolutionComments((Map<Id, Case>)newItems, (Map<Id, Case>)oldItems); 
                }
                else if(businessUnit == 'Wellness'){
                    //PR1030924-219: calculate Billable Time on Case
                    MCRM_CaseHelper.calculateBillableTimeOnCaseClose((Map<Id, Case>)newItems, (Map<Id, Case>)oldItems);
                }
                
            }
            ABCL_InvokeOneABC.evaluateCasesForOneABC(new Map<Id, Case>(mRecordTypeVsCases.get(frameworkRTId)), (Map<Id, Case>) oldItems);
        }
        
    }
    
    public void executeBeforeCaseDMLInAfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Map<String,List<Case>> mapOfBUToCases = getBUSpecificCaseRecords((List<Case>)newItems.values());
        Map<ID,List<Case>> mRecordTypeVsCases = ASF_CaseDistributionBasedOnRT.getCaseByRecordType((List<Case>)newItems.values());
        
        if(mRecordTypeVsCases.containsKey(frameworkRTId)){
            for(String businessUnit : mapOfBUToCases.keySet()){
                if(businessUnit == 'ABSLI'){
                    ABSLI_AfterUpdateLogic.changeOwnerOnAutoResolve((List<Case>)mapOfBUToCases.get(businessUnit),(Map<Id,Case>)oldItems);  
                }
            }
        }
        
    }
    
    public void beforeUpdateInteractionCases(Map<Id,Case> newItems, Map<Id, Case> oldItems){
        
        Map<String,List<Case>> mapOfBUToCases = getBUSpecificCaseRecords((List<Case>)newItems.values());
        for(String businessUnit : mapOfBUToCases.keySet()){
            ABHI_BusinessLogic_Helper abhiBusinessLogicHlprClass = new ABHI_BusinessLogic_Helper();
            abhiBusinessLogicHlprClass.abhiHandlerMethod(mapOfBUToCases, oldItems, 'AfterASFCodeBeforeUpdate');  
        }
        
    }
    
    /* THIS METHOD IS USED TO SEPERATE OUT THE BUSINESS UNIT RELATED CASES */
    private static Map<String,List<Case>> getBUSpecificCaseRecords(List<Case> newItems){
        Map<String,List<Case>> mapOfBUToCases = new Map<String,List<Case>>();
        for(Case caseRec : newItems) {
            String businessUnit = 'DEFAULT';
            if(caseRec.Business_Unit__c != null){
                businessUnit = caseRec.Business_Unit__c;
            }
            if(!mapOfBUToCases.containsKey(businessUnit)){
                mapOfBUToCases.put(businessUnit, new List<Case>());
            }
            mapOfBUToCases.get(businessUnit).add(caseRec);
        }
        return mapOfBUToCases;
    }
    
}
