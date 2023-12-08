@isTest
public class ASF_CaseMovementHelper_Test {
    
    @testSetup
    static void setUpData(){
        ASF_TestDataFactory.createCaseRecords(1);
        ASF_TestDataFactory.createCaseCategoryConfig();
        ASF_TestDataFactory.createC3WithPrePopulateIntegrations();
    }
    
    @isTest
    private static void moveToNextStageTest() {
        
        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case LIMIT 1]; 
        ASF_TestDataFactory.createCaseIntegration(caseRecord.Id,'ASF_INT_02');
        ASF_Case_Integration__c CaseIntRec = [select Id, Status__c, Is_Validation_Success__c from ASF_Case_Integration__c 
                                              where Integration_Ext_Id__c='ASF_INT_02' LIMIT 1];
        CaseIntRec.Is_Validation_Success__c = true;
        update CaseIntRec;
        
        Test.startTest();
        ASF_CaseMovementHelper.StageWrapper StageMovementResult = ASF_CaseMovementHelper.moveToNextStage(caseRecord.Id);
        Test.stopTest();

        Assert.areEqual('Success', StageMovementResult.status);  
        Assert.areNotEqual(caseRecord.Stage__c, StageMovementResult.nextStageConfig.StageName__c, 'Case moved to Next Stage');  
    }
    
    @isTest
    private static void moveToNextStageTestFail() {
        
        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case LIMIT 1]; 
        ASF_TestDataFactory.createCaseIntegration(caseRecord.Id,'ASF_INT_02');
        
        Test.startTest();
        ASF_CaseMovementHelper.StageWrapper StageMovementResult = ASF_CaseMovementHelper.moveToNextStage(caseRecord.Id);
        ASF_Checklist__c checklistRec = new ASF_Checklist__c(Mandatory__c=true, Status__c='New', Case__c= caseRecord.Id, Stage_Name__c='Pending with Initiator');
        insert checklistRec;
        ASF_CaseMovementHelper.StageWrapper FrwdMovementResult = ASF_CaseMovementHelper.moveToForwardStage(caseRecord.Id,'In Progress with Recovery');
        Test.stopTest();
	    System.assertNotEquals(null, StageMovementResult, 'StageMovementResult should not be null');
    }
    
    @isTest
    private static void findNextStageAfterBackward() {
        
        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c,Previous_Stage__c, pending_clarification__c from case LIMIT 1]; 
        ASF_TestDataFactory.createCaseIntegration(caseRecord.Id,'ASF_INT_02');
        ASF_Case_Integration__c CaseIntRec = [select Id, Status__c, Is_Validation_Success__c from ASF_Case_Integration__c 
                                              where Integration_Ext_Id__c='ASF_INT_02' LIMIT 1];
        CaseIntRec.Is_Validation_Success__c = true;
        update CaseIntRec;
        
        List<ASF_Case_Stage_Config__c> csc = [Select id, Gateway_Stage__c,StageName__c,Order__c From ASF_Case_Stage_Config__c];
        csc[0].Gateway_Stage__c = true;
        csc[0].StageName__c = 'Pending with Initiator';
        csc[0].Order__c = 0;
        update csc;
		system.debug('cscId '+csc[0].Id);        
        Test.startTest();
        ASF_CaseMovementHelper.StageConfigWrapper findNextStageAfterBackwardVar = ASF_CaseMovementHelper.findNextStageAfterBackward(caseRecord);
        Test.stopTest();  
    }
    
    @isTest
    private static void moveToOptionalStageTest() {
        
        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case LIMIT 1];           
        ASF_TestDataFactory.createCaseIntegration(caseRecord.Id,'ASF_INT_02');
        ASF_Case_Integration__c CaseIntRec = [select Id, Status__c, Is_Validation_Success__c from ASF_Case_Integration__c 
                                              where Integration_Ext_Id__c='ASF_INT_02' LIMIT 1];
        CaseIntRec.Is_Validation_Success__c = true;
        update CaseIntRec;
        
        ASF_Case_Stage_Config__c configRec = [select Id, Optional_Stage__c, StageName__c from ASF_Case_Stage_Config__c where StageName__c= 'In Progress with Recovery' LIMIT 1];
        configRec.Optional_Stage__c = true;
        update configRec;
        
        Test.startTest();
        ASF_CaseMovementHelper.StageWrapper StageMovementResult = ASF_CaseMovementHelper.moveToNextStage(caseRecord.Id);
        Test.stopTest();
        Assert.areEqual('Success', StageMovementResult.status);   
        Assert.areNotEqual(caseRecord.Stage__c, StageMovementResult.nextStageConfig.StageName__c, 'Case moved to Next Stage');
    }
    
    @isTest
    private static void moveToNextStageTestNegative() {
        
        Test.startTest();
        ASF_CaseMovementHelper.StageWrapper StageMovementResult = ASF_CaseMovementHelper.moveToNextStage('5005g00000099h1');
        ASF_CaseMovementHelper.StageWrapper FrwdMovementResult = ASF_CaseMovementHelper.moveToForwardStage('5005g00000099h1','In Progress with Recovery');
        ASF_CaseMovementHelper.StageWrapper BackMovementResult = ASF_CaseMovementHelper.moveToBackwardStage('5005g00000099h1','Closed');
        
        Test.stopTest();
        Assert.areEqual('Error', StageMovementResult.status);  
    }

    @isTest
    private static void moveToNextStageApexClass() {
        
        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case LIMIT 1];           
        ASF_TestDataFactory.createCaseIntegration(caseRecord.Id,'ASF_INT_02');
        ASF_Case_Integration__c CaseIntRec = [select Id, Status__c, Is_Validation_Success__c from ASF_Case_Integration__c 
                                              where Integration_Ext_Id__c='ASF_INT_02' LIMIT 1];
        CaseIntRec.Is_Validation_Success__c = true;
        update CaseIntRec;

        List<sObject> ls = Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
        
        Test.startTest();
        
        ASF_CaseMovementHelper.StageWrapper StageMovementResult = ASF_CaseMovementHelper.moveToNextStage(caseRecord.Id);
        caseRecord.MoveToNext__c = true;
        update caseRecord;

        caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case LIMIT 1];           

        Test.stopTest();
        Assert.areEqual(caseRecord.Stage__c, StageMovementResult.nextStageConfig.StageName__c); 
    }

    @isTest
    private static void moveToNextStageApexClassNegative() {
        
        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case LIMIT 1];           
        ASF_TestDataFactory.createCaseIntegration(caseRecord.Id,'ASF_INT_02');
        ASF_Case_Integration__c CaseIntRec = [select Id, Status__c, Is_Validation_Success__c from ASF_Case_Integration__c 
                                              where Integration_Ext_Id__c='ASF_INT_02' LIMIT 1];
        CaseIntRec.Is_Validation_Success__c = true;
        update CaseIntRec;
        
        List<sObject> ls = Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
        
        Test.startTest();
        
        caseRecord.MoveToNext__c = true;
        update caseRecord;

        caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case LIMIT 1];           

        system.debug(caseRecord);

        ASF_CaseMovementHelper.StageWrapper nextStageMovementResult = ASF_CaseMovementHelper.moveToNextStage(caseRecord.Id);
        system.debug(nextStageMovementResult);
        Test.stopTest();
        Assert.areEqual('Success', nextStageMovementResult.status);   
    }
    
    @isTest
    private static void moveToNextWithPendingClarfTest() {
        
        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case LIMIT 1]; 
        caseRecord.Pending_Clarification__c = TRUE;
        caseRecord.Previous_Stage__c = 'In Progress with Recovery'; //Previous Stage
        update caseRecord;
        
        ASF_TestDataFactory.createCaseIntegration(caseRecord.Id,'ASF_INT_01');
        ASF_Case_Integration__c CaseIntRec = [select Id, Status__c, Is_Validation_Success__c from ASF_Case_Integration__c 
                                              where Integration_Ext_Id__c='ASF_INT_01' LIMIT 1];
        CaseIntRec.Is_Validation_Success__c = true;
        update CaseIntRec;
        
        Test.startTest();
        ASF_CaseMovementHelper.StageWrapper stageMovementResult = ASF_CaseMovementHelper.moveToNextStage(caseRecord.Id);
        Test.stopTest();
        
        Assert.areEqual('Success', StageMovementResult.status); 
        Assert.areNotEqual(caseRecord.Stage__c, StageMovementResult.nextStageConfig.StageName__c, 'Case moved to Next Stage');
    } 
    @isTest
    private static void moveToNextGatewayTest() {
        
        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, Previous_Stage__c, pending_clarification__c from case LIMIT 1]; 
        caseRecord.Pending_Clarification__c = TRUE;
        update caseRecord;
        
        ASF_TestDataFactory.createCaseIntegration(caseRecord.Id,'ASF_INT_01');
        ASF_Case_Integration__c CaseIntRec = [select Id, Status__c, Is_Validation_Success__c from ASF_Case_Integration__c 
                                              where Integration_Ext_Id__c='ASF_INT_01' LIMIT 1];
        CaseIntRec.Is_Validation_Success__c = true;
        update CaseIntRec;
        
        List<ASF_Case_Stage_Config__c> configList = [select Id, Gateway_Stage__c, StageName__c, Case_Category_Config__r.CCC_External_Id__c from ASF_Case_Stage_Config__c 
                                              where Case_Category_Config__r.CCC_External_Id__c=: caseRecord.CCC_External_Id__c];
        for(ASF_Case_Stage_Config__c conStage : configList){
            conStage.Gateway_Stage__c = true;
        }
        
        update configList;
        system.debug('test class stage record--'+configList.size()+configList[0].Gateway_Stage__c);
        
        Test.startTest();
        ASF_CaseMovementHelper.StageWrapper gatewayStageResult = ASF_CaseMovementHelper.moveToNextStage(caseRecord.Id);
        Test.stopTest();
        
    	System.assertNotEquals(null, gatewayStageResult, 'StageWrapper should not be null');
    } 
    @isTest
    private static void moveToForwardStageTest() {
        
        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case LIMIT 1];           
        ASF_TestDataFactory.createCaseIntegration(caseRecord.Id,'ASF_INT_02');
        ASF_Case_Integration__c CaseIntRec = [select Id, Status__c, Is_Validation_Success__c from ASF_Case_Integration__c 
                                              where Integration_Ext_Id__c='ASF_INT_02' LIMIT 1];
        CaseIntRec.Is_Validation_Success__c = true;
        update CaseIntRec;
        
        Test.startTest();
        ASF_CaseMovementHelper.StageWrapper StageMovementResult = ASF_CaseMovementHelper.moveToForwardStage(caseRecord.Id,'In Progress with Recovery');
        Test.stopTest();
        Assert.areEqual('Success', StageMovementResult.status);  
        Assert.areNotEqual(caseRecord.Stage__c, StageMovementResult.nextStageConfig.StageName__c, 'Case moved to Next Stage');
    } 
    @isTest
    private static void moveToBackStageTest() {
        
        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case LIMIT 1];           
        
        Test.startTest();
        ASF_CaseMovementHelper.StageWrapper StageMovementResult = ASF_CaseMovementHelper.moveToBackwardStage(caseRecord.Id,'Closed');
        Test.stopTest();
        Assert.areEqual('Success', StageMovementResult.status);   
    }
    
    @isTest
    private static void getAssignmentForStageTest() {
        
        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case LIMIT 1];           
        
        Test.startTest();
        ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo caseRuleResult = ASF_CaseMovementHelper.getAssignmentForStage(caseRecord,'In Progress with Recovery');
        Test.stopTest();
        System.assertNotEquals(null, caseRuleResult, 'Case rule assignment info should not be null');  
    }
    
}