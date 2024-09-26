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
        ccc.Nature__c = 'Complaint';
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
                Technical_Source__c = 'LWC',
                Source__c = 'Advisor Portal',
                Sub_Type_Text__c = 'Loan Payout'
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
                //System.assertEquals(1, caseRec.getErrors().size());
                //System.assertEquals('Category Type of "Complaint" is not applicable for Non-IGMS cases', caseRec.getErrors()[0].getMessage());
            } else {
                System.assertEquals(0, caseRec.getErrors().size());
            }
        }
    }

    @IsTest
    public static void checkCreateCaseValidationsTest(){
        String errorMessage = '';
        Account accRec = ASF_TestDataFactory.insertPersonAccount('Aditya', 'Mehrotra', '100');
        
        Asset assetRec = ASF_TestDataFactory.createAsset(accRec.Id, 'Loans');
		assetRec.Policy_No__c = '1234';
        assetRec.Status = 'REJECTED';
		update assetRec;

		ABSLI_Case_Detail__c detailRec = new ABSLI_Case_Detail__c();
        detailRec.Status_Valid_For_STP__c = true;
		insert detailRec;
        Case cs = new Case(AssetId=assetRec.Id,ABSLI_Case_Detail__c=detailRec.Id,Business_Unit__c='ABSLI',Technical_Source__c='LWC',
                           RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId(),
                          Status = 'In Progress', Origin = 'Email', Subject = 'Test Case Creation', Stage__c = 'Pending with Initiator',
                          SLA_Target_1__c = 'test2@salesforce.com' , CSAT__c = 20, DB_Hours__c = 5, has_CheckLists__c=TRUE, Reopen_Days__c=30,
                          Stage_SLA_1__c = System.now(),Stage_SLA_2__c = System.now()+1,Stage_SLA_3__c = System.now()+2,CCC_External_Id__c = 'PNFT007');
        try{
        	insert cs;    
        }catch(Exception ex){
            errorMessage = ex.getMessage();
        }
        System.assertEquals(errorMessage,'Insert failed. First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, Policy is not eligible for \'Email ID Update\': []');
    }
    
    @IsTest
    static void testAssociateCustomerForAPIFromPhoneNumber(){
        string frameworkRecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
        List<Case> caseRec = ASF_TestDataFactory.createCaseRecords(1);
        Account acc = ASF_TestDataFactory.insertPersonAccount('first','last','test');
        caseRec[0].Business_Unit__c = 'ABSLI';
        caseRec[0].Technical_Source__c = 'API';
        caseRec[0].SuppliedPhone = '1234';
        //update cases;
        ABSLI_BeforeInsertTriggerLogic.associateCustomerForAPIFromPhoneNumber(new List<Case>{caseRec[0]});
    }
	
}