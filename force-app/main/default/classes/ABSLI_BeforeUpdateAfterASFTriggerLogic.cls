/**
 * @description       : BSLI BeforeUpdateTrigger Logic After ASF Code
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-02-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class ABSLI_BeforeUpdateAfterASFTriggerLogic {
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
                                       WHERE Id IN :mAbsliCases.keySet() WITH SECURITY_ENFORCED]);
            System.debug('Inside ABSLI before Update Trigger logic');
            System.debug(absliCasesAdditionalFields);
            ABSLI_BeforeUpdateAfterASFTriggerLogic.restrictComplaintsRejection(mAbsliCases.values(), oldMap, newMap);
            ABSLI_BeforeUpdateAfterASFTriggerLogic.checkComplaintApplicability(newMap.values(), oldMap, newMap);
        }  
    }
    
   	 /**
     * @description This method is called from ASF_CaseTriggerBUSpecificHandler whenever a case is
     * updated. To Restrict Rejection of Complaints that are already IGMS Synced.
     * @param absliCases
     * @param oldMap
     */
    public static void restrictComplaintsRejection(List<Case> absliCases, Map<Id, Case> oldMap,Map<Id, Case> newMap){
        if(!absliCases.isEmpty()){
            for (Case caseRec : absliCasesAdditionalFields.values()) {
                Case caseError = newMap.get(caseRec.Id);                
        		// Check if the Case record is related to ABSLI business unit
                if (caseError.ABSLI_Case_Detail__c != null  && 
                    caseError.Technical_Source__c != 'API' &&
                    caseError.Stage__c == 'Unresolved' && 
                    caseError.Nature__c == 'Complaint') {
                       	   System.debug('Inside restrictComplaintsRejection: IRDAI_Token_Number__c=' + caseRec.ABSLI_Case_Detail__r.IRDAI_Token_Number__c + ', Nature__c=' + caseRec.Nature__c);
                           caseError.addError('Complaints cannot be Unresolved.');
                           newMap.put(caseRec.Id,caseError);
                    	
                	}
            }
        }
	}
    
    public static void checkComplaintApplicability(List<Case> absliCases, Map<Id, Case> oldMap, Map<Id, Case> newMap) {
        Set<String> externalIds = new Set<String>();
        Set<String> caseDetailIds = new Set<String>();
        for (Case caseRec : newMap.values()) {
            if (caseRec.CCC_External_Id__c != null) {
                externalIds.add(caseRec.CCC_External_Id__c);
            }
            if (caseRec.ABSLI_Case_Detail__c != null) {
                caseDetailIds.add(caseRec.ABSLI_Case_Detail__c);
            }
        }

        // Query ASF_Case_Category_Config__c using the external IDs
         Map<String, ASF_Case_Category_Config__c> configMap = new Map<String, ASF_Case_Category_Config__c>();
        for (ASF_Case_Category_Config__c config : [SELECT Id, CCC_External_Id__c, IGMS_Code__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c IN :externalIds]) {
            configMap.put(config.CCC_External_Id__c, config);
        }
        //Case Detail 
		Map<Id, ABSLI_Case_Detail__c> caseDetailMap = new Map<Id, ABSLI_Case_Detail__c>();
        for (ABSLI_Case_Detail__c detail : [SELECT Id, Complaint_Category__c,Resolved_Date__c,Pending_Date__c,Final_Resolution_Date__c,IGMS_Complaint_Status__c FROM ABSLI_Case_Detail__c WHERE Id IN :caseDetailIds]) {
            caseDetailMap.put(detail.Id, detail);
        }
        for (Case caseRec : newMap.values()) {
            if (caseRec.CCC_External_Id__c != null && configMap.containsKey(caseRec.CCC_External_Id__c) && ASF_BulkCaseProcessorUtility.isBulkProcessing == false) {
                ASF_Case_Category_Config__c config = configMap.get(caseRec.CCC_External_Id__c);
                ABSLI_Case_Detail__c caseDetail = caseDetailMap.get(caseRec.ABSLI_Case_Detail__c);
                if (config.IGMS_Code__c == '#N/A' &&
                    caseDetail.Complaint_Category__c == 'Complaint' &&
                    caseRec.Nature__c == 'Complaint' && 
                    caseRec.Technical_Source__c != 'API') {
                        Case caseError = newMap.get(caseRec.Id);
                        caseError.addError('Category Type of "Complaint" is not applicable for Non-IGMS cases');
                        newMap.put(caseRec.Id,caseError);
                }
                if (config.IGMS_Code__c != '#N/A' &&
                    caseDetail.Complaint_Category__c != 'Complaint' &&
                    caseRec.IRDAI_Token_Number__c != null &&
                    caseRec.Nature__c == 'Complaint' && 
                    caseRec.Technical_Source__c != 'API') {
                        Case caseError = newMap.get(caseRec.Id);
                        caseError.addError('Category type cannot be changed for IGMS Synced cases');
                        newMap.put(caseRec.Id,caseError);
                }
                if (caseRec.IRDAI_Token_Number__c != null &&
                    caseRec.Nature__c == 'Complaint' &&
                    caseDetail.Resolved_Date__c == null &&
                    caseDetail.Pending_Date__c != null &&
                    caseRec.Stage__c == 'Resolved') {
                        Case caseError = newMap.get(caseRec.Id);
                        caseError.addError('Attended to IGMS API needs to be successful in order to close this case');
                        newMap.put(caseRec.Id,caseError);
                }
                if (caseRec.IRDAI_Token_Number__c != null &&
                    caseRec.Nature__c == 'Complaint' &&
                    caseDetail.Resolved_Date__c != null &&
                    caseDetail.Pending_Date__c != null &&
                    caseDetail.Final_Resolution_Date__c == null &&
                    caseRec.Stage__c == 'Resolved' &&
                    caseDetail.IGMS_Complaint_Status__c == '6') {
                            Case caseError = newMap.get(caseRec.Id);
                        caseError.addError('Attended to IGMS Esc API needs to be successful in order to close this case');
                        	newMap.put(caseRec.Id,caseError);
                }
            }
        }
    }
    
    public static void validateContactEmailUpdate(List<Case> absliCases, Map<Id, Case> oldMap, Map<Id, Case> newMap){
        List<String> emailContactSubTypes = new List<String>{'PNFT008','PNFT007'};
        String withdrawalCCCId = 'PPAY008';
        Set<String> caseDetailIds = new Set<String>();
        for (Case caseRec : newMap.values()) {
            if (caseRec.ABSLI_Case_Detail__c != null) {
                caseDetailIds.add(caseRec.ABSLI_Case_Detail__c);
            }
        }
        //Case Detail 
		Map<Id, ABSLI_Case_Detail__c> caseDetailMap = new Map<Id, ABSLI_Case_Detail__c>();
        for (ABSLI_Case_Detail__c detail : [SELECT Id,Source_Request_submitted_by__c,Withdrawal_Amount_Available__c,Minimum_Withdrawal_Amount__c,Requested_Withdrawal_Amount__c  FROM ABSLI_Case_Detail__c WHERE Id IN :caseDetailIds]) {
            caseDetailMap.put(detail.Id, detail);
        }
        if(!absliCases.isEmpty()){
             for (Case caseRec : newMap.values()) {
                 //Validation for Contact Update and Email Id Update
                 ABSLI_Case_Detail__c caseDetail = caseDetailMap.get(caseRec.ABSLI_Case_Detail__c);
                 System.debug(caseDetail.Source_Request_submitted_by__c);
                 System.debug(caseRec.Stage__c);
				 if (caseDetail != null  && emailContactSubTypes.contains(caseRec.CCC_External_Id__c)) {
                       if (caseDetail.Source_Request_submitted_by__c != 'Customer' && caseRec.Stage__c != 'Unresolved') {
                            Case caseError = newMap.get(caseRec.Id);
                           	caseError.addError('Source (Request Submitted by) should be Customer in order to proceed further. Unresolve the case.');
                            newMap.put(caseRec.Id,caseError);
                       }   
                 }
                 if (caseDetail !=null && caseRec.CCC_External_Id__c == withdrawalCCCId){
                     if ((caseDetail.Requested_Withdrawal_Amount__c > caseDetail.Withdrawal_Amount_Available__c || 
                          caseDetail.Requested_Withdrawal_Amount__c < caseDetail.Minimum_Withdrawal_Amount__c) && 
                          caseRec.Stage__c != 'Unresolved'){
                            Case caseError = newMap.get(caseRec.Id);
                           	caseError.addError('Requested Withdrawal Amount is outside Range');
                            newMap.put(caseRec.Id,caseError);
                     }
                 }
             }
        }
    }    
}