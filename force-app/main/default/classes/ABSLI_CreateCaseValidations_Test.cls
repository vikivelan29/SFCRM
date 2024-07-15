@isTest
public class ABSLI_CreateCaseValidations_Test {

    @testSetup
    static void setupTestData() {
        // Set up test data
        ASF_Integration__c integ = new ASF_Integration__c();
		integ.External_Id__c = 'PNFT008';
		integ.Display_Name__c = 'Closed IGMS Complaint';
		integ.Query_Fields__c = 'ABSLI_Case_Detail__r.Status_Valid_For_STP__c,CaseNumber,Account.Client_Code__c,ABSLI_Case_Detail__r.WhatsApp_Opt_Out_Indicator__c,Business_Unit__c,Technical_Source__c,Is_STP__c';
		integ.Processing_Class__c = 'ABSLI_ClosedIGMSComplaintIntegration';
		integ.When_to_Appear__c = 'Stage Entry';
		integ.Type__c = 'Process';
		integ.Auto_Run_on_Load__c = true;
		insert integ;

		Account accRec = ASF_TestDataFactory.insertPersonAccount('test', 'test', '100');
		accRec.Client_Code__c = 'ABI123';
		update accRec;

        Asset assetRec = ASF_TestDataFactory.createAsset(accRec.Id, 'Loans');
        assetRec.Policy_No__c = '1234';
        assetRec.Effective_Date__c = Date.today();
        assetRec.Issue_Date__c = Date.today();
        assetRec.Business_Unit__c = ABSLI_Constants.BUSINESS_UNIT;
        update assetRec;
        
        ABSLI_Case_Detail__c caseDetail = new ABSLI_Case_Detail__c();
        insert caseDetail;
    }
    
    @isTest
    static void testGenFundApiValidationCalloutSuccess() {
        Asset asset = [SELECT Id,Policy_No__c,Effective_Date__c FROM Asset LIMIT 1];
        ABSLI_Case_Detail__c caseDetail = [SELECT Id FROM ABSLI_Case_Detail__c LIMIT 1];
        DateTime effectiveDateTime = DateTime.newInstance(asset.Effective_Date__c.year(), asset.Effective_Date__c.month(),asset.Effective_Date__c.day());
        Map<String, Object> caseRecordMap = new Map<String, Object>{
            'AssetId' => asset.Id,
            'ABSLI_Case_Detail__c' => caseDetail.Id
        };
        Map<String, Object> requestMap = new Map<String, Object>{
            'policy_id' => asset.Policy_No__c,
            'effective_date' => effectiveDateTime.format('dd-MM-yyyy')
        };   
        String caseRecord = JSON.serialize(caseRecordMap);
        String request = JSON.serialize(requestMap);
        ABSLI_CreateCaseValidationsController.GenFundResponseWrapper responseWrapper = new ABSLI_CreateCaseValidationsController.GenFundResponseWrapper();
        responseWrapper.MORE_MESSAGES_IND = 'DummyValue';
        responseWrapper.MINIMUM_WITHDRAWAL_AMT = '100.00';
        responseWrapper.ProcessCode = '00';
        responseWrapper.POLICY_BILLED_TO_DATE = '2024-11-29';
        responseWrapper.MINIMUM_LOAN_AMT = '500.00';
        responseWrapper.CSV_PAYABLE_HOLD_AMOUNT = '200.00';
        responseWrapper.POLICY_BILL_MODE = 'Monthly';
        responseWrapper.FUND_DETAILS = 'DummyDetails';
        responseWrapper.WITHDRAWL_AMOUNT_AVAILABLE = '300.00';
        responseWrapper.navdate = '2022-01-01';
        responseWrapper.MESSAGES_T = 'DummyMessageT';
        responseWrapper.LOAN_AMOUNT_AVAILED = '400.00';
        responseWrapper.MESSAGES = 'DummyMessage';
        responseWrapper.MESSAGES_T_3 = 'DummyMessageT3';
        responseWrapper.MESSAGES_T_2 = 'DummyMessageT2';
        responseWrapper.ProcessMessage = 'Success';
        responseWrapper.MESSAGES_T_1 = 'DummyMessageT1';
        responseWrapper.CASH_SURRENDER_VALUE = '500.00';
        responseWrapper.MAX_LOAD_AMOUNT_AVAILABLE = '1000.00';
        responseWrapper.POLICY_SA = '200000.00';
        String jsonResponse = JSON.serialize(responseWrapper);
        Map<String, String> successResponseMap = new Map<String, String>();
        successResponseMap.put(request,jsonResponse);
        Test.setMock(HttpCalloutMock.class, new ABSLI_CreateCaseValidations_Test.MockHttpResponseGenerator(successResponseMap));
        
        Test.startTest();
        String result = ABSLI_CreateCaseValidationsController.genFundApiValidationCallout(caseRecord);
        Test.stopTest();
        
        System.assertEquals('Success', result, 'The Gen Fund API callout should return Success.');
    }
    
    @isTest
    static void testNomineeChangeCaseCreationValidationSuccess() {
        Asset asset = [SELECT Id FROM Asset LIMIT 1];
        
        Map<String, Object> caseRecordMap = new Map<String, Object>{
            'AssetId' => asset.Id
        };
        String caseRecord = JSON.serialize(caseRecordMap);
        
        Test.startTest();
        String result = ABSLI_CreateCaseValidationsController.nomineeChangeCaseCreationValidation(caseRecord);
        Test.stopTest();
        
        System.assertEquals('Success', result, 'The nominee change case creation validation should return Success.');
    }
    
    @isTest
    static void testNomineeChangeCaseCreationValidationFailure() {
        Asset asset = [SELECT Id FROM Asset LIMIT 1];
        
        Map<String, Object> caseRecordMap = new Map<String, Object>{
            'AssetId' => 1
        };
        String caseRecord = JSON.serialize(caseRecordMap);
        
        Test.startTest();
        try{
        	String result = ABSLI_CreateCaseValidationsController.nomineeChangeCaseCreationValidation(caseRecord);    
        }catch(AuraHandledException e){
            System.assertEquals('Script-thrown exception', e.getMessage(), 'Unexpected exception message');
        }
        
        Test.stopTest();
        
    }
    
    @isTest
    static void testDuplicatePolicyPrintingValidationSuccess() {
        Asset asset = [SELECT Id FROM Asset LIMIT 1];
        
        Map<String, Object> caseRecordMap = new Map<String, Object>{
            'AssetId' => asset.Id
        };
        String caseRecord = JSON.serialize(caseRecordMap);
        
        Test.startTest();
        String result = ABSLI_CreateCaseValidationsController.duplicatePolicyPrintingValidation(caseRecord);
        Test.stopTest();
        
        System.assertEquals('Success', result, 'The duplicate policy printing validation should return Success.');
    }
    
    @isTest
    static void testDuplicatePolicyPrintingValidationFailure() {
        Asset asset = [SELECT Id FROM Asset LIMIT 1];
        
        Map<String, Object> caseRecordMap = new Map<String, Object>{
            'AssetId' => 1
        };
        String caseRecord = JSON.serialize(caseRecordMap);
        
        Test.startTest();
        try{
        	String result = ABSLI_CreateCaseValidationsController.duplicatePolicyPrintingValidation(caseRecord);
        }catch(AuraHandledException e){
            System.assertEquals('Script-thrown exception', e.getMessage(), 'Unexpected exception message');
        }
        Test.stopTest();
        
    }
    
    @isTest
    static void testPerformUINapiCalloutSuccess() {
       // Test.setMock(HttpCalloutMock.class, new ABSLI_CreateCaseValidations_Test.UINApiMock());
        
        Asset asset = [SELECT Id,Policy_No__c,Effective_Date__c FROM Asset LIMIT 1];
        
        Map<String, Object> caseRecordMap = new Map<String, Object>{
            'AssetId' => asset.Id
        };
        String caseRecord = JSON.serialize(caseRecordMap);
        DateTime effectiveDateTime = DateTime.newInstance(asset.Effective_Date__c.year(), asset.Effective_Date__c.month(),asset.Effective_Date__c.day());
        Map<String, Object> requestMap = new Map<String, Object>{
            'POLICY_ID' => asset.Policy_No__c,
            'EFFECTIVE_DATE' => effectiveDateTime.format('dd-MM-yyyy'),
            'SOURCE' => '1234'
        };
        String request = JSON.serialize(requestMap);    
        
        Map<String, String> successResponseMap = new Map<String, String>();
        successResponseMap.put(request,
                               '{"Response":{"Status_Code":"0","Message":"Success"}}'
        );
        Test.setMock(HttpCalloutMock.class, new ABSLI_CreateCaseValidations_Test.MockHttpResponseGenerator(successResponseMap));
        Test.startTest();
        String result = ABSLI_CreateCaseValidationsController.performUINapiCallout(caseRecord);
        Test.stopTest();
        
        System.assertEquals('Success', result, 'The UIN API callout should return Success.');
    }
    
    @isTest
    static void testPerformUINapiCalloutFailure() {
       // Test.setMock(HttpCalloutMock.class, new ABSLI_CreateCaseValidations_Test.UINApiMock());
        
        Asset asset = [SELECT Id,Policy_No__c,Effective_Date__c FROM Asset LIMIT 1];
        
        Map<String, Object> caseRecordMap = new Map<String, Object>{
            'AssetId' => 1
        };
        String caseRecord = JSON.serialize(caseRecordMap);
        DateTime effectiveDateTime = DateTime.newInstance(asset.Effective_Date__c.year(), asset.Effective_Date__c.month(),asset.Effective_Date__c.day());
        Map<String, Object> requestMap = new Map<String, Object>{
            'POLICY_ID' => asset.Policy_No__c,
            //'EFFECTIVE_DATE' => effectiveDateTime.format('dd-MM-yyyy'),
            'EFFECTIVE_DATE' => asset.Effective_Date__c,
            'SOURCE' => '1234'
        };
        String request = JSON.serialize(requestMap);    
        
        Map<String, String> successResponseMap = new Map<String, String>();
        successResponseMap.put(request,
                               '{"Response":{"Status_Code":"1","Message":"Failure"}}'
        );
        Test.setMock(HttpCalloutMock.class, new ABSLI_CreateCaseValidations_Test.MockHttpResponseGenerator(successResponseMap));
        Test.startTest();
        try{
        	String result = ABSLI_CreateCaseValidationsController.performUINapiCallout(caseRecord);    
        }catch(AuraHandledException e){
			System.assertEquals('Script-thrown exception', e.getMessage(), 'Unexpected exception message');
        }
        
        Test.stopTest();
    }


    // Mock class for Gen Fund API
	public class MockHttpResponseGenerator implements HttpCalloutMock {
    	private Map<String, String> responseMap;

        public MockHttpResponseGenerator(Map<String, String> responseMap) {
            this.responseMap = responseMap;
        }
    	
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String requestBody = req.getBody();
            String firstKey = responseMap.keySet().iterator().next();
			Object firstValue = responseMap.get(firstKey);
            res.setBody(String.valueOf(firstValue));
            res.setStatusCode(200);
            return res;
    	}
	}

}