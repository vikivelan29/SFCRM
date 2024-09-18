/**
 * @description Unit Test Class for Loan Register Integration
 *
 * @author Abinash Panigrahi
 * @date 2024-05-17
 */
@isTest
public with sharing class ABSLI_LoanRegisterIntegration_Test {
	/**
	 * @description Test Data Setup for this Test Class
	 */
	@testSetup
	static void setupTestData() {
		ASF_Integration__c integ = new ASF_Integration__c();
		integ.External_Id__c = 'ABSLI_LR';
		integ.Display_Name__c = 'Loan Register';
		integ.Query_Fields__c = 'Id, Status, ABSLI_Case_Detail__c, ABSLI_Case_Detail__r.Requested_Loan_Amount__c, ABSLI_Case_Detail__r.Voucher_Number__c,ABSLI_Case_Detail__r.Voucher_Date__c, LAN__c, AssetId, Asset.Policy_No__c, Business_Unit__c, CCC_External_Id__c';
		integ.Processing_Class__c = 'ABSLI_LoanRegisterIntegration';
		integ.When_to_Appear__c = 'Stage Entry';
		integ.Type__c = ''; // Type will be blank so no button
		integ.Auto_Run_on_Load__c = true;
		insert integ;

		Account accRec = ASF_TestDataFactory.insertPersonAccount('Abinash', 'Panigrahi', '100');

		Asset assetRec = ASF_TestDataFactory.createAsset(accRec.Id, 'Loans');
		assetRec.Policy_No__c = '1234';
		update assetRec;

		ABSLI_Case_Detail__c detailRec = new ABSLI_Case_Detail__c();
		detailRec.Requested_Loan_Amount__c = 999999;
        detailRec.Status_Valid_For_STP__c = true;
		insert detailRec;

		Case caseRec = ASF_TestDataFactory.createInteractionCaseRecords()[0];
		caseRec.Source__c = 'Email';
		caseRec.Business_Unit__c = 'ABSLI';
		caseRec.Status = 'Open';
		caseRec.AssetId = assetRec.Id;
		caseRec.ABSLI_Case_Detail__c = detailRec.Id;
		caseRec.AccountId = accRec.Id;
		caseRec.CCC_External_Id__c = 'ABSLI_LR';
        caseRec.Sub_Type_Text__c = ABSLI_Constants.LOANVOUCHERPROCESS_SUBTYPE;
		update caseRec;

		ASF_TestDataFactory.createCaseIntegration(caseRec.Id, 'ABSLI_LR');
        ASF_TestDataFactory.createCaseIntegration(caseRec.Id, 'ABSLI_LA');

		ASF_Case_Category_Config__c caseCatConfig = new ASF_Case_Category_Config__c();
		caseCatConfig.CCC_External_Id__c = 'ABSLI_LR';
		caseCatConfig.Overall_Case_Closure_SLA__c = 10;
		caseCatConfig.First_Stage__c = 'Pending with Initiator';
		caseCatConfig.Type__c = 'Bureau Related';
		caseCatConfig.Sub_Type__c = 'CIBIL Related Details - Ownership Related';
		caseCatConfig.Overall_Case_Closure_SLA__c = 56;
		caseCatConfig.Nature__c = 'Request';
		caseCatConfig.Source__c = 'CEC';
		caseCatConfig.Product__c = 'TFE, CV, LCV, CE, SA, GLN, RBG-CV, RBG-CE, ABG, ARB, MFI, TDF';
		insert caseCatConfig;
	}

    @isTest
	static void evaluate_Test_Method() {
		ABSLI_LoanRegisterIntegration integrationObj = new ABSLI_LoanRegisterIntegration();
		Case caseRec = [
			SELECT
            Id, Status, ABSLI_Case_Detail__c, ABSLI_Case_Detail__r.Requested_Loan_Amount__c, ABSLI_Case_Detail__r.Voucher_Number__c,ABSLI_Case_Detail__r.Voucher_Date__c, LAN__c, AssetId, Asset.Policy_No__c, Business_Unit__c, CCC_External_Id__c
			FROM Case
			LIMIT 1
		];

		Test.startTest();
		ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRec.Id => caseRec };
		ASF_IntegrationsController.IntegrationWrapper result = integrationObj.evaluate(caseRec);
		System.assertEquals('Success', result.status);
		Test.stopTest();
	}

	@isTest
	static void run_Test_Method() {
		ABSLI_LoanRegisterIntegration integrationObj = new ABSLI_LoanRegisterIntegration();
		ASF_Integration__c integ = [
			SELECT Id, Processing_Class__c, External_Id__c
			FROM ASF_Integration__c
			LIMIT 1
		];
		Case caseRec = [
			SELECT
            Id, Status, ABSLI_Case_Detail__c, ABSLI_Case_Detail__r.Requested_Loan_Amount__c, ABSLI_Case_Detail__r.Voucher_Number__c,ABSLI_Case_Detail__r.Voucher_Date__c, LAN__c, AssetId, Asset.Policy_No__c, Business_Unit__c, CCC_External_Id__c
			FROM Case
			LIMIT 1
		];

		Test.startTest();
		ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRec.Id => caseRec };
		ASF_IntegrationsController.IntegrationWrapper res = integrationObj.run(integ, caseRec);
		System.assertEquals('Success', res.status);
		Test.stopTest();
	}

	@isTest
	static void evaluate_Test_MethodBulk() {
		ABSLI_LoanRegisterIntegration integrationObj = new ABSLI_LoanRegisterIntegration();
		Case caseRec = [
			SELECT
            Id, Status, ABSLI_Case_Detail__c, ABSLI_Case_Detail__r.Requested_Loan_Amount__c, ABSLI_Case_Detail__r.Voucher_Number__c,ABSLI_Case_Detail__r.Voucher_Date__c, LAN__c, AssetId, Asset.Policy_No__c, Business_Unit__c, CCC_External_Id__c
			FROM Case
			LIMIT 1
		];

		Test.startTest();
		ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRec.Id => caseRec };
		Map<Id, ASF_IntegrationsController.IntegrationWrapper> result = integrationObj.evaluate(
			new List<Case>{ caseRec }
		);
		System.assertEquals('Success', result.get(caseRec.Id).status);
		Test.stopTest();
	}

	@isTest
	static void run_Test_MethodBulk() {
		ABSLI_LoanRegisterIntegration integrationObj = new ABSLI_LoanRegisterIntegration();
		ASF_Integration__c integ = [
			SELECT Id, Processing_Class__c, External_Id__c
			FROM ASF_Integration__c
			LIMIT 1
		];

		Case caseRec = [
			SELECT
            Id, Status, ABSLI_Case_Detail__c, ABSLI_Case_Detail__r.Requested_Loan_Amount__c, ABSLI_Case_Detail__r.Voucher_Number__c,ABSLI_Case_Detail__r.Voucher_Date__c, LAN__c, AssetId, Asset.Policy_No__c, Business_Unit__c, CCC_External_Id__c
			FROM Case
			LIMIT 1
		];

		Test.startTest();
		ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRec.Id => caseRec };
		Map<Id, ASF_IntegrationsController.IntegrationWrapper> res = integrationObj.run(
			new Map<Id, List<ASF_Integration__c>>{ caseRec.Id => new List<ASF_Integration__c>{ integ } },
			new List<Case>{ caseRec }
		);
		System.assertEquals('Success', res.get(caseRec.Id).status);
		Test.stopTest();
	}

	@IsTest
	static void testProcessResponse() {
		ABSLI_LoanRegisterIntegration integrationObj = new ABSLI_LoanRegisterIntegration();
		Case caseRec = [
			SELECT
            Id, Status, ABSLI_Case_Detail__c, ABSLI_Case_Detail__r.Requested_Loan_Amount__c, ABSLI_Case_Detail__r.Voucher_Number__c,ABSLI_Case_Detail__r.Voucher_Date__c, LAN__c, AssetId, Asset.Policy_No__c, Business_Unit__c, CCC_External_Id__c
			FROM Case
			LIMIT 1
		];
		ASF_Case_Integration__c caseIntegRec = [
			SELECT Id, Case__c, Business_External_Id__c, Status__c, Response__c, CreatedById
			FROM ASF_Case_Integration__c
			LIMIT 1
		];

		ABSLI_LoanRegisterIntegration.LRResponseWrapper responseObj = new ABSLI_LoanRegisterIntegration.LRResponseWrapper();
		responseObj.MIR_ACT_CHQ_VCHR_NUM = '8895335596';
        responseObj.LSIR_RETURN_CD = '00';

		caseIntegRec.Response__c = JSON.serialize(responseObj);
		caseIntegRec.Status__c = 'Success';
		update caseIntegRec;

		Test.startTest();
		ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRec.Id => caseRec };
		integrationObj.processResponse(caseIntegRec);
		System.assertEquals(caseIntegRec.Status__c, 'Success');
		Test.stopTest();
	}


	@IsTest
	static void testBatchExecute() {
        ASF_Integration__c integ = new ASF_Integration__c();
		integ.External_Id__c = 'ABSLI_LA';
		integ.Display_Name__c = 'Loan Approval';
		integ.Query_Fields__c = 'Id, Status, LAN__c, AssetId, Asset.Policy_No__c, ABSLI_Case_Detail__c, ABSLI_Case_Detail__r.Voucher_Number__c, ABSLI_Case_Detail__r.Voucher_Date__c, Business_Unit__c, CCC_External_Id__c';
		integ.Processing_Class__c = 'ABSLI_LoanApprovalIntegration';
		integ.When_to_Appear__c = 'Stage Entry';
		integ.Type__c = ''; // Type will be blank so no button
		integ.Auto_Run_on_Load__c = true;
		insert integ;

        ABSLI_Case_Detail__c detailRec = new ABSLI_Case_Detail__c();
		detailRec.Requested_Loan_Amount__c = 999999;
        detailRec.Status_Valid_For_STP__c = true;
		insert detailRec;

        Case caseRec2 = ASF_TestDataFactory.createInteractionCaseRecords()[0];
		caseRec2.Source__c = 'Email';
		caseRec2.Business_Unit__c = 'ABSLI';
		caseRec2.Status = 'Open';
		caseRec2.AssetId = [SELECT Id FROM Asset LIMIT 1].Id;
		caseRec2.ABSLI_Case_Detail__c = detailRec.Id;
		caseRec2.AccountId = [SELECT Id FROM Account LIMIT 1].Id;
		caseRec2.CCC_External_Id__c = 'ABSLI_LA';
        caseRec2.Is_STP__c = true;
        caseRec2.Sub_Type_Text__c = ABSLI_Constants.LOANVOUCHERPROCESS_SUBTYPE;
		update caseRec2;

		Test.startTest();
		Database.executeBatch(new ABSLI_LoanVoucherProcessIntegrationBatch(), 2);
		Test.stopTest();
	}

	@IsTest
	static void testBatchExecuteFail() {
		Test.startTest();
		delete [SELECT Id FROM ASF_Integration__c];
		Database.executeBatch(new ABSLI_LoanVoucherProcessIntegrationBatch(), 1);
		Test.stopTest();
	}

	@IsTest
	static void testScheduldeExecute() {
		Test.startTest();
		ABSLI_LoanVoucherProcessIntegrationBatch obj = new ABSLI_LoanVoucherProcessIntegrationBatch();
		obj.schedule();
		System.schedule(
			ABSLI_Constants.LOANVOUCHERPROCESS_SCHEDULDE_JOB + ' Run#3',
			'0 0 0 1/1 * ? *',
			new ABSLI_LoanVoucherProcessIntegrationBatch()
		);
		Test.stopTest();
	}
}