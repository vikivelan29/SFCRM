public without sharing class ASF_CaseTriggerModularHelper {
    
    /** STATIC VARIABLES to pass data between Before and After events*/
    public static ASF_CaseMovementHelper.CaseAdditionalData addlDataFromStageMovementMethods;
    public static Boolean triggerEncounteredError = false;
    public static Boolean preClosureStageAlreadyStamped = false;
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
        Map<Id, Id> caseIdToAssetIdMap = new Map<Id, Id>();
        Map<Id, Asset> assetMap = new Map<Id, Asset>();
        Map<Id, String> caseIdToCCCExtIdMap = new Map<Id, String>();
        Map<String, ASF_Case_Category_Config__c> cccExtIdToCCCMap = new Map<String, ASF_Case_Category_Config__c>();
        Boolean blankSourcePresent = false;
        ASF_CreateCaseWithTypeController.CaseDetailsWrapper objCaseDetailsWrapper;

        //Get the Issue Code for API cases and CCC External id for UI cases.
        for(Case caseRec : newList){
            if(isUpdate){
                if(caseRec.CCC_External_Id__c != oldMap.get(caseRec.Id).CCC_External_Id__c){
                    caseIdToCCCExtIdMap.put(caseRec.Id, caseRec.CCC_External_Id__c);
                }
                Map<String, Boolean> statusMap = ASF_CaseQueryHandler.getCaseStatusMap();
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
                    caseIdToAssetIdMap.put(caseRec.Id, caseRec.AssetId);
                }
            }
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
        if(!caseIdToAssetIdMap.isEmpty()){
            assetMap = new Map<Id, Asset>(ASF_CaseQueryHandler.getAssets(caseIdToAssetIdMap.values()));
        }
        
        //Fetch Source from LOBMappingDetails__mdt - beforeinsert only
        if(blankSourcePresent){
            objCaseDetailsWrapper = ASF_CreateCaseWithTypeController.getUserDetails();
        }
        
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
                if(!isUpdate){
                    // beforeinsert only
                    // If the case is Closed during creation, dont set the first stage.
                    caseRec.Stage__c = caseRec.IsClosed?caseRec.Stage__c:appliedCCC.First_Stage__c;
                    caseRec.Nature__c = String.isBlank(caseRec.Nature__c)?appliedCCC.Nature__c:caseRec.Nature__c;
                }
                caseRec.CCC_External_Id__c = appliedCCC.CCC_External_Id__c;
                caseRec.Type_Text__c = appliedCCC.Type__c;
                caseRec.Subject = 'SR - '+caseRec.Type_Text__c;
                caseRec.Sub_Type_Text__c = appliedCCC.Sub_Type__c;
                caseRec.ASF_Is_Cloneable__c = appliedCCC.ASF_Is_Cloneable__c;
                caseRec.Reopen_Days__c = appliedCCC.Reopen_Days__c;
                caseRec.Reopen_Style__c = appliedCCC.Reopen_Style__c;
                caseRec.Is_STP__c = appliedCCC.Is_STP__c;
            }

            //Populate always
            //During insert - STP+API+Attachment Status = NA => Move to next stage
            //During update - STP+API+Attachment Status = Completed => Move to next stage
            if(((!isUpdate && caseRec.Attachment_Status__c == 'NA') || 
                (isUpdate && caseRec.Attachment_Status__c != oldMap.get(caseRec.Id).Attachment_Status__c && caseRec.Attachment_Status__c == 'Completed'))
                && caseRec.Is_STP__c == true && caseRec.Technical_Source__c == 'API' ){
                caseRec.MoveToNext__c = true;
            }

            //Populate fields from Asset - beforeinsert only
            if(caseRec.AssetId != null && caseIdToAssetIdMap.containsKey(caseRec.AssetId) 
            && assetMap.containsKey(caseIdToAssetIdMap.get(caseRec.AssetId))){
                caseRec.LAN__c = assetMap.get(caseIdToAssetIdMap.get(caseRec.AssetId)).ASF_Card_or_Account_Number__c;
            }else{
                //if Asset is not present
                caseRec.LAN__c = 'NA';
            }
            //Check if the source is API - do API specific population - beforeinsert only
            if(blankSourcePresent && caseRec.Technical_Source__c == 'API'
            && String.isBlank(caseRec.Source__c) && objCaseDetailsWrapper != null){
                caseRec.Source__c = objCaseDetailsWrapper.strSource;
            }
            if(caseRec.Technical_Source__c == 'API' && String.IsBlank(caseRec.Channel__c)){
                caseRec.Channel__c = 'API';
            }
            
            //Check if source is LWC - do LWC specific population
            
            //Check if the case is cloned, - do clone specific population
            
        }
        
    }

    public static void checkAndProcessReopenCase(List<Case> newList, Map<Id, Case> oldMap) {
        List<Case> eligibleRecords = new List<Case>();
        List<String> cccExtIds = new List<String>();
        Map<String, ASF_Case_Category_Config__c> cccExtIdToCCCMap = new Map<String, ASF_Case_Category_Config__c>();
        for(Case caseRec : newList){
            //On update, if Reopened_DateTime__c changed, else no action
            if(caseRec.Reopened_DateTime__c != oldMap.get(caseRec.Id).Reopened_DateTime__c && caseRec.Reopened__c == true){
                eligibleRecords.add(caseRec);
                cccExtIds.add(caseRec.CCC_External_Id__c);
            }
        }
        if(!cccExtIds.isEmpty()){
            for(ASF_Case_Category_Config__c cccRec : ASF_CaseQueryHandler.getCaseCategoryConfigs(cccExtIds))
            {
                cccExtIdToCCCMap.put(cccRec.CCC_External_Id__c, cccRec);
            }

            for(Case caseRec : eligibleRecords){
                ASF_Case_Category_Config__c appliedCCC = cccExtIdToCCCMap.get(caseRec.CCC_External_Id__c);
                switch on caseRec.Reopen_Style__c {
                    when 'Move To First Stage' {
                        ASF_CaseMovementHelper.StageWrapper resultWrap = ASF_CaseMovementHelper.moveToBackwardStage(caseRec.Id, appliedCCC.First_Stage__c);
                        caseRec.Stage__c = resultWrap.caseToBeUpdated.Stage__c;
                        caseRec.Status = resultWrap.caseToBeUpdated.Status;
                    }
                    when 'Reopen Stage With Movement', 'Reopen Stage No Movement' {
                        //ASF_CaseMovementHelper.StageWrapper resultWrap = ASF_CaseMovementHelper.moveToNextStage(caseRec.Id);
                        ASF_CaseMovementHelper.StageWrapper resultWrap = ASF_CaseMovementHelper.moveToForwardStage(caseRec.Id, 'Reopened');
                        if(resultWrap.status == 'Success'){
                            Map<String, Object> populatedFieldMap = resultWrap.caseToBeUpdated.getPopulatedFieldsAsMap();
                            for(String fieldName : populatedFieldMap.keySet()){
                                caseRec.put(fieldName, resultWrap.caseToBeUpdated.get(fieldName));
                            }
                            // caseRec.Stage__c = resultWrap.caseToBeUpdated.Stage__c;
                            // caseRec.Status = resultWrap.caseToBeUpdated.Status;
                            addlDataFromStageMovementMethods = resultWrap.data;
                        }else{
                            caseRec.addError(resultWrap.errorMessage);
                        }
                    }
                    when else {
                        
                    }
                }
            }
        }
    }
    
    //Method checks whether move to next stage is changed to true, if yes, calls the right modular methods to process it
    public static void checkAndProcessMoveToNextStage(List<Case> newList, Map<Id, Case> oldMap){
        Boolean isUpdate = oldMap!=null?true:false;
        List<Case> eligibleRecords = new List<Case>();
        Boolean supressErrors = (newList[0].Technical_Source__c == 'API' && oldMap == null)?true:false;
        for(Case caseRec : newList){
            //If update, is MoveToNext changed to true, else if insert, MoveToNext is true
            if(((isUpdate && caseRec.MoveToNext__c != oldMap.get(caseRec.Id).MoveToNext__c) || !isUpdate)
               && caseRec.MoveToNext__c == true){
                   eligibleRecords.add(caseRec);
               }
        }
        
        if(!eligibleRecords.isEmpty()){
            for(Case caseRec : eligibleRecords){
                //invoke moveToNextStage of ASF_CaseMovementHelper
                //TODO - pass another flag to this method to skip the current stage validation if Insert + movetonextstage=true
                ASF_CaseMovementHelper.StageWrapper resultWrap = ASF_CaseMovementHelper.moveToNextStage(caseRec.Id);
                if(resultWrap.status == 'Success'){
                    addlDataFromStageMovementMethods = resultWrap.data;
                    if(isUpdate){
                        caseRec.Previous_Stage__c = oldMap.get(caseRec.Id).Stage__c;
                        Map<String, Object> populatedFieldMap = resultWrap.caseToBeUpdated.getPopulatedFieldsAsMap();
                        for(String fieldName : populatedFieldMap.keySet()){
                            caseRec.put(fieldName, resultWrap.caseToBeUpdated.get(fieldName));
                        }
                    }else{
                        //TODO - Skip before trigger
                        resultWrap.caseToBeUpdated.MoveToNext__c = false;
                        resultWrap.caseToBeUpdated.Previous_Stage__c = caseRec.Stage__c;//Current new stage becomes previous stage
                        try{
                            update resultWrap.caseToBeUpdated;
                        }catch(Exception e){
                            if(supressErrors){
                                triggerEncounteredError = true;
                            }
                        }
                    }
                    
                }else{
                    if(supressErrors){
                        triggerEncounteredError = true;
                    }else{
                        eligibleRecords[0].addError(resultWrap.errorMessage);
                    }
                }
            }
        }
    }
    
    //Method checks whether stage is changed(Forward stage movement) or pending clarification = true with stage movement(backward) and process it
    //skip when case is being reopened
    //skip when case is being closed
    public static void checkAndProcessManualStageMovement(List<Case> newList, Map<Id, Case> oldMap) {
        List<Case> eligibleRecords = new List<Case>();
        String movement = '';
        for(Case caseRec : newList){
            //1. This is not moveToNextStage update
            //2. MoveToNext = false - addl check
            //3. Case is not being reopened
            //4. Case is not being rejected
            //5. If stage updated
            if((caseRec.MoveToNext__c == oldMap.get(caseRec.Id).MoveToNext__c 
                && caseRec.MoveToNext__c == false)
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
                    wrapToReturn = ASF_CaseMovementHelper.moveToForwardStage(caseRec.Id, caseRec.Stage__c);
                    if(wrapToReturn.status == 'Success'){
                        ASF_CaseTriggerModularHelper.addlDataFromStageMovementMethods = wrapToReturn.data;
                        //Skip before and after trigger
                        //update wrapToReturn.caseToBeUpdated;
                        caseRec.Previous_Stage__c = oldMap.get(caseRec.Id).Stage__c;
                        Map<String, Object> populatedFieldMap = wrapToReturn.caseToBeUpdated.getPopulatedFieldsAsMap();
                        for(String fieldName : populatedFieldMap.keySet()){
                            caseRec.put(fieldName, wrapToReturn.caseToBeUpdated.get(fieldName));
                        }
                    }
                }else{
                    wrapToReturn = ASF_CaseMovementHelper.moveToBackwardStage(caseRec.Id, caseRec.Stage__c);
                    if(wrapToReturn.status == 'Success'){
                        //Skip before and after trigger
                        // wrapToReturn.caseToBeUpdated.Pending_Clarification__c = true;
                        // update wrapToReturn.caseToBeUpdated;
                        caseRec.Previous_Stage__c = oldMap.get(caseRec.Id).Stage__c;
                        Map<String, Object> populatedFieldMap = wrapToReturn.caseToBeUpdated.getPopulatedFieldsAsMap();
                        for(String fieldName : populatedFieldMap.keySet()){
                            caseRec.put(fieldName, wrapToReturn.caseToBeUpdated.get(fieldName));
                        }
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
                System.debug('ownerInfo --> '+ownerInfo);
                Case caseObj = new Case(Id = caseRec.Id);
                caseObj.OwnerId = ownerInfo.defaultOwnerId;
                if(triggerEncounteredError){
                    caseObj.OwnerId = ownerInfo.defaultErrorOwnerId;
                }
                casesToUpdate.add(caseObj);
            }
        }
        ASF_TriggerSkipperUtility.markTriggerRun('Case');
        update casesToUpdate;
        triggerEncounteredError = false;
    }
    
    //Creates Checklist, Tasks, Approvals, Integrations
    public static void checkAndInsertPeripheralRecords(List<Case> newList, Map<Id, Case> oldMap) {
        List<ASF_Case_Approv__c> approvalsToInsert;
        List<ASF_Checklist__c> checklistToInsert;
        List<Task> tasksToInsert;
        List<ASF_Integration__c> allIntegrations;
        Boolean supressErrors = (newList[0].Technical_Source__c == 'API' && oldMap == null)?true:false;
        try{
            if(ASF_CaseTriggerModularHelper.addlDataFromStageMovementMethods != null){
                approvalsToInsert = ASF_CaseTriggerModularHelper.addlDataFromStageMovementMethods.approvalsToInsert;
                checklistToInsert = ASF_CaseTriggerModularHelper.addlDataFromStageMovementMethods.checklistToInsert;
                tasksToInsert = ASF_CaseTriggerModularHelper.addlDataFromStageMovementMethods.tasksToInsert;
                allIntegrations = ASF_CaseTriggerModularHelper.addlDataFromStageMovementMethods.allIntegrations;
            }else{
                Case currentCaseRec = newList[0];
                ASF_CaseMovementHelper.CaseAdditionalData dataWrapper = ASF_CaseMovementHelper.getCaseAdditionalDataForNextStage(currentCaseRec, newList[0].Stage__c);
                approvalsToInsert = dataWrapper.approvalsToInsert;
                checklistToInsert = dataWrapper.checklistToInsert;
                tasksToInsert = dataWrapper.tasksToInsert;
                allIntegrations = dataWrapper.allIntegrations;
            }
            
            if(approvalsToInsert != null){
                insert approvalsToInsert;
            }
            if(checklistToInsert != null){
                insert checklistToInsert;
            }
            if(tasksToInsert != null){
                insert tasksToInsert;
            }
            
            ASF_CaseTriggerModularHelper.addlDataFromStageMovementMethods = null;
        }catch(Exception e){
            if(supressErrors){
                triggerEncounteredError = true;
            }else{
                newList[0].addError(e.getMessage());
            }
        }
    }

    public static void onCreateCloseServiceRequest(List<Case> newList){
        List<Case> onCreateCloseCases = new List<Case>();
        
        for(case c : newList){
            if(c.OnCreateCloseSR__c){
                c.Status = 'Resolved';
                c.Stage__c = 'Resolved';
            }
        }
    }
    public static void rejectFrameworkCaseBeforeUpdate(List<Case> newList,Map<Id,Case> oldMap){
        List<Case> eligibleRecords = new List<Case>();
        for(Case caseRec : newList){
            if(caseRec.Reject_Case__c != oldMap.get(caseRec.Id).Reject_Case__c && caseRec.Reject_Case__c == true){
                eligibleRecords.add(caseRec);
            }
        }
        if(!eligibleRecords.isEmpty()){
            for(Case caseRec : eligibleRecords){
                ASF_CaseMovementHelper.StageWrapper resultWrap = ASF_CaseMovementHelper.moveToForwardStage(caseRec.Id, 'Unresolved');
                System.debug(resultWrap);
                caseRec.Stage__c = resultWrap.caseToBeUpdated.Stage__c;
                caseRec.Status = resultWrap.caseToBeUpdated.Status!=null?resultWrap.caseToBeUpdated.Status:'Unresolved';
            }
        }
    }
    public static void rejectFrameworkCaseAfterUpdate(Map<Id,Case> newMap, Map<Id,Case> oldMap){
        Set<Id> rejectedCaseIds = new Set<Id>();
        for(Case c : newMap.values()){
            if(c.Reject_Case__c != oldMap.get(c.Id).Reject_Case__c && c.Reject_Case__c == true){
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
            c.Rejected_Reason__c = newMap.get(c.Id).Rejected_Reason__c;
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
    

    /** OLD METHODS STARTS- NEEDS TO BE OPTIMIZED */

    public static void validateCloseCase(Map<Id, sObject> oldItems,map<Id, sObject> newItems){
        Boolean boolOwnerError = false;
        
        for(Sobject s : newItems.values()){
            Case objNewCase = (Case) newItems.get(s.Id);
            Case oldCase = (Case) oldItems.get(s.Id);
            System.debug(objNewCase.Reopened_DateTime__c +'--'+oldCase.Reopened_DateTime__c);
            //If case is being reopened, allow it.
            if(objNewCase.Reopened_DateTime__c != oldCase.Reopened_DateTime__c && objNewCase.Reopened__c == true){
                return;
            }
            
            if (objNewCase.IsClosed == true && objNewCase.OnCreateCloseSR__c == false && !test.isRunningTest()){
                if(String.isNotBlank(objNewCase.Bulk_Action__c)){
                    objNewCase.addError('FIELD_CUSTOM_VALIDATION_EXCEPTION '+ System.label.Case_Closed_Validation_Message);
                }
                else{
                    objNewCase.addError(System.label.Case_Closed_Validation_Message);
                }
                boolOwnerError = true;
            }
        }
        //return boolOwnerError;
    }

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
        Set<String> queueIds = new Set<String>();
        Map<String,String> GrpVsQueIds = new Map<String,String>();
        Map<String,List<String>> queVsmembersIds = new Map<String,List<String>>();
        for(Case c : newList){
            String oldOwnerId = oldMap.get(c.Id).OwnerId;
            String newOwnerId = c.OwnerId; 
            //ADO-131839 Making the Queue Checked Disabled for Queue to Queue Assignment
            if(c.OwnerId != oldOwnerId && oldOwnerId.startsWith('00G')
               && String.isNotBlank(newOwnerId) && !newOwnerId.startsWith('00G')){
                   queueIds.add(oldOwnerId);
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
                    if(!memberList.isEmpty() && !memberList.contains(c.OwnerId)){
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

    /*
    public static void lwcCaseValidationBeforeInsertUpdate(list<Case> newCases,list<Case> oldCases){
        
        //Before insert evaluate validation rules
        list<string> externalIdList = new list<string>();
        list<string> caseStageList = new list<String>();
        map<Id,Case> newCasesMap = new map<Id,case>();
        list<Id> caseBranchList = new list<Id>();
        
        map<Id,Case> newCasesListMap = new map<Id,Case>(newCases);
        map<Id,Case> oldCasesListMap = new map<Id,Case>(oldCases);
        
        
        
        //FOr before update
        if(oldCases != null){
            for( case c:newCases){
                if(caseBackStageMovement((case)oldCasesListMap.get(c.id),(string)c.get('Stage__c')) || isCaseRevisitingStage((case)oldCasesListMap.get(c.id),(string)newCasesListMap.get(c.Id).Stage__c)){
                    continue;
                }
                if(c.CCC_External_Id__c != null && oldCasesListMap.containsKey(c.Id) && newCasesListMap.containsKey(c.Id) && newCasesListMap.get(c.Id).Stage__c != oldCasesListMap.get(c.Id).Stage__c){
                    externalIdList.add(c.CCC_External_Id__c);
                }
                
                if(c.Stage__c != null && oldCasesListMap.containsKey(c.Id) && newCasesListMap.containsKey(c.Id) && newCasesListMap.get(c.Id).Stage__c != oldCasesListMap.get(c.Id).Stage__c){
                    caseStageList.add(c.Stage__c);
                }
                for(case c1: newCases){
                    newCasesMap.put(c1.Id,c1);
                }
            }            
        }else{
            //for before insert
            for( case c:newCases){
                if(c.CCC_External_Id__c != null){
                    externalIdList.add(c.CCC_External_Id__c);
                }
                
                if(c.Stage__c != null){
                    caseStageList.add(c.Stage__c);
                }
            }
        }
        
        if(!caseStageList.isEmpty()){
            //Get all validation rules
            list<ASF_Case_Rule__c> caseValidationRules = [SELECT Id,Order__c,Type__c,C3ExternalId__c,Stage_Name__c,Validation_Message__c,Case_Stage_Config__r.Query_Fields__c,Logical_Condition__c,(SELECT Id,Field_Api_Name__c,Operator__c,Value__c,Data_Type__c,Number__c FROM Case_Rule_Entries__r) FROM ASF_Case_Rule__c WHERE C3ExternalId__c IN :externalIdList AND Stage_Name__c IN :caseStageList AND Type__c = 'Validation'];
            map<string,list<ASF_Case_Rule__c>> stageRulesMap = new map<string,list<ASF_Case_Rule__c>>();
            for(ASF_Case_Rule__c cr: caseValidationRules){
                string mapKey = cr.C3ExternalId__c + cr.Stage_Name__c;
                if(stageRulesMap.containsKey(mapKey)){
                    stageRulesMap.get(mapKey).add(cr);
                }else{
                    list<ASF_Case_Rule__c> tempRules = new list<ASF_Case_Rule__c>();
                    tempRules.add(cr);
                    stageRulesMap.put(mapKey,tempRules);
                }
            }
            //diff logic for before and before update
            if(oldCases != null){
                for(Case c: newCases){
                    string caseMapKey = c.CCC_External_Id__c + c.Stage__c;
                    // if(stageRulesMap.containsKey(caseMapKey) && c.Technical_Source__c == 'LWC'){
                    if(stageRulesMap.containsKey(caseMapKey)){
                        list<ASF_Case_Rule__c> rulesToBeEvaluated = stageRulesMap.get(caseMapKey);
                        string queryToBeRetrieved = 'Select '+(rulesToBeEvaluated[0].Case_Stage_Config__r.Query_Fields__c)+' FROM Case WHERE Id = \''+String.valueOf(c.Id)+'\'';
                        Case evaludationCaseRecord = (case)Database.Query(queryToBeRetrieved);
                        for(ASF_Case_Rule__c vcr: rulesToBeEvaluated){
                            
                            Boolean result = evaluateCondition(vcr.Logical_Condition__c,vcr.Case_Rule_Entries__r,evaludationCaseRecord);
                            if(result == true){
                                newCasesMap.get(c.id).addError(vcr.Validation_Message__c);
                            }
                        }
                    }
                }
            }else{
                for(Case c: newCases){
                    string caseMapKey = c.CCC_External_Id__c + c.Stage__c;
                    // if(stageRulesMap.containsKey(caseMapKey) && c.Technical_Source__c == 'LWC'){
                    if(stageRulesMap.containsKey(caseMapKey)){
                        list<ASF_Case_Rule__c> rulesToBeEvaluated = stageRulesMap.get(caseMapKey);
                        string queryToBeRetrieved = 'Select '+(rulesToBeEvaluated[0].Case_Stage_Config__r.Query_Fields__c)+' FROM Case WHERE Id = \''+String.valueOf(c.Id)+'\'';
                        Case evaludationCaseRecord = (case)Database.Query(queryToBeRetrieved);
                        for(ASF_Case_Rule__c vcr: rulesToBeEvaluated){
                            
                            Boolean result = evaluateCondition(vcr.Logical_Condition__c,vcr.Case_Rule_Entries__r,evaludationCaseRecord);
                            if(result == true){
                                c.addError(vcr.Validation_Message__c);
                            }
                        }
                    }
                }
            }
        }
    }
    */

    /*
    public static void validateUserForAssignMe(Map<Id,Case> newCases,Map<Id,Case> oldCases){
        
        User userRecord;
        Boolean isOwnerDifferent = false;
        String loggedInUser = UserInfo.getUserId();
        
        Set<Id> ownerIds = new Set<Id>();
        Id newUserId;
        Boolean hasDifferentOwnerIds = false;
        
        
        for(Id i: newCases.keyset()){
            if(newCases.get(i).OwnerUser__c == null && newCases.get(i).Assign_Me_list_button__c == true){
                newcases.get(i).addError('You need to select a user');
            }
            if(String.valueOf(oldCases.get(i).OwnerId).startsWith('005') && newCases.get(i).Assign_Me_list_button__c == true){
                newCases.get(i).addError(System.label.Change_Owner_V2_User_to_user_vaiidation);
            }
            if(newCases.get(i).OwnerUser__c != null && newCases.get(i).OwnerUser__c != oldCases.get(i).OwnerId && String.valueOf(oldCases.get(i).OwnerId).startsWith('00G') && newCases.get(i).Stage__c == oldCases.get(i).Stage__c && String.valueOf(newCases.get(i).OwnerUser__c).StartsWith('005') && newCases.get(i).Assign_Me_list_button__c == true ){
                ownerIds.add(oldCases.get(i).OwnerId);
                newUserId = newCases.get(i).OwnerUser__c;
            }
        }
        
        if(ownerIds.size() == 0)
            return;
        if (ownerIds.size() > 1) {
            // hasDifferentOwnerIds = true;
            for(Id i: ownerIds){
                newCases.get(i).addError(system.Label.Change_Owner_v2_different_owners_error);
            }
        }else{
            //Check if the selected cases is of Queue
            if(String.valueOf(new list<Id>(ownerIds).get(0)).startsWith('00G')){
                
                if(!checkUserQueueAccess(UserInfo.getUserId(),new list<Id>(ownerIds))){
                    for(Id i: newCases.keyset()){
                        newCases.get(i).addError(System.Label.Change_Owner_V2_current_user_not_part_of_queue);
                    }
                }
                
                
                if(!checkUserQueueAccess(newUserId,new list<Id>(ownerIds))){
                    for(Id i: newCases.keyset()){
                        newCases.get(i).addError(System.Label.Change_owner_v2_target_user_not_part_of_queue);
                    }
                }
                //Assign the OwnerUser to OwnerId
                
                for(Id i: newCases.keyset()){
                    newCases.get(i).OwnerId = newCases.get(i).OwnerUser__c;
                    newCases.get(i).Assign_Me_list_button__c = false;
                    newCases.get(i).OwnerUser__c = null;
                }
                
                
                
                
            }else{
                //throw error for the case
                for(Id i: newCases.keyset()){
                    newCases.get(i).addError(System.label.Change_owner_v2_no_access );
                    newCases.get(i).Assign_Me_list_button__c = false;
                    newCases.get(i).OwnerUser__c = null;
                }
                
            }
        }
    }
    */
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
    
    public static void validateIfCCCInAPIRequest(List<Case> newList){
        for(Case c : newList){
            if((c.CCC_External_Id__c == null || c.CCC_External_Id__c == '') && c.Technical_Source__c == 'API'){
                 c.addError('Create Case request is invoked without CCC_External_Id__c parameter.');
            }
        }
    }
}
