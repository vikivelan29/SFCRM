/**
 * @description Unit Test Class for Bank Account Update Integration
 *
 * @author Abinash Panigrahi
 * @date 2024-05-29
 */
@isTest
public with sharing class ABSLI_BankAccountUpdateIntegration_Test {
	/**
	 * @description Test Data Setup for this Test Class
	 */
	@testSetup
	static void setupTestData() {
		ASF_Integration__c integ = new ASF_Integration__c();
		integ.External_Id__c = 'ABSLI_PAS';
		integ.Display_Name__c = 'Bank Account Update';
		integ.Query_Fields__c = 'Id, Status, OwnerId, AssetId, CaseNumber, Asset.Policy_No__c, LAN__c, ABSLI_Case_Detail__c, ABSLI_Case_Detail__r.Status_Valid_For_STP__c, Technical_Source__c, ABSLI_Case_Detail__r.IFSC_Code__c, ABSLI_Case_Detail__r.Account_Number__c, ABSLI_Case_Detail__r.Account_Type__c, ABSLI_Case_Detail__r.Bank_IMPS_Date__c,ABSLI_Case_Detail__r.Bank_Account_Holder_Name__c, Business_Unit__c, CCC_External_Id__c';
		integ.Processing_Class__c = 'ABSLI_BankAccountUpdateIntegration';
		integ.When_to_Appear__c = 'Stage Entry';
		integ.Type__c = 'Process';
		integ.Auto_Run_on_Load__c = true;
		insert integ;

		Account accRec = ASF_TestDataFactory.insertPersonAccount('Abinash', 'Panigrahi', '100');
		accRec.PersonBirthdate = Date.today();
		update accRec;

		Asset assetRec = ASF_TestDataFactory.createAsset(accRec.Id, 'Loans');
		assetRec.Policy_No__c = '1234';
		update assetRec;

		ABSLI_Case_Detail__c detailRec = new ABSLI_Case_Detail__c();
		detailRec.IFSC_Code__c = 'PAYTM123';
        detailRec.Account_Number__c = '8895335596';
        detailRec.Account_Type__c = 'Savings';
        detailRec.Bank_Account_Holder_Name__c = 'Abinash Panigrahi';
		detailRec.Bank_IMPS_Date__c = Date.today().addDays(2);
        detailRec.Status_Valid_For_STP__c = true;
		insert detailRec;

		Case caseRec = ASF_TestDataFactory.createInteractionCaseRecords()[0];
		caseRec.Source__c = 'Email';
		caseRec.Business_Unit__c = 'ABSLI';
		caseRec.Status = 'Open';
		caseRec.AssetId = assetRec.Id;
		caseRec.ABSLI_Case_Detail__c = detailRec.Id;
		caseRec.AccountId = accRec.Id;
		caseRec.CCC_External_Id__c = 'ABSLI_PAS';
        caseRec.LAN__c = '8895335596';
        caseRec.Technical_Source__c = 'API';
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
		ABSLI_BankAccountUpdateIntegration integrationObj = new ABSLI_BankAccountUpdateIntegration();
		Case caseRec = [
			SELECT
				Id,
            	Source__c,
				Status,
				OwnerId,
				AssetId,
				CaseNumber,
				Asset.Policy_No__c,
				LAN__c,
				ABSLI_Case_Detail__c,
				ABSLI_Case_Detail__r.Status_Valid_For_STP__c,
				Technical_Source__c,
				ABSLI_Case_Detail__r.IFSC_Code__c,
				ABSLI_Case_Detail__r.Account_Number__c,
				ABSLI_Case_Detail__r.Account_Type__c,
				ABSLI_Case_Detail__r.Bank_IMPS_Date__c,
				ABSLI_Case_Detail__r.Bank_Account_Holder_Name__c,
				Business_Unit__c,
				CCC_External_Id__c
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
		ABSLI_BankAccountUpdateIntegration integrationObj = new ABSLI_BankAccountUpdateIntegration();
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
				AssetId,
				CaseNumber,
				Asset.Policy_No__c,
				LAN__c,
				ABSLI_Case_Detail__c,
				ABSLI_Case_Detail__r.Status_Valid_For_STP__c,
				Technical_Source__c,
				ABSLI_Case_Detail__r.IFSC_Code__c,
				ABSLI_Case_Detail__r.Account_Number__c,
				ABSLI_Case_Detail__r.Account_Type__c,
				ABSLI_Case_Detail__r.Bank_IMPS_Date__c,
				ABSLI_Case_Detail__r.Bank_Account_Holder_Name__c,
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
		ABSLI_BankAccountUpdateIntegration integrationObj = new ABSLI_BankAccountUpdateIntegration();
		Case caseRec = [
			SELECT
				Id,
            	Source__c,
				Status,
				OwnerId,
				AssetId,
				CaseNumber,
				Asset.Policy_No__c,
				LAN__c,
				ABSLI_Case_Detail__c,
				ABSLI_Case_Detail__r.Status_Valid_For_STP__c,
				Technical_Source__c,
				ABSLI_Case_Detail__r.IFSC_Code__c,
				ABSLI_Case_Detail__r.Account_Number__c,
				ABSLI_Case_Detail__r.Account_Type__c,
				ABSLI_Case_Detail__r.Bank_IMPS_Date__c,
				ABSLI_Case_Detail__r.Bank_Account_Holder_Name__c,
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
		System.assertEquals('Success', result.get(caseRec.Id).status);
		Test.stopTest();
	}

	@isTest
	static void run_Test_MethodBulk() {
		ABSLI_BankAccountUpdateIntegration integrationObj = new ABSLI_BankAccountUpdateIntegration();
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
				AssetId,
				CaseNumber,
				Asset.Policy_No__c,
				LAN__c,
				ABSLI_Case_Detail__c,
				ABSLI_Case_Detail__r.Status_Valid_For_STP__c,
				Technical_Source__c,
				ABSLI_Case_Detail__r.IFSC_Code__c,
				ABSLI_Case_Detail__r.Account_Number__c,
				ABSLI_Case_Detail__r.Account_Type__c,
				ABSLI_Case_Detail__r.Bank_IMPS_Date__c,
				ABSLI_Case_Detail__r.Bank_Account_Holder_Name__c,
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
		ABSLI_BankAccountUpdateIntegration integrationObj = new ABSLI_BankAccountUpdateIntegration();
		Case caseRec = [
			SELECT
				Id,
				Status,
				OwnerId,
				AssetId,
				CaseNumber,
				Asset.Policy_No__c,
				LAN__c,
				ABSLI_Case_Detail__c,
				ABSLI_Case_Detail__r.Status_Valid_For_STP__c,
				Technical_Source__c,
				ABSLI_Case_Detail__r.IFSC_Code__c,
				ABSLI_Case_Detail__r.Account_Number__c,
				ABSLI_Case_Detail__r.Account_Type__c,
				ABSLI_Case_Detail__r.Bank_IMPS_Date__c,
				ABSLI_Case_Detail__r.Bank_Account_Holder_Name__c,
				Business_Unit__c,
				CCC_External_Id__c,
				No_Auto_Communication__c
			FROM Case
			LIMIT 1
		];
		ASF_Case_Integration__c caseIntegRec = [
			SELECT Id, Case__c, Business_External_Id__c, Status__c, Response__c, CreatedById
			FROM ASF_Case_Integration__c
			LIMIT 1
		];

		ABSLI_BankAccountUpdateIntegration.BAUResponseWrapper responseObj = new ABSLI_BankAccountUpdateIntegration.BAUResponseWrapper();
		responseObj.LSIR_RETURN_CD = '00';
		responseObj.MIR_NEFT_IFSC_CD = 'PAYTM123';
		responseObj.MIR_NEFT_IFSC_CD_UP = 'PAYTM123';
		responseObj.MIR_RETRN_CD = '00';
		responseObj.Page = 'BF9151-P';
		responseObj.MIR_NEFT_ACCT_NUM_UP = '8895335596';
		responseObj.MIR_NEFT_ACCT_TYP_CD = 'SAV';
		responseObj.MIR_NEFT_BNK_MICR_CD_UP = '8895335596';
		responseObj.MIR_IMPS_FLAG = 'S';
		responseObj.MIR_IMPS_DATE = '29-04-2024';
		responseObj.MESSAGES = 'RECORD CREATED - CONTINUE ~ ';
		responseObj.ProcessMessage = 'LSIR-RETURN-OK';
		responseObj.MIR_ACC_HLDR_NM = 'Abinash Panigrahi';
		responseObj.MIR_IMPS_STATUS_CODE = '00';
		responseObj.MIR_IFSC_SEQ_NUM = '1234';
		responseObj.TRANS_NO = 'CAS-29540988-K1P3F4';
		responseObj.ProcessCode = '00';
		responseObj.MIR_NEFT_BNK_MICR_CD = '000000000';
		responseObj.MIR_NO_OF_IFSC_REC = '01';
		responseObj.MIR_NEFT_ACCT_TYP_CD_UP = 'SAV';
		responseObj.MIR_IMPS_ACC_HLDR_NM = '';
		responseObj.MIR_NEFT_BNK_BR_NM = 'PPL TOWNSHIP';
		responseObj.MIR_NEFT_BNK_NM = 'PAYTM PAYMENT BANK';
		responseObj.MIR_NEFT_ACCT_NUM = '8895335596';
		responseObj.MIR_IMPS_STATUS_DES = '0';

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