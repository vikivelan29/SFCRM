@IsTest
public class ABSLI_ReinstatementIntegration_Test {
	@testSetup
	static void setupTestData() {
		ASF_Integration__c integ = new ASF_Integration__c();
		integ.External_Id__c = 'PNFT007';
		integ.Display_Name__c = 'Reinstatement';
		integ.Query_Fields__c = 'ABSLI_Case_Detail__r.Status_Valid_For_STP__c,CaseNumber,Business_Unit__c,'+
            'Technical_Source__c,AccountId,Client_Code_Text__c,ABSLI_Case_Detail__r.Address_Line_1__c,'+
            'ABSLI_Case_Detail__r.Country__c,ABSLI_Case_Detail__r.City__c,ABSLI_Case_Detail__r.State__c,'+
            'ABSLI_Case_Detail__r.Pincode__c';
		integ.Processing_Class__c = 'ABSLI_ReinstatementIntegration';
		integ.When_to_Appear__c = 'Stage Entry';
		integ.Type__c = 'Process';
		integ.Auto_Run_on_Load__c = true;
		insert integ;

        ASF_TestDataFactory.createCaseCategoryConfig();
        ASF_Case_Category_Config__c config = [SELECT Id,CCC_External_Id__c
                                             FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c ='CCC-CC-CCLTD-01' LIMIT 1];
        config.CCC_External_Id__c = 'PNFT007';
        update config;
        
		Account accRec = ASF_TestDataFactory.insertPersonAccount('Aditya', 'Mehrotra', '100');
		accRec.PersonBirthdate = Date.today();
        accRec.PAN__c = 'ABC1232B';
        accRec.Client_Code__c = 'ABCXXX001';
		update accRec;

		Asset assetRec = ASF_TestDataFactory.createAsset(accRec.Id, 'Loans');
		assetRec.Policy_No__c = '1234';
		update assetRec;

		ABSLI_Case_Detail__c detailRec = new ABSLI_Case_Detail__c();
        detailRec.Status_Valid_For_STP__c = true;
		detailRec.Address_Line_1__c = '6/47, ABC Colony';
        detailRec.Country__c = 'IND';
        detailRec.City__c = 'Mumbai';
        detailRec.State__c = 'MH';
        detailRec.Pincode__c = '400010';
        detailRec.COI_Signed_Date__c = Date.today();
        detailRec.COI_Covid_Quest__c = 'test';
        detailRec.Reinstatement_Amount__c = 500;
        detailRec.PX_Response__c = 'clean';
		insert detailRec;
        
        List<Case> caseRecList = ASF_TestDataFactory.createCaseRecords(1);
        caseRecList[0].AssetId = assetRec.Id;
        caseRecList[0].Business_Unit__c = 'ABSLI';
        caseRecList[0].Technical_Source__c = 'LWC';
        caseRecList[0].AccountId = accRec.Id;
        caseRecList[0].ABSLI_Case_Detail__c = detailRec.Id;
        caseRecList[0].Client_Code_Text__c = 'ABCXXX001';
        caseRecList[0].CCC_External_Id__c = 'PNFT007';
        update caseRecList[0];
        
        ASF_TestDataFactory.createCaseIntegration(caseRecList[0].Id, 'PNFT007');
        
        ASF_Checklist__c chk1 = new ASF_Checklist__c(Case__c = caseRecList[0].Id, Status__c ='Completed', Label__c= 'New Ceck Label');
        insert chk1;
    }
    
    @IsTest
    static void testEvaluate(){
        ABSLI_ReinstatementIntegration reInt = new ABSLI_ReinstatementIntegration();
       	Case caseRecord = [SELECT id,Source__c,ABSLI_Case_Detail__r.PX_Response__c,Technical_Source__c,ABSLI_Case_Detail__r.Status_Valid_For_STP__c,CaseNumber,
                           AccountId, Client_Code_Text__c,ABSLI_Case_Detail__r.Address_Line_1__c,
            ABSLI_Case_Detail__r.Country__c,ABSLI_Case_Detail__r.City__c,ABSLI_Case_Detail__r.State__c,
            ABSLI_Case_Detail__r.Pincode__c,Business_Unit__c FROM Case LIMIT 1];
        ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRecord.Id => caseRecord };
        Test.startTest();
        ASF_IntegrationsController.IntegrationWrapper successfulEvaluate = reInt.evaluate(caseRecord);
        System.assertEquals('Success', successfulEvaluate.status);
        Test.stopTest();
    }
    
    @IsTest
    static void testRun(){
        ABSLI_ReinstatementIntegration reInt = new ABSLI_ReinstatementIntegration();
       	Case caseRecord = [SELECT id,Technical_Source__c,Asset.Policy_No__c,CaseNumber,AccountId,Account.Client_Code__c,Client_Code_Text__c,ABSLI_Case_Detail__r.Address_Line_1__c,
            ABSLI_Case_Detail__r.Country__c,ABSLI_Case_Detail__r.City__c,ABSLI_Case_Detail__r.State__c,
            ABSLI_Case_Detail__r.Pincode__c,Business_Unit__c, ABSLI_Case_Detail__r.Address_Line_2__c,
            ABSLI_Case_Detail__r.Address_Line_3__c,ABSLI_Case_Detail__r.COI_Covid_Quest__c,
            ABSLI_Case_Detail__r.Reinstatement_Amount__c,ABSLI_Case_Detail__r.Medicals__c,ABSLI_Case_Detail__r.PX_Response__c,
            ABSLI_Case_Detail__r.COI_Signed_Date__c FROM Case LIMIT 1];
        ASF_Integration__c integ = [SELECT Id, Processing_Class__c, External_Id__c, Do_Not_Retry_Integration__c FROM ASF_Integration__c LIMIT 1];
        ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRecord.Id => caseRecord };
        Test.startTest();
        ASF_IntegrationsController.IntegrationWrapper successfulRun = reInt.run(integ,caseRecord);
        
        System.assertEquals('Success', successfulRun.status);
        Test.stopTest();
    }
    
    @IsTest
    static void testProcessResponse(){
        ABSLI_ReinstatementIntegration reInt = new ABSLI_ReinstatementIntegration();
        ASF_Case_Integration__c caseInteg = [SELECT Id, Status__c, Case__c FROM ASF_Case_Integration__c LIMIT 1];
        caseInteg.Status__c = 'Success';
        caseInteg.Response__c = '{"ProcessCode":"00"}';
        ASF_TriggerSkipperUtility.markTriggerRun('ASF_Case_Integration__c');
        update caseInteg;
        ASF_TriggerSkipperUtility.resetTriggerRun('ASF_Case_Integration__c');
        Test.startTest();
        reInt.processResponse(caseInteg);
        Test.stopTest();
    }
}