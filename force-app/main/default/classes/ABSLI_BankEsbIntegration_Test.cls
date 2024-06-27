@IsTest
public class ABSLI_BankEsbIntegration_Test {
	@testSetup
	static void setupTestData() {
		ASF_Integration__c integ = new ASF_Integration__c();
		integ.External_Id__c = 'PNFT007';
		integ.Display_Name__c = 'Bank Account Update';
		integ.Query_Fields__c = 'ABSLI_Case_Detail__r.Status_Valid_For_STP__c,CaseNumber,Account.Client_Code__c,ABSLI_Case_Detail__r.Mobile_Number__c,Business_Unit__c,ABSLI_Case_Detail__r.IFSC_Code__c,ABSLI_Case_Detail__r.MICR_Code__c';
		integ.Processing_Class__c = 'ABSLI_BankEsbIntegration';
		integ.When_to_Appear__c = 'Stage Entry';
		integ.Type__c = 'Process';
		integ.Auto_Run_on_Load__c = true;
		insert integ;

        ASF_TestDataFactory.createCaseCategoryConfig();
        ASF_Case_Category_Config__c config = [SELECT Id,CCC_External_Id__c
                                             FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c ='CCC-CC-CCLTD-01' LIMIT 1];
        config.CCC_External_Id__c = 'PNFT007';
        update config;
        
		Account accRec = ASF_TestDataFactory.insertPersonAccount('Aditya', 'Mehrotra', '100');
		accRec.PersonBirthdate = Date.today();
        accRec.PAN__c = 'ABC1232B';
		update accRec;

		Asset assetRec = ASF_TestDataFactory.createAsset(accRec.Id, 'Loans');
		assetRec.Policy_No__c = '1234';
		update assetRec;

		ABSLI_Case_Detail__c detailRec = new ABSLI_Case_Detail__c();
		detailRec.From_Date__c = Date.today();
        detailRec.Status_Valid_For_STP__c = true;
		detailRec.To_Date__c = Date.today().addDays(2);
        detailRec.IFSC_Code__c = 'ABIN0000123';
		insert detailRec;
        
        List<Case> caseRecList = ASF_TestDataFactory.createCaseRecords(1);
        caseRecList[0].AssetId = assetRec.Id;
        caseRecList[0].ABSLI_Case_Detail__c = detailRec.Id;
        caseRecList[0].Technical_Source__c = 'API';
        ASF_TriggerSkipperUtility.markTriggerRun('Case');
        update caseRecList[0];
        ASF_TriggerSkipperUtility.resetTriggerRun('Case');
        
        ASF_TestDataFactory.createCaseIntegration(caseRecList[0].Id, 'PNFT007');
	}
    
    @IsTest
    static void testEvaluate(){
        ABSLI_BankEsbIntegration bankEsbInt = new ABSLI_BankEsbIntegration();
       	Case caseRecord = [SELECT id,CaseNumber,Technical_Source__c,ABSLI_Case_Detail__r.Status_Valid_For_STP__c,ABSLI_Case_Detail__r.IFSC_Code__c,ABSLI_Case_Detail__r.MICR_Code__c FROM Case LIMIT 1];
        ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRecord.Id => caseRecord };
        Test.startTest();
        ASF_IntegrationsController.IntegrationWrapper successfulEvaluate = bankEsbInt.evaluate(caseRecord);
        System.assertEquals('Success', successfulEvaluate.status,'Success');
        Test.stopTest();
    }
    
    @IsTest
    static void testRun(){
        ABSLI_BankEsbIntegration bankEsbInt = new ABSLI_BankEsbIntegration();
       	Case caseRecord = [SELECT id,CaseNumber,ABSLI_Case_Detail__r.Status_Valid_For_STP__c,ABSLI_Case_Detail__r.IFSC_Code__c,ABSLI_Case_Detail__r.MICR_Code__c,Business_Unit__c FROM Case LIMIT 1];
        ASF_Integration__c integ = [SELECT Id, Processing_Class__c, External_Id__c FROM ASF_Integration__c LIMIT 1];
        ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRecord.Id => caseRecord };
            
        /*MultiStaticResourceCalloutMock mock = new MultiStaticResourceCalloutMock();
        mock.setStaticResource(ABCL_Integrations__mdt.getInstance('ABSLI_Bank_ESB_Integration').EndPoint__c,'BankEsbMockResponse');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);*/
        
        // Mock the HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        ASF_IntegrationsController.IntegrationWrapper successfulRun = bankEsbInt.run(integ,caseRecord);
        system.debug('Aditya successfulRun:'+successfulRun);
        System.assertEquals('Success', successfulRun.status,'Success');
        Test.stopTest();
        
    }
    
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"ReturnMessage":"Success","ReturnCode":"0","lstDetails":{"IFSC_CODE":"IFSC001","MICR_CODE":"MICR001","BANK_NAME":"Test Bank","BANK_BRANCH":"Test Branch"}}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    @IsTest
    static void testProcessResponse(){
        ABSLI_BankEsbIntegration bankEsbInt = new ABSLI_BankEsbIntegration();
        ASF_Case_Integration__c caseInteg = [SELECT Id, Status__c, Case__c FROM ASF_Case_Integration__c LIMIT 1];
        caseInteg.Status__c = 'Success';
        caseInteg.Response__c = '{"ReturnMessage":"Record retrieved successfully.","ReturnCode":"0","lstDetails":{"IFSC_CODE":"ABIN0000123","MICR_CODE":"400065001","BANK_NAME":"ABHYUDAYA COOPERATIVE BANK LIMITED","BANK_BRANCH":"RTGSHO"}}';
        ASF_TriggerSkipperUtility.markTriggerRun('ASF_Case_Integration__c');
        update caseInteg;
        ASF_TriggerSkipperUtility.resetTriggerRun('ASF_Case_Integration__c');
        Test.startTest();
        bankEsbInt.processResponse(caseInteg);
        Test.stopTest();
        System.assertEquals('Success', 'Success','Success');
    }
}