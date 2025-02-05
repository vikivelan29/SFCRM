/**
 * @description Unit Test Class for Loan Repayment Integration
 *
 * @author Abinash Panigrahi
 * @date 2024-05-17
 */
@isTest
public with sharing class ABSLI_LoanRepaymentIntegration_Test {
	/**
	 * @description Test Data Setup for this Test Class
	 */
	@testSetup
	static void setupTestData() {
		ASF_Integration__c integ = new ASF_Integration__c();
		integ.External_Id__c = 'ABSLI_LA';
		integ.Display_Name__c = 'Loan Repayment';
		integ.Query_Fields__c = 'Id, Status, LAN__c, AssetId, Asset.Policy_No__c, Source__c, Technical_Source__c, ABSLI_Case_Detail__c, ABSLI_Case_Detail__r.Loan_Repayment_Type__c, ABSLI_Case_Detail__r.Status_Valid_For_STP__c, Business_Unit__c, CCC_External_Id__c';
		integ.Processing_Class__c = 'ABSLI_LoanRepaymentIntegration';
		integ.When_to_Appear__c = 'Stage Entry';
		integ.Type__c = ''; // Type will be blank so no button
		integ.Auto_Run_on_Load__c = true;
		insert integ;

		Account accRec = ASF_TestDataFactory.insertPersonAccount('Abinash', 'Panigrahi', '100');

		Asset assetRec = ASF_TestDataFactory.createAsset(accRec.Id, 'Loans');
		assetRec.Policy_No__c = '1234';
		update assetRec;

		ABSLI_Case_Detail__c detailRec = new ABSLI_Case_Detail__c();
        detailRec.Status_Valid_For_STP__c = true;
        detailRec.Loan_Repayment_Type__c = 'Full Loan Repayment';
		insert detailRec;

		Case caseRec = ASF_TestDataFactory.createInteractionCaseRecords()[0];
		caseRec.Source__c = 'Customer Portal';
        caseRec.Technical_Source__c = 'API';
		caseRec.Business_Unit__c = 'ABSLI';
		caseRec.Status = 'Open';
		caseRec.AssetId = assetRec.Id;
        caseRec.LAN__c = '1234';
		caseRec.ABSLI_Case_Detail__c = detailRec.Id;
		caseRec.AccountId = accRec.Id;
		caseRec.CCC_External_Id__c = 'ABSLI_LA';
		update caseRec;

		ASF_TestDataFactory.createCaseIntegration(caseRec.Id, 'ABSLI_LA');

		ASF_Case_Category_Config__c caseCatConfig = new ASF_Case_Category_Config__c();
		caseCatConfig.CCC_External_Id__c = 'ABSLI_LA';
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
		ABSLI_LoanRepaymentIntegration integrationObj = new ABSLI_LoanRepaymentIntegration();
		Case caseRec = [
			SELECT
            Id, Status, LAN__c, AssetId, Asset.Policy_No__c, Source__c, Technical_Source__c, ABSLI_Case_Detail__c, ABSLI_Case_Detail__r.Loan_Repayment_Type__c, ABSLI_Case_Detail__r.Status_Valid_For_STP__c, Business_Unit__c, CCC_External_Id__c
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
		ABSLI_LoanRepaymentIntegration integrationObj = new ABSLI_LoanRepaymentIntegration();
		ASF_Integration__c integ = [
			SELECT Id, Processing_Class__c, External_Id__c, Do_Not_Retry_Integration__c
			FROM ASF_Integration__c
			LIMIT 1
		];
		Case caseRec = [
			SELECT
            Id, Status, LAN__c, AssetId, Asset.Policy_No__c, Source__c, Technical_Source__c, ABSLI_Case_Detail__c, ABSLI_Case_Detail__r.Loan_Repayment_Type__c, ABSLI_Case_Detail__r.Status_Valid_For_STP__c, Business_Unit__c, CCC_External_Id__c
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
		ABSLI_LoanRepaymentIntegration integrationObj = new ABSLI_LoanRepaymentIntegration();
		Case caseRec = [
			SELECT
            Id, Status, LAN__c, AssetId, Asset.Policy_No__c, Source__c, Technical_Source__c, ABSLI_Case_Detail__c, ABSLI_Case_Detail__r.Loan_Repayment_Type__c, ABSLI_Case_Detail__r.Status_Valid_For_STP__c, Business_Unit__c, CCC_External_Id__c
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
		ABSLI_LoanRepaymentIntegration integrationObj = new ABSLI_LoanRepaymentIntegration();
		ASF_Integration__c integ = [
			SELECT Id, Processing_Class__c, External_Id__c, Do_Not_Retry_Integration__c
			FROM ASF_Integration__c
			LIMIT 1
		];

		Case caseRec = [
			SELECT
            Id, Status, LAN__c, AssetId, Asset.Policy_No__c, Source__c, Technical_Source__c, ABSLI_Case_Detail__c, ABSLI_Case_Detail__r.Loan_Repayment_Type__c, ABSLI_Case_Detail__r.Status_Valid_For_STP__c, Business_Unit__c, CCC_External_Id__c
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
		ABSLI_LoanRepaymentIntegration integrationObj = new ABSLI_LoanRepaymentIntegration();
		Case caseRec = [
			SELECT
            Id, Status, LAN__c, AssetId, Asset.Policy_No__c, Source__c, Technical_Source__c, ABSLI_Case_Detail__c, ABSLI_Case_Detail__r.Loan_Repayment_Type__c, ABSLI_Case_Detail__r.Status_Valid_For_STP__c, Business_Unit__c, CCC_External_Id__c
			FROM Case
			LIMIT 1
		];
		ASF_Case_Integration__c caseIntegRec = [
			SELECT Id, Case__c, Business_External_Id__c, Status__c, Response__c, CreatedById
			FROM ASF_Case_Integration__c
			LIMIT 1
		];

		ABSLI_LoanRepaymentIntegration.LoanRepaymentResponseWrapper responseObj = new ABSLI_LoanRepaymentIntegration.LoanRepaymentResponseWrapper();
		responseObj.LSIR_RETURN_CD = '00';
        responseObj.MESSAGES = 'Approved by Abinash panigrahi';

		caseIntegRec.Response__c = JSON.serialize(responseObj);
		caseIntegRec.Status__c = 'Success';
		update caseIntegRec;

		Test.startTest();
		ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRec.Id => caseRec };
		integrationObj.processResponse(caseIntegRec);
		System.assertEquals(caseIntegRec.Status__c, 'Success');
		Test.stopTest();
	}
}