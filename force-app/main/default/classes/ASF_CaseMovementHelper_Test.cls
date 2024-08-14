@isTest
public class ASF_CaseMovementHelper_Test {
    
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    @testSetup
    static void setUpData(){
        ASF_TestDataFactory.createCaseRecords(1);
        ASF_TestDataFactory.createCaseCategoryConfig();
        List<sObject> ls = Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
        ASF_TestDataFactory.createC3IntegrationsAndCase();
    } 
    
    @isTest
    private static void moveToNextStageTest() {
        
        List<Case> caseList = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case where CCC_External_Id__c != '' and CCC_External_Id__c != null]; 
        ASF_TestDataFactory.createCaseIntegration(caseList[0].Id,'ASF_INT_02');
        ASF_Case_Integration__c CaseIntRec = [select Id, Status__c, Is_Validation_Success__c from ASF_Case_Integration__c 
                                              where Integration_Ext_Id__c='ASF_INT_02' LIMIT 1];
        CaseIntRec.Is_Validation_Success__c = true;
        update CaseIntRec;
        Map<Id, String> currentStageMap = new Map<Id, String>();
        for(Case caseRec : caseList){
            currentStageMap.put(caseRec.Id, caseRec.Stage__c);
        }
        Test.startTest();
        Map<Id, ASF_CaseMovementHelper.StageWrapper> stageMovementResult = ASF_CaseMovementHelper.moveToNextStage(caseList, currentStageMap);
        Map<Id, ASF_CaseMovementHelper.StageWrapper> backMovementResult = ASF_CaseMovementHelper.moveToBackwardStage(caseList, currentStageMap);

        Test.stopTest();

        Assert.areEqual('Success', StageMovementResult.get(caseList[0].Id).status);  
        //Assert.areNotEqual(caseRecord.Stage__c, StageMovementResult.nextStageConfig.StageName__c, 'Case moved to Next Stage');
    }
    @isTest
    private static void findNextStageTest() {
        
        List<Case> caseList = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case where CCC_External_Id__c != '' and CCC_External_Id__c != null]; 
        ASF_TestDataFactory.createCaseIntegration(caseList[0].Id,'ASF_INT_02');
        ASF_Case_Integration__c CaseIntRec = [select Id, Status__c, Is_Validation_Success__c from ASF_Case_Integration__c 
                                              where Integration_Ext_Id__c='ASF_INT_02' LIMIT 1];
        CaseIntRec.Is_Validation_Success__c = true;
        update CaseIntRec;
        Map<Id, String> currentStageMap = new Map<Id, String>();
        for(Case caseRec : caseList){
            currentStageMap.put(caseRec.Id, caseRec.Stage__c);
        }
        Test.startTest();
        Map<Id, ASF_CaseMovementHelper.StageWrapper> stageMovementResult2 = ASF_CaseMovementHelper.findNextStageForMoveToNextStage(caseList, currentStageMap);
        Test.stopTest();

        Assert.areEqual('Success', stageMovementResult2.get(caseList[0].Id).status);  
        //Assert.areNotEqual(caseRecord.Stage__c, StageMovementResult.nextStageConfig.StageName__c, 'Case moved to Next Stage');
    }
    @isTest
    private static void addlDataTest() {
        
        List<Case> caseList = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case where CCC_External_Id__c != '' and CCC_External_Id__c != null]; 
        ASF_TestDataFactory.createCaseIntegration(caseList[0].Id,'ASF_INT_02');
        ASF_Case_Integration__c CaseIntRec = [select Id, Status__c, Is_Validation_Success__c from ASF_Case_Integration__c 
                                              where Integration_Ext_Id__c='ASF_INT_02' LIMIT 1];
        CaseIntRec.Is_Validation_Success__c = true;
        update CaseIntRec;
        Map<Id, String> currentStageMap = new Map<Id, String>();
        for(Case caseRec : caseList){
            currentStageMap.put(caseRec.Id, caseRec.Stage__c);
        }
        Test.startTest();
  
        Map<Id, ASF_CaseMovementHelper.CaseAdditionalData> addlDataResult = ASF_CaseMovementHelper.getCaseAdditionalDataForNextStage(caseList, currentStageMap, caseList);
        
        Test.stopTest();

        Assert.areEqual('Success', addlDataResult.get(caseList[0].Id).status);  
        //Assert.areNotEqual(caseRecord.Stage__c, StageMovementResult.nextStageConfig.StageName__c, 'Case moved to Next Stage');
    }
    
   
    @isTest
    private static void moveToOptionalStageTest() {
        
        List<Case> caseList = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case];           
        ASF_TestDataFactory.createCaseIntegration(caseList[0].Id,'ASF_INT_02');
        ASF_Case_Integration__c CaseIntRec = [select Id, Status__c, Is_Validation_Success__c from ASF_Case_Integration__c 
                                              where Integration_Ext_Id__c='ASF_INT_02' LIMIT 1];
        CaseIntRec.Is_Validation_Success__c = true;
        update CaseIntRec;
        Map<Id, String> currentStageMap = new Map<Id, String>();
        for(Case caseRec : caseList){
             caseRec.CCC_External_Id__c = 'CCC-CC-CCLTD-11';
        }
        update caseList;
        for(Case caseRec : caseList){
            currentStageMap.put(caseRec.Id, caseRec.Stage__c);
        }
        ASF_Case_Stage_Config__c configRec = [select Id, Optional_Stage__c, StageName__c from ASF_Case_Stage_Config__c where StageName__c= 'In Progress with Recovery' LIMIT 1];
        configRec.Optional_Stage__c = true;
        update configRec;
        
        Test.startTest();
        Map<Id, ASF_CaseMovementHelper.StageWrapper> StageMovementResult = ASF_CaseMovementHelper.moveToNextStage(caseList, currentStageMap);
        Test.stopTest();
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
        
        List<Case> caseList = [
                                SELECT Id, CCC_External_Id__c, Stage__c, pending_clarification__c 
                                FROM case 
                                WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-05'];            
		Map<Id, String> currentStageMap = new Map<Id, String>();
        for(Case caseRec : caseList){
            currentStageMap.put(caseRec.Id, caseRec.Stage__c);
        }
        Test.startTest();
        
        Map<Id, ASF_CaseMovementHelper.StageWrapper> StageMovementResult = ASF_CaseMovementHelper.moveToNextStage(caseList, currentStageMap);
        system.debug(StageMovementResult);

        caseList[0].MoveToNext__c = true;
        Database.SaveResult sResult = Database.update(caseList[0], false);

        Test.stopTest();
       // Assert.isTrue(sResult.isSuccess()); 
        //Assert.areEqual(StageMovementResult.errorMessage, sResult.getErrors()[0].getMessage(), 'Error Returned from the Integration Validation should match');
    }

    @isTest
    private static void moveToNextStageApexClass() {
        
        List<Case> caseList = [
                                SELECT Id, CCC_External_Id__c, Stage__c, pending_clarification__c 
                                FROM case 
                                WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-05'];            
        ASF_TestDataFactory.createCaseIntegration(caseList[0].Id,'ASF_INT_02');
        ASF_Case_Integration__c CaseIntRec = [select Id, Status__c, Is_Validation_Success__c from ASF_Case_Integration__c 
                                              where Integration_Ext_Id__c='ASF_INT_02' LIMIT 1];
        CaseIntRec.Is_Validation_Success__c = true;
        update CaseIntRec;
		
        Test.startTest();
        Map<Id, String> currentStageMap = new Map<Id, String>();
        for(Case caseRec : caseList){
            currentStageMap.put(caseRec.Id, caseRec.Stage__c);
        }
        Map<Id, ASF_CaseMovementHelper.StageWrapper> StageMovementResult = ASF_CaseMovementHelper.moveToNextStage(caseList, currentStageMap);
        system.debug(StageMovementResult);
        try{
        caseList[0].MoveToNext__c = true;
        update caseList[0];
        }
        catch(Exception e){}
        Test.stopTest();
        //Assert.areEqual(caseList[0].Id.Stage__c, StageMovementResult.get(caseList[0].Id).nextStageConfig.StageName__c); 
    }

    @isTest
    private static void moveToNextStageApexClassNegative() {
        
        List<Case> caseList = [
                                SELECT Id, CCC_External_Id__c, Stage__c, pending_clarification__c 
                                FROM case 
                                WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-05'];           
        ASF_TestDataFactory.createCaseIntegration(caseList[0].Id,'ASF_INT_02');
        ASF_Case_Integration__c CaseIntRec = [select Id, Status__c, Is_Validation_Success__c from ASF_Case_Integration__c 
                                              where Integration_Ext_Id__c='ASF_INT_02' LIMIT 1];
        CaseIntRec.Is_Validation_Success__c = true;
        update CaseIntRec;
        
        Test.startTest();
        try{
        caseList[0].MoveToNext__c = true;
        update caseList[0];
        }
        catch(Exception e){}
		Map<Id, String> currentStageMap = new Map<Id, String>();
        for(Case caseRec : caseList){
            currentStageMap.put(caseRec.Id, caseRec.Stage__c);
        }
        ASF_TriggerSkipperUtility.resetTriggerRun('Case');
        ASF_CaseQueryHandler.refreshRecords = true;
        Map<Id, ASF_CaseMovementHelper.StageWrapper> StageMovementResult = ASF_CaseMovementHelper.moveToNextStage(caseList, currentStageMap);
        system.debug(StageMovementResult);

        caseList[0].MoveToNext__c = true;
        Database.SaveResult sResult = Database.update(caseList[0], false);
        
        Test.stopTest();
        Assert.isFalse(sResult.isSuccess()); 
        //Assert.areEqual(StageMovementResult.errorMessage, sResult.getErrors()[0].getMessage(), 'Error Returned from the Apex Class should match');
         
    }
    
    @isTest
    private static void moveToNextWithPendingClarfTest() {
        
        List<Case> caseList = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case LIMIT 1]; 
        caseList[0].Pending_Clarification__c = TRUE;
        caseList[0].Previous_Stage__c = 'In Progress with Recovery'; //Previous Stage
        update caseList[0];
        
        ASF_TestDataFactory.createCaseIntegration(caseList[0].Id,'ASF_INT_01');
        ASF_Case_Integration__c CaseIntRec = [select Id, Status__c, Is_Validation_Success__c from ASF_Case_Integration__c 
                                              where Integration_Ext_Id__c='ASF_INT_01' LIMIT 1];
        CaseIntRec.Is_Validation_Success__c = true;
        update CaseIntRec;
        Map<Id, String> currentStageMap = new Map<Id, String>();
        for(Case caseRec : caseList){
            currentStageMap.put(caseRec.Id, caseRec.Stage__c);
        }
        Test.startTest();
        Map<Id, ASF_CaseMovementHelper.StageWrapper> stageMovementResult = ASF_CaseMovementHelper.moveToNextStage(caseList, currentStageMap);
        Test.stopTest();
        
        Assert.areEqual('Success', StageMovementResult.get(caseList[0].Id).status); 
        //Assert.areNotEqual(caseList[0].Stage__c, StageMovementResult.nextStageConfig.StageName__c, 'Case moved to Next Stage');
    } 
    @isTest
    private static void moveToNextGatewayTest() {
        
        List<Case> caseList = [select Id, CCC_External_Id__c, Stage__c, Previous_Stage__c, pending_clarification__c from case LIMIT 1]; 
        caseList[0].Pending_Clarification__c = TRUE;
        update caseList;
        
        ASF_TestDataFactory.createCaseIntegration(caseList[0].Id,'ASF_INT_01');
        ASF_Case_Integration__c CaseIntRec = [select Id, Status__c, Is_Validation_Success__c from ASF_Case_Integration__c 
                                              where Integration_Ext_Id__c='ASF_INT_01' LIMIT 1];
        CaseIntRec.Is_Validation_Success__c = true;
        update CaseIntRec;
        
        List<ASF_Case_Stage_Config__c> configList = [select Id, Gateway_Stage__c, StageName__c, Case_Category_Config__r.CCC_External_Id__c from ASF_Case_Stage_Config__c 
                                              where Case_Category_Config__r.CCC_External_Id__c=: caseList[0].CCC_External_Id__c];
        for(ASF_Case_Stage_Config__c conStage : configList){
            conStage.Gateway_Stage__c = true;
        }
        
        update configList;
        
        Map<Id, String> currentStageMap = new Map<Id, String>();
        for(Case caseRec : caseList){
            currentStageMap.put(caseRec.Id, caseRec.Stage__c);
        }
        
        Test.startTest();
        Map<Id, ASF_CaseMovementHelper.StageWrapper> gatewayStageResult = ASF_CaseMovementHelper.moveToNextStage(caseList, currentStageMap);
        Test.stopTest();
        
        Assert.areEqual('Success', gatewayStageResult.get(caseList[0].Id).status);  
    } 
    @isTest
    private static void moveToForwardStageTest() {
        
        List<Case> caseList = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case];           
        ASF_TestDataFactory.createCaseIntegration(caseList[0].Id,'ASF_INT_02');
        ASF_Case_Integration__c CaseIntRec = [select Id, Status__c, Is_Validation_Success__c from ASF_Case_Integration__c 
                                              where Integration_Ext_Id__c='ASF_INT_02' LIMIT 1];
        CaseIntRec.Is_Validation_Success__c = true;
        update CaseIntRec;
        
        Map<Id, String> requestedStageMap = new Map<Id, String>();
        Map<Id, String> currentStageMap = new Map<Id, String>();
        for(Case caseRec : caseList){
             caseRec.CCC_External_Id__c = 'CCC-CC-CCLTD-11';
        }
        update caseList;
         for(Case caseRec : caseList){
            currentStageMap.put(caseRec.Id, caseRec.Stage__c);
            requestedStageMap.put(caseRec.Id,'In Progress with Recovery');
        }
        
        Test.startTest();
        Map<Id, ASF_CaseMovementHelper.StageWrapper> StageMovementResult = ASF_CaseMovementHelper.moveToForwardStage(caseList, requestedStageMap, currentStageMap);
        Test.stopTest();
        Assert.areEqual('Success', StageMovementResult.get(caseList[0].Id).status);  
        //Assert.areNotEqual(caseRecord.Stage__c, StageMovementResult.nextStageConfig.StageName__c, 'Case moved to Next Stage');
    } 
    
    @isTest
    private static void testGetAssignmentForStageBlank(){
        
        List<Case> caseList = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case LIMIT 1];           
        // Find the Assignment for this case
		Map<Id, String> caseStageMap = new Map<Id, String>();
        caseStageMap.put(caseList[0].Id, 'Pending with Initiator');
        // No Default Owner Assigned
        Test.startTest();
         Map<Id,ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo> info = ASF_CaseMovementHelper.getAssignmentForStage(caseList, caseStageMap);
         Test.stopTest();
        system.assertEquals(info.get(caseList[0].Id).defaultOwnerId, null);
        //system.assertEquals(info.defaultErrorOwnerId, null);

    }

    @isTest
    private static void testGetAssignmentForStageGroup(){
        
        List<Case> caseList = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case LIMIT 1];           
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
            //rule.Assigned_Queue_Id__c = [select id from group where type='Queue' and name='OCC-Test-Group' LIMIT 1].Id;
            rule.Assigned_Error_Queue_Id__c = UserInfo.getUserId();
            update rule;
        }
        Map<Id, String> caseStageMap = new Map<Id, String>();
        caseStageMap.put(caseList[0].Id, 'Pending with Initiator');
        Test.startTest();
        	Map<Id,ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo> info = ASF_CaseMovementHelper.getAssignmentForStage(caseList, caseStageMap);
         Test.stopTest();
    }

    @isTest
    private static void testGetAssignmentForStageDefault(){
        
        List<Case> caseList = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case LIMIT 1];           
        // Find the Assignment for this case

        User userRecord = new User(Alias = 'standt', Email='standarduser@testorg.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='abcdefghijk56@gmail.com');
        insert userRecord;

        System.runAs(userRecord){
             Test.startTest();
            // Assign Group to the Stage
            List<Group> glist = new List<Group>();
            Group g1 = new Group(Name='OCC-Test-Group', type='Queue');
            glist.add(g1);
            Group g2 = new Group(Name='OCC-Test-Group1', type='Queue');
            //glist.add(g2);
            
            insert glist;
            List<QueuesObject> qObejctlist = new List<QueuesObject>();
            QueuesObject q1 = new QueueSObject(QueueID = glist[0].Id, SobjectType = 'Case');
            qObejctlist.add(q1);
            //QueuesObject q2 = new QueueSObject(QueueID = glist[1].Id, SobjectType = 'Case');
            //qObejctlist.add(q2);
            insert qObejctlist;
            ASF_Case_Stage_Config__c stageConfig = [
                                        SELECT Id 
                                        FROM ASF_Case_Stage_Config__c
                                        WHERE StageName__c = 'Pending with Initiator' LIMIT 1];

            stageConfig.Default_Queue__c = [select id from group where type='Queue' and name='OCC-Test-Group' LIMIT 1].Id;
            stageConfig.Default_Error_Queue__c = [select id from group where type='Queue' and name='OCC-Test-Group' LIMIT 1].Id;
            update stageConfig;
        }
        Map<Id, String> caseStageMap = new Map<Id, String>();
        caseStageMap.put(caseList[0].Id, 'Pending with Initiator');
       
        	Map<Id,ASF_CaseFrameworkHelper.CaseRuleAssignmentInfo> info = ASF_CaseMovementHelper.getAssignmentForStage(caseList, caseStageMap);
         Test.stopTest();
        Assert.isNotNull(info.get(caseList[0].Id).defaultOwnerId);
        //system.assertEquals(info.defaultErrorOwnerId, g2.Id);

    }
    
}