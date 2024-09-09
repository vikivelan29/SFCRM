/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-29-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class ASF_CaseMovementHelper {
    
    //static Boolean boolCalledFromBulk = false;
    // static Map<string, List<ASF_Case_Rule__c>> stageAssignmentRulesMap = new Map<string, List<ASF_Case_Rule__c>>();
    // static List<ASF_Case_Approv__c> approvalToInsert = new List<ASF_Case_Approv__c>();
    // static List<ASF_Checklist__c> checklistToInsert = new List<ASF_Checklist__c>();
    // static List<Task> tasksToInsert = new List<Task>();
    // static Case tempCase = new case();
    

    /**
     * This method is used in before trigger where it returns the next eligible stage 
     * so that before trigger can set the stage__c on trigger.new
     * Bulkified
     */
    @AuraEnabled
    public static Map<Id, StageWrapper> findNextStageForMoveToNextStage(List<Case> currentCases, Map<Id, String> currentStageMap){
        Map<Id, StageWrapper> resultWrapperMap = new Map<Id, StageWrapper>();
        Map<Id,Case> casesAfterBackward = new Map<Id,Case>();
        Map<Id,Case> casesMovingNextPure = new Map<Id,Case>();
        
        Set<String> externalIds = new Set<String>();
        Set<Id> caseIds = new Set<Id>();
        for(Case caseRec : currentCases){
            StageWrapper resultWrapper = new StageWrapper();
            resultWrapperMap.put(caseRec.Id, resultWrapper);
            externalIds.add(caseRec.CCC_External_Id__c);
            caseIds.add(caseRec.Id);
        }
        
        List<ASF_Case_Stage_Config__c> allStageConfigs = ASF_CaseQueryHandler.getCaseStageConfigWithRlAndIntr(externalIds);

        // Find All Query Fields for Case, Merge them togther, and perform one Query on Case
        Set<String> allFields = new Set<String>{'stage__c', 'businesshoursid', 'ccc_external_id__c', 'previous_stage__c', 'business_unit__c', 'lead__c','lob__c'};
            allFields.addAll(ASF_Constants.CASE_EXTENSION_FIELDSET);
        for(ASF_Case_Stage_Config__c config: allStageConfigs){
            if(config.Query_Fields__c != null){
                allFields.addAll(config.Query_Fields__c.toLowerCase().split(','));
            }
        }

        List<Case> queriedCaseRecords = ASF_CaseQueryHandler.getCaseRecordWithQueryFields(allFields, caseIds);
        Map<Id,Case> queriesCasesMap = new Map<Id,Case>(queriedCaseRecords);
        
        for(Case caseRec : currentCases){
            StageWrapper resultWrapper = new StageWrapper();
            resultWrapperMap.put(caseRec.Id, resultWrapper);
            if(caseRec.pending_clarification__c == true){
                casesAfterBackward.put(caseRec.Id, queriesCasesMap.get(caseRec.Id));
            }else{
                casesMovingNextPure.put(caseRec.Id, queriesCasesMap.get(caseRec.Id));
            }
        }

        if(!casesAfterBackward.isEmpty()){
            //Find the next stage when moved forward after backward movement
            Map<Id, StageConfigWrapper> caseIdToNextStageMap = ASF_CaseMovementHelper.findNextStageAfterBackward(casesAfterBackward.values(), currentStageMap);
            for(Id caseId : caseIdToNextStageMap.keySet()){
                StageConfigWrapper nextStage = caseIdToNextStageMap.get(caseId);
                StageWrapper resultWrapper = resultWrapperMap.get(caseId);
                if(nextStage.status != 'Error'){
                    resultWrapper.status = 'Success';
                    Case updatedCase = new Case(Id = caseId);
                    updatedCase.Pending_Clarification__c = false;
                    resultWrapper.caseToBeUpdated = updatedCase;
                    resultWrapper.nextStageConfig = nextStage.stageConfig;
                    resultWrapper.ownerId = nextStage.ownerId;
                    resultWrapper.errorOwnerId = nextStage.errorOwnerId;
                    // VIRENDRA - 8 JUNE 2024 - TO STAMP CASE ASSIGNED TEAM ON CASE.
                    resultWrapper.ownerName = nextStage.ownerName;
                }
                else{
                    resultWrapper.errorMessage = nextStage.errorMessage;
                    resultWrapper.status = 'Error';
                }
                resultWrapperMap.put(caseId, resultWrapper);
            }
        }

        if(!casesMovingNextPure.isEmpty()){
            //Find the next stage when moved purely forward
            if(!casesMovingNextPure.isEmpty()){
                //Find the next stage
                Map<Id, StageConfigWrapper> caseIdToNextStageConfig = ASF_CaseMovementHelper.findNextStageForward(casesMovingNextPure.values(), currentStageMap);
                for(Case caseRec : casesMovingNextPure.values()){
                    StageConfigWrapper nextStage = caseIdToNextStageConfig.get(caseRec.Id);
                    StageWrapper resultWrapper = resultWrapperMap.get(caseRec.Id);
                    if(nextStage.status == 'Success'){
                        resultWrapper.status = 'Success';
                        resultWrapper.nextStageConfig = nextStage.stageConfig;
                        resultWrapper.ownerId = nextStage.ownerId;
                        // VIRENDRA - 8 JUNE 2024 - TO STAMP CASE ASSIGNED TEAM ON CASE.
                    	resultWrapper.ownerName = nextStage.ownerName;
                        resultWrapper.errorOwnerId = nextStage.errorOwnerId;
                        resultWrapperMap.put(caseRec.Id, resultWrapper);
                    }else{
                        resultWrapper.errorMessage = nextStage.errorMessage;
                        resultWrapper.status = 'Error';
                        resultWrapperMap.put(caseRec.Id, resultWrapper);
                    }
                }
            }
        }
        return resultWrapperMap;
    }

    /**
    * This method is called when moved to Next Automated Stage for Automated Forward Movement - Standard Case
    * and used when moved to next stage after back movement
    * Returns StageWrapper - Contains Case Data to be updated, and other Objects to be inserted as well
    * Bulkified
    */
    @AuraEnabled
    public static Map<Id, StageWrapper> moveToNextStage(List<Case> currentCases, Map<Id, String> currentStageMap){
        
        Map<Id, StageWrapper> resultWrapperMap = new Map<Id, StageWrapper>();
        Map<Id,Case> casesAfterBackward = new Map<Id,Case>();
        Map<Id,Case> casesMovingNextPure = new Map<Id,Case>();
        
        Set<String> externalIds = new Set<String>();
        Set<Id> caseIds = new Set<Id>();
        for(Case caseRec : currentCases){
            StageWrapper resultWrapper = new StageWrapper();
            resultWrapperMap.put(caseRec.Id, resultWrapper);
            externalIds.add(caseRec.CCC_External_Id__c);
            caseIds.add(caseRec.Id);
        }
        
        List<ASF_Case_Stage_Config__c> allStageConfigs = ASF_CaseQueryHandler.getCaseStageConfigWithRlAndIntr(externalIds);

        // Find All Query Fields for Case, Merge them togther, and perform one Query on Case
        Set<String> allFields = new Set<String>{'stage__c', 'businesshoursid', 'ccc_external_id__c', 'previous_stage__c', 'business_unit__c', 'lead__c','lob__c'};
        	allFields.addAll(ASF_Constants.CASE_EXTENSION_FIELDSET);
            for(ASF_Case_Stage_Config__c config: allStageConfigs){
            if(config.Query_Fields__c != null){
                allFields.addAll(config.Query_Fields__c.toLowerCase().split(','));
            }
        }
        ASF_CaseQueryHandler.refreshRecords = true;
        List<Case> queriedCaseRecords = ASF_CaseQueryHandler.getCaseRecordWithQueryFields(allFields, caseIds);
        ASF_CaseQueryHandler.refreshRecords = false;
        Map<Id,Case> queriesCasesMap = new Map<Id,Case>(queriedCaseRecords);
        for(Case caseRec : currentCases){
            StageWrapper resultWrapper = new StageWrapper();
            resultWrapperMap.put(caseRec.Id, resultWrapper);
            if(caseRec.pending_clarification__c == true){
                casesAfterBackward.put(caseRec.Id, queriesCasesMap.get(caseRec.Id));
            }else{
                casesMovingNextPure.put(caseRec.Id, queriesCasesMap.get(caseRec.Id));
            }
        }

        if(!casesAfterBackward.isEmpty()){
            //Run validation on current Stage
            Map<Id, CaseStageValidationWrapper> validationResults = ASF_CaseMovementHelper.validateCurrentStageExit(casesAfterBackward.values(), currentStageMap);
            for(Id caseId : validationResults.keySet()){
                StageWrapper resultWrapper = resultWrapperMap.get(caseId);
                CaseStageValidationWrapper validationResult = validationResults.get(caseId);
                if(validationResult.status != 'Success'){
                    resultWrapper.errorMessage = validationResult.errorMessage;
                    resultWrapper.status = 'Error';
                    casesAfterBackward.remove(caseId);
                    resultWrapperMap.put(caseId, resultWrapper);
                }
            }
            
            Map<Id, Case> casesWithNextStageFound = new Map<Id, Case>();
            Map<Id, ASF_Case_Stage_Config__c> nextStageConfigMap = new Map<Id, ASF_Case_Stage_Config__c>();
            if(!casesAfterBackward.isEmpty()){
                //Find the next stage when moved forward after backward movement
                Map<Id, StageConfigWrapper> caseIdToNextStageMap = ASF_CaseMovementHelper.findNextStageAfterBackward(casesAfterBackward.values(), currentStageMap);
                for(Id caseId : caseIdToNextStageMap.keySet()){
                    StageConfigWrapper nextStage = caseIdToNextStageMap.get(caseId);
                    StageWrapper resultWrapper = resultWrapperMap.get(caseId);
                    Case caseRec =  casesAfterBackward.get(caseId);
                    if(nextStage.status != 'Error'){
                        casesWithNextStageFound.put(caseRec.Id, caseRec);
                        nextStageConfigMap.put(caseRec.Id, nextStage.stageConfig);
                        Case updatedCase = new Case(Id = caseId);
                        //Workaround for Gateway stage -- to be removed when Gateway stage movement is fixed
                        //When case get to Gateway stage after backward movement, unable to find valid next stage.
                        if(!ASF_CaseTriggerModularHelper.preClosureStageAlreadyStamped){
                            updatedCase.Stage__c = nextStage.stageConfig.StageName__c;
                            updatedCase.Status = nextStage.stageConfig.Status_Mapping__c;
                            resultWrapper.ownerId = nextStage.ownerId;
                            // VIRENDRA - 8 JUNE 2024 - TO STAMP CASE ASSIGN TEAM ON CASE ASSIGNMENT
                            resultWrapper.ownerName = nextStage.ownerName;
                            // VIRENDRA - 8 JUNE 2024 - ENDS HERE.
                            System.debug('@@@ Virendra - Coming here -- '+nextStage.ownerName);
                        }
                        updatedCase.is_Manual_Approval__c = nextStage.stageConfig.Manual_Approval__c;
                    	updatedCase.MoveToNext__c = false;
                        resultWrapper.errorOwnerId = nextStage.errorOwnerId;
                        // If previous stage or any stage after previous stage found, Remove Pending Clarification Flag
                        //if(nextStage.isPreviousStage){
                            updatedCase.pending_clarification__c = false;
                        //}
                        resultWrapper.caseToBeUpdated = updatedCase;
                    	resultWrapper.status = 'Success';
                        resultWrapper.nextStageConfig = nextStage.stageConfig;                      
                        resultWrapperMap.put(caseRec.Id, resultWrapper);
                    }else{
                        resultWrapper.errorMessage = nextStage.errorMessage;
                        resultWrapper.status = 'Error';
                        resultWrapperMap.put(caseRec.Id, resultWrapper);
                    }  
                }
                if(!casesWithNextStageFound.isEmpty()){
                    Map<Id, CaseStageValidationWrapper> beforeResultMap = validateNextStageEntry(casesWithNextStageFound.values(), nextStageConfigMap);
                    for(Id caseId : beforeResultMap.keySet()){
                        StageWrapper resultWrapper = resultWrapperMap.get(caseId);
                        CaseStageValidationWrapper beforeResult = beforeResultMap.get(caseId);
                        ASF_Case_Stage_Config__c nextStage = nextStageConfigMap.get(caseId);
                        if(beforeResult != null && beforeResult.status != 'Success'){
                            resultWrapper.errorMessage = beforeResult.errorMessage;
                            resultWrapper.status = 'Error';
                            resultWrapperMap.put(caseId, resultWrapper);
                        }else{
                            Case updatedCase = resultWrapper.caseToBeUpdated;
                            // If Before Apex Class Run returned any fields on Case, append the same
                            if(beforeResult.isCaseUpdated == true){
                                Map<String, Object> sourceFields = beforeResult.updatedCase.getPopulatedFieldsAsMap();
                                for (String fieldName : sourceFields.keySet()) {
                                    updatedCase.put(fieldName, sourceFields.get(fieldName));
                                }
                            }
                            resultWrapper.caseToBeUpdated = updatedCase;
                            resultWrapper.status = 'Success';
                            resultWrapperMap.put(caseId, resultWrapper);
                        }
                    }
                }
            }
        }

        if(!casesMovingNextPure.isEmpty()){
            //Find the next stage when moved purely forward
            //Run validation on current Stage
            Map<Id, CaseStageValidationWrapper> validationResults = ASF_CaseMovementHelper.validateCurrentStageExit(casesMovingNextPure.values(), currentStageMap);
            for(Id caseId : validationResults.keySet()){
                StageWrapper resultWrapper = resultWrapperMap.get(caseId);
                CaseStageValidationWrapper validationResult = validationResults.get(caseId);
                if(validationResult.status != 'Success'){
                    resultWrapper.errorMessage = validationResult.errorMessage;
                    resultWrapper.status = 'Error';
                    casesMovingNextPure.remove(caseId);
                    resultWrapperMap.put(caseId, resultWrapper);
                }
            }

            Map<Id, Case> casesWithNextStageFound = new Map<Id, Case>();
            Map<Id, ASF_Case_Stage_Config__c> nextStageConfigMap = new Map<Id, ASF_Case_Stage_Config__c>();
            //Atleast one case passed validation
            if(!casesMovingNextPure.isEmpty()){
                //Find the next stage
                Map<Id, StageConfigWrapper> caseIdToNextStageConfig = ASF_CaseMovementHelper.findNextStageForward(casesMovingNextPure.values(), currentStageMap);
                for(Case caseRec : casesMovingNextPure.values()){
                    StageConfigWrapper nextStage = caseIdToNextStageConfig.get(caseRec.Id);
                    StageWrapper resultWrapper = resultWrapperMap.get(caseRec.Id);
                    if(nextStage.status == 'Success'){
                        casesWithNextStageFound.put(caseRec.Id, caseRec);
                        nextStageConfigMap.put(caseRec.Id, nextStage.stageConfig);
                        resultWrapper.nextStageConfig = nextStage.stageConfig;
                        resultWrapper.ownerId = nextStage.ownerId;
                        resultWrapper.errorOwnerId = nextStage.errorOwnerId;
                        resultWrapper.status = 'Success';
                        // VIRENDRA - 8 JUNE 2024 - TO STAMP CASE ASSIGNED TEAM
                        resultWrapper.ownerName = nextStage.ownerName;
                        // VIRENDRA - ENDS HERE.
                        resultWrapperMap.put(caseRec.Id, resultWrapper);
                        
                    }else{
                        resultWrapper.errorMessage = nextStage.errorMessage;
                        resultWrapper.status = 'Error';
                        resultWrapperMap.put(caseRec.Id, resultWrapper);
                    }
                }

                if(!casesWithNextStageFound.isEmpty()){
                    Map<Id, CaseStageValidationWrapper> beforeResultMap = validateNextStageEntry(casesWithNextStageFound.values(), nextStageConfigMap);
                    for(Id caseId : beforeResultMap.keySet()){
                        StageWrapper resultWrapper = resultWrapperMap.get(caseId);
                        CaseStageValidationWrapper beforeResult = beforeResultMap.get(caseId);
                        ASF_Case_Stage_Config__c nextStage = nextStageConfigMap.get(caseId);
                        if(beforeResult != null && beforeResult.status != 'Success'){
                            resultWrapper.errorMessage = beforeResult.errorMessage;
                            resultWrapper.status = 'Error';
                            resultWrapperMap.put(caseId, resultWrapper);
                        }else{
                            String nextStageName = nextStage.StageName__c;
                            //Update assignment, and other case fields
                            Case updatedCase = new Case(Id = caseId);
                            // updatedCase.Stage__c = nextStageName;
                            // updatedCase.Status = nextStage.Status_Mapping__c;  
                            updatedCase.is_Manual_Approval__c = nextStage.Manual_Approval__c;
                            updatedCase.MoveToNext__c = false;
                            // If Before Apex Class Run returned any fields on Case, append the same
                            if(beforeResult.isCaseUpdated == true){
                                Map<String, Object> sourceFields = beforeResult.updatedCase.getPopulatedFieldsAsMap();
                                for (String fieldName : sourceFields.keySet()) {
                                    updatedCase.put(fieldName, sourceFields.get(fieldName));
                                }
                            }

                            resultWrapper.caseToBeUpdated = updatedCase;
                            resultWrapper.status = 'Success';
                            resultWrapper.nextStageConfig = nextStage;
                            resultWrapperMap.put(caseId, resultWrapper);
                        }
                    }
                }
            }
        }
        return resultWrapperMap;
    }
    

    /**
    * This method runs when the user moves to next stage manually
    * This is not to be used when moving to next stage after back movement
    * Returns StageWrapper
    * Bulkified
    */

    public static Map<Id, StageWrapper> moveToForwardStage(List<Case> currentCases, Map<Id, String> requestedStageMap, Map<Id, String> currentStageMap){
        Map<Id, StageWrapper> resultWrapperMap = new Map<Id, StageWrapper>();
        
        Map<Id, Case> currentCasesMap = new Map<Id, Case>(currentCases);
        Set<String> externalIds = new Set<String>();
        for(Case caseRec : currentCases){
            StageWrapper resultWrapper = new StageWrapper();
            resultWrapper.status = 'Success';
            resultWrapperMap.put(caseRec.Id, resultWrapper);
            externalIds.add(caseRec.CCC_External_Id__c);
        }

        List<ASF_Case_Stage_Config__c> allStageConfigs = ASF_CaseQueryHandler.getCaseStageConfigWithRlAndIntr(externalIds);

        // Find All Query Fields for Case, Merge them togther, and perform one Query on Case
        Set<String> allFields = new Set<String>{'stage__c', 'businesshoursid', 'ccc_external_id__c', 'previous_stage__c', 'business_unit__c', 'lead__c','lob__c'};
        	allFields.addAll(ASF_Constants.CASE_EXTENSION_FIELDSET);
            for(ASF_Case_Stage_Config__c config: allStageConfigs){
            if(config.Query_Fields__c != null){
                allFields.addAll(config.Query_Fields__c.toLowerCase().split(','));
            }
        }
        ASF_CaseQueryHandler.refreshRecords = true;
        List<Case> queriedCaseRecords = ASF_CaseQueryHandler.getCaseRecordWithQueryFields(allFields, currentCasesMap.keySet());
        Map<Id,Case> queriesCasesMap = new Map<Id,Case>(queriedCaseRecords);
        ASF_CaseQueryHandler.refreshRecords = false;
        //Run validation on current Stage
        Map<Id, CaseStageValidationWrapper> validationResults = ASF_CaseMovementHelper.validateCurrentStageExit(queriedCaseRecords, currentStageMap);
        for(Id caseId : validationResults.keySet()){
            StageWrapper resultWrapper = resultWrapperMap.get(caseId);
            CaseStageValidationWrapper validationResult = validationResults.get(caseId);
            if(validationResult.status != 'Success'){
                resultWrapper.errorMessage = validationResult.errorMessage;
                resultWrapper.status = 'Error';
                queriesCasesMap.remove(caseId);
                resultWrapperMap.put(caseId, resultWrapper);
            }
        }

        Map<String, List<ASF_Case_Stage_Config__c>> externalIdToStageConfigsMap = new Map<String, List<ASF_Case_Stage_Config__c>>();
        Map<Id, ASF_Case_Stage_Config__c> caseIdToNextStageConfigMap = new Map<Id, ASF_Case_Stage_Config__c>();
        Map<Id, String> caseIdToLastActionedStageMap = new Map<Id, String>();
        List<Case> casesWithoutAssignment = new List<Case>();
        Map<Id, String> caseIdToStageMap = new Map<Id, String>();
        //Atleast one case passed validation
        if(!queriesCasesMap.isEmpty()){
            // Determine Next Stage Config
            for(ASF_Case_Stage_Config__c config: allStageConfigs){
                if(!externalIdToStageConfigsMap.containsKey(config.Case_Category_Config__r.CCC_External_Id__c)){
                    externalIdToStageConfigsMap.put(config.Case_Category_Config__r.CCC_External_Id__c, new List<ASF_Case_Stage_Config__c>());
                }
                externalIdToStageConfigsMap.get(config.Case_Category_Config__r.CCC_External_Id__c).add(config);
            }

            for(Case caseRec : currentCasesMap.values()){
                if(externalIdToStageConfigsMap.containsKey(caseRec.CCC_External_Id__c)){
                    for(ASF_Case_Stage_Config__c config: externalIdToStageConfigsMap.get(caseRec.CCC_External_Id__c)){
                        if(config.StageName__c == requestedStageMap.get(caseRec.Id)){
                            caseIdToNextStageConfigMap.put(caseRec.Id, config);
                            break;
                        }
                    }
                }
            }

            Map<Id, CaseStageValidationWrapper> beforeResultMap = validateNextStageEntry(queriesCasesMap.values(), caseIdToNextStageConfigMap);

            // If movement to next Stage is valid
            for(Case caseRec : queriesCasesMap.values()){
                CaseStageValidationWrapper beforeResult = beforeResultMap.get(caseRec.Id);
                StageWrapper resultWrapper = resultWrapperMap.containsKey(caseRec.Id) ? resultWrapperMap.get(caseRec.Id) : new StageWrapper();
                if(beforeResult != null && beforeResult.status != 'Success'){
                    resultWrapper.errorMessage = beforeResult.errorMessage;
                    resultWrapper.status = 'Error';
                    resultWrapperMap.put(caseRec.Id, resultWrapper);
                    queriesCasesMap.remove(caseRec.Id);
                }else{
                    //Update assignment, and other case fields
                    ASF_Case_Stage_Config__c nextStageConfig = caseIdToNextStageConfigMap.get(caseRec.Id);
                    Case updatedCase = new Case(Id = caseRec.Id);
                    updatedCase.Stage__c = requestedStageMap.get(caseRec.Id);
                    updatedCase.Status = nextStageConfig!=null?nextStageConfig.Status_Mapping__c:null;
                    updatedCase.Is_Manual_Stage_Visited__c = true;
                    
                    // If Validation Layer Returned any fields in Case, append the same
                    // This is returned from Custom Apex Class Run After the Stage Movement
                    CaseStageValidationWrapper validationResult = validationResults.get(caseRec.Id);
                    if(validationResult.isCaseUpdated == true){
                        Map<String, Object> sourceFields = validationResult.updatedCase.getPopulatedFieldsAsMap();
                        for (String fieldName : sourceFields.keySet()) {
                            updatedCase.put(fieldName, sourceFields.get(fieldName));
                        }
                    }

                    // If Before Apex Class Run returned any fields on Case, append the same
                    if(beforeResult != null && beforeResult.isCaseUpdated == true){
                        Map<String, Object> sourceFields = beforeResult.updatedCase.getPopulatedFieldsAsMap();
                        for (String fieldName : sourceFields.keySet()) {
                            updatedCase.put(fieldName, sourceFields.get(fieldName));
                        }
                    }

                    resultWrapper.caseToBeUpdated = updatedCase;
                    resultWrapper.nextStageConfig = nextStageConfig;
                    

                    // Fetch Owner Assignment for Stage
                    if(nextStageConfig !=null){
                        if(nextStageConfig.Assign_To_Last_Actioned_Stage__c != null){
                            caseIdToLastActionedStageMap.put(caseRec.Id, nextStageConfig.Assign_To_Last_Actioned_Stage__c);
                        }else if(nextStageConfig.Default_Queue__c != null){
                            resultWrapper.ownerId = nextStageConfig.Default_Queue__c;
                            resultWrapper.errorOwnerId = nextStageConfig.Default_Error_Queue__c;
                            resultWrapper.status = resultWrapper.ownerId != null?'Success':null;
                            resultWrapperMap.put(caseRec.Id, resultWrapper);
                        }else{
                            casesWithoutAssignment.add(caseRec);
                            caseIdToStageMap.put(caseRec.Id, nextStageConfig.StageName__c);
                        }
                    }
                    resultWrapperMap.put(caseRec.Id, resultWrapper);
                }
            }
            
            if(!caseIdToLastActionedStageMap.isEmpty()){
                Map<Id, ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo> infos = ASF_CaseFrameworkHelper.findAssignmentForPreviouslyVisitedStage(caseIdToLastActionedStageMap);
                for(Case caseRec : currentCasesMap.values()){
                    StageWrapper resultWrapper = resultWrapperMap.get(caseRec.Id);
                    if(infos.containsKey(caseRec.Id)){
                        ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo info = infos.get(caseRec.Id);
                        //resultWrapper.isPreviousStage = true;
                        resultWrapper.ownerId = info.defaultOwnerId;
                        resultWrapper.errorOwnerId = info.defaultErrorOwnerId;
                        resultWrapper.status = resultWrapper.ownerId != null?'Success':null;
                    }
                    resultWrapperMap.put(caseRec.Id, resultWrapper);
                    if(resultWrapper.ownerId == null && resultWrapper.status == null){
                        casesWithoutAssignment.add(caseRec);
                        caseIdToStageMap.put(caseRec.Id, caseIdToNextStageConfigMap.get(caseRec.Id).StageName__c);
                    }
                }
            }

            if(!casesWithoutAssignment.isEmpty()){
                Map<Id, ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo> infos = ASF_CaseMovementHelper.getAssignmentForStage(casesWithoutAssignment, caseIdToStageMap);
                for(Case caseRec : casesWithoutAssignment){
                    StageWrapper resultWrapper = resultWrapperMap.get(caseRec.Id);
                    if(infos.containsKey(caseRec.Id)){
                        ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo info = infos.get(caseRec.Id);
                        resultWrapper.ownerId = info.defaultOwnerId;
                        resultWrapper.errorOwnerId = info.defaultErrorOwnerId;
                    }
                    resultWrapper.status = 'Success'; //Even if assignment not found, its a success for movetoforward.
                    resultWrapperMap.put(caseRec.Id, resultWrapper);
                }
            }
        }
        return resultWrapperMap;
    }
    
    
    /**
    * This method runs when the user moves to Back stage manually
    * Returns StageWrapper
    * Bulkified
    */
    @AuraEnabled
    public static Map<Id, StageWrapper> moveToBackwardStage(List<Case> currentCases, Map<Id, String> requestedStageMap){
        Map<Id, StageWrapper> resultWrapperMap = new Map<Id, StageWrapper>();
        
        Set<String> externalIds = new Set<String>();
        set<Id> caseIds = new Set<Id>();
        for(Case caseRec : currentCases){
            StageWrapper resultWrapper = new StageWrapper();
            resultWrapperMap.put(caseRec.Id, resultWrapper);
            externalIds.add(caseRec.CCC_External_Id__c);
            caseIds.add(caseRec.Id);
        }

        List<ASF_Case_Stage_Config__c> allStageConfigs = ASF_CaseQueryHandler.getCaseStageConfigWithRlAndIntr(externalIds);

        // Find All Query Fields for Case, Merge them togther, and perform one Query on Case
        Set<String> allFields = new Set<String>{'stage__c', 'businesshoursid', 'ccc_external_id__c', 'previous_stage__c', 'business_unit__c', 'lead__c','lob__c'};
        	allFields.addAll(ASF_Constants.CASE_EXTENSION_FIELDSET);
            for(ASF_Case_Stage_Config__c config: allStageConfigs){
            if(config.Query_Fields__c != null){
                allFields.addAll(config.Query_Fields__c.toLowerCase().split(','));
            }
        }

        List<Case> queriedCaseRecords = ASF_CaseQueryHandler.getCaseRecordWithQueryFields(allFields, caseIds);
        Map<Id,Case> queriesCasesMap = new Map<Id,Case>(queriedCaseRecords);
        
        Map<String, List<ASF_Case_Stage_Config__c>> externalIdToStageConfigsMap = new Map<String, List<ASF_Case_Stage_Config__c>>();
        Map<Id, ASF_Case_Stage_Config__c> caseIdToNextStageConfigMap = new Map<Id, ASF_Case_Stage_Config__c>();
        Map<Id, String> caseIdToLastActionedStageMap = new Map<Id, String>();
        List<Case> casesWithoutAssignment = new List<Case>();
        if(!queriesCasesMap.isEmpty()){
            // Determine Next Stage Config
            for(ASF_Case_Stage_Config__c config: allStageConfigs){
                if(!externalIdToStageConfigsMap.containsKey(config.Case_Category_Config__r.CCC_External_Id__c)){
                    externalIdToStageConfigsMap.put(config.Case_Category_Config__r.CCC_External_Id__c, new List<ASF_Case_Stage_Config__c>());
                }
                externalIdToStageConfigsMap.get(config.Case_Category_Config__r.CCC_External_Id__c).add(config);
            }

            for(Case caseRec : queriesCasesMap.values()){
                for(ASF_Case_Stage_Config__c config: externalIdToStageConfigsMap.get(caseRec.CCC_External_Id__c)){
                    if(config.StageName__c == requestedStageMap.get(caseRec.Id)){
                        caseIdToNextStageConfigMap.put(caseRec.Id, config);
                        break;
                    }
                }
            }

            List<ASF_Case_Rule__c> allCaseRules = ASF_CaseQueryHandler.getCaseRuleWithHierarchy(externalIds);

            Map<Id, List<ASF_Case_Rule__c>> stageConfigIdToCaseRules = new Map<Id, List<ASF_Case_Rule__c>>();
            for(ASF_Case_Rule__c caseRule : allCaseRules){
                if(!stageConfigIdToCaseRules.containsKey(caseRule.Case_Stage_Config__c)){
                    stageConfigIdToCaseRules.put(caseRule.Case_Stage_Config__c, new List<ASF_Case_Rule__c>());
                }
                stageConfigIdToCaseRules.get(caseRule.Case_Stage_Config__c).add(caseRule);
            }

            for(Case caseRec : queriedCaseRecords){
                ASF_Case_Stage_Config__c nextStageConfig = caseIdToNextStageConfigMap.get(caseRec.Id);
                // Run Stage Movement Rules to check if this is the Next Stage
                List<ASF_Case_Rule__c> caseRulesForStage = new List<ASF_Case_Rule__c>();
                if(stageConfigIdToCaseRules.containsKey(nextStageConfig.Id)){
                    caseRulesForStage.addAll(stageConfigIdToCaseRules.get(nextStageConfig.Id));
                }

                Boolean isStageMovementValid = ASF_CaseFrameworkHelper.runStageMovementRules(caseRec, caseRulesForStage);
                if(isStageMovementValid){
                    StageWrapper resultWrapper = resultWrapperMap.get(caseRec.Id);
                    resultWrapper.nextStageConfig = nextStageConfig;
                    resultWrapperMap.put(caseRec.Id, resultWrapper);
                }else{
                    StageWrapper resultWrapper = resultWrapperMap.get(caseRec.Id);
                    resultWrapper.status = 'Error';
                    resultWrapper.errorMessage = 'Case is not eligible to enter '+requestedStageMap.get(caseRec.Id)+' stage';
                    resultWrapperMap.put(caseRec.Id, resultWrapper);
                    queriesCasesMap.remove(caseRec.Id);
                    requestedStageMap.remove(caseRec.Id);
                }
            }

            if(!queriesCasesMap.isEmpty()){
                Map<Id, ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo> assignmentInfoMap = new Map<Id, ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo>();
                assignmentInfoMap = ASF_CaseFrameworkHelper.findAssignmentForPreviouslyVisitedStage(requestedStageMap);
                for(Case caseRec : queriesCasesMap.values()){
                    StageWrapper resultWrapper = resultWrapperMap.get(caseRec.Id);
                    if(assignmentInfoMap.containsKey(caseRec.Id)){
                        ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo info = assignmentInfoMap.get(caseRec.Id);
                        resultWrapper.ownerId = info?.defaultOwnerId;
                        // VIRENDRA - 8 JUNE 2024 - TO STAMP CASE ASSIGNED TEAM.
                        resultWrapper.ownerName = info != null? info.defaultOwnerName : '';
                        // VIRENDRA - ENDS HERE.
                        resultWrapper.errorOwnerId = info?.defaultErrorOwnerId;
                        resultWrapperMap.put(caseRec.Id, resultWrapper);
                        // If Owner Id not found, find by regular method
                        if(resultWrapper.ownerId == null){
                            casesWithoutAssignment.add(caseRec);
                        }
                    }else{
                        casesWithoutAssignment.add(caseRec);
                    }
                }
            }
            if(!casesWithoutAssignment.isEmpty()){
                Map<Id, ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo> rulesAssignmentInfos = ASF_CaseMovementHelper.getAssignmentForStage(casesWithoutAssignment, requestedStageMap);
                for(Case caseRec : casesWithoutAssignment){
                    ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo info = rulesAssignmentInfos.get(caseRec.Id);
                    StageWrapper resultWrapper = resultWrapperMap.get(caseRec.Id);
                    resultWrapper.ownerId = info.defaultOwnerId;
                    // VIRENDRA - 8 JUNE 2024 - TO STAMP CASE ASSIGNED TEAM.
                    resultWrapper.ownerName = info.defaultOwnerName;
                    // VIRENDRA - ENDS HERE.
                    resultWrapper.errorOwnerId = info.defaultErrorOwnerId;
                    resultWrapperMap.put(caseRec.Id, resultWrapper);
                }
            }

            for(Case caseRec : queriesCasesMap.values()){
                StageWrapper resultWrapper = resultWrapperMap.get(caseRec.Id);
                Case updatedCase = new Case(Id = caseRec.Id);
                updatedCase.Stage__c = requestedStageMap.get(caseRec.Id);
                updatedCase.Status = caseIdToNextStageConfigMap.get(caseRec.Id).Status_Mapping__c;
                updatedCase.is_Manual_Approval__c = caseIdToNextStageConfigMap.get(caseRec.Id).Manual_Approval__c;
                resultWrapper.caseToBeUpdated = updatedCase;
                resultWrapper.status = 'Success';
                resultWrapperMap.put(caseRec.Id, resultWrapper);
            }
        }
        return resultWrapperMap;
    }

    
    
    /**
     * Validate if the movemnet out of this current stage is valid or not
     * Accordinlgy only next stage movement will happen
     * Bulkified
     */
    public static Map<Id, CaseStageValidationWrapper> validateCurrentStageExit(List<Case> currentCases, Map<Id, String> currentStageMap){
        
        Map<Id, CaseStageValidationWrapper> resultWrapperMap = new Map<Id, CaseStageValidationWrapper>();
        
        Set<String> externalIds = new Set<String>();
        for(Case caseRec : currentCases){
            externalIds.add(caseRec.CCC_External_Id__c);
            CaseStageValidationWrapper resultWrapper = new CaseStageValidationWrapper();
            resultWrapper.status  = 'Success';
            resultWrapperMap.put(caseRec.Id, resultWrapper);
        }

        Map<Id, ASF_Case_Stage_Config__c> caseIdToCurrentStageConfigMap = new Map<Id, ASF_Case_Stage_Config__c>();
        Map<String, List<ASF_Case_Stage_Config__c>> externalIdToStageConfigsMap = new Map<String, List<ASF_Case_Stage_Config__c>>();
        
        List<ASF_Case_Stage_Config__c> allStageConfigs = ASF_CaseQueryHandler.getCaseStageConfigWithRlAndIntr(externalIds);
        for(ASF_Case_Stage_Config__c config: allStageConfigs){
            if(!externalIdToStageConfigsMap.containsKey(config.Case_Category_Config__r.CCC_External_Id__c)){
                externalIdToStageConfigsMap.put(config.Case_Category_Config__r.CCC_External_Id__c, new List<ASF_Case_Stage_Config__c>());
            }
            externalIdToStageConfigsMap.get(config.Case_Category_Config__r.CCC_External_Id__c).add(config);
        }

        for(Case caseRec : currentCases){
            if(externalIdToStageConfigsMap.containsKey(caseRec.CCC_External_Id__c)){
                for(ASF_Case_Stage_Config__c config: externalIdToStageConfigsMap.get(caseRec.CCC_External_Id__c)){
                    if(config.StageName__c == currentStageMap.get(caseRec.Id)){
                        caseIdToCurrentStageConfigMap.put(caseRec.Id, config);
                        break;
                    }
                }
            }
        }

        Map<Id, Boolean> areChecklistsCompletePerCase = ASF_CaseFrameworkValidator.validateChecklists(currentCases, currentStageMap);
        Map<Id, Boolean> areTasksCompletePerCase = ASF_CaseFrameworkValidator.validateTasks(currentCases, currentStageMap);
        Map<Id, Boolean> areApprovalsCompletedPerCase = ASF_CaseFrameworkValidator.validateApprovals(currentCases, currentStageMap);
        Map<Id, String> areValidationsOkPerCase = ASF_CaseFrameworkValidator.validateValidations(currentCases, caseIdToCurrentStageConfigMap);
        Map<Id, String> areIntegrationsCompletePerCase = ASF_CaseFrameworkValidator.validateIntegrations(currentCases, caseIdToCurrentStageConfigMap);

        Map<Id, CaseStageValidationWrapper> afterStageResultMap = new Map<Id, CaseStageValidationWrapper>();
        Map<String, List<Case>> apexclassToCases = new Map<String, List<Case>>();
        for(Case caseRec : currentCases){
            ASF_Case_Stage_Config__c currentStageConfig = caseIdToCurrentStageConfigMap.get(caseRec.Id);
            if(currentStageConfig != null && currentStageConfig.AfterStageApexClass__c != null){
                if(!apexclassToCases.containsKey(currentStageConfig.AfterStageApexClass__c)){
                    apexclassToCases.put(currentStageConfig.AfterStageApexClass__c, new List<Case>());
                }
                apexclassToCases.get(currentStageConfig.AfterStageApexClass__c).add(caseRec);
            }
        }
        for(String apexClass : apexclassToCases.keySet()){
            Type customType = Type.forName(apexClass);
            ASF_CaseStageClassInvocable instance = (ASF_CaseStageClassInvocable)customType.newInstance();
            Map<Id, CaseStageValidationWrapper> afterResults = instance.afterStageMovement(apexclassToCases.get(apexClass)); 
            afterStageResultMap.putAll(afterResults);
        }

        for(Case caseRec : currentCases){
            CaseStageValidationWrapper resultWrapper = resultWrapperMap.get(caseRec.Id);
            if(areChecklistsCompletePerCase.containsKey(caseRec.Id) && !areChecklistsCompletePerCase.get(caseRec.Id)){
                resultWrapper.status  = 'Error';
                resultWrapper.errorMessage = System.Label.Incomplete_Checklist_Error_Message;
            }
            else if(areTasksCompletePerCase.containsKey(caseRec.Id) && !areTasksCompletePerCase.get(caseRec.Id)){
                resultWrapper.status  = 'Error';
                resultWrapper.errorMessage = System.Label.Incomplete_Tasks_Error_Message;
            }
            else if(areApprovalsCompletedPerCase.containsKey(caseRec.Id) && !areApprovalsCompletedPerCase.get(caseRec.Id)){
                resultWrapper.status  = 'Error';
                // TODO - Create Labels
                resultWrapper.errorMessage = 'Approvals are Pending';
            }
            else if(areValidationsOkPerCase.containsKey(caseRec.Id) && areValidationsOkPerCase.get(caseRec.Id) != 'Success'){
                resultWrapper.status  = 'Error';
                resultWrapper.errorMessage = areValidationsOkPerCase.get(caseRec.Id);
            }
            else if(areIntegrationsCompletePerCase.containsKey(caseRec.Id) && areIntegrationsCompletePerCase.get(caseRec.Id) != 'Success'){
                resultWrapper.status  = 'Error';
                resultWrapper.errorMessage = areIntegrationsCompletePerCase.get(caseRec.Id);
            }

            if(resultWrapper.status != 'Error'){
                if(afterStageResultMap.containsKey(caseRec.Id)){
                    resultWrapper = afterStageResultMap.get(caseRec.Id);
                }
                // ASF_Case_Stage_Config__c currentStageConfig = caseIdToCurrentStageConfigMap.get(caseRec.Id);
                // if(currentStageConfig != null && currentStageConfig.AfterStageApexClass__c != null){
                //     Type customType = Type.forName(currentStageConfig.AfterStageApexClass__c);
                //     ASF_CaseStageClassInvocable instance = (ASF_CaseStageClassInvocable)customType.newInstance();
                //     resultWrapper = instance.afterStageMovement(caseRec);            
                //     system.debug(resultWrapper);
                // }
            }
            resultWrapperMap.put(caseRec.Id, resultWrapper);
        }
        return resultWrapperMap;
    }

    /**
     * Validate if the movemnet to the Next Stage is Valid or not
     */
    public static Map<Id, CaseStageValidationWrapper> validateNextStageEntry(List<Case> currentCases, Map<Id, ASF_Case_Stage_Config__c> nextStageConfigs){
        
        Map<Id, CaseStageValidationWrapper> returnWrapperMap = new Map<Id, CaseStageValidationWrapper>();
        Map<String, List<Case>> apexclassToCases = new Map<String, List<Case>>();
        for(Case caseRec : currentCases){
            ASF_Case_Stage_Config__c nextStageConfig = nextStageConfigs.get(caseRec.Id);
            if(nextStageConfig != null && nextStageConfig.BeforeStageApexClass__c != null){
                if(!apexclassToCases.containsKey(nextStageConfig.BeforeStageApexClass__c)){
                    apexclassToCases.put(nextStageConfig.BeforeStageApexClass__c, new List<Case>());
                }
                apexclassToCases.get(nextStageConfig.BeforeStageApexClass__c).add(caseRec);
            }else {
                 CaseStageValidationWrapper caseValidationWrapper = new CaseStageValidationWrapper();
                 caseValidationWrapper.Status = 'Success';
                returnWrapperMap.put(caseRec.Id,caseValidationWrapper);
            }
        }
        for(String apexClass : apexclassToCases.keySet()){
            Type customType = Type.forName(apexClass);
            ASF_CaseStageClassInvocable instance = (ASF_CaseStageClassInvocable)customType.newInstance();
            Map<Id, CaseStageValidationWrapper> beforeResultMap = instance.beforeStageMovement(apexclassToCases.get(apexClass)); 
            returnWrapperMap.putAll(beforeResultMap); 
        }
        // Run Before Apex Class
        // CaseStageValidationWrapper beforeResult = new CaseStageValidationWrapper();
        // beforeResult.status = 'Success';
        // if(nextStageConfig != null && nextStageConfig.BeforeStageApexClass__c != null){
        //     Type customType = Type.forName(nextStageConfig.BeforeStageApexClass__c);
        //     ASF_CaseStageClassInvocable instance = (ASF_CaseStageClassInvocable)customType.newInstance();
        //     beforeResult = instance.beforeStageMovement(currentCase);  
        // }

        return returnWrapperMap;
    
    }
    
    /**
    * Finds the Next Automated Stage for Automated Forward Movement - Standard Case
    * This is not to be used when finding next stage after back movement
    * Returns the next Stage Name
    * Process - 
    * 1.Keep looping through next order. 
    * 2. If Mandatory Stage found, stop. 
    * 3. If Optional Stage Found, run Stage Assignment Rules. If ok, Stop.
    * 4. Else continue to look
    * 5. Determine the Ownership by running assignment rule for the Stage Found
    * Bulkified
    */
    public static Map<Id, StageConfigWrapper> findNextStageForward(List<Case> currentCases, Map<Id, String> currentStageMap){
        Map<Id, StageConfigWrapper> resultWrapperMap = new Map<Id, StageConfigWrapper>();

        Set<String> externalIds = new Set<String>();
        Set<Id> caseIds = new Set<Id>();
        for(Case caseRec : currentCases){
            StageConfigWrapper resultWrapper = new StageConfigWrapper();
            resultWrapper.status = 'Success';
            resultWrapperMap.put(caseRec.Id, resultWrapper);
            externalIds.add(caseRec.CCC_External_Id__c);
            caseIds.add(caseRec.Id);
        }
        

        Map<Id, ASF_Case_Stage_Config__c> caseIdToCurrentStageConfigMap = new Map<Id, ASF_Case_Stage_Config__c>();
        Map<String, List<ASF_Case_Stage_Config__c>> externalIdToStageConfigsMap = new Map<String, List<ASF_Case_Stage_Config__c>>();
        
        List<ASF_Case_Stage_Config__c> allStageConfigs = ASF_CaseQueryHandler.getCaseStageConfigWithRlAndIntr(externalIds);
        for(ASF_Case_Stage_Config__c config: allStageConfigs){
            if(!externalIdToStageConfigsMap.containsKey(config.Case_Category_Config__r.CCC_External_Id__c)){
                externalIdToStageConfigsMap.put(config.Case_Category_Config__r.CCC_External_Id__c, new List<ASF_Case_Stage_Config__c>());
            }
            externalIdToStageConfigsMap.get(config.Case_Category_Config__r.CCC_External_Id__c).add(config);
        }

        for(Case caseRec : currentCases){
            if(externalIdToStageConfigsMap.containsKey(caseRec.CCC_External_Id__c)){
                for(ASF_Case_Stage_Config__c config: externalIdToStageConfigsMap.get(caseRec.CCC_External_Id__c)){
                    if(config.StageName__c == currentStageMap.get(caseRec.Id)){
                        caseIdToCurrentStageConfigMap.put(caseRec.Id, config);
                        break;
                    }
                }
            }
        }

        // Fetch all Case Rules and Run the Approrpriate One - For Approval matching the Case Stage Config
        List<ASF_Case_Rule__c> allCaseRules = ASF_CaseQueryHandler.getCaseRuleWithHierarchy(externalIds);
        Map<Id, List<ASF_Case_Rule__c>> stageIdToCaseRulesMap = new Map<Id, List<ASF_Case_Rule__c>>();
        for(ASF_Case_Rule__c rule : allCaseRules){
            if(!stageIdToCaseRulesMap.containsKey(rule.Case_Stage_Config__c)){
                stageIdToCaseRulesMap.put(rule.Case_Stage_Config__c, new List<ASF_Case_Rule__c>());
            }
            stageIdToCaseRulesMap.get(rule.Case_Stage_Config__c).add(rule);
        }
        // Find All Query Fields for Case, Merge them togther, and perform one Query on Case
        Set<String> allFields = new Set<String>{'stage__c', 'businesshoursid', 'ccc_external_id__c', 'previous_stage__c', 'business_unit__c', 'lead__c','lob__c'};
        	allFields.addAll(ASF_Constants.CASE_EXTENSION_FIELDSET);
            for(ASF_Case_Stage_Config__c config: allStageConfigs){
            if(config.Query_Fields__c != null){
                allFields.addAll(config.Query_Fields__c.toLowerCase().split(','));
            }
        }
		ASF_CaseQueryHandler.refreshRecords = true;
        List<Case> queriedCaseRecords = ASF_CaseQueryHandler.getCaseRecordWithQueryFields(allFields, caseIds);
        ASF_CaseQueryHandler.refreshRecords = false;
        Map<Id,Case> queriesCasesMap = new Map<Id,Case>(queriedCaseRecords);
        Map<Id, ASF_Case_Stage_Config__c> caseIdToNextStageConfigMap = new Map<Id, ASF_Case_Stage_Config__c>();
        for(Case caseRec : currentCases){
            if(externalIdToStageConfigsMap.containsKey(caseRec.CCC_External_Id__c)){
                for(ASF_Case_Stage_Config__c config: externalIdToStageConfigsMap.get(caseRec.CCC_External_Id__c)){
                    ASF_Case_Stage_Config__c currentStageConfig = caseIdToCurrentStageConfigMap.get(caseRec.Id);
                    if(currentStageConfig != null && currentStageConfig.Order__c < config.Order__c){
                        // See if Applicable. 
                        // If Not Optional, Allot to Next Stage and Break
                        if(config.Optional_Stage__c){
                            
                            // Run Stage Movement Rules to check if this is the Next Stage
                            List<ASF_Case_Rule__c> caseRulesForStage = new List<ASF_Case_Rule__c>();
                            caseRulesForStage.addAll(stageIdToCaseRulesMap.get(config.Id));
                            
                            Boolean isStageMovementValid = ASF_CaseFrameworkHelper.runStageMovementRules(queriesCasesMap.get(caseRec.Id), caseRulesForStage);
                            System.debug('***isStageMovementValid'+isStageMovementValid);
                            if(isStageMovementValid){
                                caseIdToNextStageConfigMap.put(caseRec.Id, config);
                                System.debug('***nextStageConfig:'+config);
                            }
                            else{
                                continue;
                            }
                        } else if(config.Gateway_Stage__c){
                            caseIdToNextStageConfigMap.put(caseRec.Id, config);
                        }
                        // If Manual, Continue ahead
                        else if(config.Manual_Stage__c){
                            continue;
                        }
                        else {
                            caseIdToNextStageConfigMap.put(caseRec.Id, config);
                        }
                    }
                    if(caseIdToNextStageConfigMap.containsKey(caseRec.Id)){
                        StageConfigWrapper resultWrapper = resultWrapperMap.get(caseRec.Id);
                        resultWrapper.stageConfig = caseIdToNextStageConfigMap.get(caseRec.Id);
                        resultWrapperMap.put(caseRec.Id, resultWrapper);
                        break;//next stage found, go to next case
                    }
                }
            }
        }

        // Once Next Stage is found, run Assignment Rules to get the Owner Information
        Map<Id, String> caseIdToLastActionedStageMap = new Map<Id,String>();
        List<Case> casesWithoutAssignment = new List<Case>();
        Map<Id, String> caseIdToStageMap = new Map<Id,String>();
        for(Case caseRec : currentCases){
            ASF_Case_Stage_Config__c nextStageConfig = caseIdToNextStageConfigMap.get(caseRec.Id);
            if(nextStageConfig != null){
                if(nextStageConfig.Assign_To_Last_Actioned_Stage__c != null){
                    caseIdToLastActionedStageMap.put(caseRec.Id, nextStageConfig.Assign_To_Last_Actioned_Stage__c);
                }else if(nextStageConfig.Default_Queue__c != null){
                    StageConfigWrapper resultWrapper = resultWrapperMap.get(caseRec.Id);
                    resultWrapper.ownerId = nextStageConfig.Default_Queue__c;
                    // VIRENDRA - 8 JUNE 2024 - ADDED TO STAMP CASE ASSIGNED TEAM.
                    resultWrapper.ownerName = nextStageConfig.Default_Queue_user_Name__c;
                    // VIRENDRA - ENDS HERE.
                    resultWrapper.errorOwnerId = nextStageConfig.Default_Error_Queue__c;
                    resultWrapper.status = resultWrapper.ownerId != null?'Success':null;
                    resultWrapperMap.put(caseRec.Id, resultWrapper);
                }else{
                    casesWithoutAssignment.add(caseRec);
                    caseIdToStageMap.put(caseRec.Id, nextStageConfig.StageName__c);
                }
            }
            else{
                //next stage not found, throw error
                StageConfigWrapper resultWrapper = resultWrapperMap.get(caseRec.Id);
                resultWrapper.status = 'Error';
                resultWrapper.errorMessage = 'No applicable next stage found';
                resultWrapperMap.put(caseRec.Id, resultWrapper);
            }
        }

        
        
        if(!caseIdToLastActionedStageMap.isEmpty()){
            Map<Id, ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo> infos = ASF_CaseFrameworkHelper.findAssignmentForPreviouslyVisitedStage(caseIdToLastActionedStageMap);
            for(Case caseRec : currentCases){
                StageConfigWrapper resultWrapper = resultWrapperMap.get(caseRec.Id);
                if(infos.containsKey(caseRec.Id)){
                    ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo info = infos.get(caseRec.Id);
                    resultWrapper.isPreviousStage = true;
                    resultWrapper.ownerId = info.defaultOwnerId;
                    resultWrapper.errorOwnerId = info.defaultErrorOwnerId;
                    resultWrapper.status = resultWrapper.ownerId != null?'Success':null;
                }
                resultWrapperMap.put(caseRec.Id, resultWrapper);
                if(resultWrapper.ownerId == null && resultWrapper.status == null){
                    casesWithoutAssignment.add(caseRec);
                    caseIdToStageMap.put(caseRec.Id, caseIdToNextStageConfigMap.get(caseRec.Id).StageName__c);
                }
            }
        }

        if(!casesWithoutAssignment.isEmpty()){
            Map<Id, ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo> infos = ASF_CaseMovementHelper.getAssignmentForStage(casesWithoutAssignment, caseIdToStageMap);
            for(Case caseRec : casesWithoutAssignment){
                StageConfigWrapper resultWrapper = resultWrapperMap.get(caseRec.Id);
                if(infos.containsKey(caseRec.Id)){
                    ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo info = infos.get(caseRec.Id);
                    resultWrapper.ownerId = info.defaultOwnerId;
                    // VIRENDRA - 21 JUL 2024 - Added for SIT BUG FIX.
                    resultWrapper.ownerName = info.defaultOwnerName != null? info.defaultOwnerName : '';
                    resultWrapper.errorOwnerId = info.defaultErrorOwnerId;
                    resultWrapper.status = 'Success';
                }
                resultWrapperMap.put(caseRec.Id, resultWrapper);
            }
        }
        return resultWrapperMap;
    }

    /**
     * One Method to find the rightr assignment for a certain stage
     * This takes into account he following
     * Bulkfied
     */
    public static Map<Id,ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo> getAssignmentForStage(List<Case> currentCases, Map<Id, String> caseIdToStageNameMap){
        System.debug('****getAssignmentForStage');
        Map<Id, ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo> resultWrapperMap = new Map<Id, ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo>();
        
        Set<String> externalIds = new Set<String>();
        Set<Id> caseIds = new Set<Id>();
        for(Case caseRec : currentCases){
            externalIds.add(caseRec.CCC_External_Id__c);
            caseIds.add(caseRec.Id);
            ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo resultWrapper = new ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo();
            resultWrapperMap.put(caseRec.Id, resultWrapper);
        }

        Map<Id, ASF_Case_Stage_Config__c> caseIdToCurrentStageConfigMap = new Map<Id, ASF_Case_Stage_Config__c>();
        Map<String, List<ASF_Case_Stage_Config__c>> externalIdToStageConfigsMap = new Map<String, List<ASF_Case_Stage_Config__c>>();
        System.debug('externalIds ---> '+externalIds);
        ASF_CaseQueryHandler.refreshRecords = true;
        List<ASF_Case_Stage_Config__c> allStageConfigs = ASF_CaseQueryHandler.getCaseStageConfigWithRlAndIntr(externalIds);
        ASF_CaseQueryHandler.refreshRecords = false;
        for(ASF_Case_Stage_Config__c config: allStageConfigs){
            if(!externalIdToStageConfigsMap.containsKey(config.Case_Category_Config__r.CCC_External_Id__c)){
                externalIdToStageConfigsMap.put(config.Case_Category_Config__r.CCC_External_Id__c, new List<ASF_Case_Stage_Config__c>());
            }
            externalIdToStageConfigsMap.get(config.Case_Category_Config__r.CCC_External_Id__c).add(config);
        }

        Set<String> allFields = new Set<String>{'stage__c', 'businesshoursid', 'ccc_external_id__c', 'previous_stage__c', 'business_unit__c', 'lead__c','lob__c'};
        	allFields.addAll(ASF_Constants.CASE_EXTENSION_FIELDSET);
            for(Case caseRec : currentCases){
            System.debug('Check here ---> '+caseRec.Id+ ' --> '+externalIdToStageConfigsMap.containsKey(caseRec.CCC_External_Id__c));
            if(externalIdToStageConfigsMap.containsKey(caseRec.CCC_External_Id__c)){
                for(ASF_Case_Stage_Config__c config: externalIdToStageConfigsMap.get(caseRec.CCC_External_Id__c)){
                    System.debug('Case Id - '+caseRec.Id+' '+config.StageName__c+ ' == '+ caseIdToStageNameMap.get(caseRec.Id));
                    if(config.StageName__c == caseIdToStageNameMap.get(caseRec.Id)){
                        caseIdToCurrentStageConfigMap.put(caseRec.Id, config);
                        if(config.Query_Fields__c != null){
                            allFields.addAll(config.Query_Fields__c.toLowerCase().split(','));
                        }
                        break;
                    }
                }
            }
        }

        Map<Id, List<ASF_Case_Rule__c>> stageConfigToCaseRuleMap = new Map<Id, List<ASF_Case_Rule__c>>();
        List<ASF_Case_Rule__c> allCaseRules = ASF_CaseQueryHandler.getCaseRuleWithHierarchy(externalIds);
        for(ASF_Case_Rule__c rule: allCaseRules){
            if(!stageConfigToCaseRuleMap.containsKey(rule.Case_Stage_Config__c)){
                stageConfigToCaseRuleMap.put(rule.Case_Stage_Config__c, new List<ASF_Case_Rule__c>());
            }
            stageConfigToCaseRuleMap.get(rule.Case_Stage_Config__c).add(rule);
        }

        System.debug('caseIds ---> '+caseIds);
        ASF_CaseQueryHandler.refreshRecords = true;
        List<Case> queriedCaseRecords = ASF_CaseQueryHandler.getCaseRecordWithQueryFields(allFields, caseIds);
        ASF_CaseQueryHandler.refreshRecords = false;
        Map<Id, List<ASF_Case_Rule__c>> caseRulesForStage = new Map<Id, List<ASF_Case_Rule__c>>();
        for(Case caseRec : currentCases){
            if(caseIdToCurrentStageConfigMap.containsKey(caseRec.Id) && stageConfigToCaseRuleMap.containsKey(caseIdToCurrentStageConfigMap.get(caseRec.Id).Id)){
                caseRulesForStage.put(caseRec.Id, stageConfigToCaseRuleMap.get(caseIdToCurrentStageConfigMap.get(caseRec.Id).Id));
            }
        }

        for(Case tempC: queriedCaseRecords){
            System.debug(' Queries Cases Id --> '+tempC.Id);
        }

        Map<Id, ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo> infos = ASF_CaseFrameworkHelper.runAssignmentRules(queriedCaseRecords, caseRulesForStage);
        for(Id caseId : infos.keySet()){
            ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo info = infos.get(caseId);
            ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo resultWrapper = resultWrapperMap.containsKey(caseId) ? resultWrapperMap.get(caseId) : new ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo();
            resultWrapper.defaultOwnerId = info.defaultOwnerId;
            resultWrapper.defaultErrorOwnerId = info.defaultErrorOwnerId;
            
            // VIRENDRA - 8 JUNE 2024 - ADDED defaultOwnerName to store on Case.
            resultWrapper.defaultOwnerName = info.defaultOwnerName;
            // VIRENDRA - 8 JUNE 2024 - ENDS HERE.

            System.debug('@@@@caseIdToCurrentStageConfigMap'+caseIdToCurrentStageConfigMap);
            System.debug('@@@@caseId'+caseId);
            ASF_Case_Stage_Config__c currentStageConfig = caseIdToCurrentStageConfigMap.containsKey(caseId) ? caseIdToCurrentStageConfigMap.get(caseId) : null;
            if(resultWrapper.defaultOwnerId == null){
                resultWrapper.defaultOwnerId = currentStageConfig != null ? currentStageConfig.Default_Queue__c : null;
                // VIRENDRA - 9 JUNE 2024 - ADDED DEFAULTOWNERNAME to store the QUEUE NAME ON CASE.
                resultWrapper.defaultOwnerName = currentStageConfig != null ? currentStageConfig.Default_Queue_user_Name__c : null;
            }
            if(resultWrapper.defaultErrorOwnerId == null){
                resultWrapper.defaultErrorOwnerId = currentStageConfig != null ? currentStageConfig.Default_Error_Queue__c : null;
            }
            resultWrapper.status = 'Success';
            resultWrapperMap.put(caseId, resultWrapper);
        }
        System.debug('****getAssignmentForStage>resultWrapperMap:'+resultWrapperMap);
        return resultWrapperMap;
    }
    
    /**
    * Finds the Next Automated Stage for Automated Forward Movement, but After a Backward Movement
    * This is not to be used when finding next stage in standard case
    * Returns the next Stage Name
    * Process - 
    * 1. Keep looping through next order. 
    * 2. If a Gateway Stage is Found, before the Previous Stage, Stop
    * 3. Else assign Previous Stage. 
    * 4. Find Ownership - For Previous Stage - By Previous Owner Or Assignment Rule if Inactive
    * 5. Find Ownership - For Gateway Stage - By Assigment Rule

    * Bulkified
    */
    public static Map<Id, StageConfigWrapper> findNextStageAfterBackward(List<Case> currentCases, Map<Id, String> currentStageMap){
        
        Map<Id, StageConfigWrapper> resultWrapperMap = new Map<Id, StageConfigWrapper>();
        
        Set<String> externalIds = new Set<String>();
        for(Case caseRec : currentCases){
            externalIds.add(caseRec.CCC_External_Id__c);
            StageConfigWrapper resultWrapper = new StageConfigWrapper();
            resultWrapper.status = 'Error';
            resultWrapperMap.put(caseRec.Id, resultWrapper);
        }

        Map<Id, ASF_Case_Stage_Config__c> caseIdToCurrentStageConfigMap = new Map<Id, ASF_Case_Stage_Config__c>();
        Map<String, List<ASF_Case_Stage_Config__c>> externalIdToStageConfigsMap = new Map<String, List<ASF_Case_Stage_Config__c>>();
        
        List<ASF_Case_Stage_Config__c> allStageConfigs = ASF_CaseQueryHandler.getCaseStageConfigWithRlAndIntr(externalIds);
        for(ASF_Case_Stage_Config__c config: allStageConfigs){
            if(!externalIdToStageConfigsMap.containsKey(config.Case_Category_Config__r.CCC_External_Id__c)){
                externalIdToStageConfigsMap.put(config.Case_Category_Config__r.CCC_External_Id__c, new List<ASF_Case_Stage_Config__c>());
            }
            externalIdToStageConfigsMap.get(config.Case_Category_Config__r.CCC_External_Id__c).add(config);
        }

        // Fetch all Case Rules and Run the Approrpriate One - For Approval matching the Case Stage Config
        List<ASF_Case_Rule__c> allCaseRules = ASF_CaseQueryHandler.getCaseRuleWithHierarchy(externalIds);
        Map<Id, List<ASF_Case_Rule__c>> stageIdToCaseRulesMap = new Map<Id, List<ASF_Case_Rule__c>>();
        for(ASF_Case_Rule__c rule : allCaseRules){
            if(!stageIdToCaseRulesMap.containsKey(rule.Case_Stage_Config__c)){
                stageIdToCaseRulesMap.put(rule.Case_Stage_Config__c, new List<ASF_Case_Rule__c>());
            }
            stageIdToCaseRulesMap.get(rule.Case_Stage_Config__c).add(rule);
        }

        for(Case caseRec : currentCases){
            if(externalIdToStageConfigsMap.containsKey(caseRec.CCC_External_Id__c)){
                for(ASF_Case_Stage_Config__c config: externalIdToStageConfigsMap.get(caseRec.CCC_External_Id__c)){
                    if(config.StageName__c == currentStageMap.get(caseRec.Id)){
                        caseIdToCurrentStageConfigMap.put(caseRec.Id, config);
                        break;
                    }
                }
            }
        }

        Map<Id, ASF_Case_Stage_Config__c> caseIdToNextStageConfigMap = new Map<Id, ASF_Case_Stage_Config__c>();
        Map<Id, String> caseIdToAssignmentStageMap = new Map<Id, String>();
        Map<Id, Boolean> caseIdToIsPreviousStageMap = new Map<Id,Boolean>();
        for(Case caseRec : currentCases){
            ASF_Case_Stage_Config__c currentStageConfig = caseIdToCurrentStageConfigMap.get(caseRec.Id);
            caseIdToIsPreviousStageMap.put(caseRec.Id, false);
            if(externalIdToStageConfigsMap.containsKey(caseRec.CCC_External_Id__c)){
                Boolean afterPreviousStage = false;
                for(ASF_Case_Stage_Config__c config: externalIdToStageConfigsMap.get(caseRec.CCC_External_Id__c)){
                    if(currentStageConfig != null && currentStageConfig.Order__c < config.Order__c){
                        //Added by Nikhil EY- PR970457-2176 (Not to go back to previous stage if user done backword movement of stage and again try to forward the stage)
                        boolean isStageSkip = config.Case_Category_Config__r.isStageSkip__c;
                        if(isStageSkip){
                            caseRec.Previous_Stage__c = config.StageName__c;
                        }
			// End
                        if(afterPreviousStage){
                            // If Not Optional, Allot to Next Stage and Break
                            if(config.Optional_Stage__c){
                                // Run Stage Movement Rules to check if this is the Next Stage
                                List<ASF_Case_Rule__c> caseRulesForStage = new List<ASF_Case_Rule__c>();
                                caseRulesForStage.addAll(stageIdToCaseRulesMap.get(config.Id));
                                
                                Boolean isStageMovementValid = ASF_CaseFrameworkHelper.runStageMovementRules(caseRec, caseRulesForStage);
                                System.debug('***isStageMovementValid'+isStageMovementValid);
                                if(isStageMovementValid){
                                    caseIdToNextStageConfigMap.put(caseRec.Id, config);
                                    System.debug('***nextStageConfig:'+config);
                                }
                                else{
                                    continue;
                                }
                            }
                            // If Manual, Continue ahead
                            else if(config.Manual_Stage__c){
                                continue;
                            }
                            else {
                                caseIdToNextStageConfigMap.put(caseRec.Id, config);
                            }
                        }
                        if(config.Gateway_Stage__c){
                            caseIdToNextStageConfigMap.put(caseRec.Id, config);
                        }
                        else if(config.StageName__c == caseRec.Previous_Stage__c) {
                            afterPreviousStage = true;
                            if(config.Optional_Stage__c){
                                // Run Stage Movement Rules to check if this is the Next Stage
                                List<ASF_Case_Rule__c> caseRulesForStage = new List<ASF_Case_Rule__c>();
                                caseRulesForStage.addAll(stageIdToCaseRulesMap.get(config.Id));
                                
                                Boolean isStageMovementValid = ASF_CaseFrameworkHelper.runStageMovementRules(caseRec, caseRulesForStage);
                                System.debug('***isStageMovementValid'+isStageMovementValid);
                                if(isStageMovementValid){
                                    caseIdToNextStageConfigMap.put(caseRec.Id, config);
                                    // Later used to determine the right owner
                                    caseIdToIsPreviousStageMap.put(caseRec.Id, true);
                                    System.debug('***nextStageConfig:'+config);
                                }
                                else{
                                    continue;
                                }
                            }else{
                                caseIdToNextStageConfigMap.put(caseRec.Id, config);
                                // Later used to determine the right owner
                                caseIdToIsPreviousStageMap.put(caseRec.Id, true);
                                System.debug('***nextStageConfig:'+config);
                            }
                        }

                        // If Previously Assigned Stage, Find Previously Assigned Owner
                        // If the Stage Config dictates to assign to an owner who 
                        // was the last actioned user of another stage, then find that
                        if(caseIdToIsPreviousStageMap.get(caseRec.Id) || config.Assign_To_Last_Actioned_Stage__c != null){
                            String stageName = config.StageName__c;
                            if(config.Assign_To_Last_Actioned_Stage__c != null){
                                stageName = config.Assign_To_Last_Actioned_Stage__c;
                            }
                            caseIdToAssignmentStageMap.put(caseRec.Id, stageName);
                        }
                        if(caseIdToNextStageConfigMap.containsKey(caseRec.Id)){
                            break;
                        }
                    }
                }
            }

        }
        Map<Id, ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo> assignmentInfoMap = new Map<Id, ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo>();
        if(!caseIdToAssignmentStageMap.isEmpty()){
            assignmentInfoMap = ASF_CaseFrameworkHelper.findAssignmentForPreviouslyVisitedStage(caseIdToAssignmentStageMap);
        }
        
        List<Case> casesForAssignment = new List<Case>();
        Map<Id, String> caseIdToStageNameMap = new Map<Id, String>();
        for(Case caseRec : currentCases){
            StageConfigWrapper resultWrapper = resultWrapperMap.get(caseRec.Id);
            if(caseIdToNextStageConfigMap.containsKey(caseRec.Id)){
                ASF_Case_Stage_Config__c nextStageConfig = caseIdToNextStageConfigMap.get(caseRec.Id);
                resultWrapper.stageConfig = nextStageConfig;
                resultWrapper.status = 'Success';

                ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo info = assignmentInfoMap.get(caseRec.Id);
                resultWrapper.isPreviousStage = caseIdToIsPreviousStageMap.get(caseRec.Id);
                resultWrapper.ownerId = info?.defaultOwnerId;
                // VIRENDRA - 11 June 2024 - TO STAMP THE CASE ASSIGNED TEAM
                resultWrapper.ownerName = info != null ? info.defaultOwnerName : '';
                // VIRENDRA - ENDS HERE.
                resultWrapper.errorOwnerId = info?.defaultErrorOwnerId;

                if(resultWrapper.ownerId == null){
                    casesForAssignment.add(caseRec);
                    caseIdToStageNameMap.put(caseRec.Id, nextStageConfig.StageName__c);
                    
                }
                resultWrapperMap.put(caseRec.Id, resultWrapper);
            }
        }
        if(!casesForAssignment.isEmpty()){
            Map<Id, ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo> infos = ASF_CaseMovementHelper.getAssignmentForStage(casesForAssignment, caseIdToStageNameMap);
            for(Id caseId : infos.keySet()){
                ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo info = infos.get(caseId);
                StageConfigWrapper resultWrapper = resultWrapperMap.get(caseId);
                resultWrapper.ownerId = info.defaultOwnerId;
                // VIRENDRA - 8 JUNE 2024 - TO STAMP CASE ASSIGN TEAM ON CASE MOVEMENT.
                resultWrapper.ownerName = info.defaultOwnerName != null ?info.defaultOwnerName : '';
                // VIRENDRA - 8 JUNE 2024 - ENDS HERE.
                resultWrapper.errorOwnerId = info.defaultErrorOwnerId;
                resultWrapper.isPreviousStage = caseIdToIsPreviousStageMap.get(caseId);
                resultWrapperMap.put(caseId, resultWrapper);
            }
        }
        
        return resultWrapperMap;
    }
    
    
    /**
    * Get Additional Peripheral Objects Data for Case Transition
    * Includes Checklists, Tasks, Approvals and Integrations
    * Bulkified
    */
    public static Map<Id, CaseAdditionalData> getCaseAdditionalDataForNextStage(List<Case> currentCases, Map<Id, String> caseIdToNextStageMap, List<Case> casesFromBackward){
        Map<Id, CaseAdditionalData> resultWrapperMap = new Map<Id, CaseAdditionalData>();

        Set<String> externalIds = new Set<String>();
        Set<Id> caseIds = new Set<Id>();
        List<Case> combinedCaseList = new List<Case>();
        combinedCaseList.addAll(currentCases);
        if(casesFromBackward != null && !casesFromBackward.isEmpty()){
            combinedCaseList.addAll(casesFromBackward);
        }
        
        for(Case caseRec : combinedCaseList){
            externalIds.add(caseRec.CCC_External_Id__c);
            caseIds.add(caseRec.Id);
            CaseAdditionalData resultWrapper = new CaseAdditionalData();
            resultWrapperMap.put(caseRec.Id, resultWrapper);
        }

        Map<String, List<ASF_Case_Stage_Config__c>> externalIdToStageConfigsMap = new Map<String, List<ASF_Case_Stage_Config__c>>();
        Map<Id, ASF_Case_Stage_Config__c> caseIdToNextStageConfigMap = new Map<Id, ASF_Case_Stage_Config__c>();
        // Fetch All Case Stage Configs from Query Handler, Find the Correct One for Next Stage
        List<ASF_Case_Stage_Config__c> allStageConfigs = ASF_CaseQueryHandler.getCaseStageConfigWithRlAndIntr(externalIds);
        for(ASF_Case_Stage_Config__c config: allStageConfigs){
            if(!externalIdToStageConfigsMap.containsKey(config.Case_Category_Config__r.CCC_External_Id__c)){
                externalIdToStageConfigsMap.put(config.Case_Category_Config__r.CCC_External_Id__c, new List<ASF_Case_Stage_Config__c>());
            }
            externalIdToStageConfigsMap.get(config.Case_Category_Config__r.CCC_External_Id__c).add(config);
        }

        for(Case caseRec : currentCases){
            if(externalIdToStageConfigsMap.containsKey(caseRec.CCC_External_Id__c)){
                system.debug('externalIdToStageConfigsMap.get(caseRec.CCC_External_Id__c)---->'+externalIdToStageConfigsMap.get(caseRec.CCC_External_Id__c));
                for(ASF_Case_Stage_Config__c config: externalIdToStageConfigsMap.get(caseRec.CCC_External_Id__c)){
                    system.debug('config---->'+config);
                    if(config.StageName__c == caseIdToNextStageMap.get(caseRec.Id)){
                        caseIdToNextStageConfigMap.put(caseRec.Id, config);
                        CaseAdditionalData resultWrapper = resultWrapperMap.get(caseRec.Id);
                        resultWrapper.manualApprovalStage = config.Manual_Approval__c;
                        resultWrapperMap.put(caseRec.Id, resultWrapper);
                        break;
                    }
                }
            }
        }

        for(Case caseRec : casesFromBackward){
            if(externalIdToStageConfigsMap.containsKey(caseRec.CCC_External_Id__c)){
                system.debug('externalIdToStageConfigsMap.get(caseRec.CCC_External_Id__c)---->'+externalIdToStageConfigsMap.get(caseRec.CCC_External_Id__c));
                for(ASF_Case_Stage_Config__c config: externalIdToStageConfigsMap.get(caseRec.CCC_External_Id__c)){
                    system.debug('config---->'+config);
                    if(config.StageName__c == caseIdToNextStageMap.get(caseRec.Id)){
                        caseIdToNextStageConfigMap.put(caseRec.Id, config);
                        CaseAdditionalData resultWrapper = resultWrapperMap.get(caseRec.Id);
                        resultWrapper.manualApprovalStage = config.Manual_Approval__c;
                        resultWrapperMap.put(caseRec.Id, resultWrapper);
                        break;
                    }
                }
            }
        }

        // Fetch all Case Rules and Run the Approrpriate One - For Approval matching the Case Stage Config
        List<ASF_Case_Rule__c> allCaseRules = ASF_CaseQueryHandler.getCaseRuleWithHierarchy(externalIds);
        Map<String, List<ASF_Case_Rule__c>> externalIdToCaseRulesMap = new Map<String, List<ASF_Case_Rule__c>>();
        Map<Id, List<ASF_Case_Rule__c>> caseIdToCaseRuleMap = new Map<Id, List<ASF_Case_Rule__c>>();
        for(ASF_Case_Rule__c rule : allCaseRules){
            if(!externalIdToCaseRulesMap.containsKey(rule.C3ExternalId__c+rule.Stage_Name__c)){
                externalIdToCaseRulesMap.put(rule.C3ExternalId__c+rule.Stage_Name__c, new List<ASF_Case_Rule__c>());
            }
            externalIdToCaseRulesMap.get(rule.C3ExternalId__c+rule.Stage_Name__c).add(rule);
        }

        for(Case caseRec : combinedCaseList){
            String nextStage = caseIdToNextStageMap.get(caseRec.Id);
            if(externalIdToCaseRulesMap.containsKey(caseRec.CCC_External_Id__c+nextStage)){
                if(!caseIdToCaseRuleMap.containsKey(caseRec.Id)){
                    caseIdToCaseRuleMap.put(caseRec.Id, new List<ASF_Case_Rule__c>());
                }
                caseIdToCaseRuleMap.get(caseRec.Id).addAll(externalIdToCaseRulesMap.get(caseRec.CCC_External_Id__c+nextStage));
            }
        }

        // Find All Query Fields for Case, Merge them togther, and perform one Query on Case
        Set<String> allFields = new Set<String>{'stage__c', 'businesshoursid', 'ccc_external_id__c', 'previous_stage__c', 'business_unit__c', 'lead__c','lob__c'};
        	allFields.addAll(ASF_Constants.CASE_EXTENSION_FIELDSET);
            for(ASF_Case_Stage_Config__c config: allStageConfigs){
            if(config.Query_Fields__c != null){
                allFields.addAll(config.Query_Fields__c.toLowerCase().split(','));
            }
        }
        ASF_CaseQueryHandler.refreshRecords = true;
        List<Case> queriedCaseRecords = ASF_CaseQueryHandler.getCaseRecordWithQueryFields(allFields, caseIds);
        ASF_CaseQueryHandler.refreshRecords = false;
        Map<Id,Case> queriesCasesMap = new Map<Id,Case>(queriedCaseRecords);
        List<Case> currentQueriedCaseList = new List<Case>();
        Map<Id,Case> currentCasesMap = new Map<Id,Case>(currentCases);
        
        for(Case caseRec : queriedCaseRecords){
            if(currentCasesMap.containsKey(caseRec.Id)){
                currentQueriedCaseList.add(caseRec);
            }
        }
        
        Map<Id, List<ASF_Case_Approv__c>> approvalsToInsert = ASF_CaseFrameworkHelper.addApprovals(currentQueriedCaseList, caseIdToCaseRuleMap);
        Map<Id, List<ASF_Checklist__c>> checklistToInsert = ASF_CaseFrameworkHelper.addChecklists(currentQueriedCaseList, caseIdToCaseRuleMap);
        Map<Id, List<Task>> tasksToInsert = ASF_CaseFrameworkHelper.addTasks(currentQueriedCaseList, caseIdToCaseRuleMap);
        Map<Id, Map<string,long>> slaCaseAndStageOverrideValues = ASF_CaseFrameworkHelper.addSLA(queriedCaseRecords, caseIdToCaseRuleMap);

        for(Case caseRec : currentCases){
            CaseAdditionalData resultWrapper = resultWrapperMap.get(caseRec.Id);
            resultWrapper.approvalsToInsert = approvalsToInsert.get(caseRec.Id);
            resultWrapper.checklistToInsert = checklistToInsert.get(caseRec.Id);
            resultWrapper.tasksToInsert = tasksToInsert.get(caseRec.Id);
            resultWrapper.slaCaseAndStageOverrideValues = slaCaseAndStageOverrideValues.get(caseRec.Id);
            resultWrapper.allIntegrations = caseIdToNextStageConfigMap.containsKey(caseRec.Id)?caseIdToNextStageConfigMap.get(caseRec.Id).ASF_Integrations__r:null;
            resultWrapper.status = 'Success';
            resultWrapperMap.put(caseRec.Id, resultWrapper);
        }
        if(casesFromBackward != null && !casesFromBackward.isEmpty()){
            for(Case caseRec : casesFromBackward){
                CaseAdditionalData resultWrapper = resultWrapperMap.get(caseRec.Id);
                resultWrapper.slaCaseAndStageOverrideValues = slaCaseAndStageOverrideValues.get(caseRec.Id);
                resultWrapper.allIntegrations = (caseIdToNextStageConfigMap.containsKey(caseRec.Id) && caseIdToNextStageConfigMap.get(caseRec.Id).Save_Data_On_Back__c) ? caseIdToNextStageConfigMap.get(caseRec.Id).ASF_Integrations__r:null;
                resultWrapper.status = 'Success';
                resultWrapperMap.put(caseRec.Id, resultWrapper);
        	}
        }
        return resultWrapperMap;
    }
    
    /**
    * This method is used to assign the case to right Queue, when moved from Pre-Framework to Framework.
    * In case of Cases getting converted from Pre-Framework to Framework from UI, don't change the owner.
    * 
    */
    public static Map<Id, ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo> preFrameworkToFrameworkMovementAssignment(List<Case> newList,boolean isUpdate, Map<Id, Case> oldMap, Map<Id,String> nextStageMap){
        List<Case> updFrameworkCases = new List<Case>();
                                                                    
        Map<Id, ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo> ownerInfo  = new Map<Id, ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo>();
        for(Case caseRec : newList){
            if(isUpdate){
                if(caseRec.CCC_External_Id__c != oldMap.get(caseRec.Id).CCC_External_Id__c 
                    && caseRec.CCC_External_Id__c != null){
                        // VIRENDRA - 19 Feb 2024 - ADDITIONAL CHECK TO FIND OUT CASES NOT CONVERTED FROM PREFRAMWORK TO FRAMEWORK.
                       //if(!(caseRec.Preframework_to_Framework_FromUI__c != oldMap.get(caseRec.Id).Preframework_to_Framework_FromUI__c && caseRec.Preframework_to_Framework_FromUI__c))
                       //{
                            updFrameworkCases.add(caseRec);
                       //}
                }
            }
        }
        if(isUpdate && updFrameworkCases.size()>0){
            // CHECK IF THE CASE IF UPDATED FROM PREFRAMEWORK TO FRAMEWORK.
            ownerInfo = ASF_CaseMovementHelper.getAssignmentForStage(updFrameworkCases, nextStageMap);
        }
        return ownerInfo;
        // for(Case caseRec : newList){
        //     ASF_Case_Category_Config__c appliedCCC;
        //     if(isUpdate){
        //         if(String.isNotBlank(caseRec.CCC_External_Id__c) 
        //         && cccExtIdToCCCMap.containsKey(caseRec.CCC_External_Id__c)){
        //             appliedCCC = cccExtIdToCCCMap.get(caseRec.CCC_External_Id__c);
        //         }
        //     }
        //     if(appliedCCC != null){ 
        //         //For Technical Source = Email, if CCC External Id is being populated which means case is converting 
        //         //from interaction to framework RT. So run assignment rule for first stage of framework
        //         //Update 1: This assignment rules should run for recategoriasation too.
        //         if(isUpdate && ownerInfo.containsKey(caseRec.Id)){
        //             caseRec.OwnerId = ownerInfo.get(caseRec.Id).defaultOwnerId != null ? ownerInfo.get(caseRec.Id).defaultOwnerId : 
        //             (ownerInfo.get(caseRec.Id).defaultErrorOwnerId != null ? ownerInfo.get(caseRec.Id).defaultErrorOwnerId : caseRec.OwnerId);
        //         }
        //     }
        // }
    }
    
    
    /**
    * Wrapper to be returned for Stage Movement methods
    * The calling method decides what to do with this data
    * as no DML is happening here
    * Provides modified Case record, Additional Data, and Stage Config
    */
    public class StageWrapper {
        
        public string status; 
        public string errorMessage;
        public Case caseToBeUpdated;
        public Id ownerId;
        public Id errorOwnerId;
        // Removing Case Additional Data from Overall Result Wrapper
        // Trigger to Call that directly as needed
        //public CaseAdditionalData data;
        public ASF_Case_Stage_Config__c nextStageConfig;
        // VIRENDRA - 8 JUNE 2024 - ADDED VARIABLE TO STORE THE OWNERNAME
        // THIS IS USED TO STAMP CASE ASSIGN TEAM ON CASE RECORD.
        public string ownerName;
        
    }
    
    /**
    * Wrapper for all Additional Case Data needed
    * by the caller for making any DML's
    */
    public class CaseAdditionalData {
        
        public List<ASF_Case_Approv__c> approvalsToInsert;
        public List<ASF_Checklist__c> checklistToInsert;
        public List<Task> tasksToInsert;
        public List<ASF_Integration__c> allIntegrations;
        public map<String,long> slaCaseAndStageOverrideValues;
        public boolean manualApprovalStage;
        public string status; 
        public string errorMessage;
    }
    
    /**
    * Returned from Find Next stage Methods
    * Provides info on the next stage config and owner
    */
    public class StageConfigWrapper {
        public ASF_Case_Stage_Config__c stageConfig;
        public Id ownerId;
        public Id errorOwnerId;
        public String status;
        public String errorMessage;
        public Boolean isPreviousStage;
        // VIRENDRA - 8 JUNE 2024 - ADDED ownerName;
        public String ownerName;
    }

    public class CaseStageValidationWrapper{
        public String status;
        public String errorMessage;
        public Case updatedCase;
        public Boolean isCaseUpdated;
    }

    

    

}