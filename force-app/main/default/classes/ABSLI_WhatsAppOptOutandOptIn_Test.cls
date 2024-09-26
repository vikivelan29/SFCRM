/**
 * @description Unit Test Class for Contact Update (Email and/or Mobile Number) Details Integration
 *
 * @author Laxman R
 * @date 2024-06-10
 */
@IsTest
public class ABSLI_WhatsAppOptOutandOptIn_Test {
	/**
	 * @description Test Data Setup for this Test Class
	 */
	@testSetup
	static void setupTestData() {
		ASF_Integration__c integ = new ASF_Integration__c();
		integ.External_Id__c = 'PNFT008';
		integ.Display_Name__c = 'WhatsApp OptOut and OptIn';
		integ.Query_Fields__c = 'ABSLI_Case_Detail__r.Status_Valid_For_STP__c,CaseNumber,Account.Client_Code__c,ABSLI_Case_Detail__r.WhatsApp_Opt_Out_Indicator__c,Business_Unit__c,Technical_Source__c,Is_STP__c';
		integ.Processing_Class__c = 'ABSLI_WhatsAppOptOutandOptInIntegration';
		integ.When_to_Appear__c = 'Stage Entry';
		integ.Type__c = 'Process';
		integ.Auto_Run_on_Load__c = true;
		insert integ;

		Account accRec = ASF_TestDataFactory.insertPersonAccount('test', 'test', '100');
		accRec.Client_Code__c = 'ABI123';
		update accRec;

		Asset assetRec = ASF_TestDataFactory.createAsset(accRec.Id, 'Loans');
		assetRec.Policy_No__c = '1234';
		update assetRec;

		ABSLI_Case_Detail__c detailRec = new ABSLI_Case_Detail__c();
		detailRec.WhatsApp_Opt_Out_Indicator__c = 'true';
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
		caseRec.Technical_Source__c = 'API';
        caseRec.Is_STP__c = true;
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
        
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Status__c = 'Failure';
        caseInt.Integration_Ext_Id__c = integ.External_Id__c;
        caseInt.Case__c = caseRec.Id;
        insert caseInt;
        
        ASF_Case_Integration__c caseIntUpdate = new ASF_Case_Integration__c();  
        caseIntUpdate.Id = caseInt.Id;
        caseIntUpdate.Integration_Ext_Id__c = integ.External_Id__c;
        caseIntUpdate.Status__c = 'Success';
        caseIntUpdate.Response__c = '{"AUTOCLOSURE_IN_RR":"NO","CASEID":"03974","CASESUBTYPE":"12345","COMMENT":"updatedd","CONFIDENCESCORE":"40.12","CUSTOMERNO":"1234566","ISATTACHMENTFLAG":"NO","ISMULTIPLELAN":"YES","ISREGISTEREDCUSTOMER":"YES","ISSMT":"NO","LAN":"122321321","LOB":"001","MOODSTAMP":"not sure","OWNERFULLNAME":"Shubham Sinha","PAYTMINTERACTIONID":"","PRIORITY":"low","AUTORESPONSEFLAG":"YES"}';

	}

	@isTest
	static void evaluate_Test_Method() {
		ABSLI_WhatsAppOptOutandOptInIntegration whatsAppInt = new ABSLI_WhatsAppOptOutandOptInIntegration();
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
				AccountId,
				ABSLI_Case_Detail__r.WhatsApp_Opt_Out_Indicator__c,
				ABSLI_Case_Detail__r.Email_Id__c,
				Technical_Source__c,
            	Is_STP__c,
				Business_Unit__c,
				CCC_External_Id__c
			FROM Case
			LIMIT 1
		];

		Test.startTest();
		ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRec.Id => caseRec };
		ASF_IntegrationsController.IntegrationWrapper result = whatsAppInt.evaluate(caseRec);
		System.assertEquals('Success', result.status);
		Test.stopTest();
	}

	@isTest
	static void run_Test_Method() {
		ABSLI_WhatsAppOptOutandOptInIntegration whatsAppInt = new ABSLI_WhatsAppOptOutandOptInIntegration();
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
				CaseNumber,
				Client_Code_Text__c,
				Account.Client_Code__c,
				ABSLI_Case_Detail__c,
				ABSLI_Case_Detail__r.Status_Valid_For_STP__c,
				AccountId,
				ABSLI_Case_Detail__r.WhatsApp_Opt_Out_Indicator__c,
				ABSLI_Case_Detail__r.Email_Id__c,
				Technical_Source__c,
            	Is_STP__c,
            	Issue_Type__c,
				Business_Unit__c,
				CCC_External_Id__c
			FROM Case
			LIMIT 1
		];

		Test.startTest();
		ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRec.Id => caseRec };
		ASF_IntegrationsController.IntegrationWrapper res = whatsAppInt.run(integ, caseRec);
		System.assertEquals('Success', res.status);
		Test.stopTest();
	}

	@isTest
	static void evaluate_Test_MethodBulk() {
		ABSLI_WhatsAppOptOutandOptInIntegration whatsAppInt = new ABSLI_WhatsAppOptOutandOptInIntegration();
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
				AccountId,
				ABSLI_Case_Detail__r.WhatsApp_Opt_Out_Indicator__c,
				ABSLI_Case_Detail__r.Email_Id__c,
				Technical_Source__c,
            	Is_STP__c,
				Business_Unit__c,
				CCC_External_Id__c
			FROM Case
			LIMIT 1
		];

		Test.startTest();
		ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRec.Id => caseRec };
		Map<Id, ASF_IntegrationsController.IntegrationWrapper> result = whatsAppInt.evaluate(
			new List<Case>{ caseRec }
		);
		System.assertEquals('Success', result.get(caseRec.Id).status);
		Test.stopTest();
	}

	@isTest
	static void run_Test_MethodBulk() {
		ABSLI_WhatsAppOptOutandOptInIntegration whatsAppInt = new ABSLI_WhatsAppOptOutandOptInIntegration();
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
				CaseNumber,
				Client_Code_Text__c,
				Account.Client_Code__c,
				ABSLI_Case_Detail__c,
				ABSLI_Case_Detail__r.Status_Valid_For_STP__c,
				AccountId,
				ABSLI_Case_Detail__r.WhatsApp_Opt_Out_Indicator__c,
				ABSLI_Case_Detail__r.Email_Id__c,
				Technical_Source__c,
            	Is_STP__c,
            	Issue_Type__c,
				Business_Unit__c,
				CCC_External_Id__c
			FROM Case
			LIMIT 1
		];

		Test.startTest();
		ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRec.Id => caseRec };
		Map<Id, ASF_IntegrationsController.IntegrationWrapper> res = whatsAppInt.run(
			new Map<Id, List<ASF_Integration__c>>{ caseRec.Id => new List<ASF_Integration__c>{ integ } },
			new List<Case>{ caseRec }
		);
		System.assertEquals('Success', res.get(caseRec.Id).status);
		Test.stopTest();
	}

	@IsTest
	static void testProcessResponse() {
		ABSLI_WhatsAppOptOutandOptInIntegration whatsAppInt = new ABSLI_WhatsAppOptOutandOptInIntegration();
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
				ABSLI_Case_Detail__r.WhatsApp_Opt_Out_Indicator__c,
				ABSLI_Case_Detail__r.Email_Id__c,
				Technical_Source__c,
            	Is_STP__c,
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

		ABSLI_WhatsAppOptOutandOptInIntegration.WhatsAppOptOutOptInResponse responseObj = new ABSLI_WhatsAppOptOutandOptInIntegration.WhatsAppOptOutOptInResponse();
		responseObj.TRANS_NO = '1234';
		responseObj.LSIR_RETURN_CD = '00';
		responseObj.MIR_RETRN_CD = '00';
		responseObj.MIR_CLI_ID = '8895335596';
		responseObj.MESSAGES = 'SAV';

		caseIntegRec.Response__c = JSON.serialize(responseObj);
		caseIntegRec.Status__c = 'Success';
		update caseIntegRec;

		Test.startTest();
		ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRec.Id => caseRec };
		whatsAppInt.processResponse(caseIntegRec);
		System.assertEquals(caseIntegRec.Status__c, 'Success');
		Test.stopTest();
	}
}