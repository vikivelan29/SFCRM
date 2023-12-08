public with sharing class ASF_CaseTriggerHandler2 extends ASF_VTriggerHandler {
    private Boolean isTriggerDisabled(){
        return isDisabled('Case');
    }
    
    private Boolean isBatchSizeOne(List<SObject> listOfRecords){
        return (listOfRecords.size() == 1);
    }
    
    public override void beforeInsert(List<SObject> newItemsCase) {
        if(isTriggerDisabled()){return;}
        if(!isBatchSizeOne(newItemsCase)){return;}
        if(!ASF_TriggerSkipperUtility.isAllowedToRun('Case', 'Before')){return;}

        Id interactionRTId = ASF_Constants.RT_INTERACTION;
        Id frameworkRTId = ASF_Constants.RT_FRAMEWORK;        
        Map<ID,List<Case>> mRecordTypeVsCases = ASF_CaseDistributionBasedOnRT.getCaseByRecordType((List<Case>)newItemsCase);
        if(mRecordTypeVsCases.containsKey(frameworkRTId)){
            
            //Case to Account Association for Technical Source = API Cases. (For now Payment related. For other lob, add in static final varible inside the class)
            ASF_AssocCustomerForAPICases.searchAndAssocCustomerForAPICases(mRecordTypeVsCases.get(frameworkRTId));
            
            //Validation methods
            ASF_CaseTriggerModularHelper.validateIfCCCInAPIRequest(mRecordTypeVsCases.get(frameworkRTId));
            ASF_CaseTriggerModularHelper.populateFrameworkFieldsForCase(mRecordTypeVsCases.get(frameworkRTId), null);
            ASF_CaseTriggerModularHelper.onCreateCloseServiceRequest(mRecordTypeVsCases.get(frameworkRTId));
            
            ASF_CaseSLAHandlerV1 caseSLA = new ASF_CaseSLAHandlerV1();
            caseSLA.calculateSLAOnCaseInsert(mRecordTypeVsCases.get(frameworkRTId));
 			
            // Virendra - Check duplicacates for Payment
            ABCL_CaseDuplicateCheck dupeChecker = new ABCL_CaseDuplicateCheck();
            dupeChecker.runDuplicateCheck(mRecordTypeVsCases.get(frameworkRTId));
            
            if(System.Label.PAY_SkipCustomerCreationOnCaseCreationAPI != 'true'){
                PAY_CaseTriggerHelper.createCustomerForCreateCaseAPI(mRecordTypeVsCases.get(frameworkRTId));
            }
        }
        else if(mRecordTypeVsCases.containsKey(interactionRTId)){
            ASF_CasePreFrameworkTriggerHelper caseHelper = new ASF_CasePreFrameworkTriggerHelper();
            
            ASF_CaseE2CHelper.blockOOOCases(mRecordTypeVsCases.get(interactionRTId));
            caseHelper.populatePreFrameworkFields(mRecordTypeVsCases.get(interactionRTId));
            caseHelper.populateStageFields(mRecordTypeVsCases.get(interactionRTId));
        }
        
    }
    
    public override void beforeUpdate(Map<Id, SObject> newItemsCase, Map<Id, SObject> oldItems) {
        if(isTriggerDisabled()){return;}
        if(!isBatchSizeOne(newItemsCase.values())){return;}
        if(!ASF_TriggerSkipperUtility.isAllowedToRun('Case', 'Before')){return;}

        Id interactionRTId = ASF_Constants.RT_INTERACTION;
        Id frameworkRTId = ASF_Constants.RT_FRAMEWORK;        
        Map<ID,List<Case>> mRecordTypeVsCases = ASF_CaseDistributionBasedOnRT.getCaseByRecordType((List<Case>)newItemsCase.values());
        
        if(mRecordTypeVsCases.containsKey(frameworkRTId)){
            Map<Id,Case> newCaseMap = new Map<Id,Case>(mRecordTypeVsCases.get(frameworkRTId));
            
            //Validation methods
            ASF_CaseTriggerModularHelper.validateCloseCase(oldItems, newCaseMap);
            ASF_CaseTriggerModularHelper.validateOwnerCheckerStage(oldItems, newCaseMap);
            ASF_CaseTriggerModularHelper.caseOwnerChangeValidation(newCaseMap.values(), (Map<Id, Case>)oldItems);
            ASF_CaseTriggerModularHelper.checkisApprovalStage((Map<Id, Case>)newCaseMap, (Map<Id, Case>)oldItems);
            //ASF_CaseTriggerModularHelper.lwcCaseValidationBeforeInsertUpdate(newCaseMap.values(), oldItems.values());
            //ASF_CaseTriggerModularHelper.validateUserForAssignMe((Map<Id, Case>)newCaseMap, (Map<Id, Case>)oldItems);
            //Prepopulation methods
            ASF_CaseTriggerModularHelper.checkAndProcessReopenCase(newCaseMap.values(),(map<Id,Case>)oldItems);
            ASF_CaseTriggerModularHelper.checkAndProcessMoveToNextStage(newCaseMap.values(), (Map<Id, Case>)oldItems);
            ASF_CaseTriggerModularHelper.checkAndProcessManualStageMovement(newCaseMap.values(), (Map<Id, Case>)oldItems);
            ASF_CaseTriggerModularHelper.rejectFrameworkCaseBeforeUpdate(newCaseMap.values(),(map<Id,Case>)oldItems);
            ASF_CaseTriggerModularHelper.populateFrameworkFieldsForCase((List<Case>)newCaseMap.values(), (Map<Id, Case>)oldItems);
            //SLA calculation method - from JT's class
            ASF_CaseSLAHandlerV1 caseSLA = new ASF_CaseSLAHandlerV1();
            caseSLA.calculateSLAOnCaseUpdate(newCaseMap,(map<Id,Case>)oldItems);
            
        }
        else if(mRecordTypeVsCases.containsKey(interactionRTId)){
            Map<Id,Case> newCaseMap = new Map<Id,Case>(mRecordTypeVsCases.get(interactionRTId));
            ASF_CasePreFrameworkTriggerHelper caseHelper = new ASF_CasePreFrameworkTriggerHelper();
            ASF_CaseSLAHandlerV1 caseSLA = new ASF_CaseSLAHandlerV1();
            caseSLA.calculateSLAOnCaseUpdate(newCaseMap,(map<Id,Case>)oldItems);
            caseHelper.populateStageFields(mRecordTypeVsCases.get(interactionRTId));
            //Virendra - Reject Case
            ASF_CaseTriggerModularHelper.rejectFrameworkCaseBeforeUpdate(newCaseMap.values(),(map<Id,Case>)oldItems);
            
        }
        
        
    }
    
    public override void afterUpdate(Map<Id, SObject> newItemsCase, Map<Id, SObject> oldItems) {
        if(isTriggerDisabled()){return;}
        if(!isBatchSizeOne(newItemsCase.values())){return;}
        if(!ASF_TriggerSkipperUtility.isAllowedToRun('Case', 'After')){return;}

        Id interactionRTId = ASF_Constants.RT_INTERACTION;
        Id frameworkRTId = ASF_Constants.RT_FRAMEWORK;        
        Map<ID,List<Case>> mRecordTypeVsCases = ASF_CaseDistributionBasedOnRT.getCaseByRecordType((List<Case>)newItemsCase.values());
        
        if(mRecordTypeVsCases.containsKey(frameworkRTId)){
            //Move to next stage - TODO - This will be moved to after context
            //ASF_CaseTriggerModularHelper.checkAndProcessMoveToNextStage(mRecordTypeVsCases.get(frameworkRTId), (Map<Id, Case>)oldItems);
            //ASF_CaseTriggerModularHelper.checkAndProcessManualStageMovement(mRecordTypeVsCases.get(frameworkRTId), (Map<Id, Case>)oldItems);
            ASF_CaseTriggerModularHelper.checkAndInsertPeripheralRecords(mRecordTypeVsCases.get(frameworkRTId), (Map<Id, Case>)oldItems);
            ASF_CaseSLAHandlerV1 caseSLA = new ASF_CaseSLAHandlerV1();
            Map<Id,Case> newCaseMap = new Map<Id,Case>(mRecordTypeVsCases.get(frameworkRTId));
            caseSLA.updateSLAHistory((Map<Id, Case>)oldItems,newCaseMap); 

            // Virendra - to Reject the Checklist and Task on Case Rejection.
            ASF_CaseTriggerModularHelper.rejectFrameworkCaseAfterUpdate(newCaseMap,(Map<Id, Case>)oldItems);
            
        }
        else if(mRecordTypeVsCases.containsKey(interactionRTId)){
            ASF_CaseSLAHandlerV1 caseSLA = new ASF_CaseSLAHandlerV1();
            Map<Id,Case> newCaseMap = new Map<Id,Case>(mRecordTypeVsCases.get(interactionRTId));
            caseSLA.updateSLAHistory((Map<Id, Case>)oldItems,newCaseMap);
        }
        
        
    }
    
    public override void afterInsert(Map<Id, SObject> newItemsCase) {
        if(isTriggerDisabled()){return;}
        if(!isBatchSizeOne(newItemsCase.values())){return;}
        if(!ASF_TriggerSkipperUtility.isAllowedToRun('Case', 'After')){return;}
        
        Id interactionRTId = ASF_Constants.RT_INTERACTION;
        Id frameworkRTId = ASF_Constants.RT_FRAMEWORK;        
        Map<ID,List<Case>> mRecordTypeVsCases = ASF_CaseDistributionBasedOnRT.getCaseByRecordType((List<Case>)newItemsCase.values());
        
        if(mRecordTypeVsCases.containsKey(frameworkRTId)){
            ASF_CaseTriggerModularHelper.checkAndInsertPeripheralRecords(newItemsCase.values(), null);
            ASF_CaseTriggerModularHelper.checkAndProcessMoveToNextStage(newItemsCase.values(), null);
            if(System.Label.PAY_SkipCustomerCreationOnCaseCreationAPI != 'true'){
                PAY_CaseTriggerHelper.fetchCustomerInfoExt(mRecordTypeVsCases.get(frameworkRTId));
            }            
            //SLA 
            ASF_CaseSLAHandlerV1 caseSLA = new ASF_CaseSLAHandlerV1();
            caseSLA.insertSLAHistory(null,(Map<Id,Case>)newItemsCase);
            ASF_CaseTriggerModularHelper.checkAndPopulateOwnerOnCaseCreation(newItemsCase.values());
        }
        else if(mRecordTypeVsCases.containsKey(interactionRTId)){
            ASF_CasePreFrameworkTriggerHelper caseHelper = new ASF_CasePreFrameworkTriggerHelper();
            Map<Id,Case> newCaseMap = new Map<Id,Case>(mRecordTypeVsCases.get(interactionRTId));
            ASF_CaseRelatedDetailsUpdate relatedDetails = new ASF_CaseRelatedDetailsUpdate();
            relatedDetails.updateRelatedObjectDetailsBulk(newCaseMap.values());
            ASF_CaseSLAHandlerV1 caseSLA = new ASF_CaseSLAHandlerV1();
            caseSLA.insertSLAHistory(null,newCaseMap);
        }
        
        
    }
    
}