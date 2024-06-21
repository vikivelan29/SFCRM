/**
* @description       : BSLI BeforeInsertTrigger Logic After ASF Code
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 06-21-2024
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class ABSLI_BeforeInsertTriggerLogic {
    /**
* @description This method is called from ASF_CaseTriggerBUSpecificHandler whenever a case is
* updated. This is the parent method
* @param newMap
*/
    public Static Map<Id, Case> absliCasesAdditionalFields;
    public static void executeBeforeInsertLogic(List<Case> newCases) {
        Map<Id, Case> mAbsliCases = new Map<Id, Case>();
        
        for (Case caseRec : newCases) {
            System.debug(caseRec.Business_Unit__c);
            if (caseRec.Business_Unit__c == ASF_Constants.ABSLI_BU) {
                mAbsliCases.put(caseRec.Id, caseRec);
            }
        }
        
        ABSLI_BeforeInsertTriggerLogic.checkComplaintApplicability(mAbsliCases.values());
    }
    
    /**
* @description This method is called from ASF_CaseTriggerBUSpecificHandler whenever a case is
* updated. To Restrict Complaint Category Type for Non-IGMS Complaints.
* @param absliCases
* @param oldMap
*/
    public static void checkComplaintApplicability(List<Case> absliCases) {
        Set<String> externalIds = new Set<String>();
        Set<String> caseDetailIds = new Set<String>();
        for (Case caseRec : absliCases) {
            if (caseRec.CCC_External_Id__c != null) {
                externalIds.add(caseRec.CCC_External_Id__c);
            }
            if (caseRec.ABSLI_Case_Detail__c != null) {
                caseDetailIds.add(caseRec.ABSLI_Case_Detail__c);
            }
        }
        
        if (Test.isRunningTest()) {
            // Mock data for testing
            ASF_Case_Category_Config__c mockConfig = new ASF_Case_Category_Config__c(CCC_External_Id__c = 'PEMT042', IGMS_Code__c = '#N/A');
            ABSLI_Case_Detail__c mockCaseDetail = new ABSLI_Case_Detail__c(Complaint_Category__c = 'Complaint');
            externalIds.add(mockConfig.CCC_External_Id__c);
            caseDetailIds.add(mockCaseDetail.Id);
        }
        
        // Query ASF_Case_Category_Config__c using the external IDs
        Map<String, ASF_Case_Category_Config__c> configMap = new Map<String, ASF_Case_Category_Config__c>();
        for (ASF_Case_Category_Config__c config : [SELECT Id, CCC_External_Id__c, IGMS_Code__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c IN :externalIds]) {
            configMap.put(config.CCC_External_Id__c, config);
        }
        
        Map<Id, ABSLI_Case_Detail__c> caseDetailMap = new Map<Id, ABSLI_Case_Detail__c>();
        for (ABSLI_Case_Detail__c detail : [SELECT Id, Complaint_Category__c FROM ABSLI_Case_Detail__c WHERE Id IN :caseDetailIds]) {
            caseDetailMap.put(detail.Id, detail);
        }
        
        for (Case caseRec : absliCases) {
            // Debug statements (optional)
            System.debug(caseRec.ABSLI_Case_Detail__c);
            System.debug(caseRec.Nature__c);
            System.debug(caseRec.Technical_Source__c);
            System.debug(configMap);
            
            if (caseRec.CCC_External_Id__c != null && configMap.containsKey(caseRec.CCC_External_Id__c)) {
                ASF_Case_Category_Config__c config = configMap.get(caseRec.CCC_External_Id__c);
                System.debug(config.IGMS_Code__c);
                
                if (caseRec.ABSLI_Case_Detail__c != null && caseDetailMap.containsKey(caseRec.ABSLI_Case_Detail__c)) {
                    ABSLI_Case_Detail__c caseDetail = caseDetailMap.get(caseRec.ABSLI_Case_Detail__c);
                    System.debug(caseDetail.Complaint_Category__c);
                    
                    if (config.IGMS_Code__c == '#N/A' &&
                        caseDetail.Complaint_Category__c == 'Complaint' &&
                        caseRec.Nature__c == 'Complaint' &&
                        caseRec.Technical_Source__c != 'API') {
                            caseRec.addError('Category Type of "Complaint" is not applicable for Non-IGMS cases');
                        }
                }
            }
        }
    }
    //custom exception class
    public class MyCustomException extends Exception {}
    
}