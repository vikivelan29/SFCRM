@IsTest
public class ABSLI_DeletePolicyNominee_Test {
	@testSetup
    static void setupTestData(){
        ASF_Integration__c integ = new ASF_Integration__c();
		integ.External_Id__c = 'PNFT007';
		integ.Display_Name__c = 'Nominee Delete';
		integ.Query_Fields__c = 'ABSLI_Case_Detail__r.Status_Valid_For_STP__c,CaseNumber,Business_Unit__c,Technical_Source__c,'+
            'AssetId,Asset.Policy_No__c,LAN__c';
		integ.Processing_Class__c = 'ABSLI_DeletePolicyNomineeIntegration';
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
        
        ABSLI_Case_Detail__c detailRec1 = new ABSLI_Case_Detail__c();
		detailRec1.From_Date__c = Date.today();
        detailRec1.Status_Valid_For_STP__c = true;
		//detailRec.Next_Integration_Name__c = 
		insert detailRec1;
        
        ABSLI_Case_Detail__c detailRec2 = new ABSLI_Case_Detail__c();
		detailRec2.From_Date__c = Date.today();
        detailRec2.Status_Valid_For_STP__c = true;
		//detailRec.Next_Integration_Name__c = 
		insert detailRec2;
        
        List<Case> caseRecList = ASF_TestDataFactory.createCaseRecords(2);
        caseRecList[0].AssetId = assetRec.Id;
        caseRecList[0].Technical_Source__c = 'LWC';
        caseRecList[0].ABSLI_Case_Detail__c = detailRec1.Id;
        caseRecList[0].Source__c = 'Email';
        
        caseRecList[1].AssetId = assetRec.Id;
        caseRecList[1].Technical_Source__c = 'LWC';
        caseRecList[1].ABSLI_Case_Detail__c = detailRec2.Id;
        caseRecList[1].Source__c = 'Branch';
        update caseRecList;
        
        ABSLI_Nominee__c nominee1 = new ABSLI_Nominee__c();
        nominee1.Case__c=caseRecList[1].Id;
        nominee1.Sequence_No__c = '01';
        nominee1.Action_Item__c = 'Delete';
        insert nominee1;
        
        ASF_TestDataFactory.createCaseIntegration(caseRecList[0].Id, 'PNFT007');
        ASF_TestDataFactory.createCaseIntegration(caseRecList[1].Id, 'PNFT007');
    }
    
    @IsTest
    static void testEvaluate(){
        ABSLI_DeletePolicyNomineeIntegration deleteNomInt = new ABSLI_DeletePolicyNomineeIntegration();
       	Case caseRecord = [SELECT id,CaseNumber,Source__c,ABSLI_Case_Detail__r.Status_Valid_For_STP__c,Asset.Policy_No__c,Technical_Source__c
                           FROM Case WHERE Source__c='Email' LIMIT 1];
        ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRecord.Id => caseRecord };
        Test.startTest();
        ASF_IntegrationsController.IntegrationWrapper errorEvaluate = deleteNomInt.evaluate(caseRecord);
        System.assertEquals('Error', errorEvaluate.status);
        Test.stopTest();
    }
    
    @IsTest
    static void testRun(){
        ABSLI_DeletePolicyNomineeIntegration deleteNomInt = new ABSLI_DeletePolicyNomineeIntegration();
        Case caseRecord1 = [SELECT id,CaseNumber,Asset.Policy_No__c,Business_Unit__c,ABSLI_Case_Detail__c,Stage__c,CCC_External_Id__c,
                            Technical_Source__c FROM Case WHERE Source__c = 'Branch' LIMIT 1];
       	Case caseRecord2 = [SELECT id,CaseNumber,Asset.Policy_No__c,Business_Unit__c,ABSLI_Case_Detail__c,Stage__c,CCC_External_Id__c
                           FROM Case WHERE Source__c = 'Email' LIMIT 1];
        ASF_Integration__c integ = [SELECT Id, Processing_Class__c, External_Id__c, Do_Not_Retry_Integration__c FROM ASF_Integration__c LIMIT 1];
		
        Test.startTest();
        ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRecord1.Id => caseRecord1 };
        ASF_IntegrationsController.IntegrationWrapper runMethodIfBlock = deleteNomInt.run(integ,caseRecord1);
        
        ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{ caseRecord2.Id => caseRecord2 };
        ASF_IntegrationsController.IntegrationWrapper runMethodElseBlock = deleteNomInt.run(integ,caseRecord2);
        System.assertEquals('Success', runMethodIfBlock.status);
        Test.stopTest();
    }
    
    @IsTest
    static void testProcessResponse(){
        ABSLI_DeletePolicyNomineeIntegration deleteNomInt = new ABSLI_DeletePolicyNomineeIntegration();
        ASF_Case_Integration__c caseInteg = [SELECT Id, Status__c, Case__c,Business_External_Id__c FROM ASF_Case_Integration__c
                                             WHERE Case__r.Source__c='Branch' LIMIT 1];
        ABSLI_Nominee__c nominee = [SELECT Id FROM ABSLI_Nominee__c WHERE Case__r.Source__c = 'Branch' LIMIT 1];
        caseInteg.Business_External_Id__c = nominee.Id;
        caseInteg.Status__c = 'Success';
        caseInteg.Response__c = '{"LSIR_RETURN_CD":"00"}';
        ASF_TriggerSkipperUtility.markTriggerRun('ASF_Case_Integration__c');
        update caseInteg;
        ASF_TriggerSkipperUtility.resetTriggerRun('ASF_Case_Integration__c');
        Test.startTest();
        deleteNomInt.processResponse(caseInteg);
        Test.stopTest();
    }
}