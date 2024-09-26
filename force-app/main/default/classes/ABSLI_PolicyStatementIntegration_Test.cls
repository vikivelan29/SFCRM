/**
 * @description Unit Test Class for Policy Account Statement Integration
 *
 * @author Abinash Panigrahi, Salesforce
 * @date 2024-05-17
 */
@isTest
public with sharing class ABSLI_PolicyStatementIntegration_Test {
	/**
	 * @description Test Data Setup for this Test Class
	 */
	@testSetup
	static void setupTestData() {
		ASF_Integration__c integ = new ASF_Integration__c();
		integ.External_Id__c = 'ABSLI_PAS';
		integ.Display_Name__c = 'Policy Account Statement';
		integ.Query_Fields__c = 'Id, Status, OwnerId, AssetId, Asset.Policy_No__c, ABSLI_Case_Detail__c, ABSLI_Case_Detail__r.From_Date__c, ABSLI_Case_Detail__r.To_Date__c, AccountId, Account.PersonBirthdate, Asset.LI_DOB__c Business_Unit__c, CCC_External_Id__c';
		integ.Processing_Class__c = 'ABSLI_PolicyStatementIntegration';
		integ.When_to_Appear__c = 'Stage Entry';
		integ.Type__c = 'Process';
		integ.Auto_Run_on_Load__c = true;
		insert integ;

		Account accRec = ASF_TestDataFactory.insertPersonAccount('Abinash', 'Panigrahi', '100');
		accRec.PersonBirthdate = Date.today();
		update accRec;

		Asset assetRec = ASF_TestDataFactory.createAsset(accRec.Id, 'Loans');
		assetRec.Policy_No__c = '1234';
        assetRec.LI_DOB__c = Date.today();
		update assetRec;

		ABSLI_Case_Detail__c detailRec = new ABSLI_Case_Detail__c();
		detailRec.From_Date__c = Date.today();
		detailRec.To_Date__c = Date.today().addDays(2);
		insert detailRec;

		Case caseRec = ASF_TestDataFactory.createInteractionCaseRecords()[0];
		caseRec.Source__c = 'Email';
		caseRec.Business_Unit__c = 'ABSLI';
		caseRec.Status = 'Open';
		caseRec.AssetId = assetRec.Id;
		caseRec.ABSLI_Case_Detail__c = detailRec.Id;
		caseRec.AccountId = accRec.Id;
        caseRec.CCC_External_Id__c = 'ABSLI_PAS';
		update caseRec;

		ASF_TestDataFactory.createCaseIntegration(caseRec.Id, 'ABSLI_PAS');

        ASF_Case_Category_Config__c caseCatConfig = new ASF_Case_Category_Config__c();
        caseCatConfig.CCC_External_Id__c = 'ABSLI_PAS';
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
		ABSLI_PolicyStatementIntegration integrationObj = new ABSLI_PolicyStatementIntegration();
		Case caseRec = [
			SELECT
				Id,
            	Source__c,
				Status,
				OwnerId,
				Asset.Policy_No__c,
				ABSLI_Case_Detail__r.From_Date__c,
				ABSLI_Case_Detail__r.To_Date__c,
				Business_Unit__c,
				Account.PersonBirthdate,
                Asset.LI_DOB__c,
                AssetId,
                AccountId,
                ABSLI_Case_Detail__c
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
		ABSLI_PolicyStatementIntegration integrationObj = new ABSLI_PolicyStatementIntegration();
		ASF_Integration__c integ = [
			SELECT Id, Processing_Class__c, External_Id__c
			FROM ASF_Integration__c
			LIMIT 1
		];
		Case caseRec = [
			SELECT
				Id,
				Status,
				OwnerId,
				Asset.Policy_No__c,
				ABSLI_Case_Detail__r.From_Date__c,
				ABSLI_Case_Detail__r.To_Date__c,
				Business_Unit__c,
				Account.PersonBirthdate,
                Asset.LI_DOB__c
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
		ABSLI_PolicyStatementIntegration integrationObj = new ABSLI_PolicyStatementIntegration();
		Case caseRec = [
			SELECT
				Id,
            	Source__c,
				Status,
				OwnerId,
				Asset.Policy_No__c,
				ABSLI_Case_Detail__r.From_Date__c,
				ABSLI_Case_Detail__r.To_Date__c,
				Business_Unit__c,
				Account.PersonBirthdate,
                Asset.LI_DOB__c,
                AssetId,
                AccountId,
                ABSLI_Case_Detail__c
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
		ABSLI_PolicyStatementIntegration integrationObj = new ABSLI_PolicyStatementIntegration();
		ASF_Integration__c integ = [
			SELECT Id, Processing_Class__c, External_Id__c
			FROM ASF_Integration__c
			LIMIT 1
		];

		Case caseRec = [
			SELECT
				Id,
				Status,
				OwnerId,
				Asset.Policy_No__c,
				ABSLI_Case_Detail__r.From_Date__c,
				ABSLI_Case_Detail__r.To_Date__c,
				Business_Unit__c,
				Account.PersonBirthdate,
                Asset.LI_DOB__c
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
		ABSLI_PolicyStatementIntegration integrationObj = new ABSLI_PolicyStatementIntegration();
        Case caseRec = [
			SELECT
				Id,
				Status,
				OwnerId,
				Asset.Policy_No__c,
				ABSLI_Case_Detail__r.From_Date__c,
				ABSLI_Case_Detail__r.To_Date__c,
				Business_Unit__c,
				Account.PersonBirthdate,
                Asset.LI_DOB__c,
                CCC_External_Id__c,
                ContactId,
                AccountId, No_Auto_Communication__c
			FROM Case
			LIMIT 1
		];
		ASF_Case_Integration__c caseIntegRec = [
			SELECT Id, Case__c, Business_External_Id__c, Status__c, Response__c, CreatedById
			FROM ASF_Case_Integration__c
			LIMIT 1
		];

		ABSLI_PolicyStatementIntegration.PASResponseWrapper responseObj = new ABSLI_PolicyStatementIntegration.PASResponseWrapper();
		responseObj.pdfBytes = 'AbinashPanigrahi';
		responseObj.URL = 'www.abinash.com';
		responseObj.outputFormat = 'PDF';
		responseObj.outputJSONString = '{\"Name\": \"Abinash Panigrahi\"}';
		responseObj.outputEmail = 'Statment Sent Successfully To panigrahi.abinash@outlook.com';

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
