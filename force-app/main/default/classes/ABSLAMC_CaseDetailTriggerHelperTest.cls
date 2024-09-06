@isTest
public class ABSLAMC_CaseDetailTriggerHelperTest {
    
    @testSetup
    static void setup() {
        ABSLAMC_Case_Detail__c caseDetail = new ABSLAMC_Case_Detail__c(
            Note_For_CAMS__c = 'Initial Note',
            CAMS_Remarks__c = 'Initial Remarks',
            Additional_Remarks_for_CAMS__c = 'Initial Additional Remarks'
        );
        
        insert caseDetail;
        
        Case caseRec = new Case(
            Subject = 'Test Case',
            Status = 'New',
            ABSLAMC_Case_Detail__c = caseDetail.Id
        );
        
        insert caseRec;
    }
    
    @isTest
    static void testCreateCaseComments() {
        List<ABSLAMC_Case_Detail__c> caseDetails = [SELECT Id, Note_For_CAMS__c, CAMS_Remarks__c, Additional_Remarks_for_CAMS__c FROM ABSLAMC_Case_Detail__c];
        Map<Id, ABSLAMC_Case_Detail__c> oldCaseDetailMap = new Map<Id, ABSLAMC_Case_Detail__c>();
        for (ABSLAMC_Case_Detail__c caseDetail : caseDetails) {
            oldCaseDetailMap.put(caseDetail.Id, caseDetail.clone(false, true, false, false));
        }
        
        for (ABSLAMC_Case_Detail__c caseDetail : caseDetails) {
            caseDetail.Note_For_CAMS__c = 'Updated Note';
            caseDetail.CAMS_Remarks__c = 'Updated Remarks';
            caseDetail.Additional_Remarks_for_CAMS__c = 'Updated Additional Remarks';
        }
        update caseDetails;
        
        // Create a map of new values to simulate new trigger context
        Map<Id, ABSLAMC_Case_Detail__c> newCaseDetailMap = new Map<Id, ABSLAMC_Case_Detail__c>(caseDetails);
        
        // Call the helper method
        Test.startTest();
        ABSLAMC_CaseDetailTriggerHelper.createCaseComments(newCaseDetailMap, oldCaseDetailMap);
        Test.stopTest();
        
        // Verify that CaseComment records were created
        List<CaseComment> caseComments = [SELECT ParentId, CommentBody FROM CaseComment];
        System.assertNotEquals(caseComments.size(),0);
    }
}