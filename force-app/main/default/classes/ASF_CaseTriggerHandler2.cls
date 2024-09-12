/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 04-24-2024
 * @last modified by  : rsinghnagar@salesforce.com 
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   04-24-2024   rsinghnagar@salesforce.com   Initial Version
**/
public without sharing class ASF_CaseTriggerHandler2 extends ASF_VTriggerHandler {
    private Boolean isTriggerDisabled(){
        return isDisabled('Case');
    }
    
    /*private Boolean isBatchSizeOne(List<SObject> listOfRecords){
        return (listOfRecords.size() == 1);
    } */
    
    public override void beforeInsert(List<SObject> newItemsCase) {
        if(isTriggerDisabled()){return;}
        if(!ASF_TriggerSkipperUtility.isAllowedToRun('Case', 'Before')){return;}
        Id interactionRTId = ASF_Constants.RT_INTERACTION;
        Id frameworkRTId = ASF_Constants.RT_FRAMEWORK; 
        ASF_CaseTriggerBUSpecificHandler buSpecificCls = new ASF_CaseTriggerBUSpecificHandler();
        Map<ID,List<Case>> mRecordTypeVsCases = ASF_CaseDistributionBasedOnRT.getCaseByRecordType((List<Case>)newItemsCase);
        if(mRecordTypeVsCases.containsKey(frameworkRTId)){
            //Case to Account Association for Technical Source = API Cases. (Payment related. For other lob, add in static final varible inside the class)
            ASF_AssocCustomerForAPICases.searchAndAssocCustomerForAPICases(mRecordTypeVsCases.get(frameworkRTId));
            ASF_CaseTriggerModularHelper.setSkipperFlags(mRecordTypeVsCases.get(frameworkRTId), null);
        }
        // VIRENDRA - EXECUTE BU SPECIFIC LOGIC LOGIC IN BELOW CODE - SEQUENCE PRE ASF CODE 
        //          - Moved here to check the valid CCC Ids if not valid then assign the Intertaction recordTypeId to current Case (Jira - PR970457-1517)
        buSpecificCls.executeBeforeASFCodeInBeforeInsert((list<Case>)newItemsCase);   

        if(mRecordTypeVsCases.containsKey(frameworkRTId)){

            //Validation methods
            ASF_CaseTriggerModularHelper.validateIfCCCInAPIRequest(mRecordTypeVsCases.get(frameworkRTId), null);
            ASF_CaseTriggerModularHelper.populateFrameworkFieldsForCase(mRecordTypeVsCases.get(frameworkRTId), null);
            ASF_CaseTriggerModularHelper.onCreateCloseServiceRequest(mRecordTypeVsCases.get(frameworkRTId));
            //ASF_CaseTriggerModularHelper.checkAndValidateFirstStageEntry(mRecordTypeVsCases.get(frameworkRTId), null);
            ASF_CaseTriggerModularHelper.createCaseExtnRecordForBulk(mRecordTypeVsCases.get(frameworkRTId));
            // VIRENDRA - EXECUTE BU SPECIFIC LOGIC LOGIC IN BELOW CODE - SEQUENCE POST ASF CODE 
            buSpecificCls.executeAfterASFCodeInBeforeInsert(mRecordTypeVsCases.get(frameworkRTId));
           /* if(mRecordTypeVsCases.containsKey(frameworkRTId)){
            	ASF_CaseTriggerModularHelper.setSkipperFlags(mRecordTypeVsCases.get(frameworkRTId), null);
        	} */
            
            
        }
        else if(mRecordTypeVsCases.containsKey(interactionRTId)){
            ASF_CasePreFrameworkTriggerHelper caseHelper = new ASF_CasePreFrameworkTriggerHelper();
            
            ASF_CaseE2CHelper.blockOOOCases(mRecordTypeVsCases.get(interactionRTId));
            caseHelper.populatePreFrameworkFields(mRecordTypeVsCases.get(interactionRTId));
            caseHelper.populateStageFields(mRecordTypeVsCases.get(interactionRTId));
            // Anirudh - EXECUTE BU SPECIFIC LOGIC LOGIC IN BELOW CODE - SEQUENCE POST ASF CODE 
            buSpecificCls.executeAfterASFCodeInBeforeInsert(mRecordTypeVsCases.get(interactionRTId));
        }
        
    }
    
    public override void beforeUpdate(Map<Id, SObject> newItemsCase, Map<Id, SObject> oldItems) {
        if(isTriggerDisabled()){return;}
        if(!ASF_TriggerSkipperUtility.isAllowedToRun('Case', 'Before')){return;}
        
        Id interactionRTId = ASF_Constants.RT_INTERACTION;
        Id frameworkRTId = ASF_Constants.RT_FRAMEWORK;        
        Map<ID,List<Case>> mRecordTypeVsCases = ASF_CaseDistributionBasedOnRT.getCaseByRecordType((List<Case>)newItemsCase.values());
        system.debug('mRecordTypeVsCasesentered '+mRecordTypeVsCases.containsKey(frameworkRTId));
        
        
        if(mRecordTypeVsCases.containsKey(frameworkRTId)){
                Map<Id,Case> newCaseMap = new Map<Id,Case>(mRecordTypeVsCases.get(frameworkRTId));
            	ASF_CaseTriggerModularHelper.setSkipperFlags(newCaseMap.values(), (Map<Id, Case>)oldItems);
            
            	// VIRENDRA - EXECUTE BU SPECIFIC LOGIC LOGIC IN BELOW CODE - SEQUENCE PRE ASF CODE 
                ASF_CaseTriggerBUSpecificHandler buSpecificCls = new ASF_CaseTriggerBUSpecificHandler();
                buSpecificCls.executeBeforeASFCodeInBeforeUpdate(newCaseMap,(Map<Id,Case>)oldItems);
                //Added for Ebot
                ASF_AssocCustomerForAPICases.searchAndAssocCustomerForAPICases(mRecordTypeVsCases.get(frameworkRTId));
    
                //Validation methods
                ASF_CaseTriggerModularHelper.validateCloseCase(oldItems, newCaseMap);
                ASF_CaseTriggerModularHelper.validateOwnerCheckerStage(oldItems, newCaseMap);
                ASF_CaseTriggerModularHelper.caseOwnerChangeValidation(newCaseMap.values(), (Map<Id, Case>)oldItems);
                ASF_CaseTriggerModularHelper.checkisApprovalStage((Map<Id, Case>)newCaseMap, (Map<Id, Case>)oldItems);
                
                //Prepopulation methods
                ASF_CaseTriggerModularHelper.findNextStageAndSetOnTriggerNew((List<Case>)newCaseMap.values(), (Map<Id, Case>)oldItems);
                ASF_CaseTriggerModularHelper.findNextStageAndSetOnTriggerNewForReopenRequest((List<Case>)newCaseMap.values(), (Map<Id, Case>)oldItems);
                ASF_CaseTriggerModularHelper.populateFrameworkFieldsForCase((List<Case>)newCaseMap.values(), (Map<Id, Case>)oldItems);
                ASF_CaseTriggerModularHelper.rejectFrameworkCaseBeforeUpdate(newCaseMap.values(),(map<Id,Case>)oldItems);
                
                ASF_CaseTriggerModularHelper.validateRecategorizationParameters(newCaseMap.values(), (Map<Id, Case>)oldItems);
                ASF_CaseTriggerModularHelper.validateCCCOnUpdate((List<Case>)newCaseMap.values(), (Map<Id, Case>)oldItems);
                // VIRENDRA - EXECUTE BU SPECIFIC LOGIC LOGIC IN BELOW CODE - SEQUENCE POST ASF CODE 
                buSpecificCls.executeAfterASFCodeInBeforeUpdate(newCaseMap,(Map<Id,Case>)oldItems);
            	//ASF_CaseTriggerModularHelper.setSkipperFlags(newCaseMap.values(), (Map<Id, Case>)oldItems); 
        }
        else if(mRecordTypeVsCases.containsKey(interactionRTId)){
            Map<Id,Case> newCaseMap = new Map<Id,Case>(mRecordTypeVsCases.get(interactionRTId));
            ASF_CasePreFrameworkTriggerHelper caseHelper = new ASF_CasePreFrameworkTriggerHelper();
            // ASF_CaseSLAHandlerV1 caseSLA = new ASF_CaseSLAHandlerV1();
            // caseSLA.calculateSLAOnCaseUpdate(newCaseMap,(map<Id,Case>)oldItems);
            caseHelper.populateStageFields(mRecordTypeVsCases.get(interactionRTId));
            ASF_CaseTriggerModularHelper.caseOwnerChangeValidation(newCaseMap.values(), (Map<Id, Case>)oldItems);
            //Virendra - Reject Case
            ASF_CaseTriggerModularHelper.rejectFrameworkCaseBeforeUpdate(newCaseMap.values(),(map<Id,Case>)oldItems);
            ASF_CaseTriggerModularHelper.populateFrameworkFieldsForCase((List<Case>)newCaseMap.values(), (Map<Id, Case>)oldItems);
            
        }
        
        
    }
    
    public override void afterUpdate(Map<Id, SObject> newItemsCase, Map<Id, SObject> oldItems) {
        
        if(isTriggerDisabled()){return;}
        if(!ASF_TriggerSkipperUtility.isAllowedToRun('Case', 'After')){return;}

        Id interactionRTId = ASF_Constants.RT_INTERACTION;
        Id frameworkRTId = ASF_Constants.RT_FRAMEWORK;        
        Map<ID,List<Case>> mRecordTypeVsCases = ASF_CaseDistributionBasedOnRT.getCaseByRecordType((List<Case>)newItemsCase.values());
        
        if(mRecordTypeVsCases.containsKey(frameworkRTId)){
            Map<Id,Case> newCaseMap = new Map<Id,Case>(mRecordTypeVsCases.get(frameworkRTId));
            // VIRENDRA - EXECUTE BU SPECIFIC LOGIC LOGIC IN BELOW CODE - SEQUENCE PRE ASF CODE 
            ASF_CaseTriggerBUSpecificHandler buSpecificCls = new ASF_CaseTriggerBUSpecificHandler();
            buSpecificCls.executeBeforeASFCodeInAfterUpdate(newCaseMap, (Map<Id,Case>) oldItems);
            ASF_CaseTriggerModularHelper.populateCaseDetailFromBulk((Map<Id, Case>)newItemsCase, (Map<Id, Case>)oldItems);
            ASF_CaseTriggerModularHelper.assignCasesInFirstStageAfterConversion((List<Case>)newCaseMap.values(), (Map<Id, Case>)oldItems);
            ASF_CaseTriggerModularHelper.checkAndValidateFirstStageEntry(mRecordTypeVsCases.get(frameworkRTId), (Map<Id, Case>)oldItems);
            ASF_CaseTriggerModularHelper.checkAndProcessReopenCase(newCaseMap.values(),(map<Id,Case>)oldItems);
            ASF_CaseTriggerModularHelper.checkAndProcessManualStageMovement(newCaseMap, (Map<Id, Case>)oldItems);
            ASF_CaseTriggerModularHelper.checkAndProcessMoveToNextStage(newCaseMap.values(), (Map<Id, Case>)oldItems);
            ASF_CaseTriggerModularHelper.checkAndStorePeripheralRecordsInAfterContext(mRecordTypeVsCases.get(frameworkRTId), (Map<Id, Case>)oldItems);
            ASF_CaseTriggerModularHelper.invokeSLACalculationMethods((Map<Id, Case>)newItemsCase, (Map<Id, Case>)oldItems);
            ASF_CaseTriggerModularHelper.checkAndInsertPeripheralRecords(newCaseMap, (Map<Id, Case>)oldItems);
            
            // Virendra - to Reject the Checklist and Task on Case Rejection.
            ASF_CaseTriggerModularHelper.rejectFrameworkCaseAfterUpdate(newCaseMap,(Map<Id, Case>)oldItems);
            
            // EXECUTE BU SPECIFIC LOGIC IN BELOW CODE - Populate case field values before DML
            buSpecificCls.executeBeforeCaseDMLInAfterUpdate(newCaseMap, (Map<Id, Case>)oldItems);
            ASF_CaseTriggerModularHelper.updateCasesFinally((Map<Id, Case>)newItemsCase);
            ASF_CaseSLAHandlerV1.updateSLAHistory((Map<Id, Case>)oldItems,newCaseMap); 
            ASF_CaseTriggerModularHelper.createFeedItem((Map<Id, Case>)newItemsCase, (Map<Id, Case>)oldItems);
            
            // VIRENDRA - EXECUTE BU SPECIFIC LOGIC LOGIC IN BELOW CODE - SEQUENCE POST ASF CODE 
            buSpecificCls.executeAfterASFCodeInAfterUpdate(newCaseMap, (Map<Id,Case>) oldItems);
        }
        else if(mRecordTypeVsCases.containsKey(interactionRTId)){
            Map<Id,Case> newCaseMap = new Map<Id,Case>(mRecordTypeVsCases.get(interactionRTId));
            ASF_CaseTriggerModularHelper.invokeSLACalculationMethods((Map<Id, Case>)newCaseMap, (Map<Id, Case>)oldItems);
            ASF_CaseTriggerModularHelper.updateCasesFinally((Map<Id, Case>)newCaseMap);
            ASF_CaseSLAHandlerV1.updateSLAHistory((Map<Id, Case>)oldItems,newCaseMap);
        }
    }
    
    public override void afterInsert(Map<Id, SObject> newItemsCase) {
        if(isTriggerDisabled()){return;}
        if(!ASF_TriggerSkipperUtility.isAllowedToRun('Case', 'After')){return;}
        
        Id interactionRTId = ASF_Constants.RT_INTERACTION;
        Id frameworkRTId = ASF_Constants.RT_FRAMEWORK;        
        Map<ID,List<Case>> mRecordTypeVsCases = ASF_CaseDistributionBasedOnRT.getCaseByRecordType((List<Case>)newItemsCase.values());
        
        if(mRecordTypeVsCases.containsKey(frameworkRTId)){
            Map<Id,Case> frameworkRTCases = new map<Id,Case>(mRecordTypeVsCases.get(frameworkRTId));
            
            // VIRENDRA - EXECUTE BU SPECIFIC LOGIC LOGIC IN BELOW CODE - SEQUENCE PRE ASF CODE 
            ASF_CaseTriggerBUSpecificHandler buSpecificCls = new ASF_CaseTriggerBUSpecificHandler();
            buSpecificCls.executeBeforeASFCodeInAfterInsert(frameworkRTCases);
            ASF_CaseTriggerModularHelper.populateCaseDetailFromBulk((Map<Id, Case>)newItemsCase, null);
            ASF_CaseTriggerModularHelper.checkAndValidateFirstStageEntry(mRecordTypeVsCases.get(frameworkRTId), null);
            ASF_CaseTriggerModularHelper.checkAndPopulateOwnerOnCaseCreation((Map<Id, Case>)newItemsCase);
            ASF_CaseTriggerModularHelper.checkAndProcessMoveToNextStage(newItemsCase.values(), null);
            ASF_CaseTriggerModularHelper.checkAndStorePeripheralRecordsInAfterContext(newItemsCase.values(), null);
            ASF_CaseTriggerModularHelper.invokeSLACalculationMethods((Map<Id, Case>)newItemsCase, null);
            ASF_CaseTriggerModularHelper.checkAndInsertPeripheralRecords((Map<Id, Case>)newItemsCase, null);
            ASF_CaseSLAHandlerV1.insertSLAHistory(null,(Map<Id,Case>)newItemsCase);
            ASF_CaseTriggerModularHelper.updateCasesFinally((Map<Id, Case>)newItemsCase);
            
            // VIRENDRA - EXECUTE BU SPECIFIC LOGIC LOGIC IN BELOW CODE - SEQUENCE POST ASF CODE 
            buSpecificCls.executeAfterASFCodeInAfterInsert(frameworkRTCases);            
        }
        else if(mRecordTypeVsCases.containsKey(interactionRTId)){
            ASF_CasePreFrameworkTriggerHelper caseHelper = new ASF_CasePreFrameworkTriggerHelper();
            Map<Id,Case> newCaseMap = new Map<Id,Case>(mRecordTypeVsCases.get(interactionRTId));
            ASF_CaseRelatedDetailsUpdate relatedDetails = new ASF_CaseRelatedDetailsUpdate();
            relatedDetails.updateRelatedObjectDetailsBulk(newCaseMap.values());
            ASF_CaseSLAHandlerV1.insertSLAHistory(null,newCaseMap);
            ASF_CaseRelatedDetailsUpdate.removeAccountIdBuMissMatch(null,newCaseMap);
        }
        
        
    }
    
}