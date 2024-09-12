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
                String typeOfCCC = mapOfCCCExtIdIdsToCCCRec.get(cccExtId).Type__c;
                String subTypeOfCCC = mapOfCCCExtIdIdsToCCCRec.get(cccExtId).Sub_Type__c;
                caseDetailRec.Sub_Type__c = typeOfCCC+':'+subTypeOfCCC;
            }
            
            if(mapOfCaseDetailIdToCaseDetailRec.size() > 0) {
                update mapOfCaseDetailIdToCaseDetailRec.values();
            }
        }
    } 
}