@IsTest
public class ABSLI_PanUpdateIntegration_Test {
	@testSetup
	static void setupTestData() {
		ASF_Integration__c integ = new ASF_Integration__c();
		integ.External_Id__c = 'PNFT007';
		integ.Display_Name__c = 'PAN Update';
		integ.Query_Fields__c = 'ABSLI_Case_Detail__r.Status_Valid_For_STP__c,Technical_Source__c,CaseNumber,Account.Client_Code__c,ABSLI_Case_Detail__r.Mobile_Number__c,Business_Unit__c,Asset.Policy_No__c,Account.PAN__c,ABSLI_Case_Detail__r.PAN_Number__c';
		integ.Processing_Class__c = 'ABSLI_PanUpdateIntegration';
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
		update accRec;

		Asset assetRec = ASF_TestDataFactory.createAsset(accRec.Id, 'Loans');
		assetRec.Policy_No__c = '1234';
		update assetRec;

		ABSLI_Case_Detail__c detailRec = new ABSLI_Case_Detail__c();
		detailRec.From_Date__c = Date.today();
        detailRec.Status_Valid_For_STP__c = true;
		detailRec.To_Date__c = Date.today().addDays(2);
		insert detailRec;
        
        List<Case> caseRecList = ASF_TestDataFactory.createCaseRecords(1);
        caseRecList[0].AssetId = assetRec.Id;
        caseRecList[0].Technical_Source__c = 'LWC';
        caseRecList[0].ABSLI_Case_Detail__c = detailRec.Id;
        update caseRecList[0];
        
        ASF_TestDataFactory.createCaseIntegration(caseRecList[0].Id, 'PNFT007');
	}
    
    @IsTest
    static void testEvaluate(){
        ABSLI_PanUpdateIntegration panInt = new ABSLI_PanUpdateIntegration();
       	Case caseRecord = [SELECT id,CaseNumber,CCC_External_Id__c,Source__c,ABSLI_Case_Detail__r.Status_Valid_For_STP__c,Technical_Source__c FROM Case LIMIT 1];
        ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRecord.Id => caseRecord };
        Test.startTest();
        ASF_IntegrationsController.IntegrationWrapper successfulEvaluate = panInt.evaluate(caseRecord);
        System.assertEquals('Success', successfulEvaluate.status);
        Test.stopTest();
    }
    
    @IsTest
    static void testRun(){
        ABSLI_PanUpdateIntegration panInt = new ABSLI_PanUpdateIntegration();
       	Case caseRecord = [SELECT id,CaseNumber,ABSLI_Case_Detail__r.Status_Valid_For_STP__c,Asset.Policy_No__c,
                           Account.PAN__c,Business_Unit__c,ABSLI_Case_Detail__r.PAN_Number__c FROM Case LIMIT 1];
        ASF_Integration__c integ = [SELECT Id, Processing_Class__c, External_Id__c,Do_Not_Retry_Integration__c FROM ASF_Integration__c LIMIT 1];
        ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRecord.Id => caseRecord };
        Test.startTest();
        ASF_IntegrationsController.IntegrationWrapper successfulRun = panInt.run(integ,caseRecord);
        System.assertEquals('Success', successfulRun.status);
        Test.stopTest();
    }
    
    @IsTest
    static void testProcessResponse(){
        ABSLI_PanUpdateIntegration panInt = new ABSLI_PanUpdateIntegration();
        ASF_Case_Integration__c caseInteg = [SELECT Id, Status__c, Case__c FROM ASF_Case_Integration__c LIMIT 1];
        caseInteg.Status__c = 'Success';
        caseInteg.Response__c = '{"ProcessCode":"00"}';
        ASF_TriggerSkipperUtility.markTriggerRun('ASF_Case_Integration__c');
        update caseInteg;
        ASF_TriggerSkipperUtility.resetTriggerRun('ASF_Case_Integration__c');
        Test.startTest();
        panInt.processResponse(caseInteg);
        Test.stopTest();
    }
}