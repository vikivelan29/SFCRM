public class ASF_CaseMovementHelper {
    
    //static Boolean boolCalledFromBulk = false;
    // static Map<string, List<ASF_Case_Rule__c>> stageAssignmentRulesMap = new Map<string, List<ASF_Case_Rule__c>>();
    // static List<ASF_Case_Approv__c> approvalToInsert = new List<ASF_Case_Approv__c>();
    // static List<ASF_Checklist__c> checklistToInsert = new List<ASF_Checklist__c>();
    // static List<Task> tasksToInsert = new List<Task>();
    // static Case tempCase = new case();
    
    /**
    * This method is called when moved to Next Automated Stage for Automated Forward Movement - Standard Case
    * and used when moved to next stage after back movement
    * Returns StageWrapper - Contains Case Data to be updated, and other Objects to be inserted as well
    */
    @AuraEnabled
    public static StageWrapper moveToNextStage(string recordId){
        
        StageWrapper resultWrapper = new StageWrapper();
        resultWrapper.status = 'Error';
        resultWrapper.errorMessage = 'Unknown Error';
        
        //CaseAdditionalData dataWrapper = new CaseAdditionalData(); //To be populated based on UI req
        
        // Query Case from Query Handler
        List<Case> currentCases = ASF_CaseQueryHandler.getCases(new Set<Id>{recordId}); 
        Case currentCaseRec = new Case();
        
        if(!currentCases.isEmpty()){
            currentCaseRec = currentCases[0];
        }else{
            resultWrapper.errorMessage = 'Incorrect Case Id Passed';
            return resultWrapper;
        }
        
        //check if it is bulk load
        // TODO Bulk Handling ?
        // if(String.isNotBlank(recordId) && recordId.containsIgnoreCase('Bulk:')){
        //     boolCalledFromBulk = true;
        //     recordId = recordId.substringAfter('Bulk:'); 
        // }
        
        //Find the next stage when moved forward after backward movement
        if (currentCaseRec.pending_clarification__c == true) {
            StageConfigWrapper nextStage = ASF_CaseMovementHelper.findNextStageAfterBackward(currentCaseRec);
            
            if(nextStage.status != 'Error'){
                Case updatedCase = new Case(Id = currentCaseRec.Id);
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
                //resultWrapper.data = dataWrapper;
            }
            else{
                resultWrapper.errorMessage = nextStage.errorMessage;
                resultWrapper.status = 'Error';
            }
            
            //Find the next stage when moved purely forward
        }
        else {
            //Run validation on current Stage
            System.debug('Current Stage' + currentCaseRec.Stage__c);
            CaseStageValidationWrapper validationResult = ASF_CaseMovementHelper.validateCurrentStageExit(currentCaseRec);
            if(validationResult.status != 'Success'){
                resultWrapper.errorMessage = validationResult.errorMessage;
                resultWrapper.status = 'Error';
            }
            else{
                //Find the next stage
                StageConfigWrapper nextStage = ASF_CaseMovementHelper.findNextStageForward(currentCaseRec);
                System.debug('***nextStage:'+nextStage);
                //Create Approvals, checklists, tasks and run Integrations
                if(nextStage.status != 'Error'){
                    
                    System.debug(nextStage);
                    CaseStageValidationWrapper beforeResult = validateNextStageEntry(currentCaseRec, nextStage.stageConfig);
                    if(beforeResult.status != 'Success'){
                        resultWrapper.errorMessage = beforeResult.errorMessage;
                        resultWrapper.status = 'Error';
                        return resultWrapper;
                    }
                    
                    String nextStageName = nextStage.stageConfig.StageName__c;
                    //dataWrapper = getCaseAdditionalDataForNextStage(currentCaseRec, nextStageName);
                    //Update assignment, and other case fields
                    Case updatedCase = new Case(Id = currentCaseRec.Id);
                    updatedCase.Stage__c = nextStageName;
                    updatedCase.Status = nextStage.stageConfig.Status_Mapping__c;
                    updatedCase.MoveToNext__c = false;

                    resultWrapper.ownerId = nextStage.ownerId;
                    resultWrapper.errorOwnerId = nextStage.errorOwnerId;
                    
                    // If Validation Layer Returned any fields in Case, append the same
                    // This is returned from Custom Apex Class Run After the Stage Movement
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
                    resultWrapper.status = 'Success';
                    resultWrapper.nextStageConfig = nextStage.stageConfig;
                    //resultWrapper.data = dataWrapper;
                    //currentCaseRec.Status = tempCase.Status;
                    //currentCaseRec.is_Manual_Approval__c = tempCase.is_Manual_Approval__c;
                    
                }
                else{
                    resultWrapper.errorMessage = nextStage.errorMessage;
                    resultWrapper.status = 'Error';
                } 
            }
        }
        system.debug('EEEEEEEEE');
        system.debug(resultWrapper);
        return resultWrapper;
    }
    
    
    /**
    * This method runs when the user moves to next stage manually
    * This is not to be used when moving to next stage after back movement
    * Returns StageWrapper
    */
    
    @AuraEnabled
    public static StageWrapper moveToForwardStage(string recordId, string requestedStage){
        StageWrapper resultWrapper = new StageWrapper();
        //CaseAdditionalData dataWrapper = new CaseAdditionalData(); //To be populated based on UI req
        

        List<Case> currentCases = ASF_CaseQueryHandler.getCases(new Set<Id>{recordId}); 
        Case currentCaseRec = new Case();
        
        if(!currentCases.isEmpty()){
            currentCaseRec = currentCases[0];
        }
        else{
            resultWrapper.errorMessage = 'Incorrect Case Id Passed';
            return resultWrapper;
        }
        
        //Run validation on current Stage
        CaseStageValidationWrapper validationResult = ASF_CaseMovementHelper.validateCurrentStageExit(currentCaseRec);
        if(validationResult.status != 'Success'){
            resultWrapper.errorMessage = validationResult.errorMessage;
            resultWrapper.status = 'Error';
            return resultWrapper;
        }

        // Determine Next STage Config        
        ASF_Case_Stage_Config__c nextStageConfig;
        List<ASF_Case_Stage_Config__c> allStageConfigs = ASF_CaseQueryHandler.getCaseStageConfigWithRlAndIntr(new Set<String>{currentCaseRec.CCC_External_Id__c});
        for(ASF_Case_Stage_Config__c config: allStageConfigs){
            if(config.StageName__c == requestedStage){
                nextStageConfig = config;
            }
        }

        // If movement TO next Stage is valid
        CaseStageValidationWrapper beforeResult = validateNextStageEntry(currentCaseRec, nextStageConfig);
        
        if(beforeResult.status != 'Success'){
            resultWrapper.errorMessage = beforeResult.errorMessage;
            resultWrapper.status = 'Error';
            return resultWrapper;
        }

        //dataWrapper = getCaseAdditionalDataForNextStage(currentCaseRec, requestedStage);
        

        //Update assignment, and other case fields
        Case updatedCase = new Case(Id = currentCaseRec.Id);
        updatedCase.Stage__c = requestedStage;
        updatedCase.Status = nextStageConfig!=null?nextStageConfig.Status_Mapping__c:null;
        updatedCase.Is_Manual_Stage_Visited__c = true;

        // If Validation Layer Returned any fields in Case, append the same
        // This is returned from Custom Apex Class Run After the Stage Movement
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

        // Fetch Owner Assignment for Stage
        if(nextStageConfig != null){

            if(nextStageConfig.Assign_To_Last_Actioned_Stage__c != null){
                ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo info = ASF_CaseFrameworkHelper.findAssignmentForPreviouslyVisitedStage(currentCaseRec, nextStageConfig.Assign_To_Last_Actioned_Stage__c);
                
                //resultWrapper.isPreviousStage = true;
                resultWrapper.ownerId = info.defaultOwnerId;
                resultWrapper.errorOwnerId = info.defaultErrorOwnerId;
            }
            if(resultWrapper.ownerId == null){
                ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo info = ASF_CaseMovementHelper.getAssignmentForStage(currentCaseRec, nextStageConfig.StageName__c);
                resultWrapper.ownerId = info.defaultOwnerId;
                resultWrapper.errorOwnerId = info.defaultErrorOwnerId;
            }
        }

        resultWrapper.caseToBeUpdated = updatedCase;
        resultWrapper.nextStageConfig = nextStageConfig;
        //resultWrapper.data = dataWrapper;
        resultWrapper.status = 'Success';
        return resultWrapper;
    }
    
    /**
    * This method runs when the user moves to Back stage manually
    * Returns StageWrapper
    */
    
    @AuraEnabled
    public static StageWrapper moveToBackwardStage(string recordId, string requestedStage){
        StageWrapper resultWrapper = new StageWrapper();
        //CaseAdditionalData dataWrapper = new CaseAdditionalData(); //To be populated based on UI req
        

        List<Case> currentCases = ASF_CaseQueryHandler.getCases(new Set<Id>{recordId}); 
        Case currentCaseRec = new Case();
        
        if(!currentCases.isEmpty()){
            currentCaseRec = currentCases[0];
        }else{
            resultWrapper.errorMessage = 'Incorrect Case Id Passed';
            return resultWrapper;
        }

        ASF_Case_Stage_Config__c nextStageConfig;
        List<ASF_Case_Stage_Config__c> allStageConfigs = ASF_CaseQueryHandler.getCaseStageConfigWithRlAndIntr(new Set<String>{currentCaseRec.CCC_External_Id__c});
        for(ASF_Case_Stage_Config__c config: allStageConfigs){
            if(config.StageName__c == requestedStage){
                nextStageConfig = config;
            }
        }

        resultWrapper.nextStageConfig = nextStageConfig;

        ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo assignmentInfo = ASF_CaseFrameworkHelper.findAssignmentForPreviouslyVisitedStage(currentCaseRec, requestedStage);
        resultWrapper.ownerId = assignmentInfo.defaultOwnerId;
        resultWrapper.errorOwnerId = assignmentInfo.defaultErrorOwnerId;
        
        // If Owner Id not found, find by regular method
        if(resultWrapper.ownerId == null){
            ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo rulesAssignmentInfo = ASF_CaseMovementHelper.getAssignmentForStage(currentCaseRec, requestedStage);
            resultWrapper.ownerId = rulesAssignmentInfo.defaultOwnerId;
            resultWrapper.errorOwnerId = rulesAssignmentInfo.defaultErrorOwnerId;
        }
        
        Case updatedCase = new Case(Id = currentCaseRec.Id);
        updatedCase.Stage__c = requestedStage;
        updatedCase.Status = nextStageConfig.Status_Mapping__c;
        //currentCaseRec.pending_clarification__c = true;
        // currentCaseRec.FTR__c = false; //need clarity on this field usage
        resultWrapper.caseToBeUpdated = updatedCase;
        resultWrapper.status = 'Success';
        //resultWrapper.data = dataWrapper;
        
        return resultWrapper;
    }
    
    /**
     * Validate if the movemnet out of this current stage is valid or not
     * Accordinlgy only next stage movement will happen
     */
    public static CaseStageValidationWrapper validateCurrentStageExit(Case currentCase){
        
        CaseStageValidationWrapper result = new CaseStageValidationWrapper();
        ASF_Case_Stage_Config__c currentStageConfig;
        List<ASF_Case_Stage_Config__c> allStageConfigs = ASF_CaseQueryHandler.getCaseStageConfigWithRlAndIntr(new Set<String>{currentCase.CCC_External_Id__c});
        for(ASF_Case_Stage_Config__c config: allStageConfigs){
            if(config.StageName__c == currentCase.Stage__c){
                currentStageConfig = config;
            }
        }
        
        result.status = 'Success';
        // Validate Checklists
        Boolean areChecklistsComplete = ASF_CaseFrameworkValidator.validateChecklists(currentCase);
        if(!areChecklistsComplete){
            result.status  = 'Error';
            result.errorMessage = System.Label.Incomplete_Checklist_Error_Message;
        }
        
        // Validate Tasks
        Boolean areTasksComplete = ASF_CaseFrameworkValidator.validateTasks(currentCase);
        if(!areTasksComplete){
            result.status  = 'Error';
            result.errorMessage = System.Label.Incomplete_Tasks_Error_Message;
        }

        // Validate Approvals
        Boolean areApprovalsCompleted = ASF_CaseFrameworkValidator.validateApprovals(currentCase);
        if(!areTasksComplete){
            result.status  = 'Error';
            // TODO - Create Labels
            result.errorMessage = 'Approvals are Pending';
        }

        // Validate Validations
        if(currentStageConfig != null){
            String areValidationsOk = ASF_CaseFrameworkValidator.validateValidations(currentCase, currentStageConfig);
            System.debug('***are'+areValidationsOk);
            if(areValidationsOk != 'Success'){
                result.status  = 'Error';
                result.errorMessage = areValidationsOk;
            }
        }
        
        // Validate Integrations
        if(currentStageConfig != null){
            String areIntegrationsComplete = ASF_CaseFrameworkValidator.validateIntegrations(currentCase, currentStageConfig);
            if(areIntegrationsComplete != 'Success'){
                result.status  = 'Error';
                result.errorMessage = areIntegrationsComplete;
            }
        }

        // Run After Stage Apex Class, if present
        System.debug('CURRENT STAGE CONFIG' + ' ' + currentStageConfig);
        if(currentStageConfig != null && currentStageConfig.AfterStageApexClass__c != null){
            Type customType = Type.forName(currentStageConfig.AfterStageApexClass__c);
            ASF_CaseStageClassInvocable instance = (ASF_CaseStageClassInvocable)customType.newInstance();
            result = instance.afterStageMovement(currentCase);            
            system.debug(result);
        }
       
        return result;
        
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
    */
    public static StageConfigWrapper findNextStageForward(Case currentCase){
        
        StageConfigWrapper resultWrapper = new StageConfigWrapper();
        resultWrapper.status = 'Error';
        
        ASF_Case_Stage_Config__c currentStageConfig;
        List<ASF_Case_Stage_Config__c> allStageConfigs = ASF_CaseQueryHandler.getCaseStageConfigWithRlAndIntr(new Set<String>{currentCase.CCC_External_Id__c});
        for(ASF_Case_Stage_Config__c config: allStageConfigs){
            if(config.StageName__c == currentCase.Stage__c){
                currentStageConfig = config;
                break;
            }
        }
        
        // Fetch all Case Rules and Run the Approrpriate One - For Approval matching the Case Stage Config
        List<ASF_Case_Rule__c> allCaseRules = ASF_CaseQueryHandler.getCaseRuleWithHierarchy(new Set<String>{currentCase.CCC_External_Id__c});
        
        
        // Find All Query Fields for Case, Merge them togther, and perform one Query on Case
        Set<String> allFields = new Set<String>{'stage__c', 'businesshoursid'};
        for(ASF_Case_Stage_Config__c config: allStageConfigs){
            if(config.Query_Fields__c != null){
                allFields.addAll(config.Query_Fields__c.toLowerCase().split(','));
            }
        }
        
        if(allFields.size() == 0){
            resultWrapper.errorMessage = 'Query Fields not Found on Stage Config';
            return resultWrapper;
        }
        
        Case queriedCaseRecord = ASF_CaseQueryHandler.getCaseRecordWithQueryFields(allFields, currentCase.Id);
        /*
        Case queriedCaseRecord = (Case) Database.query(
            'SELECT ' +
            String.join(allFields, ',') +
            ' FROM Case Where Id=\'' +
            currentCase.Id +
            '\''
        );
        */
        ASF_Case_Stage_Config__c nextStageConfig;
        for(ASF_Case_Stage_Config__c config: allStageConfigs){
            if(currentStageConfig != null && currentStageConfig.Order__c < config.Order__c){
                System.debug('***1'+currentStageConfig);
                System.debug('***2'+config);
                // See if Applicable. 
                // If Not Optional, Allot to Next Stage and Break
                if(config.Optional_Stage__c){
                    
                    // Run Stage Movement Rules to check if this is the Next Stage
                    List<ASF_Case_Rule__c> caseRulesForStage = new List<ASF_Case_Rule__c>();
                    for(ASF_Case_Rule__c caseRule : allCaseRules){
                        if(caseRule.Case_Stage_Config__c == config.Id){
                            caseRulesForStage.add(caseRule);
                        }
                    }
                    
                    Boolean isStageMovementValid = ASF_CaseFrameworkHelper.runStageMovementRules(queriedCaseRecord, caseRulesForStage);
                    System.debug('***isStageMovementValid'+isStageMovementValid);
                    if(isStageMovementValid){
                        nextStageConfig = config;
                        System.debug('***nextStageConfig:'+nextStageConfig);
                        break;
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
                    nextStageConfig = config;
                    break;
                }
            }
        }
        
        // Once Next Stage is found, run Assignment Rules to get the Owner Information
        if(nextStageConfig != null){
            
            System.debug('***nextStageConfig:2'+nextStageConfig);

            if(nextStageConfig.Assign_To_Last_Actioned_Stage__c != null){
                ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo info = ASF_CaseFrameworkHelper.findAssignmentForPreviouslyVisitedStage(currentCase, nextStageConfig.Assign_To_Last_Actioned_Stage__c);
                
                resultWrapper.isPreviousStage = true;
                resultWrapper.ownerId = info.defaultOwnerId;
                resultWrapper.errorOwnerId = info.defaultErrorOwnerId;
            }
            if(resultWrapper.ownerId == null){
                ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo info = ASF_CaseMovementHelper.getAssignmentForStage(currentCase, nextStageConfig.StageName__c);
                System.debug('***Ritika:2'+info);
                resultWrapper.ownerId = info.defaultOwnerId;
                resultWrapper.errorOwnerId = info.defaultErrorOwnerId;
            }
            resultWrapper.stageConfig = nextStageConfig;
            resultWrapper.status = 'Success';
        }
        System.debug('***nextStageConfig:1'+resultWrapper.stageConfig);
        return resultWrapper;
    }

    /**
     * One Method to find the rightr assignment for a certain stage
     * This takes into account he following
     * 
     */
    public static ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo getAssignmentForStage(Case currentCase, String stageName){

        ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo resultWrapper = new ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo();
        // Find the Right Stage Config
        ASF_Case_Stage_Config__c currentStageConfig;
        List<ASF_Case_Stage_Config__c> allStageConfigs = ASF_CaseQueryHandler.getCaseStageConfigWithRlAndIntr(new Set<String>{currentCase.CCC_External_Id__c});
        for(ASF_Case_Stage_Config__c config: allStageConfigs){
            if(config.StageName__c == stageName){
                currentStageConfig = config;
                break;
            }
        }

        // Fetch the Rules, so we can Get the right Assignment Rules
        List<ASF_Case_Rule__c> allCaseRules = ASF_CaseQueryHandler.getCaseRuleWithHierarchy(new Set<String>{currentCase.CCC_External_Id__c});
        
        
        List<ASF_Case_Rule__c> caseRulesForStage = new List<ASF_Case_Rule__c>();
        for(ASF_Case_Rule__c caseRule : allCaseRules){
            system.debug(caseRule.Type__c + ' ' + caseRule.Case_Stage_Config__c + ' ' + caseRule.Assigned_Queue_Id__c);
            if(caseRule.Case_Stage_Config__c == currentStageConfig.Id){
                caseRulesForStage.add(caseRule);
            }
        }

        if(caseRulesForStage.size() > 0){
            Set<String> allFields = new Set<String>{'stage__c', 'businesshoursid'};
            for(ASF_Case_Stage_Config__c config: allStageConfigs){
                if(config.Query_Fields__c != null){
                    allFields.addAll(config.Query_Fields__c.toLowerCase().split(','));
                }
            }
            // if(allFields.size() == 0){
            //     resultWrapper.errorMessage = 'Query Fields not Found on Stage Config';
            //     resultWrapper.status = 'Error';
            //     return resultWrapper;
            // }
            Case queriedCaseRecord = ASF_CaseQueryHandler.getCaseRecordWithQueryFields(allFields, currentCase.Id);
            
            /*
            Case queriedCaseRecord = (Case) Database.query(
                'SELECT ' +
                currentStageConfig.Query_Fields__c +
                ' FROM Case Where Id=\'' +
                currentCase.Id +
                '\''
            );
            */
            ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo info = ASF_CaseFrameworkHelper.runAssignmentRules(queriedCaseRecord, caseRulesForStage);
            resultWrapper.defaultOwnerId = info.defaultOwnerId;
            resultWrapper.defaultErrorOwnerId = info.defaultErrorOwnerId;
        }

        
        if(resultWrapper.defaultOwnerId == null){
            resultWrapper.defaultOwnerId = currentStageConfig.Default_Queue__c;
        }
        if(resultWrapper.defaultErrorOwnerId == null){
            resultWrapper.defaultErrorOwnerId = currentStageConfig.Default_Error_Queue__c;
        }
        resultWrapper.status = 'Success';
        return resultWrapper;

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
    */
    public static StageConfigWrapper findNextStageAfterBackward(Case currentCase){
        
        StageConfigWrapper resultWrapper = new StageConfigWrapper();
        resultWrapper.status = 'Error';
        
        ASF_Case_Stage_Config__c currentStageConfig;
        List<ASF_Case_Stage_Config__c> allStageConfigs = ASF_CaseQueryHandler.getCaseStageConfigWithRlAndIntr(new Set<String>{currentCase.CCC_External_Id__c});
        for(ASF_Case_Stage_Config__c config: allStageConfigs){
            if(config.StageName__c == currentCase.Stage__c){
                currentStageConfig = config;
            }
        }
        
        ASF_Case_Stage_Config__c nextStageConfig;
        Boolean isPreviousStage = false;
        for(ASF_Case_Stage_Config__c config: allStageConfigs){
            if(currentStageConfig != null && currentStageConfig.Order__c < config.Order__c){
                
                if(config.Gateway_Stage__c){
                    nextStageConfig = config;
                    break;
                }
                else if(config.StageName__c == currentCase.Previous_Stage__c) {
                    nextStageConfig = config;
                    // Later used to determine the right owner
                    isPreviousStage = true;
                    break;
                }
            }
        }
        
        if(nextStageConfig != null){
            
            // If Previously Assigned Stage, Find Previously Assigned Owner
            // If the Stage Config dictates to assign to an owner who 
            // was the last actioned user of another stage, then find that
            resultWrapper.stageConfig = nextStageConfig;
            resultWrapper.status = 'Success';
            if(isPreviousStage || nextStageConfig.Assign_To_Last_Actioned_Stage__c != null){
                
                String stageName = nextStageConfig.StageName__c;
                if(nextStageConfig.Assign_To_Last_Actioned_Stage__c != null){
                    stageName = nextStageConfig.Assign_To_Last_Actioned_Stage__c;
                }
                ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo info = ASF_CaseFrameworkHelper.findAssignmentForPreviouslyVisitedStage(currentCase, stageName);
                
                resultWrapper.isPreviousStage = true;
                resultWrapper.ownerId = info.defaultOwnerId;
                resultWrapper.errorOwnerId = info.defaultErrorOwnerId;
            }

            if(resultWrapper.ownerId == null){
                ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo info = ASF_CaseMovementHelper.getAssignmentForStage(currentCase, nextStageConfig.StageName__c);
                resultWrapper.ownerId = info.defaultOwnerId;
                resultWrapper.errorOwnerId = info.defaultErrorOwnerId;
                resultWrapper.isPreviousStage = false;
            }
        }
        return resultWrapper;
    }
    
    
    /**
    * Get Additional Peripheral Objects Data for Case Transition
    * Includes Checklists, Tasks, Approvals and Integrations
    */
    public static CaseAdditionalData getCaseAdditionalDataForNextStage(Case currentCase, String nextStage){
        ASF_Case_Stage_Config__c nextStageConfig;
        boolean bManualApprovalStage = false;
        CaseAdditionalData additionalData = new CaseAdditionalData();
        List<ASF_Checklist__c> checklistList = new List<ASF_Checklist__c>();
        // Fetch All Case Stage Configs from Query Handler, Find the Correct One for Next Stage
        List<ASF_Case_Stage_Config__c> allStageConfigs = ASF_CaseQueryHandler.getCaseStageConfigWithRlAndIntr(new Set<String>{currentCase.CCC_External_Id__c});
        for(ASF_Case_Stage_Config__c config: allStageConfigs){
            if(config.StageName__c == nextStage){
                nextStageConfig = config;
                bManualApprovalStage = config.Manual_Approval__c;
            }
        }
        // Fetch all Case Rules and Run the Approrpriate One - For Approval matching the Case Stage Config
        List<ASF_Case_Rule__c> allCaseRules = ASF_CaseQueryHandler.getCaseRuleWithHierarchy(new Set<String>{currentCase.CCC_External_Id__c});
        
        List<ASF_Case_Rule__c> caseRulesForStage = new List<ASF_Case_Rule__c>();
        for (ASF_Case_Rule__c caseRule : allCaseRules){
            if(nextStageConfig != null){
                if(caseRule.Case_Stage_Config__c == nextStageConfig.Id){
                    caseRulesForStage.add(caseRule);
                } 
            }
        }

        
        // Find All Query Fields for Case, Merge them togther, and perform one Query on Case
        //Initiating with these 2 fields as these are required in ASF_CaseFrameworkHelper class
        Set<String> allFields = new Set<String>{'stage__c', 'businesshoursid'};
        for(ASF_Case_Stage_Config__c config: allStageConfigs){
            if(config.Query_Fields__c != null){
                allFields.addAll(config.Query_Fields__c.toLowerCase().split(','));
            }
        }
        // if(allFields.size() == 0){
        //     additionalData.errorMessage = 'Query Fields not Found on Stage Config';
        //     additionalData.status = 'Error';
        //     return additionalData;
        // }
        ASF_CaseQueryHandler.refreshRecords = true;
        Case queriedCaseRecord = ASF_CaseQueryHandler.getCaseRecordWithQueryFields(allFields, currentCase.Id);
        ASF_CaseQueryHandler.refreshRecords = false;
        additionalData.approvalsToInsert = ASF_CaseFrameworkHelper.addApprovals(queriedCaseRecord, caseRulesForStage);
        additionalData.checklistToInsert = ASF_CaseFrameworkHelper.addChecklists(queriedCaseRecord, caseRulesForStage);
        additionalData.tasksToInsert = ASF_CaseFrameworkHelper.addTasks(queriedCaseRecord, caseRulesForStage);
         additionalData.slaCaseAndStageOverrideValues = ASF_CaseFrameworkHelper.addSLA(queriedCaseRecord, caseRulesForStage);  
        if(nextStageConfig != null){
            additionalData.allIntegrations = nextStageConfig.ASF_Integrations__r;
        }
        
        additionalData.status = 'Success';
        // VIRENDRA - 15 JAN 2024 - ADDED MANUAL APPROVAL STAGE FLAG TO SET ON CASE TO ENABLE MANUAL APPROVAL BUTTON.
        additionalData.manualApprovalStage = bManualApprovalStage;
        return additionalData;
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