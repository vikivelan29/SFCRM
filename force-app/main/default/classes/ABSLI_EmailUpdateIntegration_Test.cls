/**
 * @description Unit Test Class for Contact Update (Email and/or Mobile Number) Details Integration
 *
 * @author Laxman R
 * @date 2024-05-29
 */
@isTest
public with sharing class ABSLI_EmailUpdateIntegration_Test {
	/**
	 * @description Test Data Setup for this Test Class
	 */
	@testSetup
	static void setupTestData() {
		ASF_Integration__c integ = new ASF_Integration__c();
		integ.External_Id__c = 'PNFT008';
		integ.Display_Name__c = 'Contact Detail Update';
		integ.Query_Fields__c = 'Id, Status, OwnerId, CaseNumber, Client_Code_Text__c, Account.Client_Code__c, ABSLI_Case_Detail__c, ABSLI_Case_Detail__r.Status_Valid_For_STP__c, AccountId, ABSLI_Case_Detail__r.Mobile_Number__c, ABSLI_Case_Detail__r.Email_Id__c, Technical_Source__c, Business_Unit__c, CCC_External_Id__c';
		integ.Processing_Class__c = 'ABSLI_EmailUpdateIntegration';
		integ.When_to_Appear__c = 'Stage Entry';
		integ.Type__c = 'Process';
		integ.Auto_Run_on_Load__c = true;
		insert integ;

		Account accRec = ASF_TestDataFactory.insertPersonAccount('Abinash', 'Panigrahi', '100');
		accRec.Client_Code__c = 'ABI123';
		update accRec;

		Asset assetRec = ASF_TestDataFactory.createAsset(accRec.Id, 'Loans');
		assetRec.Policy_No__c = '1234';
		update assetRec;

		ABSLI_Case_Detail__c detailRec = new ABSLI_Case_Detail__c();
		detailRec.Mobile_Number__c = 'PAYTM123';
		detailRec.Email_Id__c = 'panigrahi@abinash.com';
		detailRec.Status_Valid_For_STP__c = true;
		insert detailRec;

		Case caseRec = ASF_TestDataFactory.createInteractionCaseRecords()[0];
		caseRec.Source__c = 'Email';
		caseRec.Business_Unit__c = 'ABSLI';
		caseRec.Status = 'Open';
		caseRec.AssetId = assetRec.Id;
		caseRec.ABSLI_Case_Detail__c = detailRec.Id;
		caseRec.AccountId = accRec.Id;
		caseRec.CCC_External_Id__c = 'PNFT008';
		caseRec.Client_Code_Text__c = '8895335596';
		caseRec.Technical_Source__c = 'LWC';
		update caseRec;

		ASF_TestDataFactory.createCaseIntegration(caseRec.Id, 'PNFT008');

		ASF_Case_Category_Config__c caseCatConfig = new ASF_Case_Category_Config__c();
		caseCatConfig.CCC_External_Id__c = 'PNFT008';
		caseCatConfig.Overall_Case_Closure_SLA__c = 10;
		caseCatConfig.First_Stage__c = 'Pending with Initiator';
		caseCatConfig.Type__c = 'Bureau Related';
		caseCatConfig.Sub_Type__c = 'CIBIL Related Details - Ownership Related';
		caseCatConfig.Overall_Case_Closure_SLA__c = 56;
		caseCatConfig.Nature__c = 'Request';
		caseCatConfig.Source__c = 'CEC';
		caseCatConfig.Product__c = 'TFE, CV, LCV, CE, SA, GLN, RBG-CV, RBG-CE, ABG, ARB, MFI, TDF';
		insert caseCatConfig;
    
        ASF_Checklist__c chk1 = new ASF_Checklist__c(Case__c = caseRec.Id, Status__c ='Completed', Label__c= 'New Ceck Label');
        insert chk1;
	}

	@isTest
	static void evaluate_Test_Method() {
		ABSLI_EmailUpdateIntegration integrationObj = new ABSLI_EmailUpdateIntegration();
		Case caseRec = [
			SELECT
				Id,
            	Source__c,
				Status,
				OwnerId,
				CaseNumber,
				Client_Code_Text__c,
				Account.Client_Code__c,
				ABSLI_Case_Detail__c,
				ABSLI_Case_Detail__r.Status_Valid_For_STP__c,
            	ABSLI_Case_Detail__r.Source_Request_submitted_by__c,
				AccountId,
				ABSLI_Case_Detail__r.Mobile_Number__c,
				ABSLI_Case_Detail__r.Email_Id__c,
				Technical_Source__c,
				Business_Unit__c,
				CCC_External_Id__c
			FROM Case
			LIMIT 1
		];

		Test.startTest();
		ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRec.Id => caseRec };
		ASF_IntegrationsController.IntegrationWrapper result = integrationObj.evaluate(caseRec);
		System.assertEquals('Error', result.status);
		Test.stopTest();
	}

	@isTest
	static void run_Test_Method() {
		ABSLI_EmailUpdateIntegration integrationObj = new ABSLI_EmailUpdateIntegration();
		ASF_Integration__c integ = [
			SELECT Id, Processing_Class__c, External_Id__c,Do_Not_Retry_Integration__c
			FROM ASF_Integration__c
			LIMIT 1
		];
		Case caseRec = [
			SELECT
				Id,
				Status,
				OwnerId,
				CaseNumber,
				Client_Code_Text__c,
				Account.Client_Code__c,
				ABSLI_Case_Detail__c,
				ABSLI_Case_Detail__r.Status_Valid_For_STP__c,
				AccountId,
				ABSLI_Case_Detail__r.Mobile_Number__c,
				ABSLI_Case_Detail__r.Email_Id__c,
				Technical_Source__c,
				Business_Unit__c,
				CCC_External_Id__c
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
		ABSLI_EmailUpdateIntegration integrationObj = new ABSLI_EmailUpdateIntegration();
		Case caseRec = [
			SELECT
				Id,
            	Source__c,
				Status,
				OwnerId,
				CaseNumber,
				Client_Code_Text__c,
				Account.Client_Code__c,
				ABSLI_Case_Detail__c,
				ABSLI_Case_Detail__r.Status_Valid_For_STP__c,
            	ABSLI_Case_Detail__r.Source_Request_submitted_by__c,
				AccountId,
				ABSLI_Case_Detail__r.Mobile_Number__c,
				ABSLI_Case_Detail__r.Email_Id__c,
				Technical_Source__c,
				Business_Unit__c,
				CCC_External_Id__c
			FROM Case
			LIMIT 1
		];

		Test.startTest();
		ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRec.Id => caseRec };
		Map<Id, ASF_IntegrationsController.IntegrationWrapper> result = integrationObj.evaluate(
			new List<Case>{ caseRec }
		);
		System.assertEquals('Error', result.get(caseRec.Id).status);
		Test.stopTest();
	}

	@isTest
	static void run_Test_MethodBulk() {
		ABSLI_EmailUpdateIntegration integrationObj = new ABSLI_EmailUpdateIntegration();
		ASF_Integration__c integ = [
			SELECT Id, Processing_Class__c, External_Id__c,Do_Not_Retry_Integration__c
			FROM ASF_Integration__c
			LIMIT 1
		];

		Case caseRec = [
			SELECT
				Id,
				Status,
				OwnerId,
				CaseNumber,
				Client_Code_Text__c,
				Account.Client_Code__c,
				ABSLI_Case_Detail__c,
				ABSLI_Case_Detail__r.Status_Valid_For_STP__c,
				AccountId,
				ABSLI_Case_Detail__r.Mobile_Number__c,
				ABSLI_Case_Detail__r.Email_Id__c,
				Technical_Source__c,
				Business_Unit__c,
				CCC_External_Id__c
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
		ABSLI_EmailUpdateIntegration integrationObj = new ABSLI_EmailUpdateIntegration();
		Case caseRec = [
			SELECT
				Id,
				Status,
				OwnerId,
				CaseNumber,
				Client_Code_Text__c,
				Account.Client_Code__c,
				ABSLI_Case_Detail__c,
				ABSLI_Case_Detail__r.Status_Valid_For_STP__c,
				AccountId,
				ABSLI_Case_Detail__r.Mobile_Number__c,
				ABSLI_Case_Detail__r.Email_Id__c,
				Technical_Source__c,
				Business_Unit__c,
				CCC_External_Id__c
			FROM Case
			LIMIT 1
		];
		ASF_Case_Integration__c caseIntegRec = [
			SELECT Id, Case__c, Business_External_Id__c, Status__c, Response__c, CreatedById
			FROM ASF_Case_Integration__c
			LIMIT 1
		];

		ABSLI_EmailUpdateIntegration.EmailUpdateResponse responseObj = new ABSLI_EmailUpdateIntegration.EmailUpdateResponse();
		responseObj.TRANS_NO = '00';
		responseObj.ProcessMessage = '00';
		responseObj.ProcessCode = '00';
		responseObj.FaultCode = '8895335596';
		responseObj.FaultMessage = 'SAV';

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