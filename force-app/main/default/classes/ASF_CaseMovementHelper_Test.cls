@isTest
public class ASF_CaseMovementHelper_Test {
    
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    @testSetup
    static void setUpData(){
        ASF_TestDataFactory.createCaseRecords(1);
        ASF_TestDataFactory.createCaseCategoryConfig();
        List<sObject> ls = Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
        ASF_TestDataFactory.createC3IntegrationsAndCase();
        //ASF_TestDataFactory.createC3WithPrePopulateIntegrations();
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
        ASF_CaseMovementHelper.StageWrapper StageMovementResult = ASF_CaseMovementHelper.moveToNextStage(caseRecord);
        Test.stopTest();

        Assert.areEqual('Success', StageMovementResult.status);  
        Assert.areNotEqual(caseRecord.Stage__c, StageMovementResult.nextStageConfig.StageName__c, 'Case moved to Next Stage');  
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
        ASF_CaseMovementHelper.StageWrapper StageMovementResult = ASF_CaseMovementHelper.moveToNextStage(caseRecord);
        Test.stopTest();
        Assert.areEqual('Success', StageMovementResult.status);   
        Assert.areNotEqual(caseRecord.Stage__c, StageMovementResult.nextStageConfig.StageName__c, 'Case moved to Next Stage');
    }
    
    // @isTest
    // private static void moveToNextStageTestNegative() {
        
    //     Test.startTest();
    //     ASF_CaseMovementHelper.StageWrapper StageMovementResult = ASF_CaseMovementHelper.moveToNextStage('5005g00000099h1');
    //     ASF_CaseMovementHelper.StageWrapper FrwdMovementResult = ASF_CaseMovementHelper.moveToForwardStage('5005g00000099h1','In Progress with Recovery');
    //     ASF_CaseMovementHelper.StageWrapper BackMovementResult = ASF_CaseMovementHelper.moveToBackwardStage('5005g00000099h1','Closed');
        
    //     Test.stopTest();
    //     Assert.areEqual('Error', StageMovementResult.status);  
    // }

    @isTest
    private static void moveToNextStageIntegrationNegative() {
        
        Case caseRecord = [
                                SELECT Id, CCC_External_Id__c, Stage__c, pending_clarification__c 
                                FROM case 
                                WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-05'];            

        Test.startTest();
        
        ASF_CaseMovementHelper.StageWrapper StageMovementResult = ASF_CaseMovementHelper.moveToNextStage(caseRecord);
        system.debug(StageMovementResult);

        caseRecord.MoveToNext__c = true;
        Database.SaveResult sResult = Database.update(caseRecord, false);

        Test.stopTest();
        Assert.isFalse(sResult.isSuccess()); 
        Assert.areEqual(StageMovementResult.errorMessage, sResult.getErrors()[0].getMessage(), 'Error Returned from the Integration Validation should match');
    }

    @isTest
    private static void moveToNextStageApexClass() {
        
        Case caseRecord = [
                                SELECT Id, CCC_External_Id__c, Stage__c, pending_clarification__c 
                                FROM case 
                                WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-05'];            
        ASF_TestDataFactory.createCaseIntegration(caseRecord.Id,'ASF_INT_02');
        ASF_Case_Integration__c CaseIntRec = [select Id, Status__c, Is_Validation_Success__c from ASF_Case_Integration__c 
                                              where Integration_Ext_Id__c='ASF_INT_02' LIMIT 1];
        CaseIntRec.Is_Validation_Success__c = true;
        update CaseIntRec;

        Test.startTest();
        
        ASF_CaseMovementHelper.StageWrapper StageMovementResult = ASF_CaseMovementHelper.moveToNextStage(caseRecord);
        system.debug(StageMovementResult);

        caseRecord.MoveToNext__c = true;
        update caseRecord;

        caseRecord = [
                        SELECT Id, CCC_External_Id__c, Stage__c, pending_clarification__c 
                        FROM case
                        WHERE Id=: caseRecord.Id];           
        system.debug(caseRecord);
        Test.stopTest();
        Assert.areEqual(caseRecord.Stage__c, StageMovementResult.nextStageConfig.StageName__c); 
    }

    @isTest
    private static void moveToNextStageApexClassNegative() {
        
        Case caseRecord = [
                                SELECT Id, CCC_External_Id__c, Stage__c, pending_clarification__c 
                                FROM case 
                                WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-05'];           
        ASF_TestDataFactory.createCaseIntegration(caseRecord.Id,'ASF_INT_02');
        ASF_Case_Integration__c CaseIntRec = [select Id, Status__c, Is_Validation_Success__c from ASF_Case_Integration__c 
                                              where Integration_Ext_Id__c='ASF_INT_02' LIMIT 1];
        CaseIntRec.Is_Validation_Success__c = true;
        update CaseIntRec;
        
        Test.startTest();
        
        caseRecord.MoveToNext__c = true;
        update caseRecord;

        ASF_TriggerSkipperUtility.resetTriggerRun('Case');
        ASF_CaseQueryHandler.refreshRecords = true;
        ASF_CaseMovementHelper.StageWrapper StageMovementResult = ASF_CaseMovementHelper.moveToNextStage(caseRecord);
        system.debug(StageMovementResult);

        caseRecord.MoveToNext__c = true;
        Database.SaveResult sResult = Database.update(caseRecord, false);
        
        Test.stopTest();
        //Assert.isFalse(sResult.isSuccess()); 
        //Assert.areEqual(StageMovementResult.errorMessage, sResult.getErrors()[0].getMessage(), 'Error Returned from the Apex Class should match');
         
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
        ASF_CaseMovementHelper.StageWrapper stageMovementResult = ASF_CaseMovementHelper.moveToNextStage(caseRecord);
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
        ASF_CaseMovementHelper.StageWrapper gatewayStageResult = ASF_CaseMovementHelper.moveToNextStage(caseRecord);
        Test.stopTest();
        
        //Assert.areEqual('Success', gatewayStageResult.status);  
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
        ASF_CaseMovementHelper.StageWrapper StageMovementResult = ASF_CaseMovementHelper.moveToForwardStage(caseRecord,'In Progress with Recovery');
        Test.stopTest();
        Assert.areEqual('Success', StageMovementResult.status);  
        Assert.areNotEqual(caseRecord.Stage__c, StageMovementResult.nextStageConfig.StageName__c, 'Case moved to Next Stage');
    } 
    // @isTest
    // private static void moveToBackStageTest() {
        
    //     Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case LIMIT 1];           
        
    //     Test.startTest();
    //     ASF_CaseMovementHelper.StageWrapper StageMovementResult = ASF_CaseMovementHelper.moveToBackwardStage(caseRecord,'Closed');
    //     Test.stopTest();
    //     Assert.areEqual('Success', StageMovementResult.status);   
    // }


    @isTest
    private static void testGetAssignmentForStageBlank(){
        
        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case LIMIT 1];           
        // Find the Assignment for this case

        // No Default Owner Assigned
        ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo info = ASF_CaseMovementHelper.getAssignmentForStage(caseRecord, 'Pending with Initiator');
        system.assertEquals(info.defaultOwnerId, null);
        system.assertEquals(info.defaultErrorOwnerId, null);

    }

    @isTest
    private static void testGetAssignmentForStageGroup(){
        
        Group g1 = new Group(Name='OCC-Test-Group', type='Queue');
        insert g1;
        QueuesObject q1 = new QueueSObject(QueueID = g1.id, SobjectType = 'Case');
        insert q1;
        
        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case LIMIT 1];           
        // Find the Assignment for this case

        User userRecord = new User(Alias = 'standt', Email='standarduser@testorg.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='abcdefghijk56@gmail.com');
        insert userRecord;

        System.runAs(userRecord){
            // Assign Group to the Stage
            ASF_Case_Rule__c rule = [
                                        SELECT Id 
                                        FROM ASF_Case_Rule__c 
                                        WHERE Case_Stage_Config__r.StageName__c = 'Pending with Initiator'
                                        AND Type__c = 'Assignment'];
            rule.Assigned_Queue_Id__c = g1.Id;
            rule.Assigned_Error_Queue_Id__c = UserInfo.getUserId();
            update rule;
        }
        
        ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo info = ASF_CaseMovementHelper.getAssignmentForStage(caseRecord, 'Pending with Initiator');
        system.assertEquals(info.defaultOwnerId, g1.Id);
        system.assertEquals(info.defaultErrorOwnerId, userRecord.Id);

    }

    @isTest
    private static void testGetAssignmentForStageDefault(){
        
        Group g1 = new Group(Name='OCC-Test-Group', type='Queue');
        insert g1;
        QueuesObject q1 = new QueueSObject(QueueID = g1.id, SobjectType = 'Case');
        insert q1;

        Group g2 = new Group(Name='OCC-Test-Group', type='Queue');
        insert g2;
        QueuesObject q2 = new QueueSObject(QueueID = g2.id, SobjectType = 'Case');
        insert q2;
        
        Case caseRecord = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case LIMIT 1];           
        // Find the Assignment for this case

        User userRecord = new User(Alias = 'standt', Email='standarduser@testorg.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='abcdefghijk56@gmail.com');
        insert userRecord;

        System.runAs(userRecord){
            // Assign Group to the Stage
            ASF_Case_Stage_Config__c stageConfig = [
                                        SELECT Id 
                                        FROM ASF_Case_Stage_Config__c
                                        WHERE Case_Category_Config__r.CCC_External_Id__c =: caseRecord.CCC_External_Id__c
                                        AND StageName__c = 'Pending with Initiator'];

            stageConfig.Default_Queue__c = g1.Id;
            stageConfig.Default_Error_Queue__c = g2.Id;
            update stageConfig;
        }
        
        ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo info = ASF_CaseMovementHelper.getAssignmentForStage(caseRecord, 'Pending with Initiator');
        system.assertEquals(info.defaultOwnerId, g1.Id);
        system.assertEquals(info.defaultErrorOwnerId, g2.Id);

    }
    
}