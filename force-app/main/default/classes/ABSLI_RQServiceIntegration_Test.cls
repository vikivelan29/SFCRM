@IsTest
public class ABSLI_RQServiceIntegration_Test {
	@testSetup
	static void setupTestData() {
		ASF_Integration__c integ = new ASF_Integration__c();
		integ.External_Id__c = 'PNFT007';
		integ.Display_Name__c = 'RQ Service';
		integ.Query_Fields__c = 'Technical_Source__c,AssetId';
		integ.Processing_Class__c = 'ABSLI_RQServiceIntegration';
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
        ABSLI_RQServiceIntegration rqInt = new ABSLI_RQServiceIntegration();
       	Case caseRecord = [SELECT Id,Technical_Source__c,AssetId
                           FROM Case LIMIT 1];
        ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRecord.Id => caseRecord };
        Test.startTest();
        ASF_IntegrationsController.IntegrationWrapper successfulEvaluate = rqInt.evaluate(caseRecord);
        System.assertEquals('Success', successfulEvaluate.status);
        Test.stopTest();
    }
    
    @IsTest
    static void testRun(){
        ABSLI_RQServiceIntegration rqInt = new ABSLI_RQServiceIntegration();
       	Case caseRecord = [SELECT id,Business_Unit__c,Asset.Policy_No__c FROM Case LIMIT 1];
        ASF_Integration__c integ = [SELECT Id, Processing_Class__c, External_Id__c FROM ASF_Integration__c LIMIT 1];
        ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRecord.Id => caseRecord };
        Test.startTest();
        ASF_IntegrationsController.IntegrationWrapper successfulRun = rqInt.run(integ,caseRecord);
        System.assertEquals('Success', successfulRun.status);
        Test.stopTest();
    }
    
    @IsTest
    static void testProcessResponse(){
        ABSLI_RQServiceIntegration rqInt = new ABSLI_RQServiceIntegration();
        ASF_Case_Integration__c caseInteg = [SELECT Id, Status__c, Case__c FROM ASF_Case_Integration__c LIMIT 1];
        caseInteg.Status__c = 'Success';
        caseInteg.Response__c = '{"RqRes":{"Response":{"Details":{"NETAMOUNT":"00","MEDICALREQUIREMENTS":{"MEDICALDETAILS":["medical fine"]},"COIFORMS":{"FORM":["coi request form"]}}}}}';
        ASF_TriggerSkipperUtility.markTriggerRun('ASF_Case_Integration__c');
        update caseInteg;
        ASF_TriggerSkipperUtility.resetTriggerRun('ASF_Case_Integration__c');
        Test.startTest();
        rqInt.processResponse(caseInteg);
        Test.stopTest();
    }
}