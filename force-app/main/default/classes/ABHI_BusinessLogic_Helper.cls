/*********************************************************
*Class        :  ABHI_BusinessLogic_Helper
*Author       :  ABHI Team
*Created Date :  30/08/2024
*@description  :  Class for ABHI related Business Logic 
*********************************************************/

@SuppressWarnings('PMD.CyclomaticComplexity,PMD.StdCyclomaticComplexity,PMD.CognitiveComplexity')
public with sharing class ABHI_BusinessLogic_Helper {
    
    public Map<String, List<Case>> mapOfBUToNewCase;
    public Map<Id, Case> mapOfIdToOldCase;
    public List<Case> abhiNewCaseList;

    /**
    * @description  Calling ABHI specific Business Logic method
    * @param mapOfBUToNewCs - map of BU to new cases
    * @param oldMapOfCases -  map of Id to old cases
    * @param triggerContext -  Trigger Context
    */
    public void abhiHandlerMethod(Map<String, List<Case>> mapOfBUToNewCs,  Map<Id, Case> oldMapOfCases, String triggerContext) {
        
        if(mapOfBUToNewCs.containsKey('ABHI') && mapOfBUToNewCs.get('ABHI').size() > 0) {
            ABHI_CaseDetailHelper abhiCsDetHelperObj = new ABHI_CaseDetailHelper();
            mapOfBUToNewCase = mapOfBUToNewCs;
            mapOfIdToOldCase = oldMapOfCases;
            abhiNewCaseList = mapOfBUToNewCs.get('ABHI');
            // Convert oldMapOfCases to List<Case>
            List<Case> oldCaseList = new List<Case>(oldMapOfCases.values());
            
            sendSecondStageCommunication(mapOfBUToNewCs.get('ABHI'), oldMapOfCases, triggerContext);
            sendRecatCommunicationOnlyWhenAckSent(mapOfBUToNewCs.get('ABHI'), oldMapOfCases, triggerContext);
            skipChecklistValidationForBulkMove(mapOfBUToNewCs.get('ABHI'), triggerContext);
            
            if(triggerContext == 'AfterASFCodeBeforeUpdate') {
                policyIsMandatory();
                dedupeLogicOnCaseCreation(triggerContext);
                populateFieldsOnCase(abhiNewCaseList, mapOfIdToOldCase);//RNWL
            }
            else if(triggerContext == 'AfterASFCodeInBeforeInsert') {
                dedupeLogicOnCaseCreation();
            }
            else {
                abhiCsDetHelperObj.updateAccountFieldsonCaseDetail(abhiNewCaseList);
                abhiCsDetHelperObj.populateCaseOnABHICaseDet(abhiNewCaseList, mapOfIdToOldCase, triggerContext);
                abhiCsDetHelperObj.captureReopenFieldsOnCaseReopen(abhiNewCaseList, mapOfIdToOldCase, triggerContext);
            }
        }
    }
    
    /**
    * Jira Story  - PR1030924-500
    * @description - ABHI send Recategorisation communication only when second stage acknowledgement sent
    */
    public void sendRecatCommunicationOnlyWhenAckSent(List<Case> lstSecondStageCommNew,Map<Id, Case> mapSecondStageCommOld, String strTriggerContext){

        List<ASF_Case_Category_Config__c> lstCCCRecords = new List<ASF_Case_Category_Config__c>();
        set<Id> setCaseIdsToQuery = new set<Id>();
        List<Case> lstCasesToWorkUpon = new List<Case>();
        set<Case> setCasesToCommunicate = new set<Case>();
        set<String> setCCCExternalIds = new set<String>();
        Map<String, String> mapRecat2EmailTemplateMap = new Map<String, String>();
        Map<String, String> mapRecat2SMSMetadataMap = new Map<String, String>();

        List<Case> lstFinalCases = new List<Case>();
        Map<Id, String> mapFinalCaseId2Email = new Map<Id, String>();
        Map<Id, String> mapFinalCaseId2SMS = new Map<Id, String>();
        Map<Id, Boolean> mapFinalCaseId2isTransferred = new Map<Id, Boolean>();

        if(!lstSecondStageCommNew.isEmpty() && mapSecondStageCommOld != null && !mapSecondStageCommOld.Values()?.isEmpty()){
            for(Case objCase: lstSecondStageCommNew){
                if(strTriggerContext == 'AfterASFCodeInAfterUpdate' && objCase.CCC_External_Id__c != mapSecondStageCommOld?.get(objCase.Id)?.CCC_External_Id__c && objCase.Recategorisation_Date__c != mapSecondStageCommOld?.get(objCase.Id)?.Recategorisation_Date__c){
                    setCCCExternalIds.add(objCase.CCC_External_Id__c);
                    setCaseIdsToQuery.add(objCase.Id);
                }
            }
        }

        lstCasesToWorkUpon = [SELECT Id, ABHI_Case_Detail__c, ABHI_Case_Detail__r.ABHI_isSecondStageAcknowledgementSent__c, 
                              CCC_External_Id__c, Stage__c, Recategorisation_Date__c
                              FROM Case
                              WHERE Id IN: setCaseIdsToQuery
                              WITH SYSTEM_MODE];

        lstCCCRecords = [SELECT Id,Resolved_Case_Email_Template__c,Resolved_Case_SMS_Metadata__c,
                         Additional_Email_Templates__c,Additional_SMS_Metadata__c, CCC_External_Id__c,
                         Recategorisation_Email_Template__c, Recategorisation_SMS_Metadata__c,
                         (SELECT Id, StageName__c, Order__c FROM Case_Stage_Configs__r WHERE Order__c = 2 LIMIT 1)
                         FROM ASF_Case_Category_Config__c 
                         WHERE CCC_External_Id__c IN: setCCCExternalIds
                         WITH SYSTEM_MODE];

        if(!lstCCCRecords.isEmpty()){
            for(ASF_Case_Category_Config__c objCCCRec : lstCCCRecords){
                if(!String.isBlank(objCCCRec.Recategorisation_Email_Template__c))
                    mapRecat2EmailTemplateMap.put(objCCCRec.CCC_External_Id__c, objCCCRec.Recategorisation_Email_Template__c);
                if(!String.isBlank(objCCCRec.Recategorisation_SMS_Metadata__c))
                    mapRecat2SMSMetadataMap.put(objCCCRec.CCC_External_Id__c, objCCCRec.Recategorisation_SMS_Metadata__c);
            }
        }

        if(!lstCasesToWorkUpon.isEmpty()){
            for(Case objCase : lstCasesToWorkUpon){
                if(objCase.ABHI_Case_Detail__r?.ABHI_isSecondStageAcknowledgementSent__c){
                    if(mapRecat2EmailTemplateMap != null && mapRecat2EmailTemplateMap.containsKey(objCase.CCC_External_Id__c) && !String.isBlank(mapRecat2EmailTemplateMap.get(objCase.CCC_External_Id__c))){
                        mapFinalCaseId2Email.put(objCase.Id,mapRecat2EmailTemplateMap.get(objCase.CCC_External_Id__c));
                    	setCasesToCommunicate.add(objCase);
                    	mapFinalCaseId2isTransferred.put(objCase.Id, false);
                    }
                    if(mapRecat2SMSMetadataMap != null && mapRecat2SMSMetadataMap.containsKey(objCase.CCC_External_Id__c) && !String.isBlank(mapRecat2SMSMetadataMap.get(objCase.CCC_External_Id__c))){
                        mapFinalCaseId2SMS.put(objCase.Id,mapRecat2SMSMetadataMap.get(objCase.CCC_External_Id__c));
                    	setCasesToCommunicate.add(objCase);
                    	mapFinalCaseId2isTransferred.put(objCase.Id, false);
                    }
                }
            }
            if(!setCasesToCommunicate.isEmpty())lstFinalCases.addAll(setCasesToCommunicate);
        }

        List<Database.SaveResult> lstPlatformEventResult = ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(lstFinalCases, mapFinalCaseId2Email, mapFinalCaseId2SMS, mapFinalCaseId2isTransferred);
    }
    
    /**
    * Jira Story  - PR1030924-500
    * @description - ABHI send communication in second stage
    */
    public void sendSecondStageCommunication(List<Case> lstSecondStageCommNew,Map<Id, Case> mapSecondStageCommOld, String strTriggerContext){
        
        List<ASF_Case_Category_Config__c> lstCCCRecords = new List<ASF_Case_Category_Config__c>();
        set<Id> setCaseIdsToQuery = new set<Id>();
        List<Case> lstCasesToWorkUpon = new List<Case>();
        set<Case> setCasesToCommunicate = new set<Case>();
        set<String> setCCCExternalIds = new set<String>();
        Map<String, Map<String, String>> mapStage2EmailTemplateMap = new Map<String, Map<String, String>>();
        Map<String, Map<String, String>> mapStage2SMSMetadataMap = new Map<String, Map<String, String>>();
        Map<String, String> mapResolved2EmailTemplateMap = new Map<String, String>();
        Map<String, String> mapResolved2SMSMetadataMap = new Map<String, String>();
        Map<String, String> mapUnresolved2EmailTemplateMap = new Map<String, String>();
        Map<String, String> mapUnresolved2SMSMetadataMap = new Map<String, String>();
        Map<String, String> mapCCCExtId2SecondStageName = new Map<String, String>();
        
        List<Case> lstFinalCases = new List<Case>();
        Map<Id, String> mapFinalCaseId2Email = new Map<Id, String>();
        Map<Id, String> mapFinalCaseId2SMS = new Map<Id, String>();
        Map<Id, Boolean> mapFinalCaseId2isTransferred = new Map<Id, Boolean>();
        List<ABHI_Case_Detail__c> lstABHICaseDetails2Update = new List<ABHI_Case_Detail__c>();
        
        if(!lstSecondStageCommNew.isEmpty() && mapSecondStageCommOld != null && !mapSecondStageCommOld.Values()?.isEmpty()){
            for(Case objCase: lstSecondStageCommNew){
                if(strTriggerContext == 'AfterASFCodeInAfterInsert' || (strTriggerContext == 'AfterASFCodeInAfterUpdate' && objCase.Stage__c != mapSecondStageCommOld?.get(objCase.Id)?.Stage__c)){
                    setCCCExternalIds.add(objCase.CCC_External_Id__c);
                    setCaseIdsToQuery.add(objCase.Id);
                }
            }
        }
        
        lstCasesToWorkUpon = [SELECT Id, ABHI_Case_Detail__c, ABHI_Case_Detail__r.ABHI_isSecondStageAcknowledgementSent__c, 
                              CCC_External_Id__c, Stage__c, Status
                              FROM Case
                              WHERE Id IN: setCaseIdsToQuery
                              WITH SYSTEM_MODE];
        
        lstCCCRecords = [SELECT Id,Resolved_Case_Email_Template__c,Resolved_Case_SMS_Metadata__c,
                         Additional_Email_Templates__c,Additional_SMS_Metadata__c, CCC_External_Id__c,
                         Rejected_Case_Email_Template__c, Rejected_Case_SMS_Metadata__c,
                         (SELECT Id, StageName__c, Order__c FROM Case_Stage_Configs__r WHERE Order__c = 2 LIMIT 1)
                         FROM ASF_Case_Category_Config__c 
                         WHERE CCC_External_Id__c IN: setCCCExternalIds
                         WITH SYSTEM_MODE];
        
        if(!lstCCCRecords.isEmpty()){
            for(ASF_Case_Category_Config__c objCCCRec : lstCCCRecords){
                if(!String.isBlank(objCCCRec.Additional_Email_Templates__c))
                    mapStage2EmailTemplateMap.put(objCCCRec.CCC_External_Id__c, ABCL_IntegrationCommonUtility.fetchStpTemplates(objCCCRec.Additional_Email_Templates__c));
                if(!String.isBlank(objCCCRec.Additional_SMS_Metadata__c))
                    mapStage2SMSMetadataMap.put(objCCCRec.CCC_External_Id__c, ABCL_IntegrationCommonUtility.fetchStpTemplates(objCCCRec.Additional_SMS_Metadata__c));
                mapCCCExtId2SecondStageName.put(objCCCRec.CCC_External_Id__c, objCCCRec.Case_Stage_Configs__r.iterator().next().StageName__c);
                mapResolved2EmailTemplateMap.put(objCCCRec.CCC_External_Id__c, objCCCRec.Resolved_Case_Email_Template__c);
                mapResolved2SMSMetadataMap.put(objCCCRec.CCC_External_Id__c, objCCCRec.Resolved_Case_SMS_Metadata__c);
                mapUnresolved2EmailTemplateMap.put(objCCCRec.CCC_External_Id__c, objCCCRec.Rejected_Case_Email_Template__c);
                mapUnresolved2SMSMetadataMap.put(objCCCRec.CCC_External_Id__c, objCCCRec.Rejected_Case_SMS_Metadata__c);
            }
        }
        
        if(!lstCasesToWorkUpon.isEmpty()){
            for(Case objCase : lstCasesToWorkUpon){
                if(mapStage2EmailTemplateMap != null && mapStage2EmailTemplateMap.containsKey(objCase.CCC_External_Id__c) && mapStage2EmailTemplateMap.get(objCase.CCC_External_Id__c) != null && mapStage2EmailTemplateMap.get(objCase.CCC_External_Id__c).containsKey(objCase.Stage__c) && !String.isBlank(mapStage2EmailTemplateMap.get(objCase.CCC_External_Id__c).get(objCase.Stage__c))){
                    mapFinalCaseId2Email.put(objCase.Id,mapStage2EmailTemplateMap.get(objCase.CCC_External_Id__c).get(objCase.Stage__c));
                    setCasesToCommunicate.add(objCase);
                    mapFinalCaseId2isTransferred.put(objCase.Id, false);
                }
                if(mapStage2SMSMetadataMap != null && mapStage2SMSMetadataMap.containsKey(objCase.CCC_External_Id__c) && mapStage2SMSMetadataMap.get(objCase.CCC_External_Id__c) != null && mapStage2SMSMetadataMap.get(objCase.CCC_External_Id__c).containsKey(objCase.Stage__c) && !String.isBlank(mapStage2SMSMetadataMap.get(objCase.CCC_External_Id__c).get(objCase.Stage__c))){
                    if(mapCCCExtId2SecondStageName != null && mapCCCExtId2SecondStageName.containsKey(objCase.CCC_External_Id__c) && !String.isBlank(mapCCCExtId2SecondStageName.get(objCase.CCC_External_Id__c))){
                        if((mapCCCExtId2SecondStageName.get(objCase.CCC_External_Id__c) != objCase.Stage__c) || (mapCCCExtId2SecondStageName.get(objCase.CCC_External_Id__c) == objCase.Stage__c && !objCase.ABHI_Case_Detail__r?.ABHI_isSecondStageAcknowledgementSent__c)){
                            mapFinalCaseId2SMS.put(objCase.Id,mapStage2SMSMetadataMap.get(objCase.CCC_External_Id__c).get(objCase.Stage__c));
                            setCasesToCommunicate.add(objCase);
                            mapFinalCaseId2isTransferred.put(objCase.Id, false);
                            if(mapCCCExtId2SecondStageName.get(objCase.CCC_External_Id__c) == objCase.Stage__c)lstABHICaseDetails2Update.add(new ABHI_Case_Detail__c(Id = objCase.ABHI_Case_Detail__c, ABHI_isSecondStageAcknowledgementSent__c = true));
                        }
                    }
                }
                if(!String.isBlank(objCase.ABHI_Case_Detail__c) && objCase.ABHI_Case_Detail__r?.ABHI_isSecondStageAcknowledgementSent__c){
                    if(ABHI_Constants.CASES_UNRESOLVED_LIST.contains(objCase.Status)){
                        if(mapUnresolved2EmailTemplateMap != null && mapUnresolved2EmailTemplateMap.containsKey(objCase.CCC_External_Id__c) && !String.isBlank(mapUnresolved2EmailTemplateMap.get(objCase.CCC_External_Id__c))){
                            mapFinalCaseId2Email.put(objCase.Id,mapUnresolved2EmailTemplateMap.get(objCase.CCC_External_Id__c));
                            setCasesToCommunicate.add(objCase);
                            mapFinalCaseId2isTransferred.put(objCase.Id, false);
                        }
                        if(mapUnresolved2SMSMetadataMap != null && mapUnresolved2SMSMetadataMap.containsKey(objCase.CCC_External_Id__c) && !String.isBlank(mapUnresolved2SMSMetadataMap.get(objCase.CCC_External_Id__c))){
                            mapFinalCaseId2SMS.put(objCase.Id,mapUnresolved2SMSMetadataMap.get(objCase.CCC_External_Id__c));
                            setCasesToCommunicate.add(objCase);
                            mapFinalCaseId2isTransferred.put(objCase.Id, false);
                        }
                    }
                }
            }
            if(!setCasesToCommunicate.isEmpty())lstFinalCases.addAll(setCasesToCommunicate);
        }
        
        List<Database.SaveResult> lstPlatformEventResult = ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(lstFinalCases, mapFinalCaseId2Email, mapFinalCaseId2SMS, mapFinalCaseId2isTransferred);
        if(!lstABHICaseDetails2Update.isEmpty())UPDATE lstABHICaseDetails2Update;
    }
                                                                                                                
                                                                         
    
    /**
    * Jira Story  - PR1030924-406
    * @description - ABHI Skip Checklists for bulk stage movement
    */
    public void skipChecklistValidationForBulkMove(List<Case> lstSkipABHICases, String strTriggerContext){
        if(strTriggerContext == 'BeforeASFCodeInBeforeUpdate' && ABHI_BulkMoveNextConverterUtility.boolSkipChklstAbhiBulk){
            Map<Id, Set<String>> recIdToSkipperFlag = new Map<Id, Set<String>>();
            if(!lstSkipABHICases.isEmpty()){
                for(Case objCase : lstSkipABHICases){
                    recIdToSkipperFlag.put(objCase.Id, new Set<String>{ASF_Constants.SKIP_VALIDATE_CHECKLISTS, ASF_Constants.SKIP_STAGE_ENTRY_CHECKS, ASF_Constants.SKIP_STAGE_EXIT_CHECKS, ASF_Constants.SKIP_VALIDATION_CHECKS, ASF_Constants.SKIP_VALIDATE_TASKS});
                }
            }
            ASF_CaseTriggerModularHelper.setManualSkipperFlags(recIdToSkipperFlag, null);
        }
    }

    /**
    * Jira Story  - PR1030924-103
    * @description - Policy number is mandatory on customer tagging but not for Prospect.
    */
    public void policyIsMandatory(){
        for(Case cs : abhiNewCaseList) {
            if(String.isNotBlank(cs.AccountId) && String.isBlank(cs.AssetId)&& cs.Source__c != 'IGMS' && cs.Technical_Source__c != 'API') {
                cs.addError(ABHI_Constants.POLICY_IS_MANDATORY_ON_CUSTOMER);
            }
        }
    }
    
    /**
     * @description  Calling ABHI specific case validations before case creation
     * @param caseRecord - the case that is created from create case page
     * @param Called from lwc component
     */
    @AuraEnabled
    public static String abhiCaseValidation(String caseRecord){
        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped((caseRecord));
        Map<String,List<String>> natureToGroupMap = new Map<String,List<String>>(); 
        String result = System.label.ABHI_Create_Case_Validation;
        try{
            Map<String, ABHI_Create_Case_Validations__mdt> metadataRecords = ABHI_Create_Case_Validations__mdt.getAll();
            if (!metadataRecords.isEmpty()) {
                Set<String> groupNames = new Set<String>();
                
                //Fetch all metadata values and store it in map
                for (String key : metadataRecords.keySet()) {
                    ABHI_Create_Case_Validations__mdt metadataRecord = metadataRecords.get(key);
                    if(metadataRecord.Validation_Name__c == 'NatureValidation'){
                        if(!natureToGroupMap.containsKey(metadataRecord.Nature__c)){
                            natureToGroupMap.put(metadataRecord.Nature__c, new List<String>());
                        }
                        natureToGroupMap.get(metadataRecord.Nature__c).addAll(metadataRecord.Public_Groups__c.split(';'));
                        groupNames.addAll(metadataRecord.Public_Groups__c.split(';'));
                    }
                }
                //validate if user is part of the queue
                if(natureToGroupMap.containsKey(String.valueOf(jsonMap.get('Nature__c')))){
                    Map<Id,Group> publicGroupIds = new Map<Id,Group>([SELECT Id,DeveloperName FROM Group WHERE DeveloperName IN: groupNames AND Type = 'Regular']);
                    List<GroupMember> groupMembers = [
                        SELECT Id, GroupId, Group.DeveloperName
                        FROM GroupMember 
                        WHERE GroupId IN: publicGroupIds.keySet() 
                        AND UserOrGroupId = :UserInfo.getUserId()
                    ];
                    if(!groupMembers.isEmpty()){
                        for(GroupMember member : groupMembers){
                            if(natureToGroupMap.get(String.valueOf(jsonMap.get('Nature__c'))).contains(member.Group.DeveloperName)){
                                return 'Success';
                            }
                        }
                    }
                    // return success if there is no entry for the current Case's nature in the metadata
                }else{
                    return 'Success';
                }
            }
            
        }catch(Exception e){
            logtheException(e);
            throw new AuraHandledException(e.getMessage());
        }        
        return result;
    }
    
    /**
    * Jira Story   - PR1030924-30 
    * @description - Get ABHI Create Case Validations metadat
    * @param sourceToExclude - Source to exclude for dedupe logic
    * @param bu -  Business Unit of the cases
    * @return createCaseValMdt
    */
    @SuppressWarnings('PMD.UnusedLocalVariable')
    public List<ABHI_Create_Case_Validations__mdt> getABHICreateCaseValidationMdt(String sourceToExclude, String bu){
        
        List<ABHI_Create_Case_Validations__mdt> createCaseValMdt = [SELECT id, Source__c FROM ABHI_Create_Case_Validations__mdt 
                                                                    WHERE masterLabel like :sourceToExclude and Business_Unit__c =: bu WITH SYSTEM_MODE];
        return createCaseValMdt;
    }

    /**
    * Jira Story  - PR1030924-30
    * @description - Case De-Dupe Logic
    */
    @SuppressWarnings('PMD.NcssMethodCount,PMD.AvoidDeeplyNestedIfStmts')
    public void dedupeLogicOnCaseCreation(){
        
        List<String> sourceToExcludeList = new List<String>();
        List<String> accIdList = new List<String>();
        List<String> policyIdList = new List<String>();
        List<ASF_Case_Category_Config__c> caseCategoryConfigs = new List<ASF_Case_Category_Config__c>();
        Map<String,ASF_Case_Category_Config__c> mapOfcccExtIdToCCCRec = new Map<String,ASF_Case_Category_Config__c>();
        Map<String,List<Case>> mapOfcccExtIdToCaseList = new Map<String,List<Case>>();
        Map<String,Case> mapOfNewUniqueCaseList = new Map<String,Case>();
        String sourceToExc = '%Source to exclude%';
        List<ABHI_Create_Case_Validations__mdt> abhiCreateCaseValMdt = getABHICreateCaseValidationMdt(sourceToExc, abhiNewCaseList[0].Business_Unit__c);
        
        for(ABHI_Create_Case_Validations__mdt ccMdt : abhiCreateCaseValMdt) {
            sourceToExcludeList.add(ccMdt.Source__c.toLowerCase());
        }
        for(Case cas : abhiNewCaseList) {
            String csCCCExtId = cas?.CCC_External_Id__c;
            String uniqueKeyForCase = '';

            if(String.isNotBlank(cas.accountId)) {
                accIdList.add(cas.accountId);  
                uniqueKeyForCase += cas.accountId + '-';
            }
            if(String.isNotBlank(cas.AssetId)) { 
                policyIdList.add(cas.AssetId);   
                uniqueKeyForCase += cas.AssetId + '-';
            }
            if(String.isNotBlank(csCCCExtId)) {
                if(!mapOfcccExtIdToCaseList.containsKey(csCCCExtId)) {
                    mapOfcccExtIdToCaseList.put(csCCCExtId, new List<Case>());
                }
                mapOfcccExtIdToCaseList.get(csCCCExtId).add(cas);

                uniqueKeyForCase += csCCCExtId;
            }
            mapOfNewUniqueCaseList.put(uniqueKeyForCase, cas);
        }

        caseCategoryConfigs = [SELECT Id, CCC_External_Id__c, Dedupe_Check__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c =: mapOfcccExtIdToCaseList.keySet() WITH SECURITY_ENFORCED];
        
        for(ASF_Case_Category_Config__c cccRecord: caseCategoryConfigs){
            mapOfcccExtIdToCCCRec.put(cccRecord.CCC_External_Id__c, cccRecord);
        }
        List<Case> dupeCaseList = [SELECT Id, Sub_Type_Text__c, CaseNumber, AccountId, CCC_External_Id__c, AssetId
                           	FROM Case 
                            WHERE (AccountId IN :accIdList)
                           	AND CCC_External_Id__c IN :mapOfcccExtIdToCaseList.keySet()
                           	AND (AssetId IN :policyIdList)
                           	AND isClosed!=true WITH SECURITY_ENFORCED];

        for(Case dupeCase: dupeCaseList) {
            
            String existingCaseUniqueKey = '';
            String exstingCaseAccountId     = dupeCase?.AccountId ?? '';
            String exstingCaseAssetId       = dupeCase?.AssetId ?? '';
            String exstingCaseCCCExternalId = dupeCase?.CCC_External_Id__c ?? '';

            if(String.isNotBlank(exstingCaseAccountId) && String.isNotBlank(exstingCaseAssetId) && String.isNotBlank(exstingCaseCCCExternalId)) {
                
                existingCaseUniqueKey = exstingCaseAccountId + '-' + exstingCaseAssetId + '-' + exstingCaseCCCExternalId;
                Case newCase  = mapOfNewUniqueCaseList.get(existingCaseUniqueKey) != null ? mapOfNewUniqueCaseList.get(existingCaseUniqueKey) : new Case();
                String sourceOfnewCase = newCase?.Source__c.toLowerCase() ?? '';
                Boolean dedupeCheck = mapOfcccExtIdToCCCRec.get(newCase.CCC_External_Id__c)?.Dedupe_Check__c;

                if(newCase != null && !sourceToExcludeList.contains(sourceOfnewCase) && !sourceOfnewCase.containsIgnoreCase('BOT') && dedupeCheck) {
                    Case cs = mapOfNewUniqueCaseList.get(existingCaseUniqueKey);
                    cs.addError('Existing case available in CRM# '+dupeCase.CaseNumber+',CaseSubType# '+dupeCase.Sub_Type_Text__c);
                }
            }
        }
    } 
}