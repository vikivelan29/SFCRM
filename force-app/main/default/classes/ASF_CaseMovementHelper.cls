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
        Set<String> allFields = new Set<String>{'stage__c', 'businesshoursid', 'ccc_external_id__c', 'previous_stage__c'};
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
            Map<Id, StageConfigWrapper> caseIdToNextStageMap = ASF_CaseMovementHelper.findNextStageAfterBackward(casesAfterBackward.values());
            for(Id caseId : caseIdToNextStageMap.keySet()){
                StageConfigWrapper nextStage = caseIdToNextStageMap.get(caseId);
                StageWrapper resultWrapper = resultWrapperMap.get(caseId);
                if(nextStage.status != 'Error'){
                    resultWrapper.status = 'Success';
                    resultWrapper.nextStageConfig = nextStage.stageConfig;
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
                Map<Id, StageConfigWrapper> caseIdToNextStageConfig = ASF_CaseMovementHelper.findNextStageForward(casesMovingNextPure.values());
                for(Case caseRec : casesMovingNextPure.values()){
                    StageConfigWrapper nextStage = caseIdToNextStageConfig.get(caseRec.Id);
                    StageWrapper resultWrapper = resultWrapperMap.get(caseRec.Id);
                    if(nextStage.status == 'Success'){
                        resultWrapper.status = 'Success';
                        resultWrapper.nextStageConfig = nextStage.stageConfig;
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
        Set<String> allFields = new Set<String>{'stage__c', 'businesshoursid', 'ccc_external_id__c', 'previous_stage__c'};
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
            Map<Id, StageConfigWrapper> caseIdToNextStageMap = ASF_CaseMovementHelper.findNextStageAfterBackward(casesAfterBackward.values());
            for(Id caseId : caseIdToNextStageMap.keySet()){
                StageConfigWrapper nextStage = caseIdToNextStageMap.get(caseId);
                StageWrapper resultWrapper = resultWrapperMap.get(caseId);
                if(nextStage.status != 'Error'){
                    Case updatedCase = new Case(Id = caseId);
                    updatedCase.Stage__c = nextStage.stageConfig.StageName__c;
                    updatedCase.Status = nextStage.stageConfig.Status_Mapping__c;
                    updatedCase.MoveToNext__c = false;
                    resultWrapper.ownerId = nextStage.ownerId;
                    resultWrapper.errorOwnerId = nextStage.errorOwnerId;
                    
                    // If moved to Previous Stage, Remove Pending Clarification Flag
                    if(nextStage.isPreviousStage){
                        updatedCase.pending_clarification__c = false;
                    }
                    resultWrapper.caseToBeUpdated = updatedCase;
                    resultWrapper.status = 'Success';
                    resultWrapper.nextStageConfig = nextStage.stageConfig;
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
            //Atleast one case passed validation
            if(!casesMovingNextPure.isEmpty()){
                //Find the next stage
                Map<Id, StageConfigWrapper> caseIdToNextStageConfig = ASF_CaseMovementHelper.findNextStageForward(casesMovingNextPure.values());
                for(Case caseRec : casesMovingNextPure.values()){
                    StageConfigWrapper nextStage = caseIdToNextStageConfig.get(caseRec.Id);
                    StageWrapper resultWrapper = resultWrapperMap.get(caseRec.Id);
                    if(nextStage.status == 'Success'){
                        CaseStageValidationWrapper beforeResult = validateNextStageEntry(caseRec, nextStage.stageConfig);
                        if(beforeResult.status != 'Success'){
                            resultWrapper.errorMessage = beforeResult.errorMessage;
                            resultWrapper.status = 'Error';
                            resultWrapperMap.put(caseRec.Id, resultWrapper);
                        }else{
                            String nextStageName = nextStage.stageConfig.StageName__c;
                            //Update assignment, and other case fields
                            Case updatedCase = new Case(Id = caseRec.Id);
                            updatedCase.Stage__c = nextStageName;
                            updatedCase.Status = nextStage.stageConfig.Status_Mapping__c;
                            updatedCase.MoveToNext__c = false;
                            // If Validation Layer Returned any fields in Case, append the same
                            // This is returned from Custom Apex Class Run After the Stage Movement
                            if(validationResults.containsKey(caseRec.Id) && validationResults.get(caseRec.Id).isCaseUpdated == true){
                                Map<String, Object> sourceFields = validationResults.get(caseRec.Id).updatedCase.getPopulatedFieldsAsMap();
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
                            resultWrapper.status = 'Success';
                            resultWrapper.nextStageConfig = nextStage.stageConfig;
                            resultWrapper.ownerId = nextStage.ownerId;
                            resultWrapper.errorOwnerId = nextStage.errorOwnerId;
                            resultWrapperMap.put(caseRec.Id, resultWrapper);
                        }
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
            resultWrapperMap.put(caseRec.Id, resultWrapper);
            externalIds.add(caseRec.CCC_External_Id__c);
        }

        List<ASF_Case_Stage_Config__c> allStageConfigs = ASF_CaseQueryHandler.getCaseStageConfigWithRlAndIntr(externalIds);

        // Find All Query Fields for Case, Merge them togther, and perform one Query on Case
        Set<String> allFields = new Set<String>{'stage__c', 'businesshoursid', 'ccc_external_id__c'};
        for(ASF_Case_Stage_Config__c config: allStageConfigs){
            if(config.Query_Fields__c != null){
                allFields.addAll(config.Query_Fields__c.toLowerCase().split(','));
            }
        }

        List<Case> queriedCaseRecords = ASF_CaseQueryHandler.getCaseRecordWithQueryFields(allFields, currentCasesMap.keySet());
        Map<Id,Case> queriesCasesMap = new Map<Id,Case>(queriedCaseRecords);

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
                for(ASF_Case_Stage_Config__c config: externalIdToStageConfigsMap.get(caseRec.CCC_External_Id__c)){
                    if(config.StageName__c == requestedStageMap.get(caseRec.Id)){
                        caseIdToNextStageConfigMap.put(caseRec.Id, config);
                        break;
                    }
                }
            }


            // If movement to next Stage is valid
            for(Case caseRec : queriesCasesMap.values()){
                CaseStageValidationWrapper beforeResult = validateNextStageEntry(caseRec, caseIdToNextStageConfigMap.get(caseRec.Id));
                StageWrapper resultWrapper = resultWrapperMap.get(caseRec.Id);
                if(beforeResult.status != 'Success'){
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
                    resultWrapperMap.put(caseRec.Id, resultWrapper);

                    // Fetch Owner Assignment for Stage
                    if(nextStageConfig.Assign_To_Last_Actioned_Stage__c != null){
                        caseIdToLastActionedStageMap.put(caseRec.Id, nextStageConfig.Assign_To_Last_Actioned_Stage__c);
                    }
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
        Set<String> allFields = new Set<String>{'stage__c', 'businesshoursid', 'ccc_external_id__c'};
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
                caseRulesForStage.addAll(stageConfigIdToCaseRules.get(nextStageConfig.Id));

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
                        resultWrapper.errorOwnerId = info?.defaultErrorOwnerId;
                        resultWrapperMap.put(caseRec.Id, resultWrapper);
                        // If Owner Id not found, find by regular method
                        if(resultWrapper.ownerId == null){
                            casesWithoutAssignment.add(caseRec);
                        }
                    }
                }
            }
            if(!casesWithoutAssignment.isEmpty()){
                Map<Id, ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo> rulesAssignmentInfos = ASF_CaseMovementHelper.getAssignmentForStage(casesWithoutAssignment, requestedStageMap);
                for(Case caseRec : casesWithoutAssignment){
                    ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo info = rulesAssignmentInfos.get(caseRec.Id);
                    StageWrapper resultWrapper = resultWrapperMap.get(caseRec.Id);
                    resultWrapper.ownerId = info.defaultOwnerId;
                    resultWrapper.errorOwnerId = info.defaultErrorOwnerId;
                    resultWrapperMap.put(caseRec.Id, resultWrapper);
                }
            }

            for(Case caseRec : queriesCasesMap.values()){
                StageWrapper resultWrapper = resultWrapperMap.get(caseRec.Id);
                Case updatedCase = new Case(Id = caseRec.Id);
                updatedCase.Stage__c = requestedStageMap.get(caseRec.Id);
                updatedCase.Status = caseIdToNextStageConfigMap.get(caseRec.Id).Status_Mapping__c;
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
            for(ASF_Case_Stage_Config__c config: externalIdToStageConfigsMap.get(caseRec.CCC_External_Id__c)){
                if(config.StageName__c == currentStageMap.get(caseRec.Id)){
                    caseIdToCurrentStageConfigMap.put(caseRec.Id, config);
                    break;
                }
            }
        }

        Map<Id, Boolean> areChecklistsCompletePerCase = ASF_CaseFrameworkValidator.validateChecklists(currentCases, currentStageMap);
        Map<Id, Boolean> areTasksCompletePerCase = ASF_CaseFrameworkValidator.validateTasks(currentCases, currentStageMap);
        Map<Id, Boolean> areApprovalsCompletedPerCase = ASF_CaseFrameworkValidator.validateApprovals(currentCases, currentStageMap);
        Map<Id, String> areValidationsOkPerCase = ASF_CaseFrameworkValidator.validateValidations(currentCases, caseIdToCurrentStageConfigMap);
        Map<Id, String> areIntegrationsCompletePerCase = ASF_CaseFrameworkValidator.validateIntegrations(currentCases, caseIdToCurrentStageConfigMap);
        
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
                ASF_Case_Stage_Config__c currentStageConfig = caseIdToCurrentStageConfigMap.get(caseRec.Id);
                if(currentStageConfig != null && currentStageConfig.AfterStageApexClass__c != null){
                    Type customType = Type.forName(currentStageConfig.AfterStageApexClass__c);
                    ASF_CaseStageClassInvocable instance = (ASF_CaseStageClassInvocable)customType.newInstance();
                    resultWrapper = instance.afterStageMovement(caseRec);            
                    system.debug(resultWrapper);
                }
            }
            resultWrapperMap.put(caseRec.Id, resultWrapper);
        }
        return resultWrapperMap;
    }

    /**
     * Validate if the movemnet to the Next Stage is Valid or not
     */
    public static CaseStageValidationWrapper validateNextStageEntry(Case currentCase, ASF_Case_Stage_Config__c nextStageConfig){
    
        // Run Before Apex Class
        CaseStageValidationWrapper beforeResult = new CaseStageValidationWrapper();
        beforeResult.status = 'Success';
        if(nextStageConfig != null && nextStageConfig.BeforeStageApexClass__c != null){
            Type customType = Type.forName(nextStageConfig.BeforeStageApexClass__c);
            ASF_CaseStageClassInvocable instance = (ASF_CaseStageClassInvocable)customType.newInstance();
            beforeResult = instance.beforeStageMovement(currentCase);  
        }

        return beforeResult;
    
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
    public static Map<Id, StageConfigWrapper> findNextStageForward(List<Case> currentCases){
        Map<Id, StageConfigWrapper> resultWrapperMap = new Map<Id, StageConfigWrapper>();

        Set<String> externalIds = new Set<String>();
        Set<Id> caseIds = new Set<Id>();
        for(Case caseRec : currentCases){
            StageConfigWrapper resultWrapper = new StageConfigWrapper();
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
            for(ASF_Case_Stage_Config__c config: externalIdToStageConfigsMap.get(caseRec.CCC_External_Id__c)){
                if(config.StageName__c == caseRec.Stage__c){
                    caseIdToCurrentStageConfigMap.put(caseRec.Id, config);
                    break;
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
        Set<String> allFields = new Set<String>{'stage__c', 'businesshoursid'};
        for(ASF_Case_Stage_Config__c config: allStageConfigs){
            if(config.Query_Fields__c != null){
                allFields.addAll(config.Query_Fields__c.toLowerCase().split(','));
            }
        }

        List<Case> queriedCaseRecords = ASF_CaseQueryHandler.getCaseRecordWithQueryFields(allFields, caseIds);
        Map<Id,Case> queriesCasesMap = new Map<Id,Case>(queriedCaseRecords);
        Map<Id, ASF_Case_Stage_Config__c> caseIdToNextStageConfigMap = new Map<Id, ASF_Case_Stage_Config__c>();
        for(Case caseRec : currentCases){
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

        // Once Next Stage is found, run Assignment Rules to get the Owner Information
        Map<Id, String> caseIdToLastActionedStageMap = new Map<Id,String>();
        for(Case caseRec : currentCases){
            ASF_Case_Stage_Config__c nextStageConfig = caseIdToNextStageConfigMap.get(caseRec.Id);
            if(nextStageConfig != null){
                if(nextStageConfig.Assign_To_Last_Actioned_Stage__c != null){
                    caseIdToLastActionedStageMap.put(caseRec.Id, nextStageConfig.Assign_To_Last_Actioned_Stage__c);
                }
            }else{
                //next stage not found, throw error
                StageConfigWrapper resultWrapper = resultWrapperMap.get(caseRec.Id);
                resultWrapper.status = 'Error';
                resultWrapper.errorMessage = 'No applicable next stage found';
                resultWrapperMap.put(caseRec.Id, resultWrapper);
            }
        }

        List<Case> casesWithoutAssignment = new List<Case>();
        Map<Id, String> caseIdToStageMap = new Map<Id,String>();
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
        
        List<ASF_Case_Stage_Config__c> allStageConfigs = ASF_CaseQueryHandler.getCaseStageConfigWithRlAndIntr(externalIds);
        for(ASF_Case_Stage_Config__c config: allStageConfigs){
            if(!externalIdToStageConfigsMap.containsKey(config.Case_Category_Config__r.CCC_External_Id__c)){
                externalIdToStageConfigsMap.put(config.Case_Category_Config__r.CCC_External_Id__c, new List<ASF_Case_Stage_Config__c>());
            }
            externalIdToStageConfigsMap.get(config.Case_Category_Config__r.CCC_External_Id__c).add(config);
        }

        Set<String> allFields = new Set<String>{'stage__c', 'businesshoursid'};
        for(Case caseRec : currentCases){
            for(ASF_Case_Stage_Config__c config: externalIdToStageConfigsMap.get(caseRec.CCC_External_Id__c)){
                if(config.StageName__c == caseIdToStageNameMap.get(caseRec.Id)){
                    caseIdToCurrentStageConfigMap.put(caseRec.Id, config);
                    if(config.Query_Fields__c != null){
                        allFields.addAll(config.Query_Fields__c.toLowerCase().split(','));
                    }
                    break;
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

        List<Case> queriedCaseRecords = ASF_CaseQueryHandler.getCaseRecordWithQueryFields(allFields, caseIds);
        Map<Id, List<ASF_Case_Rule__c>> caseRulesForStage = new Map<Id, List<ASF_Case_Rule__c>>();
        for(Case caseRec : currentCases){
            if(stageConfigToCaseRuleMap.containsKey(caseIdToCurrentStageConfigMap.get(caseRec.Id).Id)){
                caseRulesForStage.put(caseRec.Id, stageConfigToCaseRuleMap.get(caseIdToCurrentStageConfigMap.get(caseRec.Id).Id));
            }
        }

        Map<Id, ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo> infos = ASF_CaseFrameworkHelper.runAssignmentRules(queriedCaseRecords, caseRulesForStage);
        for(Id caseId : infos.keySet()){
            ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo info = infos.get(caseId);
            ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo resultWrapper = resultWrapperMap.get(caseId);
            resultWrapper.defaultOwnerId = info.defaultOwnerId;
            resultWrapper.defaultErrorOwnerId = info.defaultErrorOwnerId;

            ASF_Case_Stage_Config__c currentStageConfig = caseIdToCurrentStageConfigMap.get(caseId);
            if(resultWrapper.defaultOwnerId == null){
                resultWrapper.defaultOwnerId = currentStageConfig.Default_Queue__c;
            }
            if(resultWrapper.defaultErrorOwnerId == null){
                resultWrapper.defaultErrorOwnerId = currentStageConfig.Default_Error_Queue__c;
            }
            resultWrapper.status = 'Success';
            resultWrapperMap.put(caseId, resultWrapper);
        }
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
    public static Map<Id, StageConfigWrapper> findNextStageAfterBackward(List<Case> currentCases){
        
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

        for(Case caseRec : currentCases){
            for(ASF_Case_Stage_Config__c config: externalIdToStageConfigsMap.get(caseRec.CCC_External_Id__c)){
                if(config.StageName__c == caseRec.Stage__c){
                    caseIdToCurrentStageConfigMap.put(caseRec.Id, config);
                    break;
                }
            }
        }

        Map<Id, ASF_Case_Stage_Config__c> caseIdToNextStageConfigMap = new Map<Id, ASF_Case_Stage_Config__c>();
        Map<Id, String> caseIdToAssignmentStageMap = new Map<Id, String>();
        Map<Id, Boolean> caseIdToIsPreviousStageMap = new Map<Id,Boolean>();
        for(Case caseRec : currentCases){
            ASF_Case_Stage_Config__c currentStageConfig = caseIdToCurrentStageConfigMap.get(caseRec.Id);
            caseIdToIsPreviousStageMap.put(caseRec.Id, false);
            for(ASF_Case_Stage_Config__c config: externalIdToStageConfigsMap.get(caseRec.CCC_External_Id__c)){
                if(currentStageConfig != null && currentStageConfig.Order__c < config.Order__c){
                
                    if(config.Gateway_Stage__c){
                        caseIdToNextStageConfigMap.put(caseRec.Id, config);
                        
                    }
                    else if(config.StageName__c == caseRec.Previous_Stage__c) {
                        caseIdToNextStageConfigMap.put(caseRec.Id, config);
                        // Later used to determine the right owner
                        caseIdToIsPreviousStageMap.put(caseRec.Id, true);
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
                resultWrapper.errorOwnerId = info?.defaultErrorOwnerId;

                if(resultWrapper.ownerId == null){
                    casesForAssignment.add(caseRec);
                    caseIdToStageNameMap.put(caseRec.Id, nextStageConfig.StageName__c);
                    
                }
                resultWrapperMap.put(caseRec.Id, resultWrapper);
            }
        }

        Map<Id, ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo> infos = ASF_CaseMovementHelper.getAssignmentForStage(casesForAssignment, caseIdToStageNameMap);
        for(Id caseId : infos.keySet()){
            ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo info = infos.get(caseId);
            StageConfigWrapper resultWrapper = resultWrapperMap.get(caseId);
            resultWrapper.ownerId = info.defaultOwnerId;
            resultWrapper.errorOwnerId = info.defaultErrorOwnerId;
            resultWrapper.isPreviousStage = false;
            resultWrapperMap.put(caseId, resultWrapper);
        }
        
        return resultWrapperMap;
    }
    
    
    /**
    * Get Additional Peripheral Objects Data for Case Transition
    * Includes Checklists, Tasks, Approvals and Integrations
    * Bulkified
    */
    public static Map<Id, CaseAdditionalData> getCaseAdditionalDataForNextStage(List<Case> currentCases, Map<Id, String> caseIdToNextStageMap){
        Map<Id, CaseAdditionalData> resultWrapperMap = new Map<Id, CaseAdditionalData>();

        Set<String> externalIds = new Set<String>();
        Set<Id> caseIds = new Set<Id>();
        for(Case caseRec : currentCases){
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
            for(ASF_Case_Stage_Config__c config: externalIdToStageConfigsMap.get(caseRec.CCC_External_Id__c)){
                if(config.StageName__c == caseIdToNextStageMap.get(caseRec.Id)){
                    caseIdToNextStageConfigMap.put(caseRec.Id, config);
                    CaseAdditionalData resultWrapper = resultWrapperMap.get(caseRec.Id);
                    resultWrapper.manualApprovalStage = config.Manual_Approval__c;
                    resultWrapperMap.put(caseRec.Id, resultWrapper);
                    break;
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

        for(Case caseRec : currentCases){
            String nextStage = caseIdToNextStageMap.get(caseRec.Id);
            if(externalIdToCaseRulesMap.containsKey(caseRec.CCC_External_Id__c+nextStage)){
                if(!caseIdToCaseRuleMap.containsKey(caseRec.Id)){
                    caseIdToCaseRuleMap.put(caseRec.Id, new List<ASF_Case_Rule__c>());
                }
                caseIdToCaseRuleMap.get(caseRec.Id).addAll(externalIdToCaseRulesMap.get(caseRec.CCC_External_Id__c+nextStage));
            }
        }

        // Find All Query Fields for Case, Merge them togther, and perform one Query on Case
        Set<String> allFields = new Set<String>{'stage__c', 'businesshoursid'};
        for(ASF_Case_Stage_Config__c config: allStageConfigs){
            if(config.Query_Fields__c != null){
                allFields.addAll(config.Query_Fields__c.toLowerCase().split(','));
            }
        }

        List<Case> queriedCaseRecords = ASF_CaseQueryHandler.getCaseRecordWithQueryFields(allFields, caseIds);
        Map<Id,Case> queriesCasesMap = new Map<Id,Case>(queriedCaseRecords);
        
        Map<Id, List<ASF_Case_Approv__c>> approvalsToInsert = ASF_CaseFrameworkHelper.addApprovals(queriedCaseRecords, caseIdToCaseRuleMap);
        Map<Id, List<ASF_Checklist__c>> checklistToInsert = ASF_CaseFrameworkHelper.addChecklists(queriedCaseRecords, caseIdToCaseRuleMap);
        Map<Id, List<Task>> tasksToInsert = ASF_CaseFrameworkHelper.addTasks(queriedCaseRecords, caseIdToCaseRuleMap);
        Map<Id, Map<string,long>> slaCaseAndStageOverrideValues = ASF_CaseFrameworkHelper.addSLA(queriedCaseRecords, caseIdToCaseRuleMap);

        for(Case caseRec : currentCases){
            CaseAdditionalData resultWrapper = resultWrapperMap.get(caseRec.Id);
            resultWrapper.approvalsToInsert = approvalsToInsert.get(caseRec.Id);
            resultWrapper.checklistToInsert = checklistToInsert.get(caseRec.Id);
            resultWrapper.tasksToInsert = tasksToInsert.get(caseRec.Id);
            resultWrapper.slaCaseAndStageOverrideValues = slaCaseAndStageOverrideValues.get(caseRec.Id);
            resultWrapper.allIntegrations = caseIdToNextStageConfigMap.get(caseRec.Id).ASF_Integrations__r;
            resultWrapper.status = 'Success';
            resultWrapperMap.put(caseRec.Id, resultWrapper);
        }
        return resultWrapperMap;
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
    }

    public class CaseStageValidationWrapper{
        public String status;
        public String errorMessage;
        public Case updatedCase;
        public Boolean isCaseUpdated;
    }

    

    

}