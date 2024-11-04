@IsTest
public class ABHFL_BalanceConfLetterIntegration_Test {
  @TestSetup
    static void createTestData(){
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('Test_Cmp','Test_1');
        Branch_Master__c branchMstr = new Branch_Master__c();
        branchMstr.Branch_Queue_Id__c = [Select Id from Group where Type = 'Queue' and DeveloperName like 'ABHFL%' LIMIT 1].Id;
        branchMstr.UniqueKey__c = '234234';
        insert branchMstr;
        
        Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        astRec.LAN__c = 'Test';
        astRec.Branch__c = branchMstr.Id;
        update astRec;
        
        ABHFL_Case_Detail__c caseDetail = new ABHFL_Case_Detail__c();
        caseDetail.STP_Request_Type__c = 'Email';
        caseDetail.As_On_Date__c = date.today();
        insert caseDetail;
        
        List<Case> caseRecList = ASF_TestDataFactory.createCaseRecords(1);
        caseRecList[0].AssetId = astRec.Id;
        caseRecList[0].ABHFL_Case_Detail__c = caseDetail.Id;
        caseRecList[0].Source__c = 'Chatbot';
        caseRecList[0].Case_Stage_Change_Date__c = date.today();
        caseRecList[0].Business_Unit__c = 'ABHFL';
        update caseRecList[0];
        
        ASF_TestDataFactory.createCaseCategoryConfig();
        SLA_Threshold_Warning__c slaThreshold = SLA_Threshold_Warning__c.getOrgDefaults();
        slaThreshold.Stage_SLA_Threshold_1__c = .5;
        slaThreshold.Stage_SLA_Threshold_2__c = .75;
        slaThreshold.Stage_SLA_Threshold_3__c = 1;
        slaThreshold.Case_SLA_Threshold_1_Label__c = '50%';
        slaThreshold.Case_SLA_Threshold_2_Label__c = '75%';
        slaThreshold.Case_SLA_Threshold_3_Label__c = '100%';
        slaThreshold.Case_SLA_Threshold_1__c = .5;
        slaThreshold.Case_SLA_Threshold_2__c = .75;
        slaThreshold.Case_SLA_Threshold_3__c = 1;
        upsert slaThreshold SLA_Threshold_Warning__c.Id;
        
        ASF_Integration__c integ = new ASF_Integration__c();
        integ.External_Id__c = 'ASF_INT_01';
        integ.Display_Name__c = 'Balance Confirmation';
        insert integ;
        
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Integration_Ext_Id__c = integ.External_Id__c;
        caseInt.Case__c = caseRecList[0].Id;
        insert caseInt;
        
        ContentVersion content = new ContentVersion();
        content.PathOnClient = 'Response.txt';
        content.Title = 'Response';
        content.VersionData = Blob.valueof('Test');
        insert content;
        
        ContentVersion conVersion = [Select ContentDocumentId from ContentVersion where id =: content.Id];
        ContentDocumentLink docLink = new ContentDocumentLink();
        docLink.LinkedEntityId = caseInt.Id;
        docLink.ContentDocumentId = conVersion.ContentDocumentId;
        docLink.ShareType = 'V';
        insert docLink;
    }
    @IsTest
    static void testEvaluate(){
        ABHFL_BalanceConfLetterIntegration bclI = new ABHFL_BalanceConfLetterIntegration();
        Case caseRecord = [SELECT id,CaseNumber,AssetId,Asset.Branch__r.Queue_Id__c,ownerId,CreatedById FROM Case LIMIT 1];
        ASF_IntegrationsController.IntegrationWrapper successfulEvaluate = bclI.evaluate(caseRecord);
        System.assertEquals('Success',successfulEvaluate.Status);
        
        ABHFL_Case_Detail__c  caseDetail = [SELECT Id FROM ABHFL_Case_Detail__c LIMIT 1];
        caseDetail.As_On_Date__c = null;
        UPDATE caseDetail;
        
        ASF_IntegrationsController.IntegrationWrapper successfulEvaluate2 = bclI.evaluate(caseRecord);
        System.assertEquals('Error',successfulEvaluate2.Status);
    }
    
    @IsTest
    static void testRun(){
        ABHFL_BalanceConfLetterIntegration bclI = new ABHFL_BalanceConfLetterIntegration();
        
        Case caseRecord = [Select id,CaseNumber,AssetId,Asset.Branch__r.Queue_Id__c,CreatedById,ownerId from Case limit 1];
        
        ASF_Integration__c integRecord = [Select id,External_Id__c,Display_Name__c from ASF_Integration__c limit 1];
        
        ASF_IntegrationsController.IntegrationWrapper integrationResponse = bclI.run(integRecord,caseRecord);
        System.assertEquals('Success',integrationResponse.Status);
    }
    
    @IsTest
    static void testProcessResponse(){
        ABHFL_BalanceConfLetterIntegration bclI = new ABHFL_BalanceConfLetterIntegration();
        ASF_Case_Integration__c integRecord = [Select id,Case__c from ASF_Case_Integration__c limit 1];
        integRecord.Status__c = 'Success';
        UPDATE integRecord;
        
        Test.startTest();
        bclI.processResponse(integRecord);
        Case caseRec = [Select id,Stage__c,ownerId,CreatedById,MoveToNext__c  from Case where id =: integRecord.Case__c ];
        System.assertEquals('In Progress with Recovery',caseRec.Stage__c);
        ContentDocumentLink conDoc = [Select id from ContentDocumentLink where LinkedEntityId =: integRecord.Id limit 1];
        DELETE conDoc;
        
        bclI.processResponse(integRecord);
        caseRec = [Select id,OwnerId,createdByid,MoveToNext__c from Case where id =: integRecord.Case__c ];
        Group csQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ABHFL_Customer_Service_Team' Limit 1];
        System.assertEquals(csQueue.Id,caseRec.OwnerId);
        Test.stopTest();
    }
    
    @IsTest
    static void testEvaluateBulk(){
        ABHFL_BalanceConfLetterIntegration bclI = new ABHFL_BalanceConfLetterIntegration();
        Case caseRecord = [SELECT Id, CCC_External_Id__c,MoveToNext__c, Asset.LAN__c, Channel__c, Source__c, ABHFL_Case_Detail__r.As_On_Date__c,ABHFL_Case_Detail__r.STP_Request_Type__c,CaseNumber,Business_Unit__c FROM Case LIMIT 1];
        ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{caseRecord.Id=>caseRecord};
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> successfulEvaluate = bclI.evaluate(new List<Case>{caseRecord});
        System.assertEquals('Success',successfulEvaluate.get(caseRecord.Id).Status);
        
        ABHFL_Case_Detail__c  caseDetail = [SELECT Id FROM ABHFL_Case_Detail__c LIMIT 1];
        caseDetail.As_On_Date__c = null;
        UPDATE caseDetail;
        
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> successfulEvaluate2 = bclI.evaluate(new List<Case>{caseRecord});
        //System.assertEquals('Error',successfulEvaluate2.get(caseRecord.Id).Status);
    }
    
    @IsTest
    static void testRunBulk(){
        ABHFL_BalanceConfLetterIntegration bclI = new ABHFL_BalanceConfLetterIntegration();
        
        Case caseRecord = [Select Id, CCC_External_Id__c,MoveToNext__c, Asset.LAN__c, Channel__c, Source__c, ABHFL_Case_Detail__r.As_On_Date__c,ABHFL_Case_Detail__r.STP_Request_Type__c,CaseNumber,Business_Unit__c from Case limit 1];
        
        ASF_Integration__c integRecord = [Select id,External_Id__c,Display_Name__c, Processing_Class__c from ASF_Integration__c limit 1];
        ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{caseRecord.Id=>caseRecord};
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> integrationResponse = bclI.run(new Map<Id, List<ASF_Integration__c>>{caseRecord.Id => new List<ASF_Integration__c>{integRecord}},new List<Case>{caseRecord});
        //System.assertEquals('Success',integrationResponse.get(caseRecord.Id).Status);
    }
}