public without sharing class ASF_CaseTriggerModularHelper {
    
    /** STATIC VARIABLES to pass data between Before and After events*/
    public static ASF_CaseMovementHelper.CaseAdditionalData addlDataFromStageMovementMethods;
    public static Boolean triggerEncounteredError = false;
    private static Map<Id, Case> caseFinalDMLMap;

    /****************************************************************************************************************
    * @Function - populateFrameworkFieldsForCase
    * @param newList -  list of cases from trigger.new.
    * @param oldMap -  map of cases from trigger.oldMap.
    * @return - void .
    * @Description - Invoked from BeforeInsert & BeforeUpdate method, this method pre-populates fields on Case from related CCC record and Asset record.
    *****************************************************************************************************************/
    public static void populateFrameworkFieldsForCase(List<Case> newList, Map<Id, Case> oldMap) {
        //1. Assuming Issue Code will be provided on Case, fetch CCC based on the Issue Code, populate case fields from CCC.
        //2. Expectation is that the caller system will create the Extension record along with Case with all required fields populated. No prepopulation required on Extension record.
        //3. Populate default value fields on Case, independant on CCC record.
        //4. If Case has related Asset, the caller system will create the Asset record too and tag it with the Case.
        //5. For Before Update, the method only tracks the CCC_External_Id__c field change and updates the fields which gets data from CCC record.
        
        Boolean isUpdate = oldMap!=null?true:false;
        Map<Integer, Id> caseIndexToAssetIdMap = new Map<Integer, Id>();
        Map<Id, Asset> assetMap = new Map<Id, Asset>();
        Map<Id, String> caseIdToCCCExtIdMap = new Map<Id, String>();
        Map<String, ASF_Case_Category_Config__c> cccExtIdToCCCMap = new Map<String, ASF_Case_Category_Config__c>();
        Boolean blankSourcePresent = false;
        ASF_CreateCaseWithTypeController.CaseDetailsWrapper objCaseDetailsWrapper;
        Map<String, Boolean> statusMap = new Map<String, Boolean>();
        if(isUpdate){
            statusMap = ASF_CaseQueryHandler.getCaseStatusMap();
        }
        //Get the Issue Code for API cases and CCC External id for UI cases.
        Integer index = 0;
        for(Case caseRec : newList){
            if(isUpdate){
                if(caseRec.CCC_External_Id__c != oldMap.get(caseRec.Id).CCC_External_Id__c 
                    && caseRec.CCC_External_Id__c != null){
                        //Only in case of interaction to framework conversion
                        //or recategorization
                        caseIdToCCCExtIdMap.put(caseRec.Id, caseRec.CCC_External_Id__c);
                }
                
                if(statusMap.get(caseRec.Stage__c) != statusMap.get(oldMap.get(caseRec.Id).Stage__c) && statusMap.get(caseRec.Stage__c) == true && caseRec.First_Case_Closed_Date__c == null){
                    caseRec.First_Case_Closed_Date__c = System.now();
                }
            }else{
                if((caseRec.Technical_Source__c == 'LWC' || caseRec.Technical_Source__c == 'API') && String.isNotBlank(caseRec.CCC_External_Id__c)){
                    caseIdToCCCExtIdMap.put(caseRec.Id, caseRec.CCC_External_Id__c);
                }
                
                //Check if any Case from API has blank Source, needs to be defaulted then.
                if(!blankSourcePresent && String.isBlank(caseRec.Source__c)){
                    blankSourcePresent = true;
                }
                //Collect the Asset Id, to prepopulate case fields from Asset record.
                if(caseRec.AssetId != null){
                    caseIndexToAssetIdMap.put(index, caseRec.AssetId);
                }
            }
            index++;
        }
        
        //Fetch all types of data sources before entering Case loop.
        // 1. CCC, 2. Asset, 3. LOBMappingDetails__mdt
        if(!caseIdToCCCExtIdMap.isEmpty()){
            //Fetch CCC
            for(ASF_Case_Category_Config__c cccRec : ASF_CaseQueryHandler.getCaseCategoryConfigs(caseIdToCCCExtIdMap.values()))
            {
                if(caseIdToCCCExtIdMap.values().contains(cccRec.CCC_External_Id__c)){
                    cccExtIdToCCCMap.put(cccRec.CCC_External_Id__c, cccRec);
                }
            }
        }
        
        //Fetch Asset - beforeinsert only
        if(!caseIndexToAssetIdMap.isEmpty()){
            assetMap = new Map<Id, Asset>(ASF_CaseQueryHandler.getAssets(caseIndexToAssetIdMap.values()));
        }
        
        //Fetch Source from LOBMappingDetails__mdt - beforeinsert only
        if(blankSourcePresent){
            objCaseDetailsWrapper = ASF_CreateCaseWithTypeController.getUserDetails();
        }
        
        index = 0;
        for(Case caseRec : newList){
            ASF_Case_Category_Config__c appliedCCC;
            if(isUpdate){
                if(String.isNotBlank(caseRec.CCC_External_Id__c) 
                && cccExtIdToCCCMap.containsKey(caseRec.CCC_External_Id__c)){
                    appliedCCC = cccExtIdToCCCMap.get(caseRec.CCC_External_Id__c);
                }
            }else{
                if((caseRec.Technical_Source__c == 'LWC' || caseRec.Technical_Source__c == 'API') && String.isNotBlank(caseRec.CCC_External_Id__c)){
                    if(cccExtIdToCCCMap.containsKey(caseRec.CCC_External_Id__c)){
                        appliedCCC = cccExtIdToCCCMap.get(caseRec.CCC_External_Id__c);
                    }
                }
            }
            if(appliedCCC != null){
                //Fill all common fields irrespective of source
                caseRec.Nature__c = String.isBlank(caseRec.Nature__c)?appliedCCC.Nature__c:caseRec.Nature__c;
                caseRec.Stage__c = appliedCCC.First_Stage__c;
                caseRec.CCC_External_Id__c = appliedCCC.CCC_External_Id__c;
                caseRec.Type_Text__c = appliedCCC.Type__c;
                caseRec.Subject = 'SR - '+caseRec.Type_Text__c;
                caseRec.Sub_Type_Text__c = appliedCCC.Sub_Type__c;
                caseRec.ASF_Is_Cloneable__c = appliedCCC.ASF_Is_Cloneable__c;
                caseRec.Reopen_Days__c = appliedCCC.Reopen_Days__c;
                caseRec.Reopen_Style__c = appliedCCC.Reopen_Style__c;
                caseRec.Is_STP__c = appliedCCC.Is_STP__c;
                caseRec.Multiple_Child_Details__c = appliedCCC.Multiple_Child_Details__c;
                caseRec.Is_Recategorise_Allowed__c = appliedCCC.Is_Recategorise_Allowed__c;
                //For Technical Source = Email, if CCC External Id is being populated which means case is converting 
                //from interaction to framework RT. So run assignment rule for first stage of framework
                //Update 1: This assignment rules should run for recategoriasation too.
                if(isUpdate){
                    ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo ownerInfo = ASF_CaseMovementHelper.getAssignmentForStage(caseRec, caseRec.Stage__c);
                    caseRec.OwnerId = ownerInfo.defaultOwnerId != null ? ownerInfo.defaultOwnerId : (ownerInfo.defaultErrorOwnerId != null ? ownerInfo.defaultErrorOwnerId : caseRec.OwnerId);
                }
            }

            //Populate always
            //During insert - STP+API+Attachment Status = NA => Move to next stage
            //During update - STP+API+Attachment Status = Completed => Move to next stage
            if(((!isUpdate && caseRec.Attachment_Status__c == 'NA') || 
                (isUpdate && caseRec.Attachment_Status__c != oldMap.get(caseRec.Id).Attachment_Status__c && caseRec.Attachment_Status__c == 'Completed'))
                && caseRec.Is_STP__c == true && caseRec.Technical_Source__c == 'API' ){
                caseRec.MoveToNext__c = true;
            }
            system.debug('caseRec--'+caseRec);
            system.debug('assetMap--'+assetMap);
            //Populate fields from Asset - beforeinsert only
            if(caseRec.LAN__c == null){
                if(caseRec.AssetId != null && assetMap.containsKey(caseIndexToAssetIdMap.get(index))){
                    caseRec.LAN__c = assetMap.get(caseIndexToAssetIdMap.get(index)).LAN__c;
                }else{
                    //if Asset is not present
                    caseRec.LAN__c = 'NA';
                }
            }
            //Check if the source is API - do API specific population - beforeinsert only
            if(blankSourcePresent && caseRec.Technical_Source__c == 'API'
            && String.isBlank(caseRec.Source__c) && objCaseDetailsWrapper != null){
                caseRec.Source__c = objCaseDetailsWrapper.strSource;
            }
            if(caseRec.Technical_Source__c == 'API' && String.isBlank(caseRec.Channel__c)){
                caseRec.Channel__c = 'API';
            }
            index++;
        }
        
    }
    
    /**
     * Validate if there is mismatch in type/subtype after recategorization from API, stop stage progression
     */
    public static void validateRecategorizationParameters(List<Case> newList, Map<Id, Case> oldMap) {
        for(Case caseRec : newList){
            if(caseRec.Stage__c != oldMap.get(caseRec.Id).Stage__c 
            && caseRec.Stage__c != ASF_Constants.DUPLICATESTAGE 
            && caseRec.Stage__c != ASF_Constants.REJECTIONSTATUS){
                if(caseRec.typeSubTypeMismatch__c == true){
                    caseRec.addError(Label.RecategorizationError);
                }
            }
        }
    }

    //Applicable only for UI cases, 
    //validates the before rules of entering first stage during case creation and recategorisation
    //Moved to after trigger context - as validateNextStageEntry method requires updated field values of Case
    public static void checkAndValidateFirstStageEntry(List<Case> newList, Map<Id, Case> oldMap) {
        List<Case> eligibleRecords = new List<Case>();
        Set<String> cccExternalIds = new Set<String>();
        Boolean isUpdate = oldMap!=null?true:false;
        Boolean supressErrors = (newList[0].Technical_Source__c == 'API' && oldMap == null)?true:false;
        for(Case caseRec : newList){
            if((caseRec.Technical_Source__c == 'LWC' || caseRec.Technical_Source__c == 'API')
                && (!isUpdate 
                || (caseRec.CCC_External_Id__c != oldMap.get(caseRec.Id).CCC_External_Id__c 
                && oldMap.get(caseRec.Id).CCC_External_Id__c != null    
                && caseRec.CCC_External_Id__c != null))){
                eligibleRecords.add(caseRec);
                cccExternalIds.add(caseRec.CCC_External_Id__c);
            }
        }
        List<ASF_Case_Stage_Config__c> allStageConfigs;
        if(!cccExternalIds.isEmpty()){
            allStageConfigs = ASF_CaseQueryHandler.getCaseStageConfigWithRlAndIntr(cccExternalIds);
        }
        if(!eligibleRecords.isEmpty() && allStageConfigs != null){
            for(Case caseRec : eligibleRecords){
                ASF_Case_Stage_Config__c currentStageConfig;
                for(ASF_Case_Stage_Config__c stageConfig : allStageConfigs){
                    if(stageConfig.StageName__c == caseRec.Stage__c 
                    && stageConfig.Case_Category_Config__r.CCC_External_Id__c == caseRec.CCC_External_Id__c){
                        currentStageConfig = stageConfig;
                    }
                }
                if(currentStageConfig != null){
                    ASF_CaseMovementHelper.CaseStageValidationWrapper wrap = ASF_CaseMovementHelper.validateNextStageEntry(caseRec, currentStageConfig);
                    if(wrap.status == 'Error'){
                        if(supressErrors){
                            triggerEncounteredError = true;
                        }else{
                            caseRec.addError(wrap.errorMessage!=null?wrap.errorMessage:'Error during stage entry validation');
                        }
                    }else{
                        if(wrap.isCaseUpdated == true){
                            Map<String, Object> populatedFieldMap = wrap.updatedCase.getPopulatedFieldsAsMap();
                            caseFinalDMLMap = caseFinalDMLMap == null ? new Map<Id, Case>() : caseFinalDMLMap;
                            if(!caseFinalDMLMap.containsKey(caseRec.Id)){
                                Case caseObj = new Case(Id = caseRec.Id);
                                caseFinalDMLMap.put(caseObj.Id, caseObj);
                            }
                            Case caseRecFromMap = caseFinalDMLMap.get(caseRec.Id);
                            for(String fieldName : populatedFieldMap.keySet()){
                                caseRecFromMap.put(fieldName, wrap.updatedCase.get(fieldName));
                            }
                            caseFinalDMLMap.put(caseRecFromMap.Id, caseRecFromMap);
                        }
                    }
                }
            }
        }
    }

    //Detects the Reopen request and sets the Stage__c on trigger.new for other methods to consume
    public static void findNextStageAndSetOnTriggerNewForReopenRequest(List<Case> newList, Map<Id, Case> oldMap) {
        List<Case> eligibleRecords = new List<Case>();
        List<String> cccExtIds = new List<String>();
        Map<String, ASF_Case_Category_Config__c> cccExtIdToCCCMap = new Map<String, ASF_Case_Category_Config__c>();
        for(Case caseRec : newList){
            //On update, if Reopened_DateTime__c changed, else no action
            if(caseRec.Reopened_DateTime__c != oldMap.get(caseRec.Id).Reopened_DateTime__c && caseRec.Reopened__c == true){
                eligibleRecords.add(caseRec);
                if(caseRec.Reopen_Style__c == 'Move To First Stage'){
                    cccExtIds.add(caseRec.CCC_External_Id__c);
                }
            }
        }
        if(!cccExtIds.isEmpty()){
            for(ASF_Case_Category_Config__c cccRec : ASF_CaseQueryHandler.getCaseCategoryConfigs(cccExtIds)){
                cccExtIdToCCCMap.put(cccRec.CCC_External_Id__c, cccRec);
            }
        }
        if(!eligibleRecords.isEmpty()){
            for(Case caseRec : eligibleRecords){
                ASF_Case_Category_Config__c appliedCCC = cccExtIdToCCCMap.get(caseRec.CCC_External_Id__c);
                switch on caseRec.Reopen_Style__c {
                    when 'Move To First Stage' {
                        caseRec.Stage__c = appliedCCC.First_Stage__c;
                    }
                    when 'Reopen Stage With Movement', 'Reopen Stage No Movement' {
                        caseRec.Stage__c = 'Reopened';
                    }
                    when else {
                        System.debug('Unknown Reopen Style');
                    }
                }
            }
        }
    }


    //Detects the Reopen request and processes it based on reopen style
    //Moved to after  trigger context
    public static void checkAndProcessReopenCase(List<Case> newList, Map<Id, Case> oldMap) {
        List<Case> eligibleRecords = new List<Case>();
        List<String> cccExtIds = new List<String>();
        Map<String, ASF_Case_Category_Config__c> cccExtIdToCCCMap = new Map<String, ASF_Case_Category_Config__c>();
        for(Case caseRec : newList){
            //On update, if Reopened_DateTime__c changed, else no action
            if(caseRec.Reopened_DateTime__c != oldMap.get(caseRec.Id).Reopened_DateTime__c && caseRec.Reopened__c == true){
                eligibleRecords.add(caseRec);
                if(caseRec.Reopen_Style__c == 'Move To First Stage'){
                    cccExtIds.add(caseRec.CCC_External_Id__c);
                }
            }
        }
        if(!cccExtIds.isEmpty()){
            for(ASF_Case_Category_Config__c cccRec : ASF_CaseQueryHandler.getCaseCategoryConfigs(cccExtIds)){
                cccExtIdToCCCMap.put(cccRec.CCC_External_Id__c, cccRec);
            }
        }
        if(!eligibleRecords.isEmpty()){
            for(Case caseRec : eligibleRecords){
                ASF_Case_Category_Config__c appliedCCC = cccExtIdToCCCMap.get(caseRec.CCC_External_Id__c);
                switch on caseRec.Reopen_Style__c {
                    when 'Move To First Stage' {
                        ASF_CaseMovementHelper.StageWrapper resultWrap = ASF_CaseMovementHelper.moveToBackwardStage(caseRec, appliedCCC.First_Stage__c);
                        if(resultWrap.status == 'Success'){
                            caseFinalDMLMap = caseFinalDMLMap == null ? new Map<Id, Case>() : caseFinalDMLMap;
                            if(!caseFinalDMLMap.containsKey(caseRec.Id)){
                                Case caseObj = new Case(Id = caseRec.Id);
                                caseFinalDMLMap.put(caseObj.Id, caseObj);
                            }
                            Case caseRecFromMap = caseFinalDMLMap.get(caseRec.Id);
                            caseRecFromMap.Stage__c = resultWrap.caseToBeUpdated.Stage__c;
                            caseRecFromMap.Status = resultWrap.caseToBeUpdated.Status;
                            caseRecFromMap.OwnerId = resultWrap.ownerId != null ? resultWrap.ownerId : (resultWrap.errorOwnerId != null ? resultWrap.errorOwnerId : caseRec.OwnerId);
                            caseFinalDMLMap.put(caseRecFromMap.Id, caseRecFromMap);
                        }else{
                            caseRec.addError(resultWrap.errorMessage != null?resultWrap.errorMessage:ASF_Constants.GENERIC_ERROR_MESSAGE);
                        }
                    }
                    when 'Reopen Stage With Movement', 'Reopen Stage No Movement' {
                        ASF_CaseMovementHelper.StageWrapper resultWrap = ASF_CaseMovementHelper.moveToForwardStage(caseRec, 'Reopened', oldMap.get(caseRec.Id).Stage__c);
                        if(resultWrap.status == 'Success'){
                            caseFinalDMLMap = caseFinalDMLMap == null ? new Map<Id, Case>() : caseFinalDMLMap;
                            Map<String, Object> populatedFieldMap = resultWrap.caseToBeUpdated.getPopulatedFieldsAsMap();
                            if(!caseFinalDMLMap.containsKey(caseRec.Id)){
                                Case caseObj = new Case(Id = caseRec.Id);
                                caseFinalDMLMap.put(caseObj.Id, caseObj);
                            }
                            Case caseRecFromMap = caseFinalDMLMap.get(caseRec.Id);
                            for(String fieldName : populatedFieldMap.keySet()){
                                caseRecFromMap.put(fieldName, resultWrap.caseToBeUpdated.get(fieldName));
                            }
                            caseRecFromMap.OwnerId = resultWrap.ownerId != null ? resultWrap.ownerId : (resultWrap.errorOwnerId != null ? resultWrap.errorOwnerId : caseRec.OwnerId);
                            caseFinalDMLMap.put(caseRecFromMap.Id, caseRecFromMap);
                        }else{
                            caseRec.addError(resultWrap.errorMessage != null?resultWrap.errorMessage:ASF_Constants.GENERIC_ERROR_MESSAGE);
                        }
                    }
                    when else {
                        System.debug('Unknown Reopen Style');
                    }
                }
            }
        }
    }

    //Method to get the next eligible stage for moveToNextStage and set on trigger.new
    public static void findNextStageAndSetOnTriggerNew(List<Case> newList, Map<Id, Case> oldMap) {
        Boolean isUpdate = oldMap!=null?true:false;
        List<Case> eligibleRecords = new List<Case>();
        Boolean supressErrors = (newList[0].Technical_Source__c == 'API' && oldMap == null)?true:false;
        for(Case caseRec : newList){
            System.debug('caseRec.MoveToNext__c'+caseRec.MoveToNext__c);
           // System.debug('oldMap.get(caseRec.Id).MoveToNext__c'+oldMap.get(caseRec.Id).MoveToNext__c);
            //If update, is MoveToNext changed to true, else if insert, MoveToNext is true
            if(((isUpdate && caseRec.MoveToNext__c != oldMap.get(caseRec.Id).MoveToNext__c) || !isUpdate)
               && caseRec.MoveToNext__c == true){
                   eligibleRecords.add(caseRec);
               }
        }
        if(!eligibleRecords.isEmpty()){
            for(Case caseRec : eligibleRecords){
                ASF_CaseMovementHelper.StageWrapper resultWrap = ASF_CaseMovementHelper.findNextStageForMoveToNextStage(caseRec);
                if(resultWrap.status == 'Success'){
                    caseRec.Stage__c = resultWrap.nextStageConfig.StageName__c;
                }else{
                    if(supressErrors){
                        triggerEncounteredError = true;
                    }else{
                        eligibleRecords[0].addError(resultWrap.errorMessage != null?resultWrap.errorMessage:ASF_Constants.GENERIC_ERROR_MESSAGE);
                    }
                }
            }
        }
    }
    
    //Method checks whether move to next stage is changed to true, if yes, calls the right modular methods to process it
    //Moved to after trigger context
    public static void checkAndProcessMoveToNextStage(List<Case> newList, Map<Id, Case> oldMap){
        Boolean isUpdate = oldMap!=null?true:false;
        List<Case> eligibleRecords = new List<Case>();
        Boolean supressErrors = (newList[0].Technical_Source__c == 'API' && oldMap == null)?true:false;
        for(Case caseRec : newList){
            System.debug('caseRec.MoveToNext__c'+caseRec.MoveToNext__c);
           // System.debug('oldMap.get(caseRec.Id).MoveToNext__c'+oldMap.get(caseRec.Id).MoveToNext__c);
            //If update, is MoveToNext changed to true, else if insert, MoveToNext is true
            if(((isUpdate && caseRec.MoveToNext__c != oldMap.get(caseRec.Id).MoveToNext__c) || !isUpdate)
               && caseRec.MoveToNext__c == true){
                   eligibleRecords.add(caseRec);
               }
        }
        
        if(!eligibleRecords.isEmpty()){
            for(Case caseRec : eligibleRecords){
                //invoke moveToNextStage of ASF_CaseMovementHelper
                ASF_CaseMovementHelper.StageWrapper resultWrap = ASF_CaseMovementHelper.moveToNextStage(caseRec, caseRec.Stage__c);
                if(resultWrap.status == 'Success'){
                    if(isUpdate){
                        caseFinalDMLMap = caseFinalDMLMap == null ? new Map<Id, Case>() : caseFinalDMLMap;
                        if(!caseFinalDMLMap.containsKey(caseRec.Id)){
                            Case caseObj = new Case(Id = caseRec.Id);
                            caseFinalDMLMap.put(caseObj.Id, caseObj);
                        }
                        Case caseRecFromMap = caseFinalDMLMap.get(caseRec.Id);
                        caseRecFromMap.OwnerId = resultWrap.ownerId != null ? resultWrap.ownerId : (resultWrap.errorOwnerId != null ? resultWrap.errorOwnerId : caseRec.OwnerId);
                        caseRecFromMap.Previous_Stage__c = oldMap.get(caseRecFromMap.Id).Stage__c;
                        Map<String, Object> populatedFieldMap = resultWrap.caseToBeUpdated.getPopulatedFieldsAsMap();
                        for(String fieldName : populatedFieldMap.keySet()){
                            caseRecFromMap.put(fieldName, resultWrap.caseToBeUpdated.get(fieldName));
                        }
                        caseFinalDMLMap.put(caseRecFromMap.Id, caseRecFromMap);
                    }else{
                        //After Insert call
                        caseFinalDMLMap = caseFinalDMLMap == null ? new Map<Id, Case>() : caseFinalDMLMap;
                        if(!caseFinalDMLMap.containsKey(caseRec.Id)){
                            Case caseObj = new Case(Id = caseRec.Id);
                            caseFinalDMLMap.put(caseObj.Id, caseObj);
                        }
                        Case caseRecFromMap = caseFinalDMLMap.get(caseRec.Id);
                        Map<String, Object> populatedFieldMap = resultWrap.caseToBeUpdated.getPopulatedFieldsAsMap();
                        for(String fieldName : populatedFieldMap.keySet()){
                            caseRecFromMap.put(fieldName, resultWrap.caseToBeUpdated.get(fieldName));
                        }
                        caseRecFromMap.OwnerId = resultWrap.ownerId != null ? resultWrap.ownerId : (resultWrap.errorOwnerId != null ? resultWrap.errorOwnerId : resultWrap.caseToBeUpdated.OwnerId);
                        caseRecFromMap.MoveToNext__c = false;
                        caseRecFromMap.Previous_Stage__c = caseRec.Stage__c;//Current new stage becomes previous stage
                        caseFinalDMLMap.put(caseRecFromMap.Id, caseRecFromMap);
                    }
                }else{
                    if(supressErrors){
                        triggerEncounteredError = true;
                    }else{
                        eligibleRecords[0].addError(resultWrap.errorMessage != null?resultWrap.errorMessage:ASF_Constants.GENERIC_ERROR_MESSAGE);
                    }
                }
            }
        }
    }
    
    //Method checks whether stage is changed(Forward stage movement) or pending clarification = true with stage movement(backward) and process it
    //skip when case is being reopened
    //skip when case is being closed
    //MOved to after trigger context
    public static void checkAndProcessManualStageMovement(List<Case> newList, Map<Id, Case> oldMap) {
        List<Case> eligibleRecords = new List<Case>();
        String movement = '';
        for(Case caseRec : newList){
            //1. This is not moveToNextStage update
            //2. MoveToNext = false - addl check
            //2a.Not converting from interaction to framework
            //3. Case is not being reopened
            //4. Case is not being rejected
            //5. If stage updated
            if((caseRec.MoveToNext__c == oldMap.get(caseRec.Id).MoveToNext__c 
                && caseRec.MoveToNext__c == false)
                && (caseRec.CCC_External_Id__c == oldMap.get(caseRec.Id).CCC_External_Id__c )
                && (caseRec.Reopened_DateTime__c == oldMap.get(caseRec.Id).Reopened_DateTime__c)
                && (caseRec.Reject_Case__c == oldMap.get(caseRec.Id).Reject_Case__c)
               && caseRec.Stage__c != oldMap.get(caseRec.Id).Stage__c){
                   eligibleRecords.add(caseRec);
                   movement = caseRec.pending_clarification__c==true?'backward':'forward';
               }
        }
        if(!eligibleRecords.isEmpty()){
            for(Case caseRec : eligibleRecords){
                ASF_CaseMovementHelper.StageWrapper wrapToReturn = new ASF_CaseMovementHelper.StageWrapper();
                if(movement == 'forward'){
                    wrapToReturn = ASF_CaseMovementHelper.moveToForwardStage(caseRec, caseRec.Stage__c, oldMap.get(caseRec.Id).Stage__c);
                    if(wrapToReturn.status == 'Success'){
                        caseFinalDMLMap = caseFinalDMLMap == null ? new Map<Id, Case>() : caseFinalDMLMap;
                        if(!caseFinalDMLMap.containsKey(caseRec.Id)){
                            Case caseObj = new Case(Id = caseRec.Id);
                            caseFinalDMLMap.put(caseObj.Id, caseObj);
                        }
                        Case caseRecFromMap = caseFinalDMLMap.get(caseRec.Id);
                        caseRecFromMap.Previous_Stage__c = oldMap.get(caseRecFromMap.Id).Stage__c;
                        Map<String, Object> populatedFieldMap = wrapToReturn.caseToBeUpdated.getPopulatedFieldsAsMap();
                        for(String fieldName : populatedFieldMap.keySet()){
                            caseRecFromMap.put(fieldName, wrapToReturn.caseToBeUpdated.get(fieldName));
                        }
                        caseRecFromMap.OwnerId = wrapToReturn.ownerId != null ? wrapToReturn.ownerId : (wrapToReturn.errorOwnerId != null ? wrapToReturn.errorOwnerId : caseRec.OwnerId);
                        caseFinalDMLMap.put(caseRecFromMap.Id, caseRecFromMap);
                    }
                    else{
                        //Error scenario
                        caseRec.addError(wrapToReturn.errorMessage != null?wrapToReturn.errorMessage:ASF_Constants.GENERIC_ERROR_MESSAGE);
                    }
                }else{
                    wrapToReturn = ASF_CaseMovementHelper.moveToBackwardStage(caseRec, caseRec.Stage__c);
                    if(wrapToReturn.status == 'Success'){
                        caseFinalDMLMap = caseFinalDMLMap == null ? new Map<Id, Case>() : caseFinalDMLMap;
                        if(!caseFinalDMLMap.containsKey(caseRec.Id)){
                            Case caseObj = new Case(Id = caseRec.Id);
                            caseFinalDMLMap.put(caseObj.Id, caseObj);
                        }
                        Case caseRecFromMap = caseFinalDMLMap.get(caseRec.Id);
                        caseRecFromMap.Previous_Stage__c = oldMap.get(caseRecFromMap.Id).Stage__c;
                        Map<String, Object> populatedFieldMap = wrapToReturn.caseToBeUpdated.getPopulatedFieldsAsMap();
                        for(String fieldName : populatedFieldMap.keySet()){
                            caseRecFromMap.put(fieldName, wrapToReturn.caseToBeUpdated.get(fieldName));
                        }
                        caseRecFromMap.OwnerId = wrapToReturn.ownerId != null ? wrapToReturn.ownerId : (wrapToReturn.errorOwnerId != null ? wrapToReturn.errorOwnerId : caseRec.OwnerId);
                        caseFinalDMLMap.put(caseRecFromMap.Id, caseRecFromMap);
                    }
                    else{
                        //Error scenario
                        caseRec.addError(wrapToReturn.errorMessage != null?wrapToReturn.errorMessage:ASF_Constants.GENERIC_ERROR_MESSAGE);
                    }
                }
            }
        }
    }
    
    //After insert call, only for API cases, assigns the owner on first stage
    public static void checkAndPopulateOwnerOnCaseCreation(List<Case> newList) {
        List<Case> casesToUpdate = new List<Case>();
        for(Case caseRec : newList){
            if(caseRec.Technical_Source__c == 'API'){
                ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo ownerInfo = ASF_CaseMovementHelper.getAssignmentForStage(caseRec, caseRec.Stage__c);
                caseFinalDMLMap = caseFinalDMLMap == null ? new Map<Id, Case>() : caseFinalDMLMap;
                if(!caseFinalDMLMap.containsKey(caseRec.Id)){
                    Case caseObj = new Case(Id = caseRec.Id, OwnerId=caseRec.OwnerId);
                    caseFinalDMLMap.put(caseRec.Id, caseObj);
                }
                Case caseRecFromMap = caseFinalDMLMap.get(caseRec.Id);
                caseRecFromMap.OwnerId = ownerInfo.defaultOwnerId!=null?ownerInfo.defaultOwnerId:caseRecFromMap.OwnerId;
                if(triggerEncounteredError){
                    caseRecFromMap.OwnerId = ownerInfo.defaultErrorOwnerId!=null?ownerInfo.defaultErrorOwnerId:caseRecFromMap.OwnerId;
                }
                caseFinalDMLMap.put(caseRecFromMap.Id, caseRecFromMap);
            }
        }
        triggerEncounteredError = false;
    }
    //Runs the ASF_CaseMovementHelper.getCaseAdditionalDataForNextStage method
    //to fetch the tasks, checklists, approvals and integrations and
    //stores them in static variable for after context trigger to insert them
    //Runs the integrations and updates the owner in case of errors.
    //Runs on new case creation and recategorisation and forward stage movement
    public static void checkAndStorePeripheralRecordsInAfterContext(List<Case> newList, Map<Id, Case> oldMap) {
        List<Case> eligibleRecords = new List<Case>();
        Boolean isUpdate = oldMap!=null?true:false;

        for(Case caseRec : newList){
            //Insert case
            if(caseRec.Technical_Source__c != null && caseRec.CCC_External_Id__c != null
                && (!isUpdate 
                || (caseRec.CCC_External_Id__c != oldMap.get(caseRec.Id).CCC_External_Id__c) || 
                (caseRec.stage__c != oldMap.get(caseRec.Id).stage__c && caseRec.pending_clarification__c==false))){
                eligibleRecords.add(caseRec);
            }
        }
        if(!eligibleRecords.isEmpty()){
            Case caseToUpdate;
            ASF_CaseMovementHelper.CaseAdditionalData dataWrapper = ASF_CaseMovementHelper.getCaseAdditionalDataForNextStage(eligibleRecords[0], eligibleRecords[0].Stage__c);
            addlDataFromStageMovementMethods = new ASF_CaseMovementHelper.CaseAdditionalData();
            List<Case> casesWithPeripheralRecords = ASF_CaseQueryHandler.getCases(new Set<Id>{eligibleRecords[0].Id});
            Map<String, Boolean> checklistMap = new Map<String, Boolean>();
            Map<String, Boolean> taskMap = new Map<String, Boolean>();
            for(Case caseRec : casesWithPeripheralRecords){
                for(ASF_Checklist__c checkRec : caseRec.Checklists__r){
                    checklistMap.put(checkRec.Checklist_External_Id__c, true);
                }
                for(Task taskRec : caseRec.Tasks){
                    taskMap.put(taskRec.Work_Item_External_ID__c, true);
                }
            }
            addlDataFromStageMovementMethods.approvalsToInsert = dataWrapper.approvalsToInsert;
            for(ASF_Checklist__c checkRec : dataWrapper.checklistToInsert){
                if(!checklistMap.containsKey(checkRec.Checklist_External_Id__c)){
                    if(addlDataFromStageMovementMethods.checklistToInsert == null){
                        addlDataFromStageMovementMethods.checklistToInsert = new List<ASF_Checklist__c>();
                    }
                    addlDataFromStageMovementMethods.checklistToInsert.add(checkRec);
                }
            }
            for(Task taskRec : dataWrapper.tasksToInsert){
                if(!taskMap.containsKey(taskRec.Work_Item_External_ID__c)){
                    if(addlDataFromStageMovementMethods.tasksToInsert == null){
                        addlDataFromStageMovementMethods.tasksToInsert = new List<Task>();
                    }
                    addlDataFromStageMovementMethods.tasksToInsert.add(taskRec);
                }
            }

            //addlDataFromStageMovementMethods.checklistToInsert = dataWrapper.checklistToInsert;
            //addlDataFromStageMovementMethods.tasksToInsert = dataWrapper.tasksToInsert;
            addlDataFromStageMovementMethods.allIntegrations = dataWrapper.allIntegrations;
            addlDataFromStageMovementMethods.slaCaseAndStageOverrideValues = dataWrapper.slaCaseAndStageOverrideValues;

            if(addlDataFromStageMovementMethods != null && addlDataFromStageMovementMethods.allIntegrations != null 
                && (eligibleRecords[0].Technical_Source__c == 'API' || eligibleRecords[0].Technical_Source__c == 'Email')){
                ASF_IntegrationsController.IntegrationWrapper intWrap = ASF_CaseFrameworkHelper.runIntegrations(eligibleRecords[0], addlDataFromStageMovementMethods.allIntegrations);
                if(intWrap.status == 'Error' && intWrap.assignToId != null){
                    //eligibleRecords[0].OwnerId = intWrap.assignToId;
                    caseFinalDMLMap = caseFinalDMLMap == null ? new Map<Id, Case>() : caseFinalDMLMap;
                    if(!caseFinalDMLMap.containsKey(eligibleRecords[0].Id)){
                        caseToUpdate = new Case(Id=eligibleRecords[0].Id, OwnerId = intWrap.assignToId);
                        caseFinalDMLMap.put(caseToUpdate.Id, caseToUpdate);
                    }else{
                        caseToUpdate = caseFinalDMLMap.get(eligibleRecords[0].Id);
                        caseToUpdate.OwnerId = intWrap.assignToId;
                        caseFinalDMLMap.put(caseToUpdate.Id, caseToUpdate);
                    }
                }
            }
            if(addlDataFromStageMovementMethods != null  
                && (eligibleRecords[0].Technical_Source__c == 'API' || eligibleRecords[0].Technical_Source__c == 'LWC' || 
                   eligibleRecords[0].Technical_Source__c == 'Email')){
                    // VIRENDRA - 15 JAN 2024 - ADDED BELOW CODE FOR TECHNICAL SOURCE LWC AND EMAIL.
                    caseFinalDMLMap = caseFinalDMLMap == null ? new Map<Id, Case>() : caseFinalDMLMap;
                    if(!caseFinalDMLMap.containsKey(eligibleRecords[0].Id)){
                        caseToUpdate = new Case(Id=eligibleRecords[0].Id, is_Manual_Approval__c = dataWrapper.manualApprovalStage);
                        caseFinalDMLMap.put(caseToUpdate.Id, caseToUpdate);
                    }else{
                        caseToUpdate = caseFinalDMLMap.get(eligibleRecords[0].Id);
                        caseToUpdate.is_Manual_Approval__c = dataWrapper.manualApprovalStage;
                        caseFinalDMLMap.put(caseToUpdate.Id, caseToUpdate);
                    }
                }
        }
    }
    //Creates Checklist, Tasks, Approvals
    public static void checkAndInsertPeripheralRecords(List<Case> newList, Map<Id, Case> oldMap) {
        List<ASF_Case_Approv__c> approvalsToInsert;
        List<ASF_Checklist__c> checklistToInsert;
        List<Task> tasksToInsert;
        List<ASF_Integration__c> allIntegrations;
        Boolean supressErrors = (newList[0].Technical_Source__c == 'API' && oldMap == null)?true:false;
        
        try{
            if(addlDataFromStageMovementMethods != null){
                approvalsToInsert = addlDataFromStageMovementMethods.approvalsToInsert;
                checklistToInsert = addlDataFromStageMovementMethods.checklistToInsert;
                tasksToInsert = addlDataFromStageMovementMethods.tasksToInsert;
                allIntegrations = addlDataFromStageMovementMethods.allIntegrations;
            }
            //TODO: Convert each list to List<SObject> and insert using single DML.
            if(approvalsToInsert != null){
                insert approvalsToInsert;
            }
            if(checklistToInsert != null){
                insert checklistToInsert;
            }
            if(tasksToInsert != null){
                insert tasksToInsert;
            }
            addlDataFromStageMovementMethods = null;
        }catch(Exception e){
            if(supressErrors){
                triggerEncounteredError = true;
            }else{
                newList[0].addError(e.getMessage());
            }
        }
    }

    public static void invokeSLACalculationMethods(Map<Id, Case> newCaseMap, Map<Id, Case> oldMap) {
        //SLA calculation method - from JT's class
        Map<Id, Case> casesToUpdate = new Map<Id, Case>();
        if(oldMap != null){
            casesToUpdate = ASF_CaseSLAHandlerV1.calculateSLAOnCaseUpdate(newCaseMap,oldMap);
        }else{
            casesToUpdate = ASF_CaseSLAHandlerV1.calculateSLAOnCaseInsert(newCaseMap.values());
        }
        if(!casesToUpdate.isEmpty()){
            caseFinalDMLMap = caseFinalDMLMap == null ? new Map<Id, Case>() : caseFinalDMLMap;
            for(Case caseRecFromSLA : casesToUpdate.values()){
                if(!caseFinalDMLMap.containsKey(caseRecFromSLA.Id)){
                    caseFinalDMLMap.put(caseRecFromSLA.Id, caseRecFromSLA);
                }else{
                    Case caseRecFromMap = caseFinalDMLMap.get(caseRecFromSLA.Id);
                    //populating SLA fields on the case to be passed to DML
                    Map<String, Object> populatedFieldMap = caseRecFromSLA.getPopulatedFieldsAsMap();
                    for(String fieldName : populatedFieldMap.keySet()){
                        caseRecFromMap.put(fieldName, caseRecFromSLA.get(fieldName));
                    }
                    caseFinalDMLMap.put(caseRecFromMap.Id, caseRecFromMap);
                }
            }   
        }
    }

    public static void updateCasesFinally() {
        //This method invokes a DML on the caseFinalDMLMap map, 
        //which is accumulation of all field updates on current from After trigger
        //*** IMP: Doesnt run Case trigger***
        if(caseFinalDMLMap != null){
            ASF_TriggerSkipperUtility.markTriggerRun('Case');
            update caseFinalDMLMap.values();
            ASF_TriggerSkipperUtility.resetTriggerRun('Case');
        }
        caseFinalDMLMap = null;
    }

    public static void onCreateCloseServiceRequest(List<Case> newList){
        List<Case> onCreateCloseCases = new List<Case>();
        
        for(case caseRec : newList){
            if(caseRec.OnCreateCloseSR__c){
                caseRec.Status = ASF_Constants.ONCREATECLOSESTATUS;
                caseRec.Stage__c = ASF_Constants.ONCREATECLOSESTAGE;
            }
        }
    }
    public static void rejectFrameworkCaseBeforeUpdate(List<Case> newList,Map<Id,Case> oldMap){
        List<Case> eligibleRecords = new List<Case>();
        for(Case caseRec : newList){
            if((caseRec.Reject_Case__c != oldMap.get(caseRec.Id).Reject_Case__c && caseRec.Reject_Case__c == true) || 
               (caseRec.Is_Duplicate__c != oldMap.get(caseRec.Id).Is_Duplicate__c && caseRec.Is_Duplicate__c == true)){
                eligibleRecords.add(caseRec);
            }
        }
        if(!eligibleRecords.isEmpty()){
            for(Case caseRec : eligibleRecords){

                if(caseRec.Is_Duplicate__c){
                    ASF_CaseMovementHelper.StageWrapper resultWrap = ASF_CaseMovementHelper.moveToForwardStage(caseRec, ASF_Constants.DUPLICATESTAGE, oldMap.get(caseRec.Id).Stage__c);
                    caseRec.Stage__c = ASF_Constants.DUPLICATESTAGE;
                    caseRec.Status = ASF_Constants.DUPLICATESTATUS;
                }else{
                    ASF_CaseMovementHelper.StageWrapper resultWrap = ASF_CaseMovementHelper.moveToForwardStage(caseRec, ASF_Constants.REJECTIONSTATUS, oldMap.get(caseRec.Id).Stage__c);
                    caseRec.Stage__c = resultWrap.caseToBeUpdated.Stage__c;
                    caseRec.Status = resultWrap.caseToBeUpdated.Status!=null?resultWrap.caseToBeUpdated.Status:ASF_Constants.REJECTIONSTATUS;
                }
            }
        }
    }
    public static void rejectFrameworkCaseAfterUpdate(Map<Id,Case> newMap, Map<Id,Case> oldMap){
        Set<Id> rejectedCaseIds = new Set<Id>();
        for(Case c : newMap.values()){
            if((c.Reject_Case__c != oldMap.get(c.Id).Reject_Case__c && c.Reject_Case__c == true) ||
              (c.Is_Duplicate__c != oldMap.get(c.Id).Is_Duplicate__c && c.Is_Duplicate__c == true)){
                rejectedCaseIds.add(c.Id);
            }
        }
        if(rejectedCaseIds.size()>0){
            list<ASF_Checklist__c> checklists = [
            SELECT Id, Case__c, Rejected_Reason__c, Status__c
            FROM ASF_Checklist__c
            WHERE Case__c = :rejectedCaseIds AND Status__c = 'Pending'
        ];
        for (ASF_Checklist__c c : checklists) {
            c.Status__c = 'Rejected';
            c.Rejected_Reason__c = newMap.containsKey(c.Id)? newMap.get(c.Id).Rejected_Reason__c : 'Rejected';
        }
        
        list<Task> tasks = [
            SELECT Id, Status, WhatId, Case_Stage__c
            FROM Task
            WHERE Status = 'Open' AND WhatId = :rejectedCaseIds
        ];
        for (task t : tasks) {
            t.Status = 'Rejected';
            t.Rejected_Reason__c = newMap.get(t.WhatId).Rejected_Reason__c;
        }
        List<sObject> toUpdateList = new List<sObject>();
        toUpdateList.addAll(tasks);
        toUpdateList.addAll(checklists);        
        
        Database.SaveResult[] results = Database.update(toUpdateList,false);
        }
        
    }
    //Stops user from updating any closed Case. Reopen is exempted
    public static void validateCloseCase(Map<Id, sObject> oldItems,map<Id, sObject> newItems){
        
        for(Sobject s : newItems.values()){
            Case objNewCase = (Case) newItems.get(s.Id);
            Case oldCase = (Case) oldItems.get(s.Id);
            //If case is being reopened, allow it.
            if(objNewCase.Reopened_DateTime__c != oldCase.Reopened_DateTime__c && objNewCase.Reopened__c == true){
                return;
            }
            
            if (objNewCase.IsClosed == true && objNewCase.OnCreateCloseSR__c == false){
                if(String.isNotBlank(objNewCase.Bulk_Action__c)){
                    objNewCase.addError('FIELD_CUSTOM_VALIDATION_EXCEPTION '+ System.label.Case_Closed_Validation_Message);
                }
                else{
                    objNewCase.addError(System.label.Case_Closed_Validation_Message);
                }
            }
        }
    }

    /** OLD METHODS STARTS- NEEDS TO BE OPTIMIZED */
    public static void validateOwnerCheckerStage(Map<Id, sObject> oldItems,map<Id, sObject> newItems){
        Boolean boolSameOwnerError = false;
        Case newCase = new Case();
        Case oldCase = new Case();
        Map<Id,String> mapIdvsExtId = new Map<Id,String>();
        List<String> caseStageList = new List<String>();
        List<String> lstMakerStages =  new List<String>();
        Map<String,List<ASF_Case_SLA_History__c>> mapIDvsSLAHistory = new Map<String,List<ASF_Case_SLA_History__c>>();
        
        List<ASF_Case_Stage_Config__c> lstCSCRecords = new List<ASF_Case_Stage_Config__c>();
        
        // Get list of Cases for which Owner Check needs to be Executed
        for(Sobject s : newItems.values()){
            newCase = (Case) newItems.get(s.Id);
            oldCase = (Case) oldItems.get(s.Id);
            
            
            
            if(newCase.OwnerId!= null && 
               String.valueOf(newCase.OwnerId).startsWith('005')){
                   caseStageList.add(newCase.Stage__c);
                   mapIdvsExtId.put(newCase.Id,newCase.CCC_External_Id__c );
               }
        }
        
        // Get the list of Maker and Checker list from current stage CSC Record
        if(!mapIdvsExtId.isEmpty() && !caseStageList.isEmpty()){
            lstCSCRecords = [Select Id, Has_Same_Owner_Check__c,Owner_Check_Stages__c
                             FROM ASF_Case_Stage_Config__c
                             Where Parent_C3_Record__c IN : mapIdvsExtId.values() AND StageName__c IN :caseStageList
                             AND Has_Same_Owner_Check__c = true];
            if(!lstCSCRecords.isEmpty()){
                for(ASF_Case_Stage_Config__c objCSC :lstCSCRecords){
                    if(String.isNotBlank(objCSC.Owner_Check_Stages__c)){
                        lstMakerStages = objCSC.Owner_Check_Stages__c.split(',');
                    }
                }                 
            }
            
            // Get list of Case SLA History pertaining to he CSC records
            if(lstMakerStages!= null && !lstMakerStages.isEmpty()){
                List<ASF_Case_SLA_History__c> lstSLAHistory = new List<ASF_Case_SLA_History__c>();
                lstSLAHistory = [Select Id, Stage__c,Case__c,Current_Owner_Id__c FROM ASF_Case_SLA_History__c 
                                 Where Stage__c IN:lstMakerStages AND Case__c IN: mapIdvsExtId.keySet()
                                 AND Current_Owner_Id__c LIKE '005%'
                                 ORDER BY Createddate DeSC LIMIT 100];
                if(lstSLAHistory!= null && !lstSLAHistory.isEmpty()){
                    for(ASF_Case_SLA_History__c objSLA : lstSLAHistory){
                        if(mapIDvsSLAHistory== null || !mapIDvsSLAHistory.containskey(String.valueOf(objSLA.Case__c))){
                            List<ASF_Case_SLA_History__c> lstSLAHistoryInterim =  new List<ASF_Case_SLA_History__c>();
                            lstSLAHistoryInterim.add(objSLA);
                            mapIDvsSLAHistory.put(String.valueOf(objSLA.Case__c), lstSLAHistoryInterim);
                        }
                        else if(mapIDvsSLAHistory.containskey(objSLA.Case__c)){
                            List<ASF_Case_SLA_History__c> lstSLAHistoryInterim = mapIDvsSLAHistory.get(String.valueOf(objSLA.Case__c));
                            Boolean boolStageExists = false;
                            for(ASF_Case_SLA_History__c existingSLA :lstSLAHistoryInterim){
                                
                                // Checking if existing Stage__c is not present
                                if(existingSLA.Stage__c == objSLA.Stage__c){
                                    boolStageExists = true;
                                }
                            }
                            // Add the SLA only if its Stage is not existing
                            if(!boolStageExists){
                                lstSLAHistoryInterim.add(objSLA);
                                mapIDvsSLAHistory.put(String.valueOf(objSLA.Case__c), lstSLAHistoryInterim);
                            }
                        }
                    }
                }  
                // Get SLA History and Check for current owner
                system.debug('CaseTriggerHelperExt.validateOwnerCheckerStage mapIDvsSLAHistory >>'+ JSON.serializePretty(mapIDvsSLAHistory));
                for(String objCaseId : mapIDvsSLAHistory.keySet()){
                    Case newCaseSLA = (Case) newItems.get(objCaseId);
                    for(List<ASF_Case_SLA_History__c> lstSLA :mapIDvsSLAHistory.values()){
                        for(ASF_Case_SLA_History__c objSLA : lstSLA){
                            if(newCaseSLA.OwnerId == objSLA.Current_Owner_Id__c){
                                newCaseSLA.addError(System.Label.Maker_Owner_Error_Message);
                            }
                        }
                    }           
                }  
            }
        }
        //return boolSameOwnerError;
    }

    //Validation Method added for restricting non queue member to change owner from list view
    public static void caseOwnerChangeValidation(list<Case> newList,Map<Id, Case> oldMap){
        List<Id> bypassProfileId = new List<Id>();
        for(Profile profRec : [select Id, Name from profile where Name IN ('System Administrator','Salesforce API Only System Integrations')]){
            bypassProfileId.add(profRec.Id);
        }
        //Bypass owner validations for the sys admin and Integration Profiles
        if(bypassProfileId.contains(UserInfo.getProfileId()) && !Test.isRunningTest()){
            return;
        }
            
        Set<String> queueIds = new Set<String>();
        Map<String,String> GrpVsQueIds = new Map<String,String>();
        Map<String,List<String>> queVsmembersIds = new Map<String,List<String>>();

        //check if the running user has custom permission access
        Boolean hasPermission = FeatureManagement.checkPermission('Case_Ownership_Management');
        
        Set<Id> caseOwnerIdSet = new Set<Id>();
        Set<Id> oldCaseOwnerQueueIdset = new Set<Id>();
        Set<Id> newCaseOwnerQueueIdset = new Set<Id>();
        Set<Id> newCaseOwnerUserIdset = new Set<Id>();
        Map<Id, Group> queueIdNameMap = new Map<Id, Group>();
        Map<Id, user> newCaseOwnerMap;
        for(Case c : newList){
            String oldOwnerId = oldMap.get(c.Id).OwnerId;
            String newOwnerId = c.OwnerId; 
            if(oldOwnerId != newOwnerId){
                caseOwnerIdSet.add(oldOwnerId);                
            }
            if(oldOwnerId != newOwnerId && oldOwnerId.startsWith('00G')){
                oldCaseOwnerQueueIdset.add(oldOwnerId);
            }
            if(oldOwnerId != newOwnerId && newOwnerId.startsWith('00G')){
                newCaseOwnerQueueIdset.add(newOwnerId);
            }
            if(oldOwnerId != newOwnerId && !newOwnerId.startsWith('00G')){
                newCaseOwnerUserIdset.add(newOwnerId);
            }
            //ADO-131839 Making the Queue Checked Disabled for Queue to Queue Assignment
            if(c.OwnerId != oldOwnerId && oldOwnerId.startsWith('00G')
               && String.isNotBlank(newOwnerId) && !newOwnerId.startsWith('00G')){
                   queueIds.add(oldOwnerId);
               }
        }
        
        //validate change owner access
        if(!caseOwnerIdSet.isEmpty()){ 
            
            Map<Id,User> ownerMap = new Map<Id, User>([select Id, managerGroupId__c,managerId,manager.Id,manager.manager.Id,
                                                       manager.manager.manager.id,manager.manager.manager.manager.id,
                                                       manager.manager.manager.manager.manager.id 
                                                       from user where id IN: caseOwnerIdSet]);
            Map<Id, Id> caseOwnerGroupIdMap = new Map<Id, Id>(); 
            Map<Id, String> newOwnerQueueIdNameMap = new Map<Id, String>();
            Map<Id, List<Id>> oldQueueAndMemberMap = new Map<Id, List<Id>>();
            Set<Id> groupIdset = new Set<Id>();
            Map<Id, List<Id>> oldgroupAndMemberMap = new Map<Id, List<Id>>();
            newCaseOwnerMap = new Map<Id, user>([SELECT Id, Business_Unit__c, Email FROM User WHERE Id = :userInfo.getUserId() OR Id IN: newCaseOwnerUserIdset]);
             
            for(User userRec : ownerMap.values()){
                caseOwnerGroupIdMap.put(userRec.Id,userRec.managerGroupId__c);
            }
            for(Group queueRec : [select Id, name, DeveloperName, Email from group where type='Queue' and (Id IN: oldCaseOwnerQueueIdset OR Id IN :newCaseOwnerQueueIdset)]){
                if(oldCaseOwnerQueueIdset.contains(queueRec.Id)){
                    queueIdNameMap.put(queueRec.Id,queueRec);
                }
                if(newCaseOwnerQueueIdset.contains(queueRec.Id)){
                    newOwnerQueueIdNameMap.put(queueRec.Id,queueRec.DeveloperName);
                }
            }
            //Query case owner's Queue members
            for(GroupMember gmember : [Select userOrGroupId, groupId from GroupMember where 
                                       Group.Type = 'Queue' and UserOrGroupId != null and 
                                       (groupId IN :caseOwnerGroupIdMap.values() OR groupId IN :queueIdNameMap.keySet())]){

                    if(!oldQueueAndMemberMap.containsKey(gmember.GroupId))
                    	oldQueueAndMemberMap.put(gmember.GroupId,new List<Id>());
                	oldQueueAndMemberMap.get(gmember.GroupId).add(gmember.UserOrGroupId);  
                    if(((String)gmember.UserOrGroupId).startsWith('00G')){
                        groupIdset.add(gmember.UserOrGroupId);
                    }  
            } 
            //Query public group members that are part of above queues
            for(GroupMember gmember : [Select userOrGroupId, groupId from GroupMember where UserOrGroupId != null and groupId IN :groupIdset]){
                if(!oldgroupAndMemberMap.containsKey(gmember.GroupId))
                    	oldgroupAndMemberMap.put(gmember.GroupId,new List<Id>());
                	oldgroupAndMemberMap.get(gmember.GroupId).add(gmember.UserOrGroupId);  
            }
            //Add all the public group members to the map
            for(Id queueId : oldQueueAndMemberMap.keySet()){
				for(Id queueMember : oldQueueAndMemberMap.get(queueId)){
                    if(((String)queueMember).startsWith('00G')){
                        oldQueueAndMemberMap.get(queueId).addAll(oldgroupAndMemberMap.get(queueMember));
                    }
                }                
            }
      
            for(Case c : newList){
                String oldOwnerId = oldMap.get(c.Id).OwnerId; 
                String newOwnerId = c.OwnerId;
                
                if(oldOwnerId.startsWith('00G') && 
                   !(oldQueueAndMemberMap.get(oldOwnerId).contains(userInfo.getUserId()) && newOwnerId == userInfo.getUserId()) &&
                  !(queueIdNameMap.get(oldOwnerId).Email != null && queueIdNameMap.get(oldOwnerId).Email == newCaseOwnerMap.get(userInfo.getUserId()).Email && 
                   (oldQueueAndMemberMap.get(oldOwnerId).contains(newOwnerId) || (newCaseOwnerMap.get(newOwnerId)!= null && newCaseOwnerMap.get(newOwnerId).Email == queueIdNameMap.get(oldOwnerId).Email))) && 
                  !hasPermission){
                    c.addError(System.Label.ASF_Owner_Change_Access_Val_Msg);
                    
                }else if(!oldOwnerId.startsWith('00G') && !hasPermission && oldOwnerId != userInfo.getUserId() && 
                         ownerMap.get(oldOwnerId).managerId != userInfo.getUserId() &&
                         ownerMap.get(oldOwnerId).manager.manager.Id != userInfo.getUserId() && 
                         ownerMap.get(oldOwnerId).manager.manager.manager.Id != userInfo.getUserId() &&
                         ownerMap.get(oldOwnerId).manager.manager.manager.manager.Id != userInfo.getUserId() &&
                         ownerMap.get(oldOwnerId).manager.manager.manager.manager.manager.Id != userInfo.getUserId() &&
                         !(caseOwnerGroupIdMap.get(oldOwnerId) != null && oldQueueAndMemberMap.get(caseOwnerGroupIdMap.get(oldOwnerId)).contains(userInfo.getUserId()))
                        ){
                            c.addError(System.Label.ASF_Owner_Change_Access_Val_Msg);
                        }
                else if(!Test.isRunningTest() && newCaseOwnerMap.get(userInfo.getUserId()).Business_Unit__c == null){
                    c.addError(System.Label.ASF_Case_Owner_Queue_Val_Msg);
                }
                else if(!Test.isRunningTest() && newOwnerId.startsWith('00G') && !newOwnerQueueIdNameMap.get(newOwnerId).startsWith(newCaseOwnerMap.get(userInfo.getUserId()).Business_Unit__c)){
                    c.addError(System.Label.ASF_Case_Owner_Queue_Val_Msg);
                }
                else if(!Test.isRunningTest() && oldOwnerId.startsWith('00G') && !queueIdNameMap.get(oldOwnerId).DeveloperName.startsWith(newCaseOwnerMap.get(userInfo.getUserId()).Business_Unit__c)){
                    c.addError(System.Label.ASF_Case_Owner_Queue_Val_Msg);
                }
            }
        }
                
        if(!queueIds.isEmpty()){
           
            for(GroupMember gm : [SELECT GroupId, UserOrGroupId 
                                  FROM GroupMember 
                                  WHERE GroupId IN :queueIds]){
                                      String uOrGrpId = gm.UserOrGroupId;
                                      if(uOrGrpId.startsWith('00G')){
                                          GrpVsQueIds.put(uOrGrpId,gm.GroupId);             
                                      }
                                  }
            
            for(GroupMember gm : [SELECT GroupId, UserOrGroupId 
                                  FROM GroupMember 
                                  WHERE GroupId IN :GrpVsQueIds.keySet()]){
                                      String key = GrpVsQueIds.get(gm.GroupId);                
                                      if(queVsmembersIds.containsKey(key)){
                                          List<String> memberIds = queVsmembersIds.get(key);
                                          memberIds.add(gm.UserOrGroupId);
                                          queVsmembersIds.put(key,memberIds);
                                      }else{
                                          queVsmembersIds.put(key,new List<String>{gm.UserOrGroupId});
                                      }
                                  }
            
            for(Case c : newList){
                String oldOwnerId = oldMap.get(c.Id).OwnerId;
                String currentOwnerId = c.OwnerId;
                if(c.OwnerId != oldOwnerId && oldOwnerId.startsWith('00G')){
                    List<String> memberList = queVsmembersIds.get(oldOwnerId);
                    //ADO-131839 Making the Queue Checked Disabled for Bulk Upload
                    if(memberList!=null && !memberList.isEmpty() && !memberList.contains(c.OwnerId) && !hasPermission && !Test.isRunningTest() && 
                       queueIdNameMap.get(oldOwnerId).Email != newCaseOwnerMap.get(userInfo.getUserId()).Email){
                        c.addError(System.Label.Owner_Change_Validation_Message);
                    }
                }
            }
        }
    }

    public static void checkisApprovalStage(map<Id,Case> newCaseMap,map<Id,Case> oldCaseMap){
        //Virendra : 9th March 2023 : Starts Here: Check if Approval Stage and the latest Case Approval Record is Approved, Rejected or Recalled, If yes, allow navigation to steps.
        Set<Id> idsToCheckIfApprovalRequestPending = new Set<Id>();
        Set<Id> isCaseEscalationFromUI = new Set<Id>();
        
        for(Id i : newCaseMap.keyset()){
            if((oldCaseMap.get(i).Is_Approval_Stage__c  == newCaseMap.get(i).Is_Approval_Stage__c) && newCaseMap.get(i).Is_Approval_Stage__c == true ){
                // Get all the case Ids.
                idsToCheckIfApprovalRequestPending.add(newCaseMap.get(i).Id);
            }
            if((oldCaseMap.get(i).Escalated_Date_Time__c <> newCaseMap.get(i).Escalated_Date_Time__c)){
                isCaseEscalationFromUI.add(i);
            }
        }

        if(!idsToCheckIfApprovalRequestPending.isEmpty()){
            Map<Id,boolean> bCaseWithPendingApprovalRequest = CheckIfPendingApprovalRequest(idsToCheckIfApprovalRequestPending);
            for(Id i: newCaseMap.keyset()){
                if(oldCaseMap.get(i).Is_Approval_Stage__c == true &&  newCaseMap.get(i).Is_Approval_Stage__c == true ){
                    if(newCaseMap.get(i).ownerId == oldCaseMap.get(i).ownerId){
                        if(bCaseWithPendingApprovalRequest.containsKey(i)){
                            if(bCaseWithPendingApprovalRequest.get(i)){
                                if(!isCaseEscalationFromUI.contains(i)){
                                    newCaseMap.get(i).addError('Case Record is in Approval process');
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private static Map<Id,boolean> CheckIfPendingApprovalRequest(Set<Id> caseIds){
        Map<Id,boolean> mCaseIsPendingApprovalRequest = new Map<Id,Boolean>();
        List<String> nonPendingStatuses = new List<String>{'APPROVED','REJECTED','RECALLED'};
            List<ASF_Case_Approv__c> caseApprovals = [SELECT ID,SR__c, Approval_Status__c  FROM ASF_Case_Approv__c WHERE SR__c =: caseIds ORDER BY CreatedDate DESC];
        if(caseApprovals.size()>0){
            for(ASF_Case_Approv__c ca : caseApprovals){
                if(!mCaseIsPendingApprovalRequest.containsKey(ca.SR__c)){
                    mCaseIsPendingApprovalRequest.put(ca.SR__c,true);
                    if(nonPendingStatuses.contains(ca.Approval_Status__c.trim().toUpperCase())){
                        mCaseIsPendingApprovalRequest.put(ca.SR__c,false);
                    }
                }
            }
        }
        return mCaseIsPendingApprovalRequest;
    }

    //Validates whether Create Case request is invoked without CCC_External_Id__c parameter
    public static void validateIfCCCInAPIRequest(List<Case> newList, Map<Id, Case> oldMap){
            for(Case caseRec : newList){
                if((caseRec.CCC_External_Id__c == null || caseRec.CCC_External_Id__c == '') && caseRec.Technical_Source__c == 'API'){
                    caseRec.addError('Create Case request is invoked without CCC_External_Id__c parameter.');
                }
            }
    }
    
     /*
        Bot stamps account , type and sub type. but for given account , 
        type sub type may not be valid. we cannot block bot and STOP transaction.
        hence mark typeSubtypeInvalid = true.
        If this flag is enable , then users cannot edit case except API and Email user
        User will now be forced to go recategorize. 
    */
    public static void validateCCCOnUpdate(List<Case> newList, Map<Id, Case> oldMap){  
        list<Case> modifiedCases= new List<Case>();
        List<String> cccIds= new List<String>();
        List<Id> accountIds = new List<Id>();
        Map<String,ASF_Case_Category_Config__c> cccExternalIdCategoryMap = new Map<String,ASF_Case_Category_Config__c>();
        for(Case caseRec : newList){
            if(oldMap != null 
                && (caseRec.accountId != oldMap.get(caseRec.Id).accountId 
                || caseRec.assetId != oldMap.get(caseRec.Id).assetId 
                || caseRec.CCC_External_Id__c != oldMap.get(caseRec.Id).CCC_External_Id__c)){
                    modifiedCases.add(caseRec);  
                    cccIds.add(caseRec.CCC_External_Id__c);
                    if(caseRec.accountId != oldMap.get(caseRec.Id).accountId){
                        accountIds.add(caseRec.accountId);
                    }
            }
        }
        if(!cccIds.isEmpty()){ 
            ASF_CaseQueryHandler.refreshRecords = true;
            List<ASF_Case_Category_Config__c> categoryList = ASF_CaseQueryHandler.getCaseCategoryConfigs(cccIds);
            ASF_CaseQueryHandler.refreshRecords = false;
            for(ASF_Case_Category_Config__c r: categoryList){
                cccExternalIdCategoryMap.put(r.CCC_External_Id__c,r); 
            }
            Map<Id, Account> accountMap = new Map<Id, Account>();
            if(!accountIds.isEmpty()){
                accountMap = new Map<Id, Account>([Select Id, RecordType.Name from Account where Id IN :accountIds]);
            }
            //loop through Case and check if everything is ok
            for(Case caseRec : modifiedCases){
                if(cccExternalIdCategoryMap.containsKey(caseRec.CCC_External_Id__c)){
                    ASF_Case_Category_Config__c configuredCurrentCCC = cccExternalIdCategoryMap.get(caseRec.CCC_External_Id__c);
                    if(caseRec.accountId == null && configuredCurrentCCC.Only_CRN_Mandatory__c == true ){
                        caseRec.typeSubTypeMismatch__c = true;
                        caseRec.Type_Sub_Type_Mismatch_Reason__c = 'Account is Not there. But type sub type is selected which required Customer';
                    } 
                    if(caseRec.assetId == null && configuredCurrentCCC.is_FA_Mandatory__c == true ){
                        caseRec.typeSubTypeMismatch__c = true;
                        caseRec.Type_Sub_Type_Mismatch_Reason__c = 'Asset is Not there. But type sub type is selected which required Asset';
                    }  
                    if(configuredCurrentCCC.Priority__c != null && caseRec.Priority != configuredCurrentCCC.Priority__c ){
                        caseRec.typeSubTypeMismatch__c = true;
                        caseRec.Type_Sub_Type_Mismatch_Reason__c = 'Case category Configured Priority and case Priority is Mis match';
                    } 
                    if(configuredCurrentCCC.Custom_Segment__c != null && accountMap.containsKey(caseRec.AccountId) 
                        && accountMap.get(caseRec.AccountId).RecordType.Name != configuredCurrentCCC.Custom_Segment__c ){
                            caseRec.typeSubTypeMismatch__c = true; 
                            caseRec.Type_Sub_Type_Mismatch_Reason__c = 'Case category Configured Customer segment and Account record typ is Mis match';
                    } 
                }
            }
        }
    }
}