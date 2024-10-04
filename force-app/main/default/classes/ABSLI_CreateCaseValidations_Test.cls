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
        assetRec.Issue_Date__c = Date.today().addMonths(-6);
        assetRec.Business_Unit__c = ABSLI_Constants.BUSINESS_UNIT;
        assetRec.Plan_Name__c = 'BSLI Saral Health FAV';
        assetRec.Type__c = 'ULIP';
        assetRec.Payment_Term__c = '6';
        update assetRec;
        
        Asset assetRec1 = ASF_TestDataFactory.createAsset(accRec.Id, 'Loans');
        assetRec1.Policy_No__c = '5678';
        assetRec1.Policy_Identification__c = 'New Policy Act';
        assetRec1.Effective_Date__c = Date.today();
        assetRec1.Issue_Date__c = Date.today();
        assetRec1.Business_Unit__c = ABSLI_Constants.BUSINESS_UNIT;
        assetRec1.Plan_Name__c = 'BSLI Saral Health FAV';
        assetRec1.Type__c = 'Loans';
        assetRec1.Payment_Term__c = '6';
        update assetRec1;
        
        ABSLI_Case_Detail__c caseDetail = new ABSLI_Case_Detail__c();
        caseDetail.Reinstatement_Amount__c = 1000;
        caseDetail.COI_Covid_Quest__c = '["COVID_QUE","Hello"]';
        caseDetail.Medicals__c = 'Medical Report';
        caseDetail.COI_Signed_Date__c = Date.today();
        insert caseDetail;
        
        List<Case> caseRecList = ASF_TestDataFactory.createCaseRecords(1);
        caseRecList[0].AssetId = assetRec.Id;
        caseRecList[0].ABSLI_Case_Detail__c = caseDetail.Id;
        caseRecList[0].Technical_Source__c = 'API';
        caseRecList[0].CCC_External_Id__c = 'PREI001';
        ASF_TriggerSkipperUtility.markTriggerRun('Case');
        update caseRecList[0];
        ASF_TriggerSkipperUtility.resetTriggerRun('Case');
    }
    
    @isTest
    static void testGenFundApiValidationCalloutSuccess() {
        Asset asset = [SELECT Id,Policy_No__c,Effective_Date__c FROM Asset WHERE Policy_No__c = '1234' LIMIT 1];
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
        responseWrapper.BFID_RESPONSE.MINIMUM_WITHDRAWAL_AMT = '100.00';
        responseWrapper.BFID_RESPONSE.ProcessCode = '00';
        responseWrapper.BFID_RESPONSE.MINIMUM_LOAN_AMT = '500.00';
        responseWrapper.BFID_RESPONSE.WITHDRAWL_AMOUNT_AVAILABLE = '300.00';
        responseWrapper.BFID_RESPONSE.CASH_SURRENDER_VALUE = '500.00';
        responseWrapper.BFID_RESPONSE.MAX_LOAD_AMOUNT_AVAILABLE = '1000.00';
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
        Asset asset = [SELECT Id FROM Asset WHERE Policy_No__c = '1234' LIMIT 1];
        
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
        Asset asset = [SELECT Id FROM Asset WHERE Policy_No__c = '1234' LIMIT 1];
        
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
        Asset asset = [SELECT Id FROM Asset WHERE Policy_No__c = '1234' LIMIT 1];
        
        Map<String, Object> caseRecordMap = new Map<String, Object>{
            'AssetId' => asset.Id,
            'CCC_External_Id__c' => 'DUP002'
        };
        String caseRecord = JSON.serialize(caseRecordMap);
        
        Test.startTest();
        String result = ABSLI_CreateCaseValidationsController.duplicatePolicyPrintingValidation(caseRecord);
        Test.stopTest();
        
        System.assertEquals('Success', result, 'The duplicate policy printing validation should return Success.');
    }
    
    @isTest
    static void testDuplicatePolicyPrintingValidationFailure() {
        Asset asset = [SELECT Id FROM Asset WHERE Policy_No__c = '1234' LIMIT 1];
        
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
        
        Asset asset = [SELECT Id,Policy_No__c,Effective_Date__c FROM Asset WHERE Policy_No__c = '1234' LIMIT 1];
        
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
        
        Asset asset = [SELECT Id,Policy_No__c,Effective_Date__c FROM Asset WHERE Policy_No__c = '1234' LIMIT 1];
        
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
    
    @isTest
    static void testPenalInterestPayoutSaralHealthValidationSuccess(){
        Asset asset = [SELECT Id,Plan_Name__c FROM Asset WHERE Policy_No__c = '1234' LIMIT 1];
        
        Map<String, Object> caseRecordMap = new Map<String, Object>{
            'AssetId' => asset.Id
        };
        String caseRecord = JSON.serialize(caseRecordMap);
        
        Test.startTest();
        String result = ABSLI_CreateCaseValidationsController.penalInterestPayoutSaralHealthValidation(caseRecord);
        Test.stopTest();
        
        System.assertEquals('Success', result, 'The Penal Interest Payout Saral Health validation should return Success.');
    }
    
    @isTest
    static void testPenalInterestPayoutSaralHealthValidationFailure() {
        Asset asset = [SELECT Id FROM Asset WHERE Policy_No__c = '1234' LIMIT 1];
        
        Map<String, Object> caseRecordMap = new Map<String, Object>{
            'AssetId' => 1
        };
        String caseRecord = JSON.serialize(caseRecordMap);
        
        Test.startTest();
        try{
        	String result = ABSLI_CreateCaseValidationsController.penalInterestPayoutSaralHealthValidation(caseRecord);
        }catch(AuraHandledException e){
            System.assertEquals('Script-thrown exception', e.getMessage(), 'Unexpected exception message');
        }
        Test.stopTest();
        
    }
    
    @isTest
    static void testChangeInInvestorProfileValidationSuccess(){
        Asset asset = [SELECT Id,Type__c FROM Asset WHERE Policy_No__c = '1234' LIMIT 1];
        
        Map<String, Object> caseRecordMap = new Map<String, Object>{
            'AssetId' => asset.Id
        };
        String caseRecord = JSON.serialize(caseRecordMap);
        
        Test.startTest();
        String result = ABSLI_CreateCaseValidationsController.changeInInvestorProfileValidation(caseRecord);
        Test.stopTest();
        
        System.assertEquals('Success', result, 'The change In Investor Profile validation should return Success.');
    }
    
    @isTest
    static void testChangeInInvestorProfileValidationFailure() {
        Asset asset = [SELECT Id FROM Asset WHERE Policy_No__c = '1234' LIMIT 1];
        
        Map<String, Object> caseRecordMap = new Map<String, Object>{
            'AssetId' => 1
        };
        String caseRecord = JSON.serialize(caseRecordMap);
        
        Test.startTest();
        try{
        	String result = ABSLI_CreateCaseValidationsController.changeInInvestorProfileValidation(caseRecord);
        }catch(AuraHandledException e){
            System.assertEquals('Script-thrown exception', e.getMessage(), 'Unexpected exception message');
        }
        Test.stopTest();
        
    }
    
    @isTest
    static void testReinstatementValidationSuccess(){
        Asset asset = [SELECT Id,Type__c,Payment_Term__c FROM Asset WHERE Policy_No__c = '1234' LIMIT 1];
        
        Map<String, Object> caseRecordMap = new Map<String, Object>{
            'AssetId' => asset.Id
        };
        String caseRecord = JSON.serialize(caseRecordMap);
        
        Test.startTest();
        String result = ABSLI_CreateCaseValidationsController.reinstatementValidation(caseRecord);
        Test.stopTest();
        
        System.assertEquals('Success', result, 'The reinstatement validation should return Success.');
    }
    
    @isTest
    static void testReinstatementValidationFailure() {
        Asset asset = [SELECT Id FROM Asset WHERE Policy_No__c = '1234' LIMIT 1];
        
        Map<String, Object> caseRecordMap = new Map<String, Object>{
            'AssetId' => 1
        };
        String caseRecord = JSON.serialize(caseRecordMap);
        
        Test.startTest();
        try{
        	String result = ABSLI_CreateCaseValidationsController.reinstatementValidation(caseRecord);
        }catch(AuraHandledException e){
            System.assertEquals('Script-thrown exception', e.getMessage(), 'Unexpected exception message');
        }
        Test.stopTest();
        
    }
    
    @isTest
    static void testInterestWaiverForHOValidationSuccess(){
        Asset asset = [SELECT Id,Type__c FROM Asset WHERE Policy_No__c = '5678' LIMIT 1];
        
        Map<String, Object> caseRecordMap = new Map<String, Object>{
            'AssetId' => asset.Id
        };
        String caseRecord = JSON.serialize(caseRecordMap);
        
        Test.startTest();
        String result = ABSLI_CreateCaseValidationsController.interestWaiverForHOValidation(caseRecord);
        Test.stopTest();
        
        System.assertEquals('Success', result, 'The interest Waiver For HO validation should return Success.');
    }
    
    @isTest
    static void testInterestWaiverForHOValidationFailure() {
        Asset asset = [SELECT Id FROM Asset WHERE Policy_No__c = '5678' LIMIT 1];
        
        Map<String, Object> caseRecordMap = new Map<String, Object>{
            'AssetId' => 1
        };
        String caseRecord = JSON.serialize(caseRecordMap);
        
        Test.startTest();
        try{
        	String result = ABSLI_CreateCaseValidationsController.interestWaiverForHOValidation(caseRecord);
        }catch(AuraHandledException e){
            System.assertEquals('Script-thrown exception', e.getMessage(), 'Unexpected exception message');
        }
        Test.stopTest();
        
    }
    
    @isTest
    static void testAssignmentIssueTypeValidationSuccess(){
        Asset asset = [SELECT Id,Policy_Identification__c FROM Asset WHERE Policy_No__c = '5678' LIMIT 1];
        
        Map<String, Object> caseRecordMap = new Map<String, Object>{
            'AssetId' => asset.Id
        };
        String caseRecord = JSON.serialize(caseRecordMap);
        
        Test.startTest();
        String result = ABSLI_CreateCaseValidationsController.assignmentIssueTypeValidation(caseRecord);
        Test.stopTest();
        
        System.assertEquals('Success', result, 'The Assignment Issue Type validation should return Success.');
    }
    
    @isTest
    static void testAssignmentIssueTypeValidationFailure() {
        Asset asset = [SELECT Id FROM Asset WHERE Policy_No__c = '5678' LIMIT 1];
        
        Map<String, Object> caseRecordMap = new Map<String, Object>{
            'AssetId' => 1
        };
        String caseRecord = JSON.serialize(caseRecordMap);
        
        Test.startTest();
        try{
        	String result = ABSLI_CreateCaseValidationsController.assignmentIssueTypeValidation(caseRecord);
        }catch(AuraHandledException e){
            System.assertEquals('Script-thrown exception', e.getMessage(), 'Unexpected exception message');
        }
        Test.stopTest();
        
    }
    
    @IsTest
    static void testRedirectToCustomerPortalValidation(){
        Case c = [SELECT Id From Case WHERE CCC_External_Id__c = 'PREI001' LIMIT 1];
        List<ABSLI_CreateCaseValidationsController.RedirectToPortalResponse> responseList = ABSLI_CreateCaseValidationsController.redirectToCustomerPortalValidation(c.Id);
        String portalURL = ABSLI_CreateCaseValidationsController.generateCustomerPortalURL(c.Id);
        String staticUrl = Label.ABSLI_CustomerPortalUrl;
        System.assertEquals(staticUrl,'https://lifeinsuranceservicinguat.adityabirlacapital.com/abcLogin/interface/');
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