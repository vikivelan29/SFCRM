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

            if(triggerContext == 'AfterASFCodeBeforeUpdate') {
                policyIsMandatory();
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
                    if(!natureToGroupMap.containsKey(metadataRecord.Nature__c)){
                        natureToGroupMap.put(metadataRecord.Nature__c, new List<String>());
                    }
                    natureToGroupMap.get(metadataRecord.Nature__c).addAll(metadataRecord.Public_Groups__c.split(';'));
                    groupNames.addAll(metadataRecord.Public_Groups__c.split(';'));
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