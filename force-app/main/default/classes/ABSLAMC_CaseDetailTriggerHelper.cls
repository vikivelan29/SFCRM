/*********************************************************
*Class        :  ABSLAMC_CaseDetailTriggerHelper
*Author       :  Neeraj Kumar
*Created Date :  02-09-2024
*@description  :  Helper Class for ABSLAMC_Case_Detail__c Trigger
*********************************************************/
public with sharing class ABSLAMC_CaseDetailTriggerHelper {
    
    /****************************************************************************************************************
* @param newCaseDetailMap,oldCaseDetailMap
* @description - used to create a CaseComment record Note_For_CAMS__c,CAMS_Remarks__c,Additional_Remarks_for_CAMS__c field is updated 
*****************************************************************************************************************/
    public static void createCaseComments(Map<Id, ABSLAMC_Case_Detail__c> newCaseDetailMap, Map<Id, ABSLAMC_Case_Detail__c> oldCaseDetailMap) {
        
        List<CaseComment> caseCommentsToInsert = new List<CaseComment>();
        Map<Id, Id> caseDetailToCaseMap = new Map<Id, Id>();
        Set<Id> caseDetailIdsWithUpdates = new Set<Id>();
        
        for (Id caseDetailId : newCaseDetailMap.keySet()) {
            ABSLAMC_Case_Detail__c newCaseDetail = newCaseDetailMap.get(caseDetailId);
            ABSLAMC_Case_Detail__c oldCaseDetail = oldCaseDetailMap.get(caseDetailId);
            
            // Check if the Note_For_CAMS__c, CAMS_Remarks__c, Additional_Remarks_for_CAMS__c field is updated
            if ((newCaseDetail.Note_For_CAMS__c != oldCaseDetail.Note_For_CAMS__c && String.isNotBlank(newCaseDetail.Note_For_CAMS__c))
                || (newCaseDetail.CAMS_Remarks__c != oldCaseDetail.CAMS_Remarks__c && String.isNotBlank(newCaseDetail.CAMS_Remarks__c))
                || (newCaseDetail.Additional_Remarks_for_CAMS__c != oldCaseDetail.Additional_Remarks_for_CAMS__c 
                    && String.isNotBlank(newCaseDetail.Additional_Remarks_for_CAMS__c))) {
                    caseDetailIdsWithUpdates.add(caseDetailId);
                }
        }
        
        if (!caseDetailIdsWithUpdates.isEmpty()) {
            Map<Id, Case> relatedCaseRecs = new Map<Id, Case>([
                SELECT Id, ABSLAMC_Case_Detail__c
                FROM Case
                WHERE ABSLAMC_Case_Detail__c IN :caseDetailIdsWithUpdates
            ]);
            
            // Map ABSLAMC_Case_Detail__c Id to Case Id
            for (Case relatedCase : relatedCaseRecs.values()) {
                caseDetailToCaseMap.put(relatedCase.ABSLAMC_Case_Detail__c, relatedCase.Id);
            }
        }
        
        for (Id caseDetailId : caseDetailIdsWithUpdates) {
            Id relatedCaseId = caseDetailToCaseMap.get(caseDetailId);
            
            if (relatedCaseId != null) {
                ABSLAMC_Case_Detail__c newCaseDetail = newCaseDetailMap.get(caseDetailId);
                ABSLAMC_Case_Detail__c oldCaseDetail = oldCaseDetailMap.get(caseDetailId);
                
                // Create a CaseComment if 'Note_For_CAMS__c' field is updated
                if (newCaseDetail.Note_For_CAMS__c != oldCaseDetail.Note_For_CAMS__c) {
                    CaseComment notesForCamsUpdate = new CaseComment(
                        ParentId = relatedCaseId,
                        CommentBody = newCaseDetail.Note_For_CAMS__c
                    );
                    caseCommentsToInsert.add(notesForCamsUpdate);
                }
                
                // Create a CaseComment if 'CAMS_Remarks__c' field is updated
                if (newCaseDetail.CAMS_Remarks__c != oldCaseDetail.CAMS_Remarks__c) {
                    CaseComment camsRemarksUpdate = new CaseComment(
                        ParentId = relatedCaseId,
                        CommentBody = newCaseDetail.CAMS_Remarks__c
                    );
                    caseCommentsToInsert.add(camsRemarksUpdate);
                }
                
                // Create a CaseComment if 'Additional_Remarks_for_CAMS__c' field is updated
                if (newCaseDetail.Additional_Remarks_for_CAMS__c != oldCaseDetail.Additional_Remarks_for_CAMS__c) {
                    CaseComment addntlRemarksUpdate = new CaseComment(
                        ParentId = relatedCaseId,
                        CommentBody = newCaseDetail.Additional_Remarks_for_CAMS__c
                    );
                    caseCommentsToInsert.add(addntlRemarksUpdate);
                }
            }
        }
        
        if (!caseCommentsToInsert.isEmpty()) {
            insert caseCommentsToInsert;
        }
    }
    
}