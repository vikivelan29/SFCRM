/**
 * @description Unit Test Class for ABSLI_RegisterIGMSComplaintIntegration
 *
 * @author Laxman R
 * @date 2024-10-07
 */
@IsTest
public class ABSLI_ClosedIGMSComplaint_Test {
	/**
	 * @description Test Data Setup for this Test Class
	 */
	@testSetup
	static void setupTestData() {
		ASF_Integration__c integ = new ASF_Integration__c();
		integ.External_Id__c = 'PNFT007';
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
		update assetRec;
        
		ABSLI_Case_Detail__c detailRec = new ABSLI_Case_Detail__c();
		detailRec.IGMS_type_of_policy__c = '1';
        detailRec.IGMS_Source_of_Complaint__c = '4';
        detailRec.Receipt_Number__c = 'ABSLI0001';
        detailRec.IGMS_Complaint_Status__c = '2';
        detailRec.IGMS_Created_Case__c = true;
        detailRec.Acknowledged_Date__c = System.today();
        detailRec.Complaint_Category__c = 'Complaint';
        detailRec.IRDAI_Token_Number__c = '43546512';
        detailRec.New_Registration_Date__c = System.today();
        detailRec.Next_Integration_Name__c = 'ABSLI_PendingIGMSComplaintIntegration';
		detailRec.Email_Id__c = 'panigrahi@abinash.com';
		detailRec.Status_Valid_For_STP__c = true;
		insert detailRec;
        
        ABSLI_Case_Detail__c detailRec2 = new ABSLI_Case_Detail__c();
		detailRec2.IGMS_type_of_policy__c = '';
        detailRec2.IGMS_Source_of_Complaint__c = '';
        detailRec2.Receipt_Number__c = '';
        detailRec2.IRDAI_Token_Number__c = '';
        detailRec2.Complaint_Category__c = 'Complaint';
        detailRec2.IGMS_Complaint_Status__c = '1';
        detailRec2.IGMS_Created_Case__c = true;
		detailRec2.Email_Id__c = 'panigrahi@abinash.com';
		detailRec2.Status_Valid_For_STP__c = true;
		insert detailRec2;

		Case caseRec = ASF_TestDataFactory.createInteractionCaseRecords()[0];
		caseRec.Source__c = 'Email';
		caseRec.Business_Unit__c = 'ABSLI';
		caseRec.Status = 'Open';
		caseRec.AssetId = assetRec.Id;
        caseRec.Stage__c = 'In Progress with SA';
		caseRec.ABSLI_Case_Detail__c = detailRec.Id;
		caseRec.AccountId = accRec.Id;
		caseRec.CCC_External_Id__c = 'PNFT008';
		caseRec.Client_Code_Text__c = '8895335596';
		caseRec.Technical_Source__c = 'API';
        caseRec.Is_STP__c = true;
        caseRec.IGMS_Complaint_Type_Code__c = '1';
		update caseRec;
        
        Case caseRec1 = ASF_TestDataFactory.createInteractionCaseRecords()[0];
		caseRec1.Source__c = 'Email';
		caseRec1.Business_Unit__c = 'ABSLI';
		caseRec1.Status = 'Open';
		caseRec1.AssetId = assetRec.Id;
        caseRec1.Stage__c = 'Resolved';
		caseRec1.ABSLI_Case_Detail__c = detailRec2.Id;
		caseRec1.AccountId = accRec.Id;
		caseRec1.CCC_External_Id__c = 'PNFT008';
		caseRec1.Client_Code_Text__c = '8895335596';
		caseRec1.Technical_Source__c = 'API';
        caseRec1.Is_STP__c = true;
        caseRec1.IGMS_Complaint_Type_Code__c = '1';
		update caseRec1;

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
        caseInt.Status__c = 'Pending';
        caseInt.Integration_Ext_Id__c = integ.External_Id__c;
        caseInt.Case__c = caseRec.Id;
        insert caseInt;
        
        ASF_Case_Integration__c caseIntUpdate = new ASF_Case_Integration__c();  
        caseIntUpdate.Id = caseInt.Id;
        caseIntUpdate.Case__c = caseRec.Id;
        caseIntUpdate.Integration_Ext_Id__c = integ.External_Id__c;
        caseIntUpdate.Status__c = 'Success';
        caseIntUpdate.Response__c = '{"AUTOCLOSURE_IN_RR":"NO","CASEID":"03974","CASESUBTYPE":"12345","COMMENT":"updatedd","CONFIDENCESCORE":"40.12","CUSTOMERNO":"1234566","ISATTACHMENTFLAG":"NO","ISMULTIPLELAN":"YES","ISREGISTEREDCUSTOMER":"YES","ISSMT":"NO","LAN":"122321321","LOB":"001","MOODSTAMP":"not sure","OWNERFULLNAME":"Shubham Sinha","PAYTMINTERACTIONID":"","PRIORITY":"low","AUTORESPONSEFLAG":"YES"}';

	}

	@isTest
	static void evaluate_Test_Method() {
		ABSLI_ClosedIGMSComplaintIntegration complaint = new ABSLI_ClosedIGMSComplaintIntegration();
		Case caseRec = [
			SELECT
				Id,
				Status,
				OwnerId,
				CaseNumber,
            	Description,
				Client_Code_Text__c,
				Account.Client_Code__c,
				ABSLI_Case_Detail__c,
				ABSLI_Case_Detail__r.Status_Valid_For_STP__c,
				AccountId,
				ABSLI_Case_Detail__r.IGMS_type_of_policy__c,
            	ABSLI_Case_Detail__r.IGMS_Source_of_Complaint__c,
            	ABSLI_Case_Detail__r.IGMS_Complaint_Status__c,
            	ABSLI_Case_Detail__r.Receipt_Number__c,
				ABSLI_Case_Detail__r.Email_Id__c,
            	ABSLI_Case_Detail__r.Next_Integration_Name__c,
            	ABSLI_Case_Detail__r.Acknowledged_Date__c,
            	ABSLI_Case_Detail__r.Escalated_Date__c,
            	ABSLI_Case_Detail__r.Resolved_Date__c,
				Technical_Source__c,
            	Is_STP__c,
            	IGMS_Complaint_Type_Code__c,
				Business_Unit__c,
				CCC_External_Id__c
			FROM Case
			LIMIT 1
		];

		Test.startTest();
		ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRec.Id => caseRec };
		ASF_IntegrationsController.IntegrationWrapper result = complaint.evaluate(caseRec);
		System.assertEquals('Success', result.status, 'The evaluation did not return the expected success status.');
		Test.stopTest();
	}
	@isTest
	static void run_Test_Method() {
		ABSLI_ClosedIGMSComplaintIntegration complaint = new ABSLI_ClosedIGMSComplaintIntegration();
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
            	IRDAI_Token_Number__c,
				ABSLI_Case_Detail__c,
				ABSLI_Case_Detail__r.Status_Valid_For_STP__c,
				AccountId,
            	Stage__c,
				ABSLI_Case_Detail__r.IGMS_Complaint_Status__c,
            	ABSLI_Case_Detail__r.IGMS_Created_Case__c,
            	ABSLI_Case_Detail__r.IGMS_Source_of_Complaint__c,
            	ABSLI_Case_Detail__r.Is_Complainant_Informed__c,
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
		ASF_IntegrationsController.IntegrationWrapper res = complaint.run(integ, caseRec);
		Test.stopTest();
	}
	
	@isTest
	static void evaluate_Test_MethodBulk() {
		ABSLI_ClosedIGMSComplaintIntegration complaint = new ABSLI_ClosedIGMSComplaintIntegration();
		Case caseRec = [
			SELECT
				Id,
				Status,
				OwnerId,
				CaseNumber,
            	Description,
				Client_Code_Text__c,
				Account.Client_Code__c,
				ABSLI_Case_Detail__c,
				ABSLI_Case_Detail__r.Status_Valid_For_STP__c,
				AccountId,
				ABSLI_Case_Detail__r.IGMS_type_of_policy__c,
            	ABSLI_Case_Detail__r.IGMS_Source_of_Complaint__c,
            	ABSLI_Case_Detail__r.IGMS_Complaint_Status__c,
            	ABSLI_Case_Detail__r.Is_Complainant_Informed__c,
            	ABSLI_Case_Detail__r.Receipt_Number__c,
				ABSLI_Case_Detail__r.Email_Id__c,
            	ABSLI_Case_Detail__r.Next_Integration_Name__c,
            	ABSLI_Case_Detail__r.Acknowledged_Date__c,
            	ABSLI_Case_Detail__r.Escalated_Date__c,
            	ABSLI_Case_Detail__r.Resolved_Date__c,
				Technical_Source__c,
            	Is_STP__c,
            	IGMS_Complaint_Type_Code__c,
				Business_Unit__c,
				CCC_External_Id__c
			FROM Case
			LIMIT 1
		];

		Test.startTest();
		ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRec.Id => caseRec };
		Map<Id, ASF_IntegrationsController.IntegrationWrapper> result = complaint.evaluate(
			new List<Case>{ caseRec }
		);
		//System.assertEquals('Success', result.get(caseRec.Id).status);
		Test.stopTest();
	}
	@isTest
	static void run_Test_MethodBulk() {
		ABSLI_ClosedIGMSComplaintIntegration complaint = new ABSLI_ClosedIGMSComplaintIntegration();
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
				ABSLI_Case_Detail__r.IGMS_Complaint_Status__c,
            	ABSLI_Case_Detail__r.IGMS_Created_Case__c,
            	ABSLI_Case_Detail__r.IGMS_Source_of_Complaint__c,
            	ABSLI_Case_Detail__r.Is_Complainant_Informed__c,
				ABSLI_Case_Detail__r.Email_Id__c,
				Technical_Source__c,
            	Is_STP__c,
            	Stage__c,
				Business_Unit__c,
            	IRDAI_Token_Number__c,
				CCC_External_Id__c
			FROM Case
			LIMIT 1
		];

		Test.startTest();
		ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRec.Id => caseRec };
		Map<Id, ASF_IntegrationsController.IntegrationWrapper> res = complaint.run(
			new Map<Id, List<ASF_Integration__c>>{ caseRec.Id => new List<ASF_Integration__c>{ integ } },
			new List<Case>{ caseRec }
		);
		Test.stopTest();
	}
	
	@IsTest
	static void testProcessResponse() {
		ABSLI_ClosedIGMSComplaintIntegration complaint = new ABSLI_ClosedIGMSComplaintIntegration();
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

		ABSLI_ClosedIGMSComplaintIntegration.ClosedComplaintResponseWrapper responseObj = new ABSLI_ClosedIGMSComplaintIntegration.ClosedComplaintResponseWrapper();
		responseObj.ReturnCode = '1';
		responseObj.IRDA_TOKEN_NUMBER = '00';
		responseObj.ENTITY_COMPLAINT_REF_NUMBER = '8895335596';
		responseObj.ReturnMessage = 'SAV';

		caseIntegRec.Response__c = JSON.serialize(responseObj);
		caseIntegRec.Status__c = 'Success';
		update caseIntegRec;

		Test.startTest();
		ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRec.Id => caseRec };
		complaint.processResponse(caseIntegRec);
		System.assertEquals(caseIntegRec.Status__c, 'Success');
		Test.stopTest();
	}

}