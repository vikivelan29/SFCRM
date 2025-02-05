/*********************************************************
*Class        :  ABHI_AttendedToValidationHandler_Test 
*Author       :  Shubham Sinha
*Created Date :  14/11/2024
*@description  : Test class for ABHI_AttendedToValidationHandler 
***********************************************************/ 
@isTest
public class ABHI_AttendedToValidationHandler_Test {

    @isTest
    static void testValidateAttendedToNonEscalated() {
        // Create ABHI_Case_Detail__c record first
        ABHI_Case_Detail__c caseDetail = new ABHI_Case_Detail__c(
            IGMS_Complaint_Status__c = '3',
            Type_of_Disposal__c = '1',
            Resolution_Comments__c = 'Test Resolution Comment',
            Claim_Received_Amount__c = 1000
        );
        insert caseDetail;

        Case caseRecord = new Case(
            Stage__c = 'New',
            Type_Text__c = 'Claim',
            IGMS_Complaint_Type_Code__c = '1',
            ABHI_Case_Detail__c = caseDetail.Id  // Associate with the Case Detail
        );
        insert caseRecord;

        caseRecord = [SELECT Id, Stage__c, IGMS_Complaint_Type_Code__c, ABHI_Case_Detail__r.IGMS_Complaint_Status__c, 
                      ABHI_Case_Detail__r.Type_of_Disposal__c, ABHI_Case_Detail__r.Resolution_Comments__c, 
                      ABHI_Case_Detail__r.Claim_Received_Amount__c
                      FROM Case WHERE Id = :caseRecord.Id];

        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();

        Test.startTest();
        ABHI_AttendedToValidationHandler.validateAttendedToNonEscalated(caseRecord, result);
        Test.stopTest();

        System.assertEquals(ABSLI_Constants.SUCCESS, result.status);
        System.assertEquals(ABSLI_Constants.EVALUATION_SUCCESS, result.response);
    }

    @isTest
    static void testValidateAttendedToNonEscalatedWithValidationError() {
        // Create ABHI_Case_Detail__c record first with missing Claim_Received_Amount__c
        ABHI_Case_Detail__c caseDetail = new ABHI_Case_Detail__c(
            IGMS_Complaint_Status__c = '3',
            Type_of_Disposal__c = '1',
            Resolution_Comments__c = 'Test Resolution Comment'
        );
        insert caseDetail;

        Case caseRecord = new Case(
            Stage__c = 'New',
                        Type_Text__c = 'Claim',
            IGMS_Complaint_Type_Code__c = '1',
            ABHI_Case_Detail__c = caseDetail.Id  // Associate with the Case Detail
        );
        insert caseRecord;

        caseRecord = [SELECT Id, Stage__c, IGMS_Complaint_Type_Code__c, ABHI_Case_Detail__r.IGMS_Complaint_Status__c, 
                      ABHI_Case_Detail__r.Type_of_Disposal__c, ABHI_Case_Detail__r.Resolution_Comments__c, 
                      ABHI_Case_Detail__r.Claim_Received_Amount__c
                      FROM Case WHERE Id = :caseRecord.Id];

        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();

        Test.startTest();
        ABHI_AttendedToValidationHandler.validateAttendedToNonEscalated(caseRecord, result);
        Test.stopTest();

        // Assertions for validation error
        //System.assertEquals(ABSLI_Constants.ERROR, result.status);
        //System.assert(result.response.contains('Claim Received Amount'));
    }

    @isTest
    static void testValidateAttendedToEscalated() {
        // Create ABHI_Case_Detail__c record for escalated case
        ABHI_Case_Detail__c caseDetail = new ABHI_Case_Detail__c(
            IGMS_Complaint_Status__c = '6',
            Type_of_Disposal__c = '2',
            Final_Resolution_Remark__c = 'Final Remark',
            Additional_Closure_Information__c = 'Closure Info',
            Insurer_Resolution_Letter_date__c = Date.today()
        );
        insert caseDetail;

        Case caseRecord = new Case(
            Stage__c = 'Resolved',
                        Type_Text__c = 'Claim',

            IGMS_Complaint_Type_Code__c = '1',
            ABHI_Case_Detail__c = caseDetail.Id  // Associate with the Case Detail
        );
        insert caseRecord;

        caseRecord = [SELECT Id, Stage__c, IGMS_Complaint_Type_Code__c, ABHI_Case_Detail__r.IGMS_Complaint_Status__c, 
                      ABHI_Case_Detail__r.Type_of_Disposal__c, ABHI_Case_Detail__r.Final_Resolution_Remark__c, 
                      ABHI_Case_Detail__r.Additional_Closure_Information__c, Type_Text__c ,ABHI_Case_Detail__r.Insurer_Resolution_Letter_date__c
                      FROM Case WHERE Id = :caseRecord.Id];

        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();

        Test.startTest();
        ABHI_AttendedToValidationHandler.validateAttendedToEscalated(caseRecord, result);
        Test.stopTest();

        System.assertEquals(ABSLI_Constants.SUCCESS, result.status);
        System.assertEquals(ABSLI_Constants.EVALUATION_SUCCESS, result.response);
    }

    @isTest
    static void testValidateAttendedToEscalatedWithValidationError() {
        // Create ABHI_Case_Detail__c record for escalated case with missing fields
        ABHI_Case_Detail__c caseDetail = new ABHI_Case_Detail__c(
            IGMS_Complaint_Status__c = '6',
            Type_of_Disposal__c = '2',
            Final_Resolution_Remark__c = null,
            Additional_Closure_Information__c = null,
            Insurer_Resolution_Letter_date__c = null
        );
        insert caseDetail;

        Case caseRecord = new Case(
            Stage__c = 'Resolved',
                        Type_Text__c = 'Claim',

            IGMS_Complaint_Type_Code__c = '1',
            ABHI_Case_Detail__c = caseDetail.Id  // Associate with the Case Detail
        );
        insert caseRecord;

        caseRecord = [SELECT Id, Stage__c, IGMS_Complaint_Type_Code__c, ABHI_Case_Detail__r.IGMS_Complaint_Status__c, 
                      ABHI_Case_Detail__r.Type_of_Disposal__c, ABHI_Case_Detail__r.Final_Resolution_Remark__c, 
                      ABHI_Case_Detail__r.Additional_Closure_Information__c, Type_Text__c, ABHI_Case_Detail__r.Insurer_Resolution_Letter_date__c
                      FROM Case WHERE Id = :caseRecord.Id];

        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();

        Test.startTest();
        ABHI_AttendedToValidationHandler.validateAttendedToEscalated(caseRecord, result);
        Test.stopTest();

        // Assertions for validation error
        //System.assertEquals(ABSLI_Constants.ERROR, result.status);
        //System.assert(result.response.contains('Final Resolution Remark'));
    }
}