/**
 * @description       : BSLI BeforeUpdateTrigger Logic After ASF Code
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 06-19-2024
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
				System.debug(caseError.Stage__c);
                System.debug(caseError.ABSLI_Case_Detail__c);
                System.debug(caseError.IRDAI_Token_Number__c);
                System.debug(caseError.Technical_Source__c);
                
        		// Check if the Case record is related to ABSLI business unit
                if (caseError.ABSLI_Case_Detail__c != null  && 
                    caseError.IRDAI_Token_Number__c != null &&
                    caseError.Nature__c == 'Complaint' && 
                    caseError.Technical_Source__c != 'API' &&
                    caseError.Stage__c == 'Unresolved') {
                       	   System.debug('Inside restrictComplaintsRejection: IRDAI_Token_Number__c=' + caseRec.ABSLI_Case_Detail__r.IRDAI_Token_Number__c + ', Nature__c=' + caseRec.Nature__c);
                           caseError.addError('IGMS Synced Complaints cannot be Unresolved.');
                           newMap.put(caseRec.Id,caseError);
                    	
                	}
            }
        }
	}
}