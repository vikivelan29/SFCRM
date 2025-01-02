/*********************************************************
*Class        :  ABHI_BusinessLogic_Helper
*Author       :  ABHI Team
*Created Date :  30/08/2024
*@description  :  Class for ABHI related Business Logic 
*********************************************************/

@SuppressWarnings('PMD.CyclomaticComplexity,PMD.StdCyclomaticComplexity,PMD.CognitiveComplexity,PMD.NcssTypeCount')
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
                dedupeLogicOnCaseCreation(triggerContext);
                populateFieldsOnCase(abhiNewCaseList, null);//RNWL
                ABHI_CaseCreationValidation.checkCreateCaseValidations(abhiNewCaseList, mapOfIdToOldCase, triggerContext);
            }else if(triggerContext == 'BeforeASFCodeInBeforeUpdate') {
                ABHI_CaseStageUpdateHelper.MoveToStageMethod(abhiNewCaseList, oldCaseList);
            }
            /*else if(triggerContext == 'AfterASFCodeInAfterInsert') {
                abhiCsDetHelperObj.updateAccountFieldsonCaseDetail(abhiNewCaseList);
            }*/
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
            if(String.isNotBlank(cs.AccountId) && String.isBlank(cs.AssetId)&& cs.Source__c != 'IGMS' && cs.Technical_Source__c != 'API' && cs.Technical_Source__c != 'Email') {
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
     * @description  Calling ABHI specific case validations before case creation
     * @param caseRecord - the case that is created from create case page
     * @param Called from lwc component
     */
    @AuraEnabled
    public static String abhiActiveOneValidation(String caseRecord){
        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped((caseRecord));
        system.debug('jsonMap--'+jsonMap);
        Map<String,String> issueCodeToErrorMsgMap = new Map<String,String>(); 
        String result = 'Success';
        try{
            Map<String, ABHI_Create_Case_Validations__mdt> metadataRecords = ABHI_Create_Case_Validations__mdt.getAll();
            if (!metadataRecords.isEmpty()) {

                //Fetch all metadata values and store it in map
                for (String key : metadataRecords.keySet()) {
                    ABHI_Create_Case_Validations__mdt metadataRecord = metadataRecords.get(key);
                    if(metadataRecord.Validation_Name__c == 'ActiveOne'){
                        issueCodeToErrorMsgMap.put(metadataRecord.Issue_Code__c, metadataRecord.Error_Message__c);
                    }
                }
                //validate the case record
                if(jsonMap.get('CCC_External_Id__c') != null && issueCodeToErrorMsgMap.containsKey(String.valueOf(jsonMap.get('CCC_External_Id__c'))) 
                  && jsonMap.get('AssetId') != null && jsonMap.get('AccountId') != null){
                      
                     Account accountRec = [select Id,Is_Chronic__c, CMP_OPD__c, Chronic_care__c from account where Id=: String.valueOf(jsonMap.get('AccountId'))];
                     Asset assetRec = [select Id, ProductName__c, Plan_Name__c from asset where Id=: String.valueOf(jsonMap.get('AssetId'))];  
                     
                      if(assetRec.ProductName__c != 'Activ One' && accountRec.Is_Chronic__c == false){
                          result = issueCodeToErrorMsgMap.get(String.valueOf(jsonMap.get('CCC_External_Id__c')));
                      }
                      else if((assetRec.ProductName__c == 'Activ One' && !(accountRec.CMP_OPD__c == true && accountRec.Chronic_care__c == true))
                             && (assetRec.ProductName__c == 'Activ One' && !(assetRec.Plan_Name__c == 'VYTL'))){
                              result = issueCodeToErrorMsgMap.get(String.valueOf(jsonMap.get('CCC_External_Id__c')));    
                      }
                      
                  } else{
                      return result;
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
    public void dedupeLogicOnCaseCreation(String triggerCntxt){
        
        List<String> sourceToExcludeList = new List<String>();
        List<String> accIdList = new List<String>();
        List<String> policyIdList = new List<String>();
        List<Case> newCaseDedupeList = new List<Case>();
        List<ASF_Case_Category_Config__c> caseCategoryConfigs = new List<ASF_Case_Category_Config__c>();
        Map<String,ASF_Case_Category_Config__c> mapOfcccExtIdToCCCRec = new Map<String,ASF_Case_Category_Config__c>();
        Map<String,List<Case>> mapOfcccExtIdToCaseList = new Map<String,List<Case>>();
        Map<String,Case> mapOfNewUniqueCaseList = new Map<String,Case>();
        String sourceToExc = '%Source to exclude%';

        for(Case newCaseRec : abhiNewCaseList) {
            if(triggerCntxt == 'AfterASFCodeBeforeUpdate') {
                Case oldCaseRec = mapOfIdToOldCase.get(newCaseRec.Id);
                if(newCaseRec.Is_Recategorise_Allowed__c == true && oldCaseRec.Recategorisation_Date__c != newCaseRec.Recategorisation_Date__c) {
                    newCaseDedupeList.add(newCaseRec);
                }
            }
            else if(triggerCntxt == 'AfterASFCodeInBeforeInsert') {
                newCaseDedupeList.add(newCaseRec);
            }
        }

        if(newCaseDedupeList.size() == 0) {
            return;
        }

        List<ABHI_Create_Case_Validations__mdt> abhiCreateCaseValMdt = getABHICreateCaseValidationMdt(sourceToExc, newCaseDedupeList[0].Business_Unit__c);
        
        for(ABHI_Create_Case_Validations__mdt ccMdt : abhiCreateCaseValMdt) {
            sourceToExcludeList.add(ccMdt.Source__c.toLowerCase());
        }
        for(Case cas : newCaseDedupeList) {
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

        caseCategoryConfigs = [SELECT Id, CCC_External_Id__c, Exclude_Dedupe__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c =: mapOfcccExtIdToCaseList.keySet()];
        
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
                String sourceOfnewCase = newCase?.Source__c?.toLowerCase() ?? '';
                Boolean excludeDedupeCTST = mapOfcccExtIdToCCCRec.get(newCase.CCC_External_Id__c)?.Exclude_Dedupe__c;

                if(!excludeDedupeCTST && newCase != null && !sourceToExcludeList.contains(sourceOfnewCase)) {
                    Case cs = mapOfNewUniqueCaseList.get(existingCaseUniqueKey);
                    cs.addError('Existing case available in CRM# '+dupeCase.CaseNumber+',CaseSubType# '+dupeCase.Sub_Type_Text__c);
                }
            }
        }
    }
    /* 
    * @description - Update Claim and memeber id on Case Detail
    * @param List<Case> newListCase
    * @param oldMapOfCases
    */
    public void searchAndAssocFieldsForAPICases(List<Case> newListCase,  Map<Id, Case> oldMapOfCases) {
        Set<Id> setCaseDetail = new Set<Id>();
        Map<Id, String> mapDetailIdClaim = new Map<Id, String>();
        Map<Id, String> mapDetailIdCustomer = new Map<Id, String>();
        Map<Id, Cover__c> mapDetailIdCover = new Map<Id, Cover__c>();
        Map<Id, Health_Provider__c> mapDetailIdHospital = new Map<Id, Health_Provider__c>();
        Map<Id, Id> mapCaseIdPolicyId = new Map<Id, Id>();
        Map<ID, Id> mapCaseDetails = new Map<ID, Id>();
        Map<Id, ABHI_Case_Detail__c> mapCaseDetUpdate = new Map<Id,ABHI_Case_Detail__c>();
        Map<String, Id> mapClaimDet = new Map<String, Id>();
        Map<String, Id> mapAccountLobId = new Map<String, Id>();
        ABHI_Case_Detail__c caseDetail = null;
        
        try {
            for(Case individualCase : newListCase) {
                if(individualCase.Technical_Source__c == 'API' &&
                   ((oldMapOfCases == null && individualCase.ClaimNo_Text__c != null 
                    || individualCase.Customer_Member_Text__c != null 
                    || individualCase.Cover_Code_Text__c != null 
                    || individualCase.Hospital_Code_Text__c != null) 
                    || (oldMapOfCases != null && oldMapOfCases.get(individualCase.Id).ClaimNo_Text__c != individualCase.ClaimNo_Text__c
                    || oldMapOfCases.get(individualCase.Id).Customer_Member_Text__c != individualCase.Customer_Member_Text__c
                    || oldMapOfCases.get(individualCase.Id).Cover_Code_Text__c != individualCase.Cover_Code_Text__c 
                    || oldMapOfCases.get(individualCase.Id).Hospital_Code_Text__c != individualCase.Hospital_Code_Text__c))) {
                        
                    if(individualCase.ClaimNo_Text__c != null) {
                        mapDetailIdClaim.put(individualCase.ABHI_Case_Detail__c, individualCase.ClaimNo_Text__c);
                    }
                    else if(individualCase.ClaimNo_Text__c == null && oldMapOfCases != null && oldMapOfCases.get(individualCase.Id).ClaimNo_Text__c != individualCase.ClaimNo_Text__c) {
                        if(!mapCaseDetUpdate.containsKey(individualCase.ABHI_Case_Detail__c)) {
                            caseDetail = new ABHI_Case_Detail__c();
                            caseDetail.Id = individualCase.ABHI_Case_Detail__c;
                            mapCaseDetUpdate.put(caseDetail.Id, caseDetail);   
                        }  
                         mapCaseDetUpdate.get(caseDetail.Id).Claim__c = null;                                                                           
                    } 
                        
                    if(individualCase.Customer_Member_Text__c != null) {
                        mapDetailIdCustomer.put(individualCase.Id, 'ABHI_'+individualCase.Customer_Member_Text__c);
                        mapCaseIdPolicyId.put(individualCase.Id, individualCase.AssetId);
                    }
                    else if(individualCase.Customer_Member_Text__c == null && oldMapOfCases != null && oldMapOfCases.get(individualCase.Id).Customer_Member_Text__c != individualCase.Customer_Member_Text__c) {
                        if(!mapCaseDetUpdate.containsKey(individualCase.ABHI_Case_Detail__c)) {
                            caseDetail = new ABHI_Case_Detail__c();
                            caseDetail.Id = individualCase.ABHI_Case_Detail__c;
                            mapCaseDetUpdate.put(caseDetail.Id, caseDetail);                                                                            
                        }
                        mapCaseDetUpdate.get(caseDetail.Id).Member__c = null;
                    }  
                    
                    if(individualCase.Cover_Code_Text__c != null) {
                        Cover__c coverReference = new Cover__c(Cover_Code__c = individualCase.Cover_Code_Text__c);  
                         caseDetail = new ABHI_Case_Detail__c(Id = individualCase.ABHI_Case_Detail__c);
                         if(!mapCaseDetUpdate.containsKey(individualCase.ABHI_Case_Detail__c)) {
                             mapCaseDetUpdate.put(individualCase.ABHI_Case_Detail__c, caseDetail);                                                                            
                         }
                         mapCaseDetUpdate.get(individualCase.ABHI_Case_Detail__c).Cover_Name__r = coverReference;
                        //mapDetailIdCover.put(individualCase.ABHI_Case_Detail__c, coverReference);
                    }
                    else if(individualCase.Cover_Code_Text__c == null && oldMapOfCases != null && 
                            oldMapOfCases.get(individualCase.Id).Cover_Code_Text__c != individualCase.Cover_Code_Text__c) {
                        if(!mapCaseDetUpdate.containsKey(individualCase.ABHI_Case_Detail__c)) {
                            caseDetail = new ABHI_Case_Detail__c();
                            caseDetail.Id = individualCase.ABHI_Case_Detail__c;
                            mapCaseDetUpdate.put(caseDetail.Id, caseDetail);   
                        }  
                         mapCaseDetUpdate.get(individualCase.ABHI_Case_Detail__c).Cover_Name__c = null;                                                                           
                    }   
                    System.debug('@@covrcode'+mapCaseDetUpdate.values());
                    if(individualCase.Hospital_Code_Text__c != null) {
                        Health_Provider__c hospitalReference = new Health_Provider__c(Provider_Code__c = individualCase.Hospital_Code_Text__c);  
                        mapDetailIdHospital.put(individualCase.ABHI_Case_Detail__c, hospitalReference);
                        caseDetail = new ABHI_Case_Detail__c(Id = individualCase.ABHI_Case_Detail__c);
                         if(!mapCaseDetUpdate.containsKey(individualCase.ABHI_Case_Detail__c)) {
                             mapCaseDetUpdate.put(individualCase.ABHI_Case_Detail__c, caseDetail);                                                                            
                         }
                         mapCaseDetUpdate.get(individualCase.ABHI_Case_Detail__c).Hospital__r = hospitalReference;
                    }
                    else if(individualCase.Hospital_Code_Text__c == null && oldMapOfCases != null && 
                         oldMapOfCases.get(individualCase.Id).Hospital_Code_Text__c != individualCase.Hospital_Code_Text__c) {
                             if(!mapCaseDetUpdate.containsKey(individualCase.ABHI_Case_Detail__c)) {
                                 caseDetail = new ABHI_Case_Detail__c();
                                 caseDetail.Id = individualCase.ABHI_Case_Detail__c;
                                 mapCaseDetUpdate.put(caseDetail.Id, caseDetail);   
                             }  
                             mapCaseDetUpdate.get(individualCase.ABHI_Case_Detail__c).Hospital__c = null;                                                                           
                   }   
                        
                    mapCaseDetails.put(individualCase.Id, individualCase.ABHI_Case_Detail__c);
                }
            }
            for(Claim__c claim : [SELECT Id, Name, Policy_Number__r.LAN__c from Claim__c WHERE Name IN :mapDetailIdClaim.values()]) {
                if(!mapClaimDet.containsKey(claim.Name)) {
                    mapClaimDet.put(claim.Name, claim.Id);  
                }
            }            
            /*for(Account acc : [SELECT ID,LOB_Client_Code__c FROM Cover__c where Cover_Code__c IN :mapDetailIdCover.values()]) {
                if(!mapAccountLobId.containsKey(acc.LOB_Client_Code__c)) {
                    mapAccountLobId.put(acc.LOB_Client_Code__c, acc.ID);
                }
            }*/
            for(Customer_Member_Mapping__c cusMemMap : [SELECT ID, MemberId__r.LOB_Client_Code__c,Policy_Number__c FROM Customer_Member_Mapping__c WHERE  
                                                        MemberId__r.LOB_Client_Code__c IN :mapDetailIdCustomer.values()
                                                        AND Policy_Number__c IN :mapCaseIdPolicyId.values()]) {
                for(Id caseId : mapDetailIdCustomer.keySet()) {
                    if(mapCaseIdPolicyId.containsKey(caseId) && mapCaseIdPolicyId.get(caseId).equals(cusMemMap.Policy_Number__c)
                        && mapDetailIdCustomer.get(caseId).equals(cusMemMap.MemberId__r.LOB_Client_Code__c)) {
                            caseDetail = new ABHI_Case_Detail__c();
                            caseDetail.Id = mapCaseDetails.get(caseId);
                            if(!mapCaseDetUpdate.containsKey(caseDetail.Id)) {
                                mapCaseDetUpdate.put(caseDetail.Id, caseDetail);                                                                            
                            }   
                            mapCaseDetUpdate.get(caseDetail.Id).Member__c = cusMemMap.Id;
                            mapCaseDetUpdate.get(caseDetail.Id).Patient_Name__c = cusMemMap.Id;
                        }
                }
            }
            
            for(Id caseDet : mapDetailIdClaim.keyset()) {
                caseDetail = new ABHI_Case_Detail__c();
                if(mapClaimDet.containsKey(mapDetailIdClaim.get(caseDet))) {
                    caseDetail.Claim__c = mapClaimDet.get(mapDetailIdClaim.get(caseDet));
                    caseDetail.Id = caseDet;
                    if(!mapCaseDetUpdate.containsKey(caseDetail.Id)) {
                        mapCaseDetUpdate.put(caseDetail.Id, caseDetail);                                                                            
                    }
                    mapCaseDetUpdate.get(caseDetail.Id).Claim__c = mapClaimDet.get(mapDetailIdClaim.get(caseDet));
                }
            }
            
            /* for(Id caseDet : mapDetailIdCover.keyset()) {
                caseDetail = new ABHI_Case_Detail__c();
                 caseDetail.Id = caseDet;
                 if(!mapCaseDetUpdate.containsKey(caseDet)) {
                     mapCaseDetUpdate.put(caseDet, caseDetail);                                                                            
                 }
                 mapCaseDetUpdate.get(caseDet).Cover_Name__r = mapDetailIdCover.get(caseDet);
           
            }*/
            System.debug('@@@ mapCaseDetUpdate.values()'+ mapCaseDetUpdate.values());
            Database.SaveResult[] srList = Database.update(mapCaseDetUpdate.values(), false);
            System.debug('@@@ mapCaseDetUpdate.values()2'+ mapCaseDetUpdate.values());
        }
        catch(Exception e) {
            logtheException(e);
        }
    }
    /**
    * @description - Get Current user details
    * @return usr
    */
    public static User getCurrentUserInfo(){
        
        List<User> usr = [SELECT id, Source_Code__c, Business_Unit__c FROM User WHERE id = :UserInfo.getUserId() WITH SYSTEM_MODE];
        return usr[0];
    }

    /**
    * Jira Story  - PR1030924-703 and PR1030924-669
    * @param caseRecord - the case that is created from create case page
    * @return result - store the result of the case validations
    * @description - Source Based Case creation restriction
    */
    @SuppressWarnings('PMD.AvoidDeeplyNestedIfStmts,PMD.NcssMethodCount')
    @AuraEnabled
    public static String abhiCaseSourceValidation(Case caseRecord) {

        Map<String, Map<String, ABHI_Create_Case_Validations__mdt>> issueSourceMap = new Map<String, Map<String, ABHI_Create_Case_Validations__mdt>>();
        String caseBusinessUnit = caseRecord.Business_Unit__c ?? '';
        String caseCCCExtId = caseRecord.CCC_External_Id__c ?? '';
        String caseSource = caseRecord.Source__c!=null?caseRecord.Source__c.toLowerCase(): '';
        List<String> caseCreationRestrictionLabelList = System.label.ABHI_Case_Restriction_Creation.split(',');
        String userSourceCode = getCurrentUserInfo()?.Source_Code__c;
        String result = 'Success';

        try{
            List<ABHI_Create_Case_Validations__mdt> createCaseValidationMetaRecords = [
                SELECT Validation_Name__c, Source__c, User_Source_Code__c, Issue_Code__c, Error_Message__c 
                FROM ABHI_Create_Case_Validations__mdt
                WHERE Business_Unit__c =:caseBusinessUnit AND 
                      Validation_Name__c in :caseCreationRestrictionLabelList
                WITH SYSTEM_MODE
            ];
            
            //Fetch all metadata values and store it in map
            for (ABHI_Create_Case_Validations__mdt cseValidationMetaRecord : createCaseValidationMetaRecords) {
                String issueCodeMdt = cseValidationMetaRecord?.Issue_Code__c ?? '';
                String userSourceCodeMdt = cseValidationMetaRecord?.User_Source_Code__c ?? '';

                if (!issueSourceMap.containsKey(issueCodeMdt)) {
                    issueSourceMap.put(issueCodeMdt, new Map<String, ABHI_Create_Case_Validations__mdt>());
                }
                issueSourceMap.get(issueCodeMdt).put(userSourceCodeMdt, cseValidationMetaRecord);
            }

            //validate the case record
            if(caseCCCExtId != null && issueSourceMap.containsKey(caseCCCExtId)) {    
                Map<String, ABHI_Create_Case_Validations__mdt> userSourceCodeToMetaDataRecMap = issueSourceMap?.get(caseCCCExtId) ?? new Map<String, ABHI_Create_Case_Validations__mdt>();
                ABHI_Create_Case_Validations__mdt metaRec = new ABHI_Create_Case_Validations__mdt();
                String validationNameMdt = '';
                List<String> srcMdt = new List<String>();
                List<ABHI_Create_Case_Validations__mdt> userSourceCodeToMetaList = userSourceCodeToMetaDataRecMap.values();

                if(userSourceCodeToMetaDataRecMap.containsKey(userSourceCode) && userSourceCodeToMetaDataRecMap.values().size() > 0) {
                    metaRec = userSourceCodeToMetaDataRecMap?.get(userSourceCode);
                    validationNameMdt = metaRec?.Validation_Name__c ?? '';
                    srcMdt = metaRec?.Source__c?.toLowerCase().split(',');

                    //PR1030924-703
                    if(validationNameMdt == 'Source_Based_Case_Creation_Restriction') {
                        if(!srcMdt.contains(caseSource)) {
                            result = metaRec.Error_Message__c;
                        }
                    }
                    // PR1030924-669
                    else if(validationNameMdt == 'User_Source_Code_Based_Case_Creation_Restriction') {
                        if(metaRec.User_Source_Code__c == userSourceCode && !srcMdt.contains(caseSource)) {
                            result = metaRec.Error_Message__c; 
                        }
                    }
                }
                else {
                    metaRec = userSourceCodeToMetaList[0];
                    result = metaRec.Error_Message__c; 
                }
            }
        }
        catch(Exception e){
            logtheException(e);
            throw new AuraHandledException(e.getMessage());
        }        
        return result;
    }

    /**
    * @param exception - exception occured during the code execution
    * @description - Log the exception
    */
    public static void logtheException(Exception exceptn) {
        System.debug('@@@mess' + exceptn.getMessage() + ' ' + exceptn.getLineNumber());
        ABCL_Logger.enableExceptionLogging();
        ABCL_Logger.push('Case creation validation');
        ABCL_Logger.message(exceptn.getMessage());
        ABCL_Logger.emit();
    }
    
    /**
    * @param : newCases, oldCaseMap - 
    * @return : void 
    * @description : Prepopulates Fields on Case during before insert and update
    */
    public void populateFieldsOnCase(List<Case> newCases, Map<Id, Case> oldCaseMap){
        
        Set<Id> assetIds = new Set<Id>();
        List<Case> casesToUpdate = new List<Case>();
        Map<Id, Asset> assetIdToOppMap = new  Map<Id, Asset>();
        
        for(Case casRec : newCases){
            Case oldCase = oldCaseMap != null ? oldCaseMap.get(casRec.Id) : null;
            if(casRec.AssetId != null && 
               ((oldCaseMap == null) || 
                (oldCase != null && oldCase.AssetId != casRec.AssetId))){
                	assetIds.add(casRec.AssetId);
                    casesToUpdate.add(casRec);
            }
        }

        if(assetIds.size() == 0){ return; }
        
        for(Asset asst : [SELECT Id, Calling_Source__c, (SELECT Id FROM Opportunities__r)
                               FROM Asset WHERE Id IN : assetIds]){
            assetIdToOppMap.put(asst.Id, asst);
        }
        //Update Calling Source on Case
        for(Case cas : casesToUpdate){
            cas.Calling_Source__c = assetIdToOppMap.get(cas.AssetId)?.Calling_Source__c ?? ''; 
		}
        
        if(oldCaseMap != NULL){ return; }
        
        //Update Renewal Request on Case for below profiles users
        Id profileId = UserInfo.getProfileId();
        if(profileId == null){ return; }
        
        List<Profile> profileList = [Select Id, Name FROM Profile WHERE Id = :profileId];
        
        if(profileList.size() > 0){
        
            if(profileList[0]?.Name != 'RNWL Base Profile' && profileList[0]?.Name != 'RNWL Manager Profile'){ return; }
            
            for(Case rnwlCase : casesToUpdate){
                if(assetIdToOppMap.get(rnwlCase.AssetId)?.Opportunities__r.size() > 0){
                   rnwlCase.Renewal_Request__c = assetIdToOppMap.get(rnwlCase.AssetId)?.Opportunities__r[0]?.Id; 
                }
            }  
        }
    }
    /**
    * @param : List<case> newList
    * @return : void 
    * @description : Prepopulates Fields on Case during before insert and update
    */
    public void checkAndBypassValidationFromAPICaseMember(List<case> newList){
        Set<String> caseAccountId = new Set<String>();
        Set<Id> caseAssetId = new Set<Id>();
        Map<Integer, boolean> mCaseMember = new Map<Integer,boolean>();
        Map<Integer, Case> mCaseMemberVsCase = new Map<Integer,Case>();
        
        Map<Id, Set<String>> recIdToSkipperFlag = new Map<Id, Set<String>>();
        
        
        for(Case c : newList){
            caseAccountId.add('ABHI_'+c.Customer_Member_Text__c);
            caseAssetId.add(c.AssetId);
            
            if(c.Customer_Member_Text__c != null && c.AssetId != null){
                String temp = 'ABHI_'+c.Customer_Member_Text__c +'_'+c.AssetId;
                integer iTemp = temp.hashCode();
                mCaseMember.put(iTemp, false);
                mCaseMemberVsCase.put(iTemp,c);
            }
        }
        if(caseAccountId.size()>0 && caseAssetId.size()>0){
            for(Customer_Member_Mapping__c cusMemMap : [SELECT ID, MemberId__r.LOB_Client_Code__c,Policy_Number__c FROM Customer_Member_Mapping__c WHERE
                                                        MemberId__r.LOB_Client_Code__c IN :caseAccountId
                                                        AND Policy_Number__c IN :caseAssetId]) 
            {
                String temp = cusMemMap.MemberId__r.LOB_Client_Code__c +'_'+cusMemMap.Policy_Number__c;
                Integer itemp = temp.hashCode();
                if(mCaseMember.containsKey(itemp)){
                    mCaseMember.put(itemp,true);
                }
            }
            
            for(Integer iKey :mCaseMemberVsCase.keySet()){
                Case c = mCaseMemberVsCase.get(iKey);
                if(mCaseMember.containsKey(iKey) && mCaseMember.get(iKey) == true){
                    recIdToSkipperFlag.put(c.ABHI_Case_Detail__c, new Set<String>{ASF_Constants.SKIP_VALIDATION_CHECKS});
                }
            }
        }
        
        
        if(recIdToSkipperFlag.keySet().size()>0){
            ASF_CaseTriggerModularHelper.setManualSkipperFlags(recIdToSkipperFlag, 'ABHI_Case_Detail__c');
        }
        
    }
}
