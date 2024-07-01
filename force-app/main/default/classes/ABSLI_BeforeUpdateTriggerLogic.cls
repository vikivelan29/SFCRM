/**
 * @description       : BSLI BeforeUpdateTrigger Logic Before ASF Code
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 06-19-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class ABSLI_BeforeUpdateTriggerLogic {
    /**
     * @description This method is called from ASF_CaseTriggerBUSpecificHandler whenever a case is
     * updated. This is the parent method
     * @param newMap
     * @param oldMap
     */
    public Static Map<Id, Case> absliCasesAdditionalFields;
    public static void executeBeforeLogic(Map<Id, Case> newMap, Map<Id, Case> oldMap){
        Id frameworkRTId = ASF_Constants.RT_FRAMEWORK;
        Map<Id,Case> mAbsliCases = new Map<Id,Case>();
        Map<ID,List<Case>> mRecordTypeVsCases = ASF_CaseDistributionBasedOnRT.getCaseByRecordType((List<Case>)newMap.values());
        if(mRecordTypeVsCases.containsKey(frameworkRTId)){
            Map<Id,Case> frameworkCases = new Map<Id,Case>(mRecordTypeVsCases.get(frameworkRTId));
            for(Case caseRec : frameworkCases.values()){
                if(caseRec.Business_Unit__c == ASF_Constants.ABSLI_BU){
                    mAbsliCases.put(caseRec.Id,caseRec);
                }
            }
        }
        if(!mAbsliCases.isEmpty()){
            absliCasesAdditionalFields = new Map<Id, Case>([SELECT Id,Asset.Issue_Date__c,ABSLI_Case_Detail__c,CCC_External_Id__c, 
                                       ABSLI_Case_Detail__r.To_date__c, ABSLI_Case_Detail__r.From_date__c,CaseNumber,ABSLI_Case_Detail__r.IRDAI_Token_Number__c,Nature__c,Stage__c,Technical_Source__c,
                                       ABSLI_Case_Detail__r.Complaint_Category__c,ABSLI_Case_Detail__r.Resolve_case__c,IRDAI_Token_Number__c 
                                       FROM Case 
                                       WHERE Id IN :mAbsliCases.keySet()]);
            System.debug('Inside ABSLI before Update Trigger logic');
            System.debug(absliCasesAdditionalFields);
            ABSLI_BeforeUpdateTriggerLogic.autoResolveFtrCases(mAbsliCases.values(), oldMap);
            ABSLI_BeforeUpdateTriggerLogic.validateFromDateToDate(mAbsliCases.values(), oldMap, newMap);
            ABSLI_BeforeUpdateTriggerLogic.checkIfMandatoryChecklistNotCompleted(mAbsliCases, oldMap);
            ABSLI_BeforeUpdateTriggerLogic.checkComplaintApplicability(mAbsliCases.values(), oldMap, newMap);
        }  
    }
    /**
     * @description This method is called from ASF_CaseTriggerBUSpecificHandler whenever a case is
     * updated. If the case is marked as FTR, the case status is updated to 'Resolved'
     * @param absliCases
     * @param oldMap
     */
    public static void autoResolveFtrCases(List<Case> absliCases, Map<Id, Case> oldMap){
        if(!absliCases.isEmpty()){
            for(Case caseRec : absliCases){
                if(caseRec.MoveToNext__c != oldMap.get(caseRec.Id).MoveToNext__c 
                   && caseRec.MoveToNext__c == true && caseRec.FTR__c == true){
                       caseRec.MoveToNext__c = false;
                       caseRec.Status = ASF_Constants.ONCREATECLOSESTATUS;
                       caseRec.Stage__c = ASF_Constants.ONCREATECLOSESTAGE;
                   }
            }
        }   
    }
    
    /**
     * @description This method is called from ASF_CaseTriggerBUSpecificHandler whenever a case is
     * updated. From Date and To Date Validation.
     * @param absliCases
     * @param oldMap
     */
    public static void validateFromDateToDate(List<Case> absliCases, Map<Id, Case> oldMap, Map<Id, Case> newMap){
        List<String> validSubTypes = new List<String>{'PEMT042', 'PEMT024'};
            if(!absliCases.isEmpty()){
                for (Case caseRec : absliCasesAdditionalFields.values()) {
                    System.debug(caseRec.ABSLI_Case_Detail__r.To_date__c);
                    System.debug(caseRec.ABSLI_Case_Detail__r.From_date__c);
                    // Check if the Case record is related to ABSLI business unit
                    if (caseRec.ABSLI_Case_Detail__c != null  && validSubTypes.contains(caseRec.CCC_External_Id__c)) {
                        System.debug('Inside validate date: ' + caseRec.Asset.Issue_Date__c);
                        Date issueDate = caseRec.Asset.Issue_Date__c;
                        Date toDate = caseRec.ABSLI_Case_Detail__r.To_date__c;
                        Date fromDate = caseRec.ABSLI_Case_Detail__r.From_date__c;
                        
                        // Validate dates
                        if (toDate < issueDate || fromDate < issueDate) {
                            // Add an error message to the Case record
							Case caseError = newMap.get(caseRec.Id);
							caseError.addError('To Date/From Date should be greater than or equal to the Policy Issued Date');
							newMap.put(caseRec.Id,caseError);
                        }
                    }
                }
            }
	}
    /**
     * @description This method is called from ASF_CaseTriggerBUSpecificHandler whenever a case is
     * updated. This marks case as Unresolved based on the checklist value for certain "Request" cases
     * @param mAbsliCases
     * @param oldMap
     */
    public static void checkIfMandatoryChecklistNotCompleted(Map<Id, Case> mAbsliCases, Map<Id, Case> oldMap){
        Map<Id, Case> eligibleCases = new Map<Id, Case>();
        if(mAbsliCases.keyset().size()>0){
            for(Case c : mAbsliCases.values()){
                if(c.MoveToNext__c != oldMap.get(c.Id).MoveToNext__c 
                && c.MoveToNext__c == true && c.Technical_Source__c != 'API' && c.Nature__c == 'Request'){
                    eligibleCases.put(c.Id, c);
                }
            }
        }
        // CHECK IF OPEN CHECKLIST.
        // IF COUNT OF RECORD IS > 0, SET REJECT_CASE__C to TRUE
        if(!eligibleCases.isEmpty()){
            Map<Id,AggregateResult> mCountOfNotCompletedChecklistOnCase = new Map<Id,AggregateResult>(
                [SELECT Case__c Id, COUNT(ID) FROM ASF_Checklist__c 
                 WHERE Status__c = 'Signature Mismatched'
                 AND Case__c =: eligibleCases.keySet()
                 AND Mandatory__c = TRUE
                 GROUP BY Case__c
                 HAVING COUNT(ID) > 0]);
            for(Case c : eligibleCases.values()){
                if(mCountOfNotCompletedChecklistOnCase.containsKey(c.Id)){
                    c.Reject_Case__c = true;
                    c.Auto_Rejected__c = true;
                    c.MoveToNext__c = false;
                }
            }
        }              
    }
    
    /**
     * @description This method is called from ASF_CaseTriggerBUSpecificHandler whenever a case is
     * updated. To Restrict Complaint Category Type for Non-IGMS Complaints.
     * @param absliCases
     * @param oldMap
     */
    public static void checkComplaintApplicability(List<Case> absliCases, Map<Id, Case> oldMap, Map<Id, Case> newMap) {
        Set<String> externalIds = new Set<String>();
        for (Case caseRec : absliCasesAdditionalFields.values()) {
            if (caseRec.CCC_External_Id__c != null) {
                externalIds.add(caseRec.CCC_External_Id__c);
            }
        }

        // Query ASF_Case_Category_Config__c using the external IDs
         Map<String, ASF_Case_Category_Config__c> configMap = new Map<String, ASF_Case_Category_Config__c>();
        for (ASF_Case_Category_Config__c config : [SELECT Id, CCC_External_Id__c, IGMS_Code__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c IN :externalIds]) {
            configMap.put(config.CCC_External_Id__c, config);
        }

        for (Case caseRec : absliCasesAdditionalFields.values()) {
            if (caseRec.CCC_External_Id__c != null && configMap.containsKey(caseRec.CCC_External_Id__c)) {
                ASF_Case_Category_Config__c config = configMap.get(caseRec.CCC_External_Id__c);
				System.debug(config.IGMS_Code__c);
                System.debug(caseRec.ABSLI_Case_Detail__r.Resolve_case__c);
                System.debug(caseRec.ABSLI_Case_Detail__r.Complaint_Category__c);
                if (config.IGMS_Code__c == '#N/A' &&
                    caseRec.ABSLI_Case_Detail__r.Complaint_Category__c == 'Complaint' &&
                    caseRec.Nature__c == 'Complaint' && 
                    caseRec.Technical_Source__c != 'API') {
                        Case caseError = newMap.get(caseRec.Id);
                        caseError.addError('Category Type of "Complaint" is not applicable for Non-IGMS cases');
                        newMap.put(caseRec.Id,caseError);
                }
                if (config.IGMS_Code__c != '#N/A' &&
                    caseRec.ABSLI_Case_Detail__r.Complaint_Category__c != 'Complaint' &&
                    caseRec.ABSLI_Case_Detail__r.IRDAI_Token_Number__c != '' &&
                    caseRec.Nature__c == 'Complaint' && 
                    caseRec.Technical_Source__c != 'API') {
                        Case caseError = newMap.get(caseRec.Id);
                        caseError.addError('Category type cannot be changed for IGMS Synced cases');
                        newMap.put(caseRec.Id,caseError);
                }
            }
        }
    }
    
    //custom exception class
	public class MyCustomException extends Exception {}
}