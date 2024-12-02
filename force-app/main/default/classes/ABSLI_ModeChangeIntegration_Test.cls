@IsTest
public class ABSLI_ModeChangeIntegration_Test {
	@testSetup
	static void setupTestData() {
		ASF_Integration__c integ = new ASF_Integration__c();
		integ.External_Id__c = 'PPCT027';
		integ.Display_Name__c = 'Mode Change';
		integ.Query_Fields__c = 'ABSLI_Case_Detail__r.Status_Valid_For_STP__c,CaseNumber,Business_Unit__c,Asset.Policy_No__c,ABSLI_Case_Detail__r.Anniversary_Date__c,ABSLI_Case_Detail__r.New_Frequency__c';
		integ.Processing_Class__c = 'ABSLI_ModeChangeIntegration';
		integ.When_to_Appear__c = 'Stage Entry';
		integ.Type__c = 'Process';
		integ.Auto_Run_on_Load__c = true;
		insert integ;

        ASF_TestDataFactory.createCaseCategoryConfig();
        ASF_Case_Category_Config__c config = [SELECT Id,CCC_External_Id__c
                                             FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c ='CCC-CC-CCLTD-01' LIMIT 1];
        config.CCC_External_Id__c = 'PPCT027';
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
        detailRec.Anniversary_Date__c = Date.today();
        detailRec.New_Frequency__c = '3';
		insert detailRec;

        List<Case> caseRecList = ASF_TestDataFactory.createCaseRecords(1);
        caseRecList[0].AssetId = assetRec.Id;
        caseRecList[0].Technical_Source__c = 'LWC';
        caseRecList[0].ABSLI_Case_Detail__c = detailRec.Id;
        update caseRecList[0];

        ASF_TestDataFactory.createCaseIntegration(caseRecList[0].Id, 'PPCT027');
    }

    @IsTest
    static void testEvaluate(){
        ABSLI_ModeChangeIntegration modeInt = new ABSLI_ModeChangeIntegration();
       	Case caseRecord = [SELECT id,CaseNumber,ABSLI_Case_Detail__r.Status_Valid_For_STP__c,Asset.Policy_No__c,Technical_Source__c,
                           ABSLI_Case_Detail__r.Anniversary_Date__c,ABSLI_Case_Detail__r.New_Frequency__c
                           FROM Case LIMIT 1];
        caseRecord.Technical_Source__c = 'API';
        ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRecord.Id => caseRecord };
        Test.startTest();
        ASF_IntegrationsController.IntegrationWrapper successfulEvaluate = modeInt.evaluate(caseRecord);
        System.assertEquals('Success', successfulEvaluate.status);
        Test.stopTest();
    }

    @IsTest
    static void testRun(){
        ABSLI_ModeChangeIntegration modeInt = new ABSLI_ModeChangeIntegration();
       	Case caseRecord = [SELECT id,CaseNumber,Asset.Policy_No__c,ABSLI_Case_Detail__r.Anniversary_Date__c,
                           ABSLI_Case_Detail__r.New_Frequency__c,Business_Unit__c FROM Case LIMIT 1];
        ASF_Integration__c integ = [SELECT Id, Processing_Class__c, External_Id__c FROM ASF_Integration__c LIMIT 1];
        ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRecord.Id => caseRecord };
        Test.startTest();
        ASF_IntegrationsController.IntegrationWrapper successfulRun = modeInt.run(integ,caseRecord);
        System.assertEquals('Success', successfulRun.status);
        Test.stopTest();
    }

    @IsTest
    static void testProcessResponse(){
        ABSLI_ModeChangeIntegration modeInt = new ABSLI_ModeChangeIntegration();
        ASF_Case_Integration__c caseInteg = [SELECT Id, Status__c, Case__c FROM ASF_Case_Integration__c LIMIT 1];
        caseInteg.Status__c = 'Success';
        caseInteg.Response__c = '{"RESPONSE":"00"}';
        ASF_TriggerSkipperUtility.markTriggerRun('ASF_Case_Integration__c');
        update caseInteg;
        ASF_TriggerSkipperUtility.resetTriggerRun('ASF_Case_Integration__c');
        Test.startTest();
        modeInt.processResponse(caseInteg);
        Test.stopTest();
    }

    @IsTest
	static void testBatchExecute() {
        String strQuery =
			'SELECT Id, ABSLI_Case_Detail__r.Anniversary_Date__c FROM Case WHERE ' +
            'ABSLI_Case_Detail__r.Anniversary_Date__c = LAST_N_DAYS:10 AND IsClosed = false ' +
            'AND ABSLI_Case_Detail__r.Status_Valid_For_STP__c = true';
		Test.startTest();
		Database.executeBatch(new ABSLI_ModeChangeIntegrationBatch(strQuery), 1);
		Test.stopTest();
	}

    @IsTest
	static void testScheduldeExecute() {
		Test.startTest();
		ABSLI_ModeChangeIntegrationBatch obj = new ABSLI_ModeChangeIntegrationBatch();
		obj.schedule();
		System.schedule(
			ABSLI_Constants.MODECHANGE_SCHEDULDE_JOB + ' TestRun#1',
			'0 0 0 1/1 * ? *',
			new ABSLI_ModeChangeIntegrationBatch()
		);
		Test.stopTest();
	}
}
