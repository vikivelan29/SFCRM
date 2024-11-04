/**
* @description       : 
 * @author            : rsinghnagar@salesforce.com
* @group             : 
* @last modified on  : 10-10-2024
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
* Modifications Log
* Ver   Date         Author                       Modification
 * 1.0   04-24-2024   rsinghnagar@salesforce.com   Initial Version
**/
@SuppressWarnings('PMD.MethodNamingConventions, PMD.LocalVariableNamingConventions, PMD.VariableNamingConventions')
public without sharing class ASF_CaseTriggerModularHelper {
    
    /** STATIC VARIABLES to pass data between Before and After events*/
    public static Map<Id, ASF_CaseMovementHelper.CaseAdditionalData> addlDataFromStageMovementMethods = new Map<Id, ASF_CaseMovementHelper.CaseAdditionalData>();
    public static Map<Id, Boolean> triggerEncounteredError = new Map<Id, Boolean>();
    private static Map<Id, Case> caseFinalDMLMap = new Map<Id, Case>();
    public static Map<Id, Case> getCaseFinalDMLMap(){
        return caseFinalDMLMap;
    }
    private static Map<Id, Boolean> supressErrors = new Map<Id, Boolean>();
    public static Boolean isRecursiveUpdate = false;
    public static Boolean preClosureStageAlreadyStamped = false;
    private static Map<Id, Set<String>> skipperFlagMap = new Map<Id, Set<String>>();
    public static Map<Id, Set<String>> getSkipperFlagMap() {
        return skipperFlagMap;
    }
    public static String relObjName = '';
    /**
    * @Function - setSkipperFlags
    * @Description - method to be invoked at the beginning and end of the BEFORE triggers
    * This will set the flags set to skip per case, respective methods can just check whether their skipper flag is present in the map or not.
    */
    public static void setSkipperFlags(List<Case> newList, Map<Id, Case> oldMap) {
        skipperFlagMap = new Map<Id, Set<String>>();
        Boolean isInsert = oldMap == null ? true : false;
        String cccId = '';
        if(isInsert){
            for(Case caseRec : newList){
                if(caseRec.CCC_External_Id__c != null && caseRec.CCC_External_Id__c != ''){
                   cccId = caseRec.CCC_External_Id__c;
                   break; 
                }
            }
            if(String.isNotBlank(cccId)){
                relObjName = ASF_GetCaseRelatedDetails.getCaseRelatedObjName(cccId);
            }
        }
        for(Case caseRec : newList){
            system.debug('set flag--'+caseRec.Feature_Skipper_Flag__c);
                        if(String.isNotBlank(caseRec.Feature_Skipper_Flag__c) 
               && (oldMap == null || caseRec.Feature_Skipper_Flag__c != oldMap.get(caseRec.Id).Feature_Skipper_Flag__c)){
                   //if insert or the flag field is updated
                   Set<String> skippedItems = new Set<String>(caseRec.Feature_Skipper_Flag__c.split(';'));
                   if(oldMap != null){
                       skipperFlagMap.put(caseRec.Id, skippedItems);
                   }else if(String.isNotBlank(relObjName)){
                       Id fieldValue = (Id)caseRec.get(relObjName);
            		   skipperFlagMap.put(fieldValue, skippedItems);
                   }
                   caseRec.Feature_Skipper_Flag__c = '';
               }
        }
    }
    
     /**
    * @Function - setManualSkipperFlags
    * @Description - method to be invoked by the BU specific classes if skipper flag needs to be set
    * @param - recIdToSkipperFlag - Key as CaseId or caseDetail Id and value as skipperFlags
    * @param - caseDetRecName - pass value to this variable only if you are calling the method from before insert where 
    * 							recIdToSkipperFlag key is the caseDetail Id
    * This will set the flags set to skip per case, respective methods can just check whether their skipper flag is present in the map or not.
    */
    public static void setManualSkipperFlags(Map<Id, Set<String>> recIdToSkipperFlag, String caseDetRecName) {
        relObjName = caseDetRecName != null ? caseDetRecName : '';
        for(Id recId : recIdToSkipperFlag.keySet()){
            if(!skipperFlagMap.containsKey(recId)){
                skipperFlagMap.put(recId, recIdToSkipperFlag.get(recId));
            }else{
                Set<String> currentSkippers = skipperFlagMap.get(recId);
                currentSkippers.addAll(recIdToSkipperFlag.get(recId));
                skipperFlagMap.put(recId, currentSkippers);
        }
    }
    }
    
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
        List<Id> caseIndexToAssetIdMap = new List<Id>();
        Map<Id, Asset> assetMap = new Map<Id, Asset>();
        List<String> cccExternalIds = new List<String>();
        Map<String, ASF_Case_Category_Config__c> cccExtIdToCCCMap = new Map<String, ASF_Case_Category_Config__c>();
        Set<Id> casesChangingRT = new Set<Id>();
        ASF_CreateCaseWithTypeController.CaseDetailsWrapper objCaseDetailsWrapper;
        Map<String, Boolean> statusMap = new Map<String, Boolean>();
        
        Map<Id, ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo> ownerInfo  = new Map<Id, ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo>();
        
        Id interactionRecTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Interaction').getRecordTypeId();
        Id frameworkRecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
        
        
        if(isUpdate){
            statusMap = ASF_CaseQueryHandler.getCaseStatusMap();
        }
        //Get the Issue Code for API cases and CCC External id for UI cases.
        //Integer index = 0;
        for(Case caseRec : newList){
            
            if(isUpdate){
                if(caseRec.RecordTypeId != oldMap.get(caseRec.Id).RecordTypeId && caseRec.RecordTypeId == frameworkRecordTypeId){
                    casesChangingRT.add(caseRec.Id);
                }
                if((caseRec.CCC_External_Id__c != oldMap.get(caseRec.Id).CCC_External_Id__c 
                    && caseRec.CCC_External_Id__c != null) || 
                   ((caseRec.Recategorisation_Date__c == oldMap.get(caseRec.Id).Recategorisation_Date__c) && 
                    ((caseRec.AccountId != oldMap.get(caseRec.Id).AccountId) || 
                     (caseRec.AssetId != oldMap.get(caseRec.Id).AssetID)))){
                         //Only in case of interaction to framework conversion
                         //or recategorization
                         //or Reparenting Account
                         //or Reparenting Asset
                         cccExternalIds.add(caseRec.CCC_External_Id__c);
                     }
                
                if(statusMap.get(caseRec.Stage__c) != statusMap.get(oldMap.get(caseRec.Id).Stage__c) && statusMap.get(caseRec.Stage__c) == true && caseRec.First_Case_Closed_Date__c == null){
                    caseRec.First_Case_Closed_Date__c = System.now();
                }
            }else{
                if((caseRec.Technical_Source__c == 'LWC' || caseRec.Technical_Source__c == 'API') && String.isNotBlank(caseRec.CCC_External_Id__c)){
                    cccExternalIds.add(caseRec.CCC_External_Id__c);
                }
                
                //Check if any Case from API has blank Source, needs to be defaulted then.
                /* SP  if(!blankSourcePresent && String.isBlank(caseRec.Source__c)){
blankSourcePresent = true;
} */
                //Collect the Asset Id, to prepopulate case fields from Asset record.
                if(caseRec.AssetId != null){
                    caseIndexToAssetIdMap.add(caseRec.AssetId);
                }
            }
            //index++;
        }
        //Fetch all types of data sources before entering Case loop.
        // 1. CCC, 2. Asset, 3. LOBMappingDetails__mdt
        if(!cccExternalIds.isEmpty()){
            //Fetch CCC
            for(ASF_Case_Category_Config__c cccRec : ASF_CaseQueryHandler.getCaseCategoryConfigs(cccExternalIds))
            {
                if(cccExternalIds.contains(cccRec.CCC_External_Id__c)){
                    cccExtIdToCCCMap.put(cccRec.CCC_External_Id__c, cccRec);
                }
            }
        }
        
        //Fetch Asset - beforeinsert only
        if(!caseIndexToAssetIdMap.isEmpty()){
            assetMap = new Map<Id, Asset>(ASF_CaseQueryHandler.getAssets(caseIndexToAssetIdMap));
        }
        
        //Fetch Source from LOBMappingDetails__mdt - beforeinsert only
        //SP if(blankSourcePresent){
        objCaseDetailsWrapper = ASF_CreateCaseWithTypeController.getUserDetails();
        //}
        
        //index = 0;
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

                //If the incoming subject of the case is not blank, system will no longer overwrite it, 
                //irrespective of origin/source of the case. PR970457-1880
                if(String.isBlank(caseRec.Subject)){
                    caseRec.Subject = 'Case - '+appliedCCC.Type__c;
                }
                if(!isUpdate || (isUpdate && caseRec.CCC_External_Id__c != oldMap.get(caseRec.Id).CCC_External_Id__c)){
            
                    //Fill all common fields irrespective of source
                    caseRec.Nature__c = String.isBlank(caseRec.Nature__c)?appliedCCC.Nature__c:caseRec.Nature__c;
                    
                    // EXECUTE ONLY WHEN RECORD TYPE IS CHANGED TO FRAMEWORK.
                    if(frameworkRecordTypeId == caseRec.RecordTypeId){
                        caseRec.Stage__c = appliedCCC.First_Stage__c;
                    }
                    caseRec.CCC_External_Id__c = appliedCCC.CCC_External_Id__c;
                    // VIRENDRA - 24 JUN 2024 - ADDED IGMS_Complaint_Type_Code__c  to CaseRecord.
                    caseRec.IGMS_Complaint_Type_Code__c = appliedCCC.IGMS_Code__c;
                    caseRec.Type_Text__c = appliedCCC.Type__c;
                    caseRec.Sub_Type_Text__c = appliedCCC.Sub_Type__c;
                    caseRec.ASF_Is_Cloneable__c = appliedCCC.ASF_Is_Cloneable__c;
                    caseRec.Reopen_Days__c = appliedCCC.Reopen_Days__c;
                    caseRec.Reopen_Style__c = appliedCCC.Reopen_Style__c;
                    // BYPASS THE LOGIC TO STAMP STP FLAG FROM CCC FOR ABSLI BU.
                    if(!caseRec.Is_STP__c && caseRec.Technical_Source__c == 'API' && caseRec.Business_Unit__c != ASF_Constants.ABSLI_BU){
                        caseRec.Is_STP__c = appliedCCC.Is_STP__c;   
                    }
                    caseRec.Multiple_Child_Details__c = appliedCCC.Multiple_Child_Details__c;
                    caseRec.Is_Recategorise_Allowed__c = appliedCCC.Is_Recategorise_Allowed__c;
                    caseRec.Allow_file_upload__c = appliedCCC.Allow_file_upload__c;
                    caseRec.Run_Assignment_Rule_on_Bulk_Create__c = appliedCCC.Run_Assignment_Rule_on_Bulk_Create__c;
                }
                if((!isUpdate) || (isUpdate && oldMap.get(caseRec.Id).Categorization_Date__c == null)){
                    caseRec.Categorization_Date__c = system.now();     
                }
            }else if(isUpdate && casesChangingRT.contains(caseRec.Id)){
                //error out cases with wrong Issue Code while converting from preframework to framework
                //during case creation in framework, if wrong issue code is provided(some api), allow. 
                //Other mechanism of recategorization will allow to correctly tag issue code
                caseRec.addError(Label.ASF_ErrorMsgForWrongIssueCode);
                break;
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
                if(caseRec.AssetId != null && assetMap.containsKey(caseRec.AssetId)){
                    caseRec.LAN__c = assetMap.get(caseRec.AssetId).LAN__c;
                }else{
                    //if Asset is not present
                    caseRec.LAN__c = 'NA';
                }
            }
            //Check if the source is API - do API specific population - beforeinsert only
            if(caseRec.Technical_Source__c == 'API'
               && String.isBlank(caseRec.Source__c) && objCaseDetailsWrapper != null){
                   caseRec.Source__c = objCaseDetailsWrapper.strSource;
               }
            if(caseRec.Technical_Source__c == 'API' && String.isBlank(caseRec.Channel__c)){
                caseRec.Channel__c = 'API';
            }
            //index++;
        }
    }
    /****************************************************************************************************************
* @Function - populateCaseDetailFromBulk
* @param newList -  list of cases from trigger.new.
* @param oldMap -  map of cases from trigger.oldMap.
* @return - void .
* @Description - Invoked from AfterInsert & AfterUpdate method, this method populates related case detail fields during bulk csv upload
*****************************************************************************************************************/
    public static void populateCaseDetailFromBulk(Map<Id, Case> newMap, Map<Id, Case> oldMap){
        List<Case> eligibleCases = new List<Case>();
        String relObjectName;
        for(Case caseRec : newMap.values()){
            if(ASF_BulkCaseProcessorUtility.isBulkProcessing && String.isNotBlank(caseRec.Bulk_CaseDetail_JSON__c)
               && (oldMap == null || 
                   (oldMap != null && oldMap.get(caseRec.Id).Bulk_CaseDetail_JSON__c != caseRec.Bulk_CaseDetail_JSON__c))){
                   eligibleCases.add(caseRec);
               }
        }
        if(!eligibleCases.isEmpty()){
            List<sObject> relObjectList = new List<sObject>();
            Map<Id, Case> sObjectIdToCaseMap = new Map<Id, Case>();
            for(Case caseRec : eligibleCases){
                Map<String,Object> relObj = (Map<String,Object>) JSON.deserializeUntyped(caseRec.Bulk_CaseDetail_JSON__c);
                relObjectName = (String)((Map<String, Object>) relObj.get('attributes')).get('type');
                SObject relRec = (SObject) Schema.getGlobalDescribe().get(relObjectName).newSObject();
                relRec.put('Id',caseRec.get(relObjectName));
                for (String field : relObj.keySet()) {
                    system.debug('val--'+relObj.get(field)+'--field--'+field);
                    if(field != 'attributes'){
                        relRec.put(field, relObj.get(field));
                    }
                } 
                relObjectList.add(relRec);
                sObjectIdToCaseMap.put((String)relRec.get('Id'), caseRec);
            }
            Database.SaveResult[] saveResults = Database.update(relObjectList, false); 
            //Check each SaveResult for errors and add errors to corresponding records
            for (Integer i = 0; i < saveResults.size(); i++) {
                if (!saveResults.get(i).isSuccess()) {
                    Case failedRec = sObjectIdToCaseMap.get((String)relObjectList[i].get('Id'));
                    failedRec.addError('Error on update: ' + saveResults.get(i).getErrors()[0].getMessage());
                }           
            } 
        }
    }
    
    public static void assignCasesInFirstStageAfterConversion(List<Case> newList, Map<Id, Case> oldMap) {
        Boolean isUpdate = oldMap!=null?true:false;
        Map<Id,String> nextStageMap = new Map<Id,String>();
        List<String> cccExternalIds = new List<String>();
        Map<String, ASF_Case_Category_Config__c> cccExtIdToCCCMap = new Map<String, ASF_Case_Category_Config__c>();
        
        for(Case caseRec : newList){
            nextStageMap.put(caseRec.Id,caseRec.Stage__c);
            cccExternalIds.add(caseRec.CCC_External_Id__c);
        }
        
        if(!cccExternalIds.isEmpty()){
            //Fetch CCC
            for(ASF_Case_Category_Config__c cccRec : ASF_CaseQueryHandler.getCaseCategoryConfigs(cccExternalIds))
            {
                if(cccExternalIds.contains(cccRec.CCC_External_Id__c)){
                    cccExtIdToCCCMap.put(cccRec.CCC_External_Id__c, cccRec);
                }
            }
        }
        //VIRENDRA - MOVED QUEUE Assignment Logic below.
        if(isUpdate){
            List<Case> eligibleCaseList = new List<Case>();
            for(Case caseRec : newList){
                // Do not change the owner for certain CCC when recategorized
                if(!(ASF_RecategoriseCaseController.requestFromRecat && cccExtIdToCCCMap.get(caseRec.CCC_External_Id__c).No_Owner_Change_on_Recat__c)){
                    eligibleCaseList.add(caseRec);
                }
            }
            Map<Id, ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo> ownerInfos = ASF_CaseMovementHelper.preFrameworkToFrameworkMovementAssignment(eligibleCaseList,isUpdate,oldMap,nextStageMap);
            for(Case caseRec : newList){
                if(ownerInfos.containsKey(caseRec.Id)){
                    ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo resultWrap = ownerInfos.get(caseRec.Id);
                    ASF_Case_Category_Config__c appliedCCC;
                    if(String.isNotBlank(caseRec.CCC_External_Id__c) 
                       && cccExtIdToCCCMap.containsKey(caseRec.CCC_External_Id__c)){
                           appliedCCC = cccExtIdToCCCMap.get(caseRec.CCC_External_Id__c);
                       }
                    if(appliedCCC != null){
                        caseFinalDMLMap = caseFinalDMLMap == null ? new Map<Id, Case>() : caseFinalDMLMap;
                        if(!caseFinalDMLMap.containsKey(caseRec.Id)){
                            Case caseObj = new Case(Id = caseRec.Id);
                            caseFinalDMLMap.put(caseObj.Id, caseObj);
                        }
                        Case caseRecFromMap = caseFinalDMLMap.get(caseRec.Id);
                        caseRecFromMap.OwnerId = resultWrap.defaultOwnerId != null ? resultWrap.defaultOwnerId : (resultWrap.defaultErrorOwnerId != null ? resultWrap.defaultErrorOwnerId : caseRec.OwnerId);                        
                            // VIRENDRA - 6 July 2024 - BYPASS OWNER CHANGE ON CASE RECORDTYPE CHANGE FROM PREFRAMEWORK TO FRAMEWORK.
                            if((caseRec.Preframework_to_Framework_FromUI__c != oldMap.get(caseRec.Id).Preframework_to_Framework_FromUI__c && caseRec.Preframework_to_Framework_FromUI__c))
                        {
                            caseRecFromMap.OwnerId = caseRec.OwnerId;
                        }
                        caseRecFromMap.Case_Assigned_Team__c = resultWrap.defaultOwnerName != null ? resultWrap.defaultOwnerName : '';
                        caseRecFromMap.SkipModifyingSLAHistory__c = System.now().getTime();
                        caseFinalDMLMap.put(caseRecFromMap.Id, caseRecFromMap);
                    }
                }
            }
        }
    }
    
    public static void createFeedItem(Map<Id, Case> newMap, Map<Id, Case> oldMap){
        List<FeedItem> feedItemList = new List<FeedItem>();
        for(Case caseRec : newMap.values()){
            if(caseRec.No_Auto_Communication__c != oldMap.get(caseRec.Id).No_Auto_Communication__c){
                String oldCommValue = oldMap.get(caseRec.Id).No_Auto_Communication__c !=null ? oldMap.get(caseRec.Id).No_Auto_Communication__c : 'None';
                String newCommValue = caseRec.No_Auto_Communication__c != null ? caseRec.No_Auto_Communication__c : 'None';
                FeedItem feedItem = new FeedItem();
                feedItem.ParentId = caseRec.Id;
                feedItem.Type = 'TextPost';
                feedItem.Body = 'No Auto Communication is changed from \''+oldCommValue+'\' to '+newCommValue;
                feedItemList.add(FeedItem);
            }
        }
        if(!feedItemList.isEmpty()){
            insert feedItemList;
        }  
    }
    //Creates extension record for Case, if case is created from Bulk page
    public static void createCaseExtnRecordForBulk(List<Case> newList) {
        
        if(!ASF_BulkCaseProcessorUtility.isBulkProcessing){return;}
        
        Map<String, Integer> cccExtIdToCaseIndex = new Map<String, Integer>();
        Integer index = 0;
        for(Case caseRec : newList){
            if(caseRec.Id == null){
                cccExtIdToCaseIndex.put(caseRec.CCC_External_Id__c, index);
            }
            index++;
        }
        
        Map<String, String> cccExtIdToExtnObjectAPI  = new Map<String, String>();
        for(ASF_Case_Field_Config__c fieldconfig : [SELECT Id,ObjectAPIName__c, Case_Category_Config__c FROM ASF_Case_Field_Config__c WHERE Case_Category_Config__c IN :cccExtIdToCaseIndex.keySet() AND ObjectAPIName__c != 'Case'])
        {
            if(!cccExtIdToExtnObjectAPI.containsKey(fieldconfig.Case_Category_Config__c)){
                cccExtIdToExtnObjectAPI.put(fieldconfig.Case_Category_Config__c, fieldconfig.ObjectAPIName__c);
            }
        }
        index = 0;
        Map<Integer, SObject> extnRecords = new Map<Integer, SObject>();
        for(Case caseRec : newList){
            if(cccExtIdToExtnObjectAPI.containsKey(caseRec.CCC_External_Id__c)){
                String sObjectType = cccExtIdToExtnObjectAPI.get(caseRec.CCC_External_Id__c);
                SObject newInstance = createObject(sObjectType);
                if(newInstance != null){
                    extnRecords.put(index, newInstance);
                }
            }
            index++;
        }
        
        if(!extnRecords.isEmpty()){
            insert extnRecords.values();
            index = 0;
            for(Case caseRec : newList){
                if(cccExtIdToExtnObjectAPI.containsKey(caseRec.CCC_External_Id__c) && extnRecords.containsKey(index)){
                    String fieldAPIName = cccExtIdToExtnObjectAPI.get(caseRec.CCC_External_Id__c);
                    caseRec.put(fieldAPIName, extnRecords.get(index).Id);
                }
                index++;
            }
        }
    }
    
    private static sObject createObject(String typeName) {
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(typeName);
        if (targetType == null) {
            // throw an exception
            return null;
        }
        // Instantiate an sObject with the type passed in as an argument
        //  at run time.
        return targetType.newSObject(); 
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
    public static void checkAndValidateFirstStageEntry(List<Case> newList, Map<Id, Case> oldMap) {
        Map<Id, Case> eligibleRecords = new Map<Id, Case>();
        Set<String> cccExternalIds = new Set<String>();
        Boolean isUpdate = oldMap!=null?true:false;
        
        for(Case caseRec : newList){
            if((caseRec.Technical_Source__c == 'LWC' || caseRec.Technical_Source__c == 'API') 
               && (!isUpdate 
                   || (caseRec.CCC_External_Id__c != oldMap.get(caseRec.Id).CCC_External_Id__c 
                       && oldMap.get(caseRec.Id).CCC_External_Id__c != null    
                       && caseRec.CCC_External_Id__c != null))){
                           eligibleRecords.put(caseRec.Id, caseRec);
                           cccExternalIds.add(caseRec.CCC_External_Id__c);
                       }
        }
        List<ASF_Case_Stage_Config__c> allStageConfigs;
        if(!cccExternalIds.isEmpty()){
            allStageConfigs = ASF_CaseQueryHandler.getCaseStageConfigWithRlAndIntr(cccExternalIds);
        }
        if(allStageConfigs != null && !eligibleRecords.isEmpty()){
            
            // Find All Query Fields for Case, Merge them togther, and perform one Query on Case
            Set<String> allFields = new Set<String>{'stage__c', 'businesshoursid', 'ccc_external_id__c', 'previous_stage__c', 'business_unit__c', 'lead__c','lob__c'};
                allFields.addAll(ASF_Constants.CASE_EXTENSION_FIELDSET);
                for(ASF_Case_Stage_Config__c config: allStageConfigs){
                    if(config.Query_Fields__c != null){
                        allFields.addAll(config.Query_Fields__c.toLowerCase().split(','));
                    }
                }
            List<Case> queriedCaseRecords = ASF_CaseQueryHandler.getCaseRecordWithQueryFields(allFields, eligibleRecords.keySet());
            
            Map<Id,ASF_Case_Stage_Config__c> currentStageConfigMap = new Map<Id,ASF_Case_Stage_Config__c>();
            for(Case caseRec : eligibleRecords.values()){
                for(ASF_Case_Stage_Config__c stageConfig : allStageConfigs){
                    if(stageConfig.StageName__c == caseRec.Stage__c 
                       && stageConfig.Case_Category_Config__r.CCC_External_Id__c == caseRec.CCC_External_Id__c){
                           currentStageConfigMap.put(caseRec.Id, stageConfig);
                       }
                }
            }
            if(!currentStageConfigMap.isEmpty()){
                Map<Id,ASF_CaseMovementHelper.CaseStageValidationWrapper> validateResultMap = ASF_CaseMovementHelper.validateNextStageEntry(queriedCaseRecords, currentStageConfigMap);
                
                for(Case caseRec : eligibleRecords.values()){
                    ASF_Case_Stage_Config__c currentStageConfig = currentStageConfigMap.get(caseRec.Id);
                    if(currentStageConfig != null){
                        ASF_CaseMovementHelper.CaseStageValidationWrapper wrap = validateResultMap.get(caseRec.Id);
                        if(wrap != null && wrap.status == 'Error'){
                            caseRec.addError(wrap.errorMessage!=null?wrap.errorMessage:'Error during stage entry validation');
                        }else{
                            if(wrap != null && wrap.isCaseUpdated == true){
                                caseFinalDMLMap = caseFinalDMLMap == null ? new Map<Id, Case>() : caseFinalDMLMap;
                                if(!caseFinalDMLMap.containsKey(caseRec.Id)){
                                    Case caseObj = new Case(Id = caseRec.Id);
                                    caseFinalDMLMap.put(caseObj.Id, caseObj);
                                }
                                Case caseRecFromMap = caseFinalDMLMap.get(caseRec.Id);
                                Map<String, Object> populatedFieldMap = wrap.updatedCase.getPopulatedFieldsAsMap();
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
                cccExtIds.add(caseRec.CCC_External_Id__c);
            }
        }
        if(!cccExtIds.isEmpty()){
            Map<Id,String> backwardStageMap = new Map<Id,String>();
            List<Case> backwardCases = new List<Case>();
            List<Case> forwardCases = new List<Case>();
            Map<Id,String> forwardStageMap = new Map<Id,String>();
            Map<Id,String> forwardOldStageMap = new Map<Id,String>();
            Map<Id, ASF_CaseMovementHelper.StageWrapper> backResultWrap;
            Map<Id, ASF_CaseMovementHelper.StageWrapper> fwdResultWrap;
            
            for(ASF_Case_Category_Config__c cccRec : ASF_CaseQueryHandler.getCaseCategoryConfigs(cccExtIds))
            {
                cccExtIdToCCCMap.put(cccRec.CCC_External_Id__c, cccRec);
            }
            
            for(Case caseRec : eligibleRecords){
                ASF_Case_Category_Config__c appliedCCC = cccExtIdToCCCMap.get(caseRec.CCC_External_Id__c);
                if(caseRec.Reopen_Style__c == 'Move To First Stage'){
                    backwardStageMap.put(caseRec.Id, appliedCCC.First_Stage__c);
                    backwardCases.add(caseRec);
                }else if(caseRec.Reopen_Style__c == 'Reopen Stage With Movement' || caseRec.Reopen_Style__c == 'Reopen Stage No Movement'){
                    forwardStageMap.put(caseRec.Id, 'Reopened');
                    forwardOldStageMap.put(caseRec.Id, oldMap.get(caseRec.Id).Stage__c);
                    forwardCases.add(caseRec);
                }
            }
            if(!backwardStageMap.isEmpty()){
                backResultWrap = ASF_CaseMovementHelper.moveToBackwardStage(backwardCases, backwardStageMap);
            }
            if(!forwardStageMap.isEmpty()){
                fwdResultWrap = ASF_CaseMovementHelper.moveToForwardStage(forwardCases, forwardStageMap, forwardOldStageMap); 
            }
            
            for(Case caseRec : eligibleRecords){
                
                switch on caseRec.Reopen_Style__c {
                    when 'Move To First Stage' {
                        ASF_CaseMovementHelper.StageWrapper resultWrap = backResultWrap.containsKey(caseRec.Id) ? backResultWrap.get(caseRec.Id) : null;
                        if(resultWrap !=null && resultWrap.status == 'Success'){
                            
                            caseFinalDMLMap = caseFinalDMLMap == null ? new Map<Id, Case>() : caseFinalDMLMap;
                            if(!caseFinalDMLMap.containsKey(caseRec.Id)){
                                Case caseObj = new Case(Id = caseRec.Id);
                                caseFinalDMLMap.put(caseObj.Id, caseObj);
                            }
                            Case caseRecFromMap = caseFinalDMLMap.get(caseRec.Id);
                            caseRecFromMap.Stage__c = resultWrap.caseToBeUpdated.Stage__c;
                            caseRecFromMap.Status = resultWrap.caseToBeUpdated.Status;
                            caseRecFromMap.SkipModifyingSLAHistory__c = System.now().getTime();
                            caseRecFromMap.OwnerId = resultWrap.ownerId != null ? resultWrap.ownerId : (resultWrap.errorOwnerId != null ? resultWrap.errorOwnerId : caseRec.OwnerId);
                                caseFinalDMLMap.put(caseRecFromMap.Id, caseRecFromMap);
                        }else{
                            system.debug('as-error3');
                            
                            caseRec.addError(resultWrap.errorMessage != null?resultWrap.errorMessage:ASF_Constants.GENERIC_ERROR_MESSAGE);
                        }
                    }
                    when 'Reopen Stage With Movement', 'Reopen Stage No Movement' {
                        ASF_CaseMovementHelper.StageWrapper resultWrap = fwdResultWrap.containsKey(caseRec.Id) ? fwdResultWrap.get(caseRec.Id) : null;
                        if(resultWrap !=null && resultWrap.status == 'Success'){
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
                            caseRecFromMap.SkipModifyingSLAHistory__c = System.now().getTime();
                            caseRecFromMap.OwnerId = resultWrap.ownerId != null ? resultWrap.ownerId : (resultWrap.errorOwnerId != null ? resultWrap.errorOwnerId : caseRec.OwnerId);
                                caseFinalDMLMap.put(caseRecFromMap.Id, caseRecFromMap);
                        }else{
                            system.debug('as-error2');
                            caseRec.addError(resultWrap.errorMessage != null?resultWrap.errorMessage:ASF_Constants.GENERIC_ERROR_MESSAGE);
                        }
                    }
                    when else {
                        
                    }
                }
            }
        }
    }
    
    //Method to get the next eligible stage for moveToNextStage and set on trigger.new
    public static void findNextStageAndSetOnTriggerNew(List<Case> newList, Map<Id, Case> oldMap) {
        Boolean isUpdate = oldMap!=null?true:false;
        List<Case> eligibleRecords = new List<Case>();
        
        Map<Id, String> currentStageMap = new Map<Id, String>();
        //Boolean supressErrors = (newList[0].Technical_Source__c == 'API' && oldMap == null)?true:false;
        for(Case caseRec : newList){
            //If update, is MoveToNext changed to true, else if insert, MoveToNext is true
            if(((isUpdate && caseRec.MoveToNext__c != oldMap.get(caseRec.Id).MoveToNext__c) || !isUpdate)
               && caseRec.MoveToNext__c == true){
                   eligibleRecords.add(caseRec);
                   currentStageMap.put(caseRec.Id, isUpdate?oldMap.get(caseRec.Id).Stage__c:caseRec.Stage__c);
               }
            if(caseRec.Technical_Source__c == 'API' && oldMap == null){
                supressErrors.put(caseRec.Id, true);
            }
        }
        if(!eligibleRecords.isEmpty()){
            
            Map<Id, ASF_CaseMovementHelper.StageWrapper> resultWrapMap = ASF_CaseMovementHelper.findNextStageForMoveToNextStage(eligibleRecords, currentStageMap);
            for(Case caseRec : eligibleRecords){
                ASF_CaseMovementHelper.StageWrapper resultWrap = resultWrapMap.containsKey(caseRec.Id) ? resultWrapMap.get(caseRec.Id) : null;
                if(resultWrap != null && resultWrap.status == 'Success'){
                    caseRec.Stage__c = resultWrap.nextStageConfig.StageName__c;
                    caseRec.Status = resultWrap.nextStageConfig.Status_Mapping__c;
                    caseRec.OwnerId = resultWrap.ownerId != null ? resultWrap.ownerId : (resultWrap.errorOwnerId != null ? resultWrap.errorOwnerId : caseRec.OwnerId);
                        // VIRENDRA - 8 JUNE 2024 - TO STAMP CASE ASSIGNED TEAM ON CASE RECORD.
                        System.debug('resultWrap.ownerName --> '+resultWrap.ownerName);
                    caseRec.Case_Assigned_Team__c = resultWrap.ownerName != null ? resultWrap.ownerName: '';
                    // VIRENDRA - ENDS HERE.
                }else{
                    if(supressErrors.containsKey(caseRec.Id) && supressErrors.get(caseRec.Id)){
                        triggerEncounteredError.put(caseRec.Id, true);
                    }else{
                        system.debug('as-error1');
                        caseRec.addError(resultWrap.errorMessage != null?resultWrap.errorMessage:ASF_Constants.GENERIC_ERROR_MESSAGE);
                    }
                }
            }
        }
    }
    
    //Method checks whether move to next stage is changed to true, if yes, calls the right modular methods to process it
    //Moved to after trigger context
    public static void checkAndProcessMoveToNextStage(List<Case> newList, Map<Id, Case> oldMap){
        Boolean isUpdate = oldMap!=null?true:false;
        Map<Id, Case> eligibleRecords = new Map<Id, Case>();
        Map<Id, String> caseStageMap = new Map<Id, String>();
        for(Case caseRec : newList){
            //If update, is MoveToNext changed to true, else if insert, MoveToNext is true
            if(((isUpdate && caseRec.MoveToNext__c != oldMap.get(caseRec.Id).MoveToNext__c) || !isUpdate)
               && caseRec.MoveToNext__c == true){
                   eligibleRecords.put(caseRec.Id, caseRec);
                   caseStageMap.put(caseRec.Id, isUpdate?oldMap.get(caseRec.Id).Stage__c:caseRec.Stage__c);
                   if(caseRec.Technical_Source__c == 'API' && oldMap == null){
                       supressErrors.put(caseRec.Id, true);
                   }
               }
        }
        
        if(!eligibleRecords.isEmpty()){    
            //invoke moveToNextStage of ASF_CaseMovementHelper
            Map<Id, ASF_CaseMovementHelper.StageWrapper> resultWrapMap = ASF_CaseMovementHelper.moveToNextStage(eligibleRecords.values(), caseStageMap);
            List<Case> caseToUpdate = new List<Case>();
            for(Id caseId : eligibleRecords.keySet()){
                
                case caseRec = eligibleRecords.get(caseId);
                ASF_CaseMovementHelper.StageWrapper resultWrap = resultWrapMap.containsKey(caseId) ? resultWrapMap.get(caseId) : null;
                
                if(resultWrap != null && resultWrap.status == 'Success'){
                    if(isUpdate){
                        caseFinalDMLMap = caseFinalDMLMap == null ? new Map<Id, Case>() : caseFinalDMLMap;
                        if(!caseFinalDMLMap.containsKey(caseRec.Id)){
                            Case caseObj = new Case(Id = caseRec.Id);
                            caseFinalDMLMap.put(caseObj.Id, caseObj);
                        }
                        Case caseRecFromMap = caseFinalDMLMap.get(caseRec.Id);
                        caseRecFromMap.OwnerId = resultWrap.ownerId != null ? resultWrap.ownerId : (resultWrap.errorOwnerId != null ? resultWrap.errorOwnerId : caseRec.OwnerId);
                            caseRecFromMap.Previous_Stage__c = oldMap.get(caseRecFromMap.Id).Stage__c;
                        caseRecFromMap.MoveToNext__c = false;
                        caseRecFromMap.SkipModifyingSLAHistory__c = System.now().getTime();
                        
                        // VIRENDRA - 8 JUNE 2024 - TO STAMP CASE ASSIGNED TEAM.
                        caseRecFromMap.Case_Assigned_Team__c = resultWrap.ownerName != null ? resultWrap.ownerName : '';
                        
                        if(resultWrap.caseToBeUpdated != null){
                            Map<String, Object> populatedFieldMap = resultWrap.caseToBeUpdated.getPopulatedFieldsAsMap();
                            for(String fieldName : populatedFieldMap.keySet()){
                                caseRecFromMap.put(fieldName, resultWrap.caseToBeUpdated.get(fieldName));
                            }
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
                        if(resultWrap.caseToBeUpdated != null){
                            Map<String, Object> populatedFieldMap = resultWrap.caseToBeUpdated.getPopulatedFieldsAsMap();
                            for(String fieldName : populatedFieldMap.keySet()){
                                caseRecFromMap.put(fieldName, resultWrap.caseToBeUpdated.get(fieldName));
                            }
                        }
                        //caseRecFromMap.SkipModifyingSLAHistory__c = System.now().getTime();//commented PR970457-1746
                        caseRecFromMap.OwnerId = resultWrap.ownerId != null ? resultWrap.ownerId : (resultWrap.errorOwnerId != null ? resultWrap.errorOwnerId : caseRec.OwnerId);
                            // VIRENDRA - 8 JUNE 2024 - ADDED TO STAMP CASE ASSIGNED TEAM.
                            // THIS CODE IS NEED IN CASE OF STP FLOW - WHEN CASES ARE CREATED AND MOVED TO NEXT STAGE.
                            caseREcFromMap.Case_Assigned_Team__c = resultWrap.ownerName != null ? resultWrap.ownerName : '';
                        // VIRENDRA - ENDS HERE.
                        caseRecFromMap.MoveToNext__c = false;
                        caseRecFromMap.Previous_Stage__c = caseRec.Stage__c;//Current new stage becomes previous stage
                        caseFinalDMLMap.put(caseRecFromMap.Id, caseRecFromMap);
                    }
                }else{
                    if(supressErrors.containsKey(caseId) && supressErrors.get(caseId)){
                        triggerEncounteredError.put(caseId, true);
                    }else{                    system.debug('as-error6');
                          
                          caseRec.addError(resultWrap.errorMessage != null?resultWrap.errorMessage:ASF_Constants.GENERIC_ERROR_MESSAGE);
                         }
                }
            }
            
        }
    }
    
    //Method checks whether stage is changed(Forward stage movement) or pending clarification = true with stage movement(backward) and process it
    //skip when case is being reopened
    //skip when case is being closed
    public static void checkAndProcessManualStageMovement(Map<Id, Case> newMap, Map<Id, Case> oldMap) {
        //Map<Case, String> eligibleRecords = new Map<Case, String>();
        Map<Id, String> forwardStageMap = new Map<Id, String>();
        Map<Id, String> backwardStageMap = new Map<Id, String>();
        Map<Id, String> oldforwardStageMap = new Map<Id, String>();
        List<Case> forwardCases = new List<Case>();
        List<Case> backwardCases = new List<Case>();
        for(Case caseRec : newMap.values()){
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
               &&  (caseRec.Is_Duplicate__c == oldMap.get(caseRec.Id).Is_Duplicate__c)
               && caseRec.Stage__c != oldMap.get(caseRec.Id).Stage__c){
                   
                   String movement = caseRec.pending_clarification__c==true?'backward':'forward';
                   if(movement == 'forward'){
                       forwardCases.add(caseRec);
                       forwardStageMap.put(caseRec.Id, caseRec.Stage__c);
                       oldforwardStageMap.put(caseRec.Id, oldMap.get(caseRec.Id).Stage__c);
                   }else if(movement == 'backward'){
                       backwardCases.add(caseRec);
                       backwardStageMap.put(caseRec.Id, caseRec.Stage__c);
                   }
               }
        }
        if(!forwardCases.isEmpty()){
            Map<Id, ASF_CaseMovementHelper.StageWrapper> wrapToReturn = ASF_CaseMovementHelper.moveToForwardStage(forwardCases, forwardStageMap, oldforwardStageMap);
            for(Case caseRec : forwardCases){
                if(wrapToReturn.containsKey(caseRec.Id) && wrapToReturn.get(caseRec.Id).status == 'Success'){
                    ASF_CaseMovementHelper.StageWrapper resultWrap = wrapToReturn.get(caseRec.Id);
                    caseFinalDMLMap = caseFinalDMLMap == null ? new Map<Id, Case>() : caseFinalDMLMap;
                    if(!caseFinalDMLMap.containsKey(caseRec.Id)){
                        Case caseObj = new Case(Id = caseRec.Id);
                        caseFinalDMLMap.put(caseObj.Id, caseObj);
                    }
                    Case caseRecFromMap = caseFinalDMLMap.get(caseRec.Id);
                    caseRecFromMap.OwnerId = resultWrap.ownerId != null ? resultWrap.ownerId : (resultWrap.errorOwnerId != null ? resultWrap.errorOwnerId : caseRec.OwnerId);
                        //caseRecFromMap.Previous_Stage__c = oldMap.get(caseRecFromMap.Id).Stage__c;
                        if(resultWrap.caseToBeUpdated != null){
                            Map<String, Object> populatedFieldMap = resultWrap.caseToBeUpdated.getPopulatedFieldsAsMap();
                            for(String fieldName : populatedFieldMap.keySet()){
                                caseRecFromMap.put(fieldName, resultWrap.caseToBeUpdated.get(fieldName));
                            }
                        }
                    if(caseRec.Previous_Stage__c == caseRecFromMap.Stage__c){
                        caseRecFromMap.Pending_Clarification__c = false;
                    }
                    caseRecFromMap.SkipModifyingSLAHistory__c = System.now().getTime();
                    caseFinalDMLMap.put(caseRecFromMap.Id, caseRecFromMap);
                }else{
                    //Error scenario
                    system.debug('as-error5');
                    
                    newMap.get(caseRec.Id).addError(wrapToReturn.get(caseRec.Id).errorMessage != null?wrapToReturn.get(caseRec.Id).errorMessage:ASF_Constants.GENERIC_ERROR_MESSAGE);
                }
            }
        }
        if(!backwardCases.isEmpty()){
            Map<Id, ASF_CaseMovementHelper.StageWrapper> wrapToReturnMap = ASF_CaseMovementHelper.moveToBackwardStage(backwardCases, backwardStageMap);
            for(Case caseRec : backwardCases){
                if(wrapToReturnMap.containsKey(caseRec.Id) && wrapToReturnMap.get(caseRec.Id).status == 'Success'){
                    ASF_CaseMovementHelper.StageWrapper wrapToReturn = wrapToReturnMap.get(caseRec.Id);
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
                    caseRecFromMap.SkipModifyingSLAHistory__c = System.now().getTime();
                    caseRecFromMap.OwnerId = wrapToReturn.ownerId != null ? wrapToReturn.ownerId : (wrapToReturn.errorOwnerId != null ? wrapToReturn.errorOwnerId : caseRec.OwnerId);
                        // VIRENDRA - 8 JUNE 2024 - TO STAMP CASE ASSIGNED TEAM.
                        caseRecFromMap.Case_Assigned_Team__c = wrapToReturn.ownerName != null ? wrapToReturn.ownerName : '';
                    // VIRENDRA - ENDS HERE.
                    caseFinalDMLMap.put(caseRecFromMap.Id, caseRecFromMap);
                }
                else{
                    system.debug('as-error4');
                    
                    //Error scenario
                    ASF_CaseMovementHelper.StageWrapper wrapToReturn = wrapToReturnMap.get(caseRec.Id);
                    newMap.get(caseRec.Id).addError(wrapToReturn.errorMessage != null?wrapToReturn.errorMessage:ASF_Constants.GENERIC_ERROR_MESSAGE);
                }
            }
        }
    }
    
    //After insert call, only for API cases, assigns the owner on first stage
    public static void checkAndPopulateOwnerOnCaseCreation(Map<Id, Case> newMap) {
        List<Case> eligibleCases = new List<Case>();
        Map<Id, String> caseStageMap = new Map<Id, String>();
        Map<Id, String> caseUIStageMap = new Map<Id, String>();
        List<Case> eligibleLWCCases = new List<Case>();
        
        for(Case caseRec : newMap.values()){
            if(caseRec.Technical_Source__c == 'API' || (ASF_BulkCaseProcessorUtility.isBulkProcessing && caseRec.Run_Assignment_Rule_on_Bulk_Create__c)){
                caseStageMap.put(caseRec.Id, caseRec.Stage__c);
                eligibleCases.add(caseRec);
            }
            // VIRENDRA - 12 JUNE 2024 - TO RUN THE RULE AND FIND OUT CASE ASSIGNED TEAM.
            else if(caseRec.Technical_Source__c == 'LWC'){
                caseUIStageMap.put(caseRec.Id,caseRec.Stage__c);
                eligibleLWCCases.add(caseRec);
            }
        }
        if(!eligibleLWCCases.isEmpty()){
            Map<Id, ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo> ownerInfoMap = ASF_CaseMovementHelper.getAssignmentForStage(eligibleLWCCases, caseUIStageMap);
            for(Case caseRec : eligibleLWCCases){
                ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo ownerInfo = ownerInfoMap.get(caseRec.Id);
                caseFinalDMLMap = caseFinalDMLMap == null ? new Map<Id, Case>() : caseFinalDMLMap;
                if(!caseFinalDMLMap.containsKey(caseRec.Id)){
                    Case caseObj = new Case(Id = caseRec.Id);
                    caseFinalDMLMap.put(caseRec.Id, caseObj);
                }
                Case caseRecFromMap = caseFinalDMLMap.get(caseRec.Id);
                caseRecFromMap.Case_Assigned_Team__c  = ownerInfo.defaultOwnerName != null? ownerInfo.defaultOwnerName:'';
                caseFinalDMLMap.put(caseRecFromMap.Id, caseRecFromMap);
            }
        }
        if(!eligibleCases.isEmpty()){
            Map<Id, ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo> ownerInfoMap = ASF_CaseMovementHelper.getAssignmentForStage(eligibleCases, caseStageMap);
            for(Case caseRec : eligibleCases){
                ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo ownerInfo = ownerInfoMap.get(caseRec.Id);
                caseFinalDMLMap = caseFinalDMLMap == null ? new Map<Id, Case>() : caseFinalDMLMap;
                if(!caseFinalDMLMap.containsKey(caseRec.Id)){
                    Case caseObj = new Case(Id = caseRec.Id);
                    caseFinalDMLMap.put(caseRec.Id, caseObj);
                }
                Case caseRecFromMap = caseFinalDMLMap.get(caseRec.Id);
                caseRecFromMap.OwnerId = ownerInfo.defaultOwnerId!=null?ownerInfo.defaultOwnerId:caseRecFromMap.OwnerId;
                // VIRENDRA - 8 JUNE 2024 - TO STORE THE CASE ASSIGNED TEAM NAME.
                System.debug('caseRecFromMap.Case_Assigned_Team__c --> '+caseRecFromMap.Case_Assigned_Team__c);
                caseRecFromMap.Case_Assigned_Team__c  = ownerInfo.defaultOwnerName != null? ownerInfo.defaultOwnerName:'';
                // VIRENDRA - ENDS HERE.
                if(triggerEncounteredError.containsKey(caseRec.Id) && triggerEncounteredError.get(caseRec.Id)){
                    caseRecFromMap.OwnerId = ownerInfo.defaultErrorOwnerId!=null?ownerInfo.defaultErrorOwnerId:caseRecFromMap.OwnerId;
                    // VIRENDRA - 8 JUNE 2024 - TO STORE THE CASE ASSIGNED TEAM NAME.
                    System.debug('caseRecFromMap.Case_Assigned_Team__c --> In Error Block -->'+caseRecFromMap.Case_Assigned_Team__c);
                    caseRecFromMap.Case_Assigned_Team__c  = ownerInfo.defaultOwnerName != null? ownerInfo.defaultOwnerName:'';
                    // VIRENDRA - ENDS HERE.
                }
                caseFinalDMLMap.put(caseRecFromMap.Id, caseRecFromMap);
            }
            triggerEncounteredError = new Map<Id, Boolean>();
        }
    }

    //Runs the ASF_CaseMovementHelper.getCaseAdditionalDataForNextStage method
    //to fetch the tasks, checklists, approvals and integrations and
    //stores them in static variable for after context trigger to insert them
    //Runs the integrations and updates the owner in case of errors.
    //Runs on new case creation and recategorisation and forward stage movement
    public static void checkAndStorePeripheralRecordsInAfterContext(List<Case> newList, Map<Id, Case> oldMap) {
        List<Case> eligibleRecords = new List<Case>();
        List<Case> caseListForSla = new List<Case>();
        Map<Id, String> caseStageMap = new Map<Id, String>();
        Boolean isUpdate = oldMap!=null?true:false;
        Map<Id, case> newMap = new Map<Id, case>();
        
        for(Case caseRec : newList){
            //Insert case
            if(caseRec.Technical_Source__c != null && caseRec.CCC_External_Id__c != null
               && (!isUpdate 
                   || (caseRec.CCC_External_Id__c != oldMap.get(caseRec.Id).CCC_External_Id__c 
                       && oldMap.get(caseRec.Id).CCC_External_Id__c != null) || 
                   (caseRec.stage__c != oldMap.get(caseRec.Id).stage__c && caseRec.pending_clarification__c==false))){
                       eligibleRecords.add(caseRec);
                       newMap.put(caseRec.Id, caseRec);
                       caseStageMap.put(caseRec.Id, caseRec.Stage__c);
                   }
            else if(caseRec.Technical_Source__c != null && caseRec.CCC_External_Id__c != null && isUpdate
       				&& (caseRec.stage__c != oldMap.get(caseRec.Id).stage__c && caseRec.pending_clarification__c==true)){
                       caseListForSla.add(caseRec);
                       newMap.put(caseRec.Id, caseRec);
                       caseStageMap.put(caseRec.Id, caseRec.Stage__c);
                   }
        }
        if(!caseStageMap.isEmpty()){
            Map<Id, ASF_CaseMovementHelper.CaseAdditionalData> dataWrapper = ASF_CaseMovementHelper.getCaseAdditionalDataForNextStage(eligibleRecords, caseStageMap, caseListForSla);
            //addlDataFromStageMovementMethods = new Map<Id, ASF_CaseMovementHelper.CaseAdditionalData>();
            //addlDataFromStageMovementMethods = dataWrapper;
            List<Case> casesWithPeripheralRecords = new List<Case>();
            
            if(!eligibleRecords.isEmpty()){
                casesWithPeripheralRecords = ASF_CaseQueryHandler.getCases(caseStageMap.keySet());
            }
  
            Map<String, Boolean> checklistMap = new Map<String, Boolean>();
            Map<String, Boolean> taskMap = new Map<String, Boolean>();
            for(Case caseRec : casesWithPeripheralRecords){
                for(ASF_Checklist__c checkRec : caseRec.Checklists__r){
                    if(!ASF_Constants.completeChecklistStatus.contains(checkRec.Status__c)){
                    checklistMap.put(caseRec.Id+checkRec.Checklist_External_Id__c, true);
                }
                }
                for(Task taskRec : caseRec.Tasks){
                    taskMap.put(caseRec.Id+taskRec.Work_Item_External_ID__c, true);
                }
            }
            for(Case caseRec : eligibleRecords){
                if(!addlDataFromStageMovementMethods.containsKey(caseRec.Id)){
                    addlDataFromStageMovementMethods.put(caseRec.Id, new ASF_CaseMovementHelper.CaseAdditionalData());
                }
                if(dataWrapper.containsKey(caseRec.Id) && dataWrapper.get(caseRec.Id).checklistToInsert != null){
                    for(ASF_Checklist__c checkRec : dataWrapper.get(caseRec.Id).checklistToInsert){
                        if(!checklistMap.containsKey(caseRec.Id+checkRec.Checklist_External_Id__c)){
                            if(addlDataFromStageMovementMethods.get(caseRec.Id).checklistToInsert == null){
                                addlDataFromStageMovementMethods.get(caseRec.Id).checklistToInsert = new List<ASF_Checklist__c>();
                            }
                            addlDataFromStageMovementMethods.get(caseRec.Id).checklistToInsert.add(checkRec);
                        }   
                    }
                }
                
                if(dataWrapper.containsKey(caseRec.Id) && dataWrapper.get(caseRec.Id).tasksToInsert != null){
                    for(Task taskRec : dataWrapper.get(caseRec.Id).tasksToInsert){
                        if(!taskMap.containsKey(caseRec.Id+taskRec.Work_Item_External_ID__c)){
                            if(addlDataFromStageMovementMethods.get(caseRec.Id).tasksToInsert == null){
                                addlDataFromStageMovementMethods.get(caseRec.Id).tasksToInsert = new List<Task>();
                            }
                            addlDataFromStageMovementMethods.get(caseRec.Id).tasksToInsert.add(taskRec);
                        }
                    }
                }                
                addlDataFromStageMovementMethods.get(caseRec.Id).allIntegrations = dataWrapper.get(caseRec.Id).allIntegrations;
                addlDataFromStageMovementMethods.get(caseRec.Id).approvalsToInsert = dataWrapper.get(caseRec.Id).approvalsToInsert;
                addlDataFromStageMovementMethods.get(caseRec.Id).manualApprovalStage = dataWrapper.get(caseRec.Id).manualApprovalStage;
                addlDataFromStageMovementMethods.get(caseRec.Id).slaCaseAndStageOverrideValues = dataWrapper.get(caseRec.Id).slaCaseAndStageOverrideValues;
            }
            List<Case> integCaseList = new List<Case>();
            Map<Id, List<ASF_Integration__c>> runIntegrationMap = new Map<Id, List<ASF_Integration__c>>();
            
            for(Id caseId : caseStageMap.keySet()){
                if(addlDataFromStageMovementMethods.containsKey(caseId)){
                    if(addlDataFromStageMovementMethods.get(caseId).allIntegrations != null 
                       && newMap.get(caseId).Technical_Source__c == 'API' || newMap.get(caseId).Technical_Source__c == 'Email'
                       || newMap.get(caseId).Technical_Source__c == 'LWC'){
                           integCaseList.add(newMap.get(caseId));
                           //TO DOO:check on the data type of allintegrations wrapper
                           runIntegrationMap.put(caseId, addlDataFromStageMovementMethods.get(caseId).allIntegrations); 
                       }
                    
                    if(addlDataFromStageMovementMethods.get(caseId).manualApprovalStage != null){
                        caseFinalDMLMap = caseFinalDMLMap == null ? new Map<Id, Case>() : caseFinalDMLMap;
                        Case caseToUpdate;
                        if(!caseFinalDMLMap.containsKey(caseId)){
                            caseToUpdate = new Case(Id=caseId, is_Manual_Approval__c = addlDataFromStageMovementMethods.get(caseId).manualApprovalStage);
                            caseFinalDMLMap.put(caseToUpdate.Id, caseToUpdate);
                        }else{
                            caseToUpdate = caseFinalDMLMap.get(caseId);
                            caseToUpdate.is_Manual_Approval__c = addlDataFromStageMovementMethods.get(caseId).manualApprovalStage;
                            caseFinalDMLMap.put(caseToUpdate.Id, caseToUpdate);
                        }
                    }
                } 
            }
            if(!integCaseList.isEmpty()){
                Map<Id, ASF_IntegrationsController.IntegrationWrapper> intWrapMap = ASF_CaseFrameworkHelper.runIntegrations(integCaseList, runIntegrationMap);
                caseFinalDMLMap = caseFinalDMLMap == null ? new Map<Id, Case>() : caseFinalDMLMap;
                for(Case caseRec : integCaseList){
                    if(intWrapMap.containsKey(caseRec.Id)){
                        ASF_IntegrationsController.IntegrationWrapper intWrap = intWrapMap.get(caseRec.Id);
                        if(intWrap.status == 'Error'){
                            Case caseToUpdate = !caseFinalDMLMap.containsKey(caseRec.Id)?new Case(Id=caseRec.Id):caseFinalDMLMap.get(caseRec.Id);
                            if(intWrap.assignToId != null){
                                caseToUpdate.OwnerId = intWrap.assignToId;
                            }
                            if(intWrap.updatedCase != null){
                                Map<String, Object> populatedFieldMap = intWrap.updatedCase.getPopulatedFieldsAsMap();
                                for(String fieldName : populatedFieldMap.keySet()){
                                    caseToUpdate.put(fieldName, intWrap.updatedCase.get(fieldName));
                                }
                            }
                            caseFinalDMLMap.put(caseToUpdate.Id, caseToUpdate);
                        }
                    }
                }
            }
            for(Case caseRec : caseListForSla){
                if(!addlDataFromStageMovementMethods.containsKey(caseRec.Id)){
                    addlDataFromStageMovementMethods.put(caseRec.Id, new ASF_CaseMovementHelper.CaseAdditionalData());
                }
                addlDataFromStageMovementMethods.get(caseRec.Id).slaCaseAndStageOverrideValues = dataWrapper.get(caseRec.Id).slaCaseAndStageOverrideValues;
            }
        }
    }
    //Creates Checklist, Tasks, Approvals
    public static void checkAndInsertPeripheralRecords(Map<Id, Case> newMap, Map<Id, Case> oldMap) {
        List<SObject> combinedList = new List<SObject>();
        
        if(!addlDataFromStageMovementMethods.isEmpty()){
            for(Id caseId : addlDataFromStageMovementMethods.keySet()){
                
                if(addlDataFromStageMovementMethods.get(caseId).approvalsToInsert != null && !addlDataFromStageMovementMethods.get(caseId).approvalsToInsert.isEmpty()){
                    combinedList.addAll(addlDataFromStageMovementMethods.get(caseId).approvalsToInsert);
                }
                if(addlDataFromStageMovementMethods.get(caseId).tasksToInsert != null && !addlDataFromStageMovementMethods.get(caseId).tasksToInsert.isEmpty()){
                    combinedList.addAll(addlDataFromStageMovementMethods.get(caseId).tasksToInsert);
                }
                if(addlDataFromStageMovementMethods.get(caseId).checklistToInsert != null && !addlDataFromStageMovementMethods.get(caseId).checklistToInsert.isEmpty()){
                    combinedList.addAll(addlDataFromStageMovementMethods.get(caseId).checklistToInsert);
                }
            }        
        }
        if(!combinedList.isEmpty()){
            Database.SaveResult[] saveResults = Database.insert(combinedList, false);
            //Check each SaveResult for errors and add errors to corresponding records
            for (Integer i = 0; i < saveResults.size(); i++) {
                if (!saveResults.get(i).isSuccess()) {
                    Case failedCase;
                    Boolean supressErrors = false;
                    if(combinedList[i] instanceof ASF_Case_Approv__c){
                        ASF_Case_Approv__c approvalRec = (ASF_Case_Approv__c)combinedList[i];
                        failedCase = newMap.get(approvalRec.SR__c);
                    }
                    else if(combinedList[i] instanceof ASF_Checklist__c){
                        ASF_Checklist__c checkListRec = (ASF_Checklist__c)combinedList[i];
                        failedCase = newMap.get(checkListRec.Case__c);
                    }
                    else if(combinedList[i] instanceof Task){
                        Task taskRec = (Task)combinedList[i];
                        failedCase = newMap.get(taskRec.WhatId);
                    }
                    if(failedCase != null && failedCase.Technical_Source__c == 'API' && oldMap == null){
                        supressErrors = true;
                    }
                    if(supressErrors){
                        triggerEncounteredError.put(failedCase.Id, true);
                    }else{
                        String errorMessage = saveResults.get(i).getErrors()[0].getMessage();
                        failedCase.addError('Error on insert: ' + errorMessage);
                    }
                }
            }
        }
        //This reset is important for bulk processing as static variables dont get reset between every 200 records chunk in trigger execution
        addlDataFromStageMovementMethods = new Map<Id, ASF_CaseMovementHelper.CaseAdditionalData>();
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
    
    public static void updateCasesFinally(Map<Id, Case> newMap) {
        //This method invokes a DML on the caseFinalDMLMap map, 
        //which is accumulation of all field updates on current from After trigger
        //*** IMP: Doesnt run Case trigger***
        if(caseFinalDMLMap != null){
            ASF_CaseTriggerModularHelper.isRecursiveUpdate = true;//Reserved for future use, in case any specific module/function need skip
            ASF_TriggerSkipperUtility.markTriggerRun('Case');
            System.debug('caseFinalDMLMap.values()'+caseFinalDMLMap.values());
            List<String> propertiesToRemove = new List<String>{'OwnerId', 'Stage__c'};
                //List<Case> localListForDML = (List<Case>)JSON.deserializeStrict(JSON.serialize(caseFinalDMLMap.values()), List<Case>.class);
                List<Case> localListForDML = removeProperties(newMap, caseFinalDMLMap.values(), propertiesToRemove);
            for(Case caseRec : localListForDML){
                if(caseRec.Stage__c != null || caseRec.OwnerId != null){
                    //If Stage or Owner is being updated on any Case, After Trigger needs to run for SLA History calculation
                    ASF_TriggerSkipperUtility.resetTriggerRun('Case');
                    ASF_TriggerSkipperUtility.markTriggerRun('Case', 'Before');
                    break;
                }
            }
            System.debug('caseFinalDMLMap.values() After manipulation'+localListForDML);
            caseFinalDMLMap = new Map<Id, Case>();
            Database.SaveResult[] saveResults = Database.update(localListForDML, false);
            ASF_CaseTriggerModularHelper.isRecursiveUpdate = false;
            for (Integer i = 0; i < saveResults.size(); i++) {
                if (!saveResults.get(i).isSuccess()) {
                    Case failedCase = newMap.get(localListForDML[i].Id);
                    
                    if(supressErrors.containsKey(failedCase.Id) && supressErrors.get(failedCase.Id)){
                        triggerEncounteredError.put(failedCase.Id, true);
                    }else{
                        String errorMessage = saveResults.get(i).getErrors()[0].getMessage();
                        failedCase.addError('Error on insert: ' + errorMessage);
                    }
                }
            }
            ASF_TriggerSkipperUtility.resetTriggerRun('Case');
        }
        caseFinalDMLMap = new Map<Id, Case>();
    }
    private static List<Case> removeProperties(Map<Id, Case> currentCases, List<Object> objects, String[] propertiesToRemove){
        // serialize / deserialize into a generic List<Map<String, Object>>
        List<Object> deserializedList = (List<Object>) JSON.deserializeUntyped(JSON.serialize(objects));
        
        // For each object, remove each property
        for (Object deserialized : deserializedList) {
            Map<string, Object> obj = (Map<string, Object>) deserialized;
            Case triggerCase = currentCases.get((Id)obj.get('Id'));
            for(string property : propertiesToRemove){
                if(obj.containsKey(property) && 
                   (obj.get(property) == null || (String)triggerCase.get(property) == (String)obj.get(property))){
                       obj.remove(property);
                   }
            }
        }
        // serialize / deserialize back to object type
        return (List<Case>)JSON.deserializeStrict(JSON.serialize(deserializedList), List<Case>.class);
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
        Map<Id, String> caseStageMap = new Map<Id, String>();
        
        for(Case caseRec : newList){
            if(caseRec.Reject_Case__c != oldMap.get(caseRec.Id).Reject_Case__c && caseRec.Reject_Case__c == true){
                caseStageMap.put(caseRec.Id, ASF_Constants.REJECTIONSTATUS);    
                eligibleRecords.add(caseRec);
            }
            else if(caseRec.Is_Duplicate__c != oldMap.get(caseRec.Id).Is_Duplicate__c && caseRec.Is_Duplicate__c == true){
                caseStageMap.put(caseRec.Id, ASF_Constants.DUPLICATESTAGE);
                eligibleRecords.add(caseRec);
            }
        }
        if(!eligibleRecords.isEmpty()){
            //Map<Id, ASF_CaseMovementHelper.StageWrapper> resultWrap = ASF_CaseMovementHelper.moveToForwardStage(caseStageMap.keySet(), caseStageMap);
            
            for(Case caseRec : eligibleRecords){
                if(caseRec.Is_Duplicate__c){
                    caseRec.Stage__c = ASF_Constants.DUPLICATESTAGE;
                    caseRec.Status = ASF_Constants.DUPLICATESTATUS;
                }else{
                    caseRec.Stage__c = ASF_Constants.REJECTIONSTATUS;
                    caseRec.Status = ASF_Constants.REJECTIONSTATUS;
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
            for(Id caseId : rejectedCaseIds){
                caseFinalDMLMap = caseFinalDMLMap == null ? new Map<Id, Case>() : caseFinalDMLMap;
                if(!caseFinalDMLMap.containsKey(caseId)){
                    Case caseObj = new Case(Id = caseId);
                    caseFinalDMLMap.put(caseObj.Id, caseObj);
                }
                Case caseRecFromMap = caseFinalDMLMap.get(caseId);
                caseRecFromMap.Reject_Case__c = false;
                caseFinalDMLMap.put(caseRecFromMap.Id, caseRecFromMap);
            }
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
        for(Profile profRec : [select Id, Name from profile where Name IN : ASF_Constants.VALIDATION_BYPASS_PROFILES]){
            bypassProfileId.add(profRec.Id);
        }
        //Bypass owner validations for the sys admin and Integration Profiles
        if((bypassProfileId.contains(UserInfo.getProfileId()) || ASF_BulkCaseProcessorUtility.isBulkProcessing || ASF_Constants.bypassOwnerChangeValidation) && !Test.isRunningTest()){
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
        // VIRENDRA - 11 JUNE 2024 - TO UPDATE CASE ASSIGNED TEAM ON CHANGE OWNER TO QUEUE.
        Map<Id,Group> caseAssignTeamMap = new Map<Id,Group>();
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
            Map<Id, List<Id>> caseOwnerGroupIdMap = new Map<Id, List<Id>>();
            Map<Id, String> newOwnerQueueIdNameMap = new Map<Id, String>();
            Map<Id, List<Id>> oldQueueAndMemberMap = new Map<Id, List<Id>>();
            Set<Id> groupIdset = new Set<Id>();
            Map<Id, List<Id>> oldgroupAndMemberMap = new Map<Id, List<Id>>();
            newCaseOwnerMap = new Map<Id, user>([SELECT Id, Business_Unit__c, Email FROM User WHERE Id = :userInfo.getUserId() OR Id IN: newCaseOwnerUserIdset]);  
            
            for(User userRec : ownerMap.values()){
                List<Id> managergroupIds = new List<Id>();
                if(userRec.managerGroupId__c != null){
                    managergroupIds = userRec.managerGroupId__c.split(',');
                }
                caseOwnerGroupIdMap.put(userRec.Id,managergroupIds);
            }
            for(Group queueRec : [select Id, name, DeveloperName, Email from group where type='Queue' and (Id IN: oldCaseOwnerQueueIdset OR Id IN :newCaseOwnerQueueIdset)]){
                if(oldCaseOwnerQueueIdset.contains(queueRec.Id)){
                    queueIdNameMap.put(queueRec.Id,queueRec);
                }
                if(newCaseOwnerQueueIdset.contains(queueRec.Id)){
                    newOwnerQueueIdNameMap.put(queueRec.Id,queueRec.DeveloperName);
                }
                // VIRENDRA - 11 JUNE 2024 - TO STORE CASE ASSIGNED TEAM NAME.
                caseAssignTeamMap.put(queueRec.Id,queueRec);
                // VIRENDRA - ENDS HERE.
            }
            List<Id> allManagergroupIds = new List<Id>();
            if(!caseOwnerGroupIdMap.isEmpty()){
                for(List<Id> ids : caseOwnerGroupIdMap.values()){
                    allManagergroupIds.addAll(ids);
                }
            }
            //Query case owner's Queue members
            for(GroupMember gmember : [Select userOrGroupId, groupId from GroupMember where 
                                       Group.Type = 'Queue' and UserOrGroupId != null and 
                                       (groupId IN :allManagergroupIds OR groupId IN :queueIdNameMap.keySet())]){
                                           
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
                    if(((String)queueMember).startsWith('00G') && oldgroupAndMemberMap.containsKey(queueMember)){
                        oldQueueAndMemberMap.get(queueId).addAll(oldgroupAndMemberMap.get(queueMember));
                    }
                }
            }
            
            for(Case c : newList){
                String oldOwnerId = oldMap.get(c.Id).OwnerId; 
                String newOwnerId = c.OwnerId;
                Boolean hasManagerQueueAccess = false;
                
                if(oldOwnerId != null){
                    for(Id idVal : caseOwnerGroupIdMap.KeySet()){
                        if(idVal == oldOwnerId){
                            List<Id> managerQueueIds = new List<Id>();
                            managerQueueIds.addAll(caseOwnerGroupIdMap.get(idVal));
                            for(Id managerQueueId : managerQueueIds){
                                if(oldQueueAndMemberMap.get(managerQueueId) != null && oldQueueAndMemberMap.get(managerQueueId).contains(userInfo.getUserId())){
                                    hasManagerQueueAccess = true;
                                }
                            }
                        }
                    }
                }
                
                if(oldOwnerId.startsWith('00G') && 
                   !(oldQueueAndMemberMap.get(oldOwnerId) != null && oldQueueAndMemberMap.get(oldOwnerId).contains(userInfo.getUserId()) && newOwnerId == userInfo.getUserId()) &&
                   !(queueIdNameMap.get(oldOwnerId).Email != null && queueIdNameMap.get(oldOwnerId).Email == newCaseOwnerMap.get(userInfo.getUserId()).Email && 
                     (oldQueueAndMemberMap.get(oldOwnerId) != null && oldQueueAndMemberMap.get(oldOwnerId).contains(newOwnerId) || (newCaseOwnerMap.get(newOwnerId)!= null && newCaseOwnerMap.get(newOwnerId).Email == queueIdNameMap.get(oldOwnerId).Email))) && 
                   !hasPermission){
                       c.addError(System.Label.ASF_Owner_Change_Access_Val_Msg);
                       
                   }else if(!oldOwnerId.startsWith('00G') && !hasPermission && oldOwnerId != userInfo.getUserId() && 
                            ownerMap.get(oldOwnerId).managerId != userInfo.getUserId() &&
                            ownerMap.get(oldOwnerId).manager.manager.Id != userInfo.getUserId() && 
                            ownerMap.get(oldOwnerId).manager.manager.manager.Id != userInfo.getUserId() &&
                            ownerMap.get(oldOwnerId).manager.manager.manager.manager.Id != userInfo.getUserId() &&
                            ownerMap.get(oldOwnerId).manager.manager.manager.manager.manager.Id != userInfo.getUserId() &&
                            !(hasManagerQueueAccess)
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
        // VIRENDRA - 11 JUNE 2024 - TO UPDATE THE CASE TEAM ON CHANGE OWNER FROM UI AND TARGET NEW OWNER ID IS QUEUE ID.
        for(Case c : newList){
            if(c.OwnerId != oldMap.get(c.Id).OwnerId && c.OwnerId.getSObjectType() == Group.sObjectType){
                // VIRENDRA - 11 JUNE 2024 - UPDATE CASE ASSIGNED TEAM NAME IN BEFORE UPDATE CONTEXT
                // WHEN ONLY CASE OWNER IS CHANGED TO QUEUE.
                c.Case_Assigned_Team__c = caseAssignTeamMap.containsKey(c.OwnerId) ? caseAssignTeamMap.get(c.OwnerId).Name : '';
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
    
    public static boolean runvalidateCCCOnUpdateFromEBOT(Case caseRec, case oldCaseRec){
        if(caseRec.Business_Unit__c == ASF_Constants.ABSLI_BU && 
           oldCaseRec.CCC_External_Id__c == null && 
           caseRec.Preframework_to_Framework_FromUI__c == false)
        {
            return false;
        }
        return true;
        
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
            //AM-Removed the null check for CCC External ID
            if(oldMap != null && (caseRec.accountId != oldMap.get(caseRec.Id).accountId 
                                  || caseRec.assetId != oldMap.get(caseRec.Id).assetId ||caseRec.Lead__c != oldMap.get(caseRec.Id).Lead__c 
                                  || caseRec.CCC_External_Id__c != oldMap.get(caseRec.Id).CCC_External_Id__c)){
                                      if(runvalidateCCCOnUpdateFromEBOT(caseRec , oldMap.get(caseRec.Id))){
                                          modifiedCases.add(caseRec);  
                                          cccIds.add(caseRec.CCC_External_Id__c);
                                          if(caseRec.accountId != oldMap.get(caseRec.Id).accountId){
                                              accountIds.add(caseRec.accountId);
                                          } 
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
                    caseRec.typeSubTypeMismatch__c = false;
                    caseRec.Type_Sub_Type_Mismatch_Reason__c = '';
                    ASF_Case_Category_Config__c configuredCurrentCCC = cccExternalIdCategoryMap.get(caseRec.CCC_External_Id__c);
                    if(caseRec.accountId == null && configuredCurrentCCC.Only_CRN_Mandatory__c == true && caseRec.Lead__c == null ){
                        caseRec.typeSubTypeMismatch__c = true;
                        caseRec.Type_Sub_Type_Mismatch_Reason__c = 'Account is Not there. But type sub type is selected which required Customer';
                    } 
                    if(caseRec.assetId == null && configuredCurrentCCC.is_FA_Mandatory__c == true && caseRec.Lead__c == null && caseRec.Business_Unit__c != ASF_Constants.ABSLIG_BU){
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
    public static void addTocaseFinalDMLMap(Case caseRec){
        caseFinalDMLMap = caseFinalDMLMap == null ? new Map<Id, Case>() : caseFinalDMLMap;
        if(!caseFinalDMLMap.containsKey(caseRec.Id)){
            Case caseObj = new Case(Id = caseRec.Id);
            caseFinalDMLMap.put(caseObj.Id, caseObj);
        }
        Case caseRecFromMap = caseFinalDMLMap.get(caseRec.Id);
        Map<String, Object> populatedFieldMap = caseRec.getPopulatedFieldsAsMap();
        for(String fieldName : populatedFieldMap.keySet()){
            caseRecFromMap.put(fieldName, caseRec.get(fieldName));
        }
        caseFinalDMLMap.put(caseRecFromMap.Id, caseRecFromMap);
    }
}