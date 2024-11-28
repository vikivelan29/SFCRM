@IsTest
public class ABSLI_WithdrawalUpdateIntegration_Test {
	@testSetup
	static void setupTestData() {
		ASF_Integration__c integ = new ASF_Integration__c();
		integ.External_Id__c = 'PPAY008';
		integ.Display_Name__c = 'WithdrawalPolicyIntegration';
		integ.Query_Fields__c = 'ABSLI_Case_Detail__r.TDS_Indicator__c,Account.PAN__c,CaseNumber,Asset.Policy_No__c,ABSLI_Case_Detail__r.IFSC_Code__c,ABSLI_Case_Detail__r.MICR_Code__c,ABSLI_Case_Detail__r.Account_Number__c,ABSLI_Case_Detail__r.Bank_Name__c,ABSLI_Case_Detail__r.Branch_Name__c,Asset.Zone__c,ABSLI_Case_Detail__r.Account_Type__c,ABSLI_Case_Detail__r.Fund_Tranfer_Amount__c,Business_Unit__c';
		integ.Processing_Class__c = 'ABSLI_WithdrawalPolicyIntegration';
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
		caseRec.CCC_External_Id__c = 'PPAY008';
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
		caseRec1.CCC_External_Id__c = 'PPAY008';
		caseRec1.Client_Code_Text__c = '8895335596';
		caseRec1.Technical_Source__c = 'API';
        caseRec1.Is_STP__c = true;
        caseRec1.IGMS_Complaint_Type_Code__c = '1';
		update caseRec1;

		ASF_TestDataFactory.createCaseIntegration(caseRec.Id, 'PNFT008');

		ASF_Case_Category_Config__c caseCatConfig = new ASF_Case_Category_Config__c();
		caseCatConfig.CCC_External_Id__c = 'PPAY008';
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
    
    @IsTest
    static void testEvaluate(){
        ABSLI_WithdrawalPolicyIntegration surInt = new ABSLI_WithdrawalPolicyIntegration();
       	Case caseRecord = [SELECT id,Source__c,Technical_Source__c,ABSLI_Case_Detail__r.Status_Valid_For_STP__c,CaseNumber,
                           Asset.Policy_No__c,Business_Unit__c FROM Case LIMIT 1];
        ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRecord.Id => caseRecord };
        Test.startTest();
        ASF_IntegrationsController.IntegrationWrapper successfulEvaluate = surInt.evaluate(caseRecord);
        System.assertEquals('Success', successfulEvaluate.status);
        Test.stopTest();
    }
    
    @IsTest
    static void testRun(){
        ABSLI_WithdrawalPolicyIntegration surInt = new ABSLI_WithdrawalPolicyIntegration();
       	Case caseRecord = [SELECT id,ABSLI_Case_Detail__r.Withdrawal_Amount_Available__c,ABSLI_Case_Detail__r.TDS_Indicator__c,Account.PAN__c,CaseNumber,Asset.Policy_No__c,ABSLI_Case_Detail__r.IFSC_Code__c,ABSLI_Case_Detail__r.MICR_Code__c,ABSLI_Case_Detail__r.Account_Number__c,ABSLI_Case_Detail__r.Bank_Name__c,ABSLI_Case_Detail__r.Branch_Name__c,Asset.Zone__c,ABSLI_Case_Detail__r.Account_Type__c,ABSLI_Case_Detail__r.Fund_Tranfer_Amount__c,Business_Unit__c FROM Case LIMIT 1];
        ASF_Integration__c integ = [SELECT Id, Processing_Class__c, External_Id__c,Do_Not_Retry_Integration__c FROM ASF_Integration__c LIMIT 1];
        ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRecord.Id => caseRecord };
        Test.startTest();
        ASF_IntegrationsController.IntegrationWrapper successfulRun = surInt.run(integ,caseRecord);
        System.assertEquals('Success', successfulRun.status);
        Test.stopTest();
    }
    
    @IsTest
    static void testProcessResponse(){
        ABSLI_WithdrawalPolicyIntegration surInt = new ABSLI_WithdrawalPolicyIntegration();
        ASF_Case_Integration__c caseInteg = [SELECT Id, Status__c, Case__c FROM ASF_Case_Integration__c LIMIT 1];
        caseInteg.Status__c = 'Success';
        caseInteg.Response__c = '{"getSurvivalCertificate_UpdateSC_Flag": [{"Output_Message": "EXECUTION WAS SUCCESSFULL WITH WARNING","Error_Code": "00"}]}';
        ASF_TriggerSkipperUtility.markTriggerRun('ASF_Case_Integration__c');
        update caseInteg;
        ASF_TriggerSkipperUtility.resetTriggerRun('ASF_Case_Integration__c');
        Test.startTest();
        surInt.processResponse(caseInteg);
        Test.stopTest();
    }
    
}