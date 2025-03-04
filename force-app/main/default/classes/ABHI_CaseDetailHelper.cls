/*********************************************************
*@Class        :  ABHI_CaseDetailHelper
*@Author       :  Sara Jaipuria
*@Created Date :  31-07-2024
*@Last Modified:  31-07-2024
*@description  :  Class for ABHI Case Detail Object Business Logic
*********************************************************/
public with sharing class ABHI_CaseDetailHelper {
    
    /****************************************************************************************************************
    * @Function - populateABHILCaseDetailFields
    * @param newCaseMap
    * @description - updates Sub_Type__c on Extention object based on Type__c and Sub_Type__c on CCC
    *****************************************************************************************************************/
    @SuppressWarnings('PMD.ApexDoc')
    public void populateABHILCaseDetailFields(List<Case> newCaseList) {
        
        List<String> listOfcccExtIds = new List<String>();
        Map<String, Case> mapofCaseDetailToCase = new Map<String, Case>();
        Map<String, ASF_Case_Category_Config__c> mapOfCCCExtIdIdsToCCCRec = new Map<String, ASF_Case_Category_Config__c>();
        
        for(Case caseRec : newCaseList) {
            if(caseRec.ABHI_Case_Detail__c != null && caseRec.Business_Unit__c == 'ABHI') {
                listOfcccExtIds.add(caseRec.CCC_External_Id__c);
                mapofCaseDetailToCase.put(caseRec.ABHI_Case_Detail__c, caseRec);
            }
        }
        
        if(mapofCaseDetailToCase.keySet().size() > 0) {
            Map<Id, ASF_Case_Category_Config__c> mapOfCCCIdToCCCRec = new Map<Id, ASF_Case_Category_Config__c>([
                SELECT Id, Type__c, Sub_Type__c, CCC_External_Id__c
                FROM ASF_Case_Category_Config__c
                WHERE CCC_External_Id__c IN :listOfcccExtIds
            ]);
            
            Map<Id, ABHI_Case_Detail__c> mapOfCaseDetailIdToCaseDetailRec = new Map<Id, ABHI_Case_Detail__c>([
                SELECT Id, Sub_Type__c 
                FROM ABHI_Case_Detail__c
                WHERE Id IN :mapofCaseDetailToCase.keySet()
            ]);
            
            for(ASF_Case_Category_Config__c cccRec : mapOfCCCIdToCCCRec.values()) {
                mapOfCCCExtIdIdsToCCCRec.put(cccRec.CCC_External_Id__c, cccRec);
            }
            
            for(ABHI_Case_Detail__c caseDetailRec : mapOfCaseDetailIdToCaseDetailRec.values()) {
                String cccExtId = mapofCaseDetailToCase.get(caseDetailRec.Id).CCC_External_Id__c;
                String typeOfCCC = mapOfCCCExtIdIdsToCCCRec.get(cccExtId)?.Type__c ?? '';
                String subTypeOfCCC = mapOfCCCExtIdIdsToCCCRec.get(cccExtId)?.Sub_Type__c ?? '';
                caseDetailRec.Sub_Type__c = typeOfCCC+':'+subTypeOfCCC;
            }
            
            if(mapOfCaseDetailIdToCaseDetailRec.size() > 0) {
                update mapOfCaseDetailIdToCaseDetailRec.values();
            }
        }
    } 

    /**
    * Jira Story  - PR1030924-98
    * @param abhiNewCaseList - List of ABHI new cases
    * @param mapOfIdToOldCase - Map of Id to Old Case
    * @param triggerContext  - In which context the method is being called
    * @description - Claim filter based on customer or policy update on CASE
    */
    @SuppressWarnings('PMD.AvoidDeeplyNestedIfStmts,PMD.CognitiveComplexity,PMD.CyclomaticComplexity')
    public void populateCaseOnABHICaseDet(List<Case> abhiNewCaseList, Map<Id, Case> mapOfIdToOldCase, String triggerContext){
        
        List<ABHI_Case_Detail__c> abhiCaseDetList = new List<ABHI_Case_Detail__c>();

        for(Case cs : abhiNewCaseList) {
            
            if(String.isNotBlank(cs.ABHI_Case_Detail__c)) {
                ABHI_Case_Detail__c abhiCaseDetRec = new ABHI_Case_Detail__c();
                if(triggerContext == 'AfterASFCodeInAfterInsert') { 
                    abhiCaseDetRec.Policy__c = cs?.AssetId;
                }
                else if(triggerContext == 'AfterASFCodeInAfterUpdate') {
                    abhiCaseDetRec.Policy__c = cs?.AssetId;
                    Case oldCase = mapOfIdToOldCase.get(cs.Id);
                    if(String.isNotBlank(cs.AssetId) && cs.AssetId != oldCase.AssetId) {      
                        abhiCaseDetRec.Claim__c = null;
                    }
                    else if(String.isBlank(cs.AssetId)) {
                        abhiCaseDetRec.Claim__c = null;
                        abhiCaseDetRec.Policy__c = null;
                    }
                }
                ABHI_Case_Detail__c nullCheck = new ABHI_Case_Detail__c();
                if(abhiCaseDetRec != nullCheck) {
                    abhiCaseDetRec.Id = cs.ABHI_Case_Detail__c;
                    abhiCaseDetList.add(abhiCaseDetRec);
                }
            }
        }

        if(Schema.sObjectType.ABHI_Case_Detail__c.isUpdateable() && abhiCaseDetList.size() > 0) {
            update abhiCaseDetList;
        }
    }
    
    /**
    * Jira Story  - PR1030924-419
    * @description - Capture Case Old resolution comments, Case Old Resolved By and Case reopened By on reopen
    */
    
    public void captureReopenFieldsOnCaseReopen(List<Case> abhiNewCaseList, Map<Id, Case> mapOfIdToOldCase, String triggerContext){
        List<ABHI_Case_Detail__c> abhiCaseDetList = new List<ABHI_Case_Detail__c>();
        Set<Id> abhiCaseDetIdsResolved = new Set<Id>();
        Set<Id> abhiCaseDetIdsReopened = new Set<Id>();
        Map<String, Case> mapofCaseDetailToResolvedCase = new Map<String, Case>();
        Map<String, Case> mapofCaseDetailToReopenedCase = new Map<String, Case>();
        if(triggerContext == 'AfterASFCodeInAfterUpdate') {
            for(Case caseRec : abhiNewCaseList) {
                if(caseRec.Business_Unit__c == 'ABHI' && caseRec.Stage__c == 'Resolved' && caseRec.Reopened__c == FALSE && mapOfIdToOldCase.get(caseRec.Id).Stage__c != 'Resolved') {
                    abhiCaseDetIdsResolved.add(caseRec.ABHI_Case_Detail__c);
                    mapofCaseDetailToResolvedCase.put(caseRec.ABHI_Case_Detail__c, caseRec);
                } 
                else if(caseRec.Business_Unit__c == 'ABHI' && caseRec.Stage__c == 'Reopened' && caseRec.Reopened__c == true && mapOfIdToOldCase.get(caseRec.Id).Stage__c == 'Resolved') {
                    abhiCaseDetIdsReopened.add(caseRec.ABHI_Case_Detail__c);
                    mapofCaseDetailToReopenedCase.put(caseRec.ABHI_Case_Detail__c, caseRec);
                }
            }
            
            for(ABHI_Case_Detail__c abhiCaseDet : [SELECT Id, Case_Closed_Resolution_Comments__c , Case_Closed_Resolved_By__c , Case_Reopened_By__c , Resolution_Comments__c  
                                                   FROM ABHI_Case_Detail__c 
                                                   WHERE Id IN: abhiCaseDetIdsResolved] ) {
                Case cs = mapofCaseDetailToResolvedCase.get(abhiCaseDet.Id);
                 if(cs != null) {
                     abhiCaseDet.Case_Closed_Resolution_Comments__c = abhiCaseDet.Resolution_Comments__c;
                     abhiCaseDet.Case_Closed_Resolved_By__c = mapOfIdToOldCase.get(cs.Id).OwnerText__c;
                     abhiCaseDetList.add(abhiCaseDet);
                 }
            }
            
            for(ABHI_Case_Detail__c abhiCaseDet : [SELECT Id, Case_Closed_Resolution_Comments__c , Case_Closed_Resolved_By__c , Case_Reopened_By__c , Case_Reopened_By_Id__c, Resolution_Comments__c  
                                                   FROM ABHI_Case_Detail__c 
                                                   WHERE Id IN: abhiCaseDetIdsReopened] ) {
                Case cs = mapofCaseDetailToReopenedCase.get(abhiCaseDet.Id);
                 if(cs != null) {
                     abhiCaseDet.Case_Reopened_By__c = cs.OwnerText__c;
                     if(String.valueOf(cs.OwnerId).startsWith('005')){
                         abhiCaseDet.Case_Reopened_By_Id__c = cs.OwnerId;
                     }
                     abhiCaseDetList.add(abhiCaseDet);
                 }
            }
            System.debug('abhiCaseDetList****-->'+ abhiCaseDetList);
            if(abhiCaseDetList.size() > 0) {
            update abhiCaseDetList;
            }
        }      
    }
    
    /**
    * @description - populate permanent address fields
    */
    
    public void updateAccountFieldsonCaseDetail(List<Case> newCaseList) {
        List<String> cccIds = new List<String>{'ABHI_Policy_Request1','ABHI_Policy_Request3'};
        List<String> listOfAccIds = new List<String>();
        Map<String, Case> mapofCaseDetailToCase = new Map<String, Case>();
        for(Case caseRec : newCaseList) {
            if(caseRec.AccountId != null && caseRec.ABHI_Case_Detail__c != null && caseRec.Business_Unit__c == 'ABHI' && cccIds.contains(caseRec.CCC_External_Id__c)) {
                mapofCaseDetailToCase.put(caseRec.ABHI_Case_Detail__c, caseRec);
                listOfAccIds.add(caseRec.AccountId);
            }
        }
        
        if(mapofCaseDetailToCase.keySet().size() > 0) {
            
            Map<Id, Account> mapOfAccIdtoAcc = new Map<Id, Account>([
                SELECT Id, BillingStreet, BillingCity, BillingState, BillingCountry, BillingPostalCode
                FROM Account
                WHERE Id IN :listOfAccIds
            ]);
            
            
            Map<Id, ABHI_Case_Detail__c> mapOfCaseDetailIdToCaseDetailRec = new Map<Id, ABHI_Case_Detail__c>([
                SELECT Id, Street__c, City__c , State__c , Country__c, Postal_Code__c 
                FROM ABHI_Case_Detail__c
                WHERE Id IN :mapofCaseDetailToCase.keySet()
            ]);
            
            for(ABHI_Case_Detail__c caseDetailRec : mapOfCaseDetailIdToCaseDetailRec.values()) {
                String accId = mapofCaseDetailToCase.get(caseDetailRec.Id).AccountId;
                caseDetailRec.Street__c = mapOfAccIdtoAcc.get(accId).BillingStreet;
                caseDetailRec.City__c = mapOfAccIdtoAcc.get(accId).BillingCity;
                caseDetailRec.State__c = mapOfAccIdtoAcc.get(accId).BillingState;
                caseDetailRec.Country__c = mapOfAccIdtoAcc.get(accId).BillingCountry;
                caseDetailRec.Postal_Code__c = mapOfAccIdtoAcc.get(accId).BillingPostalCode;
            }
            
            if(mapOfCaseDetailIdToCaseDetailRec.size() > 0) {
               update mapOfCaseDetailIdToCaseDetailRec.values();
           }
        }
    }
}
