@isTest
public class ABSLI_BeforeInsertTriggerLogicTest {

    @TestSetup
    static void makeData(){
        Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
        ASF_TestDataFactory.createC3IntegrationsAndCase();
        ASF_TestDataFactory.createCaseRecords(3);
    }
    @IsTest
    public static void checkComplaintApplicabilityTest() {
        // Create ABSLI_Case_Detail records
        ABSLI_Case_Detail__c caseDetail1 = new ABSLI_Case_Detail__c(Complaint_Category__c = 'Complaint');
        insert caseDetail1;
        
        ABSLI_Case_Detail__c caseDetail2 = new ABSLI_Case_Detail__c(Complaint_Category__c = 'Escalation');
        insert caseDetail2;
        
        ASF_TestDataFactory.createCaseCategoryConfig();
		ASF_Case_Category_Config__c ccc = [SELECT id,IGMS_Code__c,CCC_External_Id__c FROM ASF_Case_Category_Config__c LIMIT 1];
        ccc.IGMS_Code__c = '#N/A';
        update ccc;
        
        // Create Cases
        List<Case> newCases = new List<Case>{
            new Case(
                RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId(),
                Business_Unit__c = 'ABSLI',
                Status = 'New',
                CCC_External_Id__c = ccc.CCC_External_Id__c,
                ABSLI_Case_Detail__c = caseDetail1.Id,
                Nature__c = 'Complaint',
                Technical_Source__c = 'Manual',
                Source__c = 'Advisor Portal'
            ),
            new Case(
                RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId(),
                Business_Unit__c = 'ABSLI',
                Status = 'New',
                CCC_External_Id__c = ccc.CCC_External_Id__c,
                ABSLI_Case_Detail__c = caseDetail2.Id,
                Nature__c = 'Complaint',
                Technical_Source__c = 'API',
                Source__c = 'Advisor Portal'
            )
        };
        
        Test.startTest();
        insert newCases;
        Test.stopTest();
        
        // Query inserted cases to check for errors
        List<Case> insertedCases = [SELECT Id, Business_Unit__c, CCC_External_Id__c, ABSLI_Case_Detail__c, Nature__c, Technical_Source__c FROM Case WHERE Id IN :newCases];
        
        for (Case caseRec : insertedCases) {
            if (caseRec.Business_Unit__c == 'ABSLI' && caseRec.Nature__c == 'Complaint' && caseRec.Technical_Source__c == 'LWC') {
                System.assertEquals(1, caseRec.getErrors().size());
                System.assertEquals('Category Type of "Complaint" is not applicable for Non-IGMS cases', caseRec.getErrors()[0].getMessage());
            } else {
                System.assertEquals(0, caseRec.getErrors().size());
            }
        }
    }
	
}