@isTest
public class ABSLI_FetchBankDetailsControllerTest {
    
    @testSetup
    static void setup() {
        ABSLI_Case_Detail__c caseDetail = new ABSLI_Case_Detail__c(
            IFSC_Code__c = 'TESTIFSC',
            MICR_Code__c = 'TESTMICR',
            Bank_Name__c = 'Test Bank',
            Branch_Name__c = 'Test Branch'
        );
        insert caseDetail;
        
        Case caseRecord = new Case(
            ABSLI_Case_Detail__c = caseDetail.Id
        );
        insert caseRecord;
    }
    
    @isTest
    static void testGetCaseDetails() {
        Case caseRecord = [SELECT Id, ABSLI_Case_Detail__c FROM Case LIMIT 1];
        
        Test.startTest();
        ABSLI_Case_Detail__c result = ABSLI_FetchBankDetailsController.getCaseDetails(caseRecord.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertEquals('TESTIFSC', result.IFSC_Code__c);
        System.assertEquals('TESTMICR', result.MICR_Code__c);
        System.assertEquals('Test Bank', result.Bank_Name__c);
        System.assertEquals('Test Branch', result.Branch_Name__c);
    }
    
    @isTest
    static void testUpdateBankDetailOnExtn() {
        Case caseRecord = [SELECT Id, ABSLI_Case_Detail__c FROM Case LIMIT 1];
        ABSLI_Case_Detail__c caseDetail = [SELECT Id FROM ABSLI_Case_Detail__c LIMIT 1];
        
        Test.startTest();
        ABSLI_FetchBankDetailsController.updateBankDetailOnExtn(
            caseDetail.Id,
            'NEWIFSC',
            'NEWMICR',
            'New Bank',
            'New Branch',
            caseRecord.Id
        );
        Test.stopTest();
        
        ABSLI_Case_Detail__c updatedDetail = [SELECT IFSC_Code__c, MICR_Code__c, Bank_Name__c, Branch_Name__c FROM ABSLI_Case_Detail__c WHERE Id = :caseDetail.Id];
        System.assertEquals('NEWIFSC', updatedDetail.IFSC_Code__c);
        System.assertEquals('NEWMICR', updatedDetail.MICR_Code__c);
        System.assertEquals('New Bank', updatedDetail.Bank_Name__c);
        System.assertEquals('New Branch', updatedDetail.Branch_Name__c);
    }
    
    @isTest
    static void testFetchBankDetail() {
        Case caseRecord = [SELECT Id FROM Case LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new ABSLI_FetchBankDetailsResponseGenerator());
        Test.startTest();
        ABSLI_FetchBankDetailsController.bankDetailResponseWrapper response = ABSLI_FetchBankDetailsController.fetchBankDetail(caseRecord.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, response);
        System.assertEquals('0', response.ReturnCode);
        //System.assertNotEquals(null, response.lstDetails);
    }
    
    @isTest
    static void testFetchBankDetailFromField() {
        Test.setMock(HttpCalloutMock.class, new ABSLI_FetchBankDetailsResponseGenerator());
        Test.startTest();
        ABSLI_FetchBankDetailsController.bankDetailResponseWrapper response = ABSLI_FetchBankDetailsController.fetchBankDetailFromField(null, 'TESTIFSC');
        Test.stopTest();
        
        System.assertNotEquals(null, response);
        System.assertEquals('0', response.ReturnCode);
        //System.assertEquals(null, response.lstDetails);
    }
    
    @isTest
    static void testFetchBankDetailInvalidCaseId() {
        Test.startTest();
        ABSLI_FetchBankDetailsController.bankDetailResponseWrapper response = ABSLI_FetchBankDetailsController.fetchBankDetail(null);
        Test.stopTest();
        
        System.assertEquals('-1', response.ReturnCode);
        System.assertEquals('Case Id is blank.', response.ReturnMessage);
    }
    
    @isTest
    static void testFetchBankDetailMissingIFSCAndMICR() {
        ABSLI_Case_Detail__c caseDetail = new ABSLI_Case_Detail__c();
        insert caseDetail;
        
        Case caseRecord = new Case(
            ABSLI_Case_Detail__c = caseDetail.Id
        );
        insert caseRecord;
        
        Test.startTest();
        ABSLI_FetchBankDetailsController.bankDetailResponseWrapper response = ABSLI_FetchBankDetailsController.fetchBankDetail(caseRecord.Id);
        Test.stopTest();
        
        System.assertEquals('-1', response.ReturnCode);
        System.assertEquals('Either IFSC Code or MICR Code required to fetch Bank Branch Details.', response.ReturnMessage);
    }
    
    public class ABSLI_FetchBankDetailsResponseGenerator implements HttpCalloutMock {
        /**
            * @description  Mocking failure response
            * @param req
            ** @return HTTPResponse
        */ 
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
			String s = '{\"absliCaseExtId\":\"2\",\"ReturnCode\":\"0\",\"ReturnMessage\":\"Nodatafound\"}';
            res.setBody(s);
            res.setStatusCode(200);
            return res;
        }
    }
}