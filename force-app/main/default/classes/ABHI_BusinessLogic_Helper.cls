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
            skipChecklistValidationForBulkMove(mapOfBUToNewCs.get('ABHI'), triggerContext);
            
            if(triggerContext == 'AfterASFCodeBeforeUpdate') {
                policyIsMandatory();
                ABHI_CaseStageUpdateHelper.MoveToStageMethod(abhiNewCaseList, oldCaseList);
            }
            else if(triggerContext == 'AfterASFCodeInBeforeInsert') {
                dedupeLogicOnCaseCreation();
            }
            else {
                abhiCsDetHelperObj.populateCaseOnABHICaseDet(abhiNewCaseList, mapOfIdToOldCase, triggerContext);
            }
        }
    }
    
    /**
    * Jira Story  - PR1030924-500
    * @description - ABHI send communication in second stage
    */
    public void sendSecondStageCommunication(List<Case> lstSecondStageCommNew,Map<Id, Case> mapSecondStageCommOld, String strTriggerContext){
        
        List<ASF_Case_Category_Config__c> lstCCCRecords = new List<ASF_Case_Category_Config__c>();
        List<Case> lstCasesToWorkUpon = new List<Case>();
        set<Case> setCasesToCommunicate = new set<Case>();
        set<String> setCCCExternalIds = new set<String>();
        Map<String, Map<String, String>> mapStage2EmailTemplateMap = new Map<String, Map<String, String>>();
        Map<String, Map<String, String>> mapStage2SMSMetadataMap = new Map<String, Map<String, String>>();
        
        List<Case> lstFinalCases = new List<Case>();
        Map<Id, String> mapFinalCaseId2Email = new Map<Id, String>();
        Map<Id, String> mapFinalCaseId2SMS = new Map<Id, String>();
        Map<Id, Boolean> mapFinalCaseId2isTransferred = new Map<Id, Boolean>();
        
        if(!lstSecondStageCommNew.isEmpty() && mapSecondStageCommOld != null && !mapSecondStageCommOld.Values()?.isEmpty()){
            for(Case objCase: lstSecondStageCommNew){
                if(!objCase.moved_back__c && !objCase.IsClosed && (strTriggerContext == 'AfterASFCodeInAfterInsert' || (strTriggerContext == 'AfterASFCodeInAfterUpdate' && objCase.Stage__c != mapSecondStageCommOld?.get(objCase.Id)?.Stage__c))){
                    setCCCExternalIds.add(objCase.CCC_External_Id__c);
                    lstCasesToWorkUpon.add(objCase);
                }
            }
        }
        
        lstCCCRecords = [SELECT Id,Resolved_Case_Email_Template__c,Resolved_Case_SMS_Metadata__c,
                         Additional_Email_Templates__c,Additional_SMS_Metadata__c, CCC_External_Id__c
                         FROM ASF_Case_Category_Config__c 
                         WHERE CCC_External_Id__c IN: setCCCExternalIds];
        
        if(!lstCCCRecords.isEmpty()){
            for(ASF_Case_Category_Config__c objCCCRec : lstCCCRecords){
                if(!String.isBlank(objCCCRec.Additional_Email_Templates__c))
                    mapStage2EmailTemplateMap.put(objCCCRec.CCC_External_Id__c, ABCL_IntegrationCommonUtility.fetchStpTemplates(objCCCRec.Additional_Email_Templates__c));
                if(!String.isBlank(objCCCRec.Additional_SMS_Metadata__c))
                    mapStage2SMSMetadataMap.put(objCCCRec.CCC_External_Id__c, ABCL_IntegrationCommonUtility.fetchStpTemplates(objCCCRec.Additional_SMS_Metadata__c));
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
                    mapFinalCaseId2SMS.put(objCase.Id,mapStage2SMSMetadataMap.get(objCase.CCC_External_Id__c).get(objCase.Stage__c));
                    setCasesToCommunicate.add(objCase);
                    mapFinalCaseId2isTransferred.put(objCase.Id, false);
                }
            }
            if(!setCasesToCommunicate.isEmpty())lstFinalCases.addAll(setCasesToCommunicate);
        }
        
        List<Database.SaveResult> lstPlatformEventResult = ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(lstFinalCases, mapFinalCaseId2Email, mapFinalCaseId2SMS, mapFinalCaseId2isTransferred);
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
                    recIdToSkipperFlag.put(objCase.Id, new Set<String>{ASF_Constants.SKIP_VALIDATE_CHECKLISTS});
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
            System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('abhiCaseValidation Case creation validation');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
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
                     
                      if(assetRec.ProductName__c != 'Active One' && accountRec.Is_Chronic__c == false){
                          result = issueCodeToErrorMsgMap.get(String.valueOf(jsonMap.get('CCC_External_Id__c')));
                      }
                      else if(assetRec.ProductName__c == 'Active One' && !(accountRec.CMP_OPD__c == true && accountRec.Chronic_care__c == true)
                             && !(assetRec.Plan_Name__c == 'VYTL')){
                              result = issueCodeToErrorMsgMap.get(String.valueOf(jsonMap.get('CCC_External_Id__c')));    
                      }
                      
                  } else{
                      return result;
                  }
            }
            
        }catch(Exception e){
            System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('abhiCaseValidation Case creation validation');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
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
                String sourceOfnewCase = newCase?.Source__c?.toLowerCase() ?? '';
                Boolean dedupeCheck = mapOfcccExtIdToCCCRec.get(newCase.CCC_External_Id__c)?.Dedupe_Check__c;

                if(newCase != null && !sourceToExcludeList.contains(sourceOfnewCase) && !sourceOfnewCase.containsIgnoreCase('BOT') && dedupeCheck) {
                    Case cs = mapOfNewUniqueCaseList.get(existingCaseUniqueKey);
                    cs.addError('Existing case available in CRM# '+dupeCase.CaseNumber+',CaseSubType# '+dupeCase.Sub_Type_Text__c);
                }
            }
        }
    }
    public void searchAndAssocFieldsForAPICases(List<Case> newListCase,  Map<Id, Case> oldMapOfCases, String triggerContext) {
        Set<Id> setCaseDetail = new Set<Id>();
        Map<Id, String> mapDetailIdClaim = new Map<Id, String>();
        Map<Id, String> mapDetailIdCustomer = new Map<Id, String>();
        Map<Id, Id> mapCaseIdPolicyId = new Map<Id, Id>();
        Map<ID, Id> mapCaseDetails = new Map<ID, Id>();
        Map<Id, ABHI_Case_Detail__c> mapCaseDetUpdate = new Map<Id,ABHI_Case_Detail__c>();
        Map<String, Id> mapClaimDet = new Map<String, Id>();
        Map<String, Id> mapAccountLobId = new Map<String, Id>();
        ABHI_Case_Detail__c caseDetail = null;
        
        try {
            for(Case individualCase : newListCase) {
                if(individualCase.Technical_Source__c == 'API' && (oldMapOfCases == null && individualCase.ClaimNo_Text__c != null || individualCase.Customer_Member_Text__c != null ) ||
                        (oldMapOfCases.get(individualCase.Id).ClaimNo_Text__c != individualCase.ClaimNo_Text__c || oldMapOfCases.get(individualCase.Id).Customer_Member_Text__c != individualCase.Customer_Member_Text__c)) {
                    if(individualCase.ClaimNo_Text__c != null) {
                        mapDetailIdClaim.put(individualCase.ABHI_Case_Detail__c, individualCase.ClaimNo_Text__c);
                        
                    }
                    else if(individualCase.ClaimNo_Text__c == null && oldMapOfCases.get(individualCase.Id).ClaimNo_Text__c != individualCase.ClaimNo_Text__c) {
                        if(!mapCaseDetUpdate.containsKey(caseDetail.Id)) {
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
                    else if(individualCase.Customer_Member_Text__c == null && oldMapOfCases.get(individualCase.Id).Customer_Member_Text__c != individualCase.Customer_Member_Text__c) {
                        if(!mapCaseDetUpdate.containsKey(individualCase.ABHI_Case_Detail__c)) {
                            caseDetail = new ABHI_Case_Detail__c();
                            caseDetail.Id = individualCase.ABHI_Case_Detail__c;
                            mapCaseDetUpdate.put(caseDetail.Id, caseDetail);                                                                            
                        }
                        mapCaseDetUpdate.get(caseDetail.Id).Member__c = null;
                    }   
                    mapCaseDetails.put(individualCase.Id, individualCase.ABHI_Case_Detail__c);
                }
            }
            for(Claim__c claim : [SELECT Id, Name, Policy_Number__r.LAN__c from Claim__c WHERE Name IN :mapDetailIdClaim.values()]) {
                if(!mapClaimDet.containsKey(claim.Name)) {
                    mapClaimDet.put(claim.Name, claim.Id);  
                }
            }
            /*for(Account acc : [SELECT ID,LOB_Client_Code__c FROM Account where LOB_Client_Code__c IN :mapDetailIdCustomer.values()]) {
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
            System.debug('@@@ mapCaseDetUpdate.values()'+ mapCaseDetUpdate.values());
            Database.update(mapCaseDetUpdate.values(), false);
            
        }
        catch(Exception e) {
            
        }
    }  
     
}