/**
 * @description Unit Test Class for ABSLI_RegisterIGMSComplaintIntegration
 *
 * @author Laxman R
 * @date 2024-05-07
 */
@IsTest
public class ABSLI_IGMSIntegrationHelper_Test {
	/**
	 * @description Test Data Setup for this Test Class
	 */
	@testSetup
	static void setupTestData() {
        List<ASF_Integration__c> integlist = new List<ASF_Integration__c>();
    
    ASF_Integration__c integ1 = new ASF_Integration__c();
    integ1.External_Id__c = 'PNFT007_1';
    integ1.Display_Name__c = 'Pending IGMS Complaint';
    integ1.Query_Fields__c = 'ABSLI_Case_Detail__r.Status_Valid_For_STP__c,CaseNumber,Account.Client_Code__c,ABSLI_Case_Detail__r.WhatsApp_Opt_Out_Indicator__c,Business_Unit__c,Technical_Source__c,Is_STP__c';
    integ1.Processing_Class__c = 'ABSLI_PendingIGMSComplaintIntegration';
    integ1.When_to_Appear__c = 'Stage Entry';
    integ1.Type__c = 'Process';
    integ1.Auto_Run_on_Load__c = true;
    integlist.add(integ1);
    
    ASF_Integration__c integ2 = new ASF_Integration__c();
    integ2.External_Id__c = 'PNFT007_2';
    integ2.Display_Name__c = 'Register IGMS Complaint';
    integ2.Query_Fields__c = 'ABSLI_Case_Detail__r.Status_Valid_For_STP__c,CaseNumber,Account.Client_Code__c,ABSLI_Case_Detail__r.WhatsApp_Opt_Out_Indicator__c,Business_Unit__c,Technical_Source__c,Is_STP__c';
    integ2.Processing_Class__c = 'ABSLI_RegisterIGMSComplaintIntegration';
    integ2.When_to_Appear__c = 'Stage Entry';
    integ2.Type__c = 'Process';
    integ2.Auto_Run_on_Load__c = true;
    integlist.add(integ2);
    
    ASF_Integration__c integ3 = new ASF_Integration__c();
    integ3.External_Id__c = 'PNFT007_3';
    integ3.Display_Name__c = 'Ack IGMS Complaint';
    integ3.Query_Fields__c = 'ABSLI_Case_Detail__r.Status_Valid_For_STP__c,CaseNumber,Account.Client_Code__c,ABSLI_Case_Detail__r.WhatsApp_Opt_Out_Indicator__c,Business_Unit__c,Technical_Source__c,Is_STP__c';
    integ3.Processing_Class__c = 'ABSLI_AckIGMSComplaintIntegration';
    integ3.When_to_Appear__c = 'Stage Entry';
    integ3.Type__c = 'Process';
    integ3.Auto_Run_on_Load__c = true;
    integlist.add(integ3);
    
    ASF_Integration__c integ4 = new ASF_Integration__c();
    integ4.External_Id__c = 'PNFT007_4';
    integ4.Display_Name__c = 'Escalated IGMS Complaint';
    integ4.Query_Fields__c = 'ABSLI_Case_Detail__r.Status_Valid_For_STP__c,CaseNumber,Account.Client_Code__c,ABSLI_Case_Detail__r.WhatsApp_Opt_Out_Indicator__c,Business_Unit__c,Technical_Source__c,Is_STP__c';
    integ4.Processing_Class__c = 'ABSLI_EscalatedIGMSComplaintIntegration';
    integ4.When_to_Appear__c = 'Stage Entry';
    integ4.Type__c = 'Process';
    integ4.Auto_Run_on_Load__c = true;
    integlist.add(integ4);
    
    ASF_Integration__c integ5 = new ASF_Integration__c();
    integ5.External_Id__c = 'PNFT007_5';
    integ5.Display_Name__c = 'Reopened IGMS Complaint';
    integ5.Query_Fields__c = 'ABSLI_Case_Detail__r.Status_Valid_For_STP__c,CaseNumber,Account.Client_Code__c,ABSLI_Case_Detail__r.WhatsApp_Opt_Out_Indicator__c,Business_Unit__c,Technical_Source__c,Is_STP__c';
    integ5.Processing_Class__c = 'ABSLI_ReopenedIGMSComplaintIntegration';
    integ5.When_to_Appear__c = 'Stage Entry';
    integ5.Type__c = 'Process';
    integ5.Auto_Run_on_Load__c = true;
    integlist.add(integ5);
    
    insert integlist;

    Account accRec = ASF_TestDataFactory.insertPersonAccount('test', 'test', '100');
    accRec.Client_Code__c = 'ABI123';
    accRec.PersonBirthdate = Date.newInstance(1990, 1, 1);
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
    caseRec.Description = 'Test';
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
    caseRec1.Description = 'Test';
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
        caseInt.Status__c = 'Failure';
        caseInt.Integration_Ext_Id__c = integlist[0].External_Id__c;
        caseInt.Case__c = caseRec.Id;
        insert caseInt;
        
        ASF_Case_Integration__c caseIntUpdate = new ASF_Case_Integration__c();  
        caseIntUpdate.Id = caseInt.Id;
        caseIntUpdate.Case__c = caseRec.Id;
        caseIntUpdate.Integration_Ext_Id__c = integlist[0].External_Id__c;
        caseIntUpdate.Status__c = 'Success';
        caseIntUpdate.Response__c = '{"AUTOCLOSURE_IN_RR":"NO","CASEID":"03974","CASESUBTYPE":"12345","COMMENT":"updatedd","CONFIDENCESCORE":"40.12","CUSTOMERNO":"1234566","ISATTACHMENTFLAG":"NO","ISMULTIPLELAN":"YES","ISREGISTEREDCUSTOMER":"YES","ISSMT":"NO","LAN":"122321321","LOB":"001","MOODSTAMP":"not sure","OWNERFULLNAME":"Shubham Sinha","PAYTMINTERACTIONID":"","PRIORITY":"low","AUTORESPONSEFLAG":"YES"}';

	}

	@isTest
	static void RegisterIGMSComplaint_Test_Method() {
		ABSLI_IGMSIntegrationHelper complaint = new ABSLI_IGMSIntegrationHelper();
		ASF_Integration__c integ = [
			SELECT Id, Processing_Class__c, External_Id__c, Do_Not_Retry_Integration__c
			FROM ASF_Integration__c 
            WHERE Processing_Class__c = 'ABSLI_RegisterIGMSComplaintIntegration'
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
            	Account.FirstName,
            	Account.LastName,
            	Account.PersonGenderIdentity,
            	Account.Street_Address_1__c,
            	Account.PersonBirthdate,
            	Account.PersonMobilePhone,
            	AssetId,
            	Asset.Name,
            	Asset.Policy_No__c,
				ABSLI_Case_Detail__r.IGMS_Complaint_Status__c,
            	ABSLI_Case_Detail__r.IGMS_Created_Case__c,
            	ABSLI_Case_Detail__r.IGMS_Source_of_Complaint__c,
				ABSLI_Case_Detail__r.Email_Id__c,
            	ABSLI_Case_Detail__r.IGMS_type_of_policy__c,
            	ABSLI_Case_Detail__r.Receipt_Number__c,
            	ABSLI_Case_Detail__r.Escalated_Remark__c,
				Technical_Source__c,
            	IGMS_Complaint_Type_Code__c,
            	Is_STP__c,
            	Stage__c,
				Business_Unit__c,
            	IRDAI_Token_Number__c,
				CCC_External_Id__c,
            	Description,
            	CreatedDate
			FROM Case
			LIMIT 1
		];

		Test.startTest();
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
		ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRec.Id => caseRec };
        ABSLI_IGMSIntegrationHelper.createRegisterComplaintRequest(
            new List<Case>{ caseRec },
			new Map<Id, List<ASF_Integration__c>>{ caseRec.Id => new List<ASF_Integration__c>{ integ } },
			resultMap
		);
        
		Test.stopTest();
	}
    @isTest
	static void AckIGMSComplaint_Test_Method() {
		ABSLI_IGMSIntegrationHelper complaint = new ABSLI_IGMSIntegrationHelper();
		ASF_Integration__c integ = [
			SELECT Id, Processing_Class__c, External_Id__c
			FROM ASF_Integration__c 
            WHERE Processing_Class__c = 'ABSLI_AckIGMSComplaintIntegration'
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
            	Account.FirstName,
            	Account.LastName,
            	Account.PersonGenderIdentity,
            	Account.Street_Address_1__c,
            	Account.PersonBirthdate,
            	Account.PersonMobilePhone,
            	AssetId,
            	Asset.Name,
            	Asset.Policy_No__c,
				ABSLI_Case_Detail__r.IGMS_Complaint_Status__c,
            	ABSLI_Case_Detail__r.IGMS_Created_Case__c,
            	ABSLI_Case_Detail__r.IGMS_Source_of_Complaint__c,
				ABSLI_Case_Detail__r.Email_Id__c,
            	ABSLI_Case_Detail__r.IGMS_type_of_policy__c,
            	ABSLI_Case_Detail__r.Receipt_Number__c,
            	ABSLI_Case_Detail__r.Escalated_Remark__c,
				Technical_Source__c,
            	IGMS_Complaint_Type_Code__c,
            	Is_STP__c,
            	Stage__c,
				Business_Unit__c,
            	IRDAI_Token_Number__c,
				CCC_External_Id__c,
            	Description,
            	CreatedDate
			FROM Case
			LIMIT 1
		];

		Test.startTest();
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
		ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRec.Id => caseRec };
        ABSLI_IGMSIntegrationHelper.createAckComplaintRequest(
            new List<Case>{ caseRec },
			new Map<Id, List<ASF_Integration__c>>{ caseRec.Id => new List<ASF_Integration__c>{ integ } },
			resultMap
		);
        
		Test.stopTest();
	}
    @isTest
	static void PendingIGMSComplaint_Test_Method() {
		ABSLI_IGMSIntegrationHelper complaint = new ABSLI_IGMSIntegrationHelper();
		ASF_Integration__c integ = [
			SELECT Id, Processing_Class__c, External_Id__c
			FROM ASF_Integration__c 
            WHERE Processing_Class__c = 'ABSLI_PendingIGMSComplaintIntegration'
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
            	Account.FirstName,
            	Account.LastName,
            	Account.PersonGenderIdentity,
            	Account.Street_Address_1__c,
            	Account.PersonBirthdate,
            	Account.PersonMobilePhone,
            	AssetId,
            	Asset.Name,
            	Asset.Policy_No__c,
				ABSLI_Case_Detail__r.IGMS_Complaint_Status__c,
            	ABSLI_Case_Detail__r.IGMS_Created_Case__c,
            	ABSLI_Case_Detail__r.IGMS_Source_of_Complaint__c,
				ABSLI_Case_Detail__r.Email_Id__c,
            	ABSLI_Case_Detail__r.IGMS_type_of_policy__c,
            	ABSLI_Case_Detail__r.Receipt_Number__c,
            	ABSLI_Case_Detail__r.Escalated_Remark__c,
				Technical_Source__c,
            	IGMS_Complaint_Type_Code__c,
            	Is_STP__c,
            	Stage__c,
				Business_Unit__c,
            	IRDAI_Token_Number__c,
				CCC_External_Id__c,
            	Description,
            	CreatedDate
			FROM Case
			LIMIT 1
		];

		Test.startTest();
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
		ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRec.Id => caseRec };
        ABSLI_IGMSIntegrationHelper.createPendingComplaintRequest(
            new List<Case>{ caseRec },
			new Map<Id, List<ASF_Integration__c>>{ caseRec.Id => new List<ASF_Integration__c>{ integ } },
			resultMap
		);
        
		Test.stopTest();
	}
    @isTest
	static void EscalatedIGMSComplaint_Test_Method() {
		ABSLI_IGMSIntegrationHelper complaint = new ABSLI_IGMSIntegrationHelper();
		ASF_Integration__c integ = [
			SELECT Id, Processing_Class__c, External_Id__c
			FROM ASF_Integration__c 
            WHERE Processing_Class__c = 'ABSLI_EscalatedIGMSComplaintIntegration'
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
            	Account.FirstName,
            	Account.LastName,
            	Account.PersonGenderIdentity,
            	Account.Street_Address_1__c,
            	Account.PersonBirthdate,
            	Account.PersonMobilePhone,
            	AssetId,
            	Asset.Name,
            	Asset.Policy_No__c,
				ABSLI_Case_Detail__r.IGMS_Complaint_Status__c,
            	ABSLI_Case_Detail__r.IGMS_Created_Case__c,
            	ABSLI_Case_Detail__r.IGMS_Source_of_Complaint__c,
				ABSLI_Case_Detail__r.Email_Id__c,
            	ABSLI_Case_Detail__r.IGMS_type_of_policy__c,
            	ABSLI_Case_Detail__r.Receipt_Number__c,
            	ABSLI_Case_Detail__r.Escalated_Remark__c,
				Technical_Source__c,
            	IGMS_Complaint_Type_Code__c,
            	Is_STP__c,
            	Stage__c,
				Business_Unit__c,
            	IRDAI_Token_Number__c,
				CCC_External_Id__c,
            	Description,
            	CreatedDate
			FROM Case
			LIMIT 1
		];

		Test.startTest();
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
		ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRec.Id => caseRec };
        ABSLI_IGMSIntegrationHelper.createEscalatedComplaintRequest(
            new List<Case>{ caseRec },
			new Map<Id, List<ASF_Integration__c>>{ caseRec.Id => new List<ASF_Integration__c>{ integ } },
			resultMap
		);
        
		Test.stopTest();
	}
    @isTest
	static void ReopenedIGMSComplaint_Test_Method() {
		ABSLI_IGMSIntegrationHelper complaint = new ABSLI_IGMSIntegrationHelper();
		ASF_Integration__c integ = [
			SELECT Id, Processing_Class__c, External_Id__c
			FROM ASF_Integration__c 
            WHERE Processing_Class__c = 'ABSLI_ReopenedIGMSComplaintIntegration'
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
            	Account.FirstName,
            	Account.LastName,
            	Account.PersonGenderIdentity,
            	Account.Street_Address_1__c,
            	Account.PersonBirthdate,
            	Account.PersonMobilePhone,
            	AssetId,
            	Asset.Name,
            	Asset.Policy_No__c,
				ABSLI_Case_Detail__r.IGMS_Complaint_Status__c,
            	ABSLI_Case_Detail__r.IGMS_Created_Case__c,
            	ABSLI_Case_Detail__r.IGMS_Source_of_Complaint__c,
				ABSLI_Case_Detail__r.Email_Id__c,
            	ABSLI_Case_Detail__r.IGMS_type_of_policy__c,
            	ABSLI_Case_Detail__r.Receipt_Number__c,
            	ABSLI_Case_Detail__r.Escalated_Remark__c,
				Technical_Source__c,
            	IGMS_Complaint_Type_Code__c,
            	Is_STP__c,
            	Stage__c,
				Business_Unit__c,
            	IRDAI_Token_Number__c,
				CCC_External_Id__c,
            	Description,
            	CreatedDate
			FROM Case
			LIMIT 1
		];

		Test.startTest();
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
		ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRec.Id => caseRec };
        ABSLI_IGMSIntegrationHelper.createReopenedComplaintRequest(
            new List<Case>{ caseRec },
			new Map<Id, List<ASF_Integration__c>>{ caseRec.Id => new List<ASF_Integration__c>{ integ } },
			resultMap
		);        
		Test.stopTest();
	}
	

}