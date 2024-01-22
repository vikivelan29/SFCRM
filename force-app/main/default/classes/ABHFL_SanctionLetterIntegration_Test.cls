@IsTest
public class ABHFL_SanctionLetterIntegration_Test {
  @TestSetup
    static void createTestData(){
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('Test_Cmp','Test_1');
        Branch_Master__c branchMstr = new Branch_Master__c();
        branchMstr.Branch_Queue_Id__c = [Select Id from Group where Type = 'Queue' LIMIT 1].Id;
        INSERT branchMstr;
        
        Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        astRec.LAN__c = 'Test';
        astRec.Branch__c = branchMstr.Id;
        UPDATE astRec;
        
        ABHFL_Case_Detail__c caseDetail = new ABHFL_Case_Detail__c();
        caseDetail.STP_Request_Type__c = 'Email';
        caseDetail.As_On_Date__c = date.today();
        
        INSERT caseDetail;
        
        List<Case> caseRecList = ASF_TestDataFactory.createCaseRecords(1);
        caseRecList[0].AssetId = astRec.Id;
        caseRecList[0].ABHFL_Case_Detail__c = caseDetail.Id;
        UPDATE caseRecList[0];
        
        ASF_Case_Category_Config__c caseCategoryConfig = new ASF_Case_Category_Config__c();
        caseCategoryConfig.CCC_External_Id__c = caseRecList[0].CCC_External_Id__c;
        caseCategoryConfig.Type__c = 'Test';
        caseCategoryConfig.Sub_Type__c = 'Test';
        INSERT caseCategoryConfig;
        
        ASF_Integration__c integ = new ASF_Integration__c();
        integ.External_Id__c = 'ASF_INT_01';
        integ.Display_Name__c = 'NDC';
        INSERT integ;
        
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Integration_Ext_Id__c = integ.External_Id__c;
        caseInt.Case__c = caseRecList[0].Id;
        INSERT caseInt;
        
        ContentVersion content = new ContentVersion();
        content.PathOnClient = 'Response.txt';
        content.Title = 'Response';
        content.VersionData = Blob.valueof('Test');
        INSERT content;
        
        ContentVersion conVersion = [Select ContentDocumentId from ContentVersion where id =: content.Id];
        ContentDocumentLink docLink = new ContentDocumentLink();
        docLink.LinkedEntityId = caseInt.Id;
        docLink.ContentDocumentId = conVersion.ContentDocumentId;
        docLink.ShareType = 'V';
        INSERT docLink;
    }
    @IsTest
    static void testEvaluate(){
        
        ABHFL_SanctionLetterIntegration sLI = new ABHFL_SanctionLetterIntegration();
        Case caseRecord = [SELECT id,CaseNumber,AssetId,Asset.Branch__r.Queue_Id__c,ownerId,CreatedById FROM Case LIMIT 1];
        ASF_IntegrationsController.IntegrationWrapper successfulEvaluate = sLI.evaluate(caseRecord);
        System.assertEquals('Success',successfulEvaluate.Status);
        
        ABHFL_Case_Detail__c  caseDetail = [SELECT Id FROM ABHFL_Case_Detail__c LIMIT 1];
        caseDetail.As_On_Date__c = null;
        UPDATE caseDetail;
        
        ASF_IntegrationsController.IntegrationWrapper successfulEvaluate2 = sLI.evaluate(caseRecord);
        System.assertEquals('Success',successfulEvaluate2.Status);
    }
    
    @IsTest
    static void testRun(){
        ABHFL_SanctionLetterIntegration sLI = new ABHFL_SanctionLetterIntegration();
        
        Case caseRecord = [Select id,CaseNumber,AssetId,Asset.Branch__r.Queue_Id__c,CreatedById,ownerId from Case limit 1];
        
        ASF_Integration__c integRecord = [Select id,External_Id__c,Display_Name__c from ASF_Integration__c limit 1];
        
        ASF_IntegrationsController.IntegrationWrapper integrationResponse = sLI.run(integRecord,caseRecord);
        System.assertEquals('Success',integrationResponse.Status);
    }
    
    @IsTest
    static void testProcessResponse(){
        ABHFL_SanctionLetterIntegration sLI = new ABHFL_SanctionLetterIntegration();
        ASF_Case_Integration__c integRecord = [Select id,Case__c from ASF_Case_Integration__c limit 1];
        integRecord.Status__c = 'Success';
        UPDATE integRecord;
        
        sLI.processResponse(integRecord);
        Case caseRec = [Select id,Stage__c,ownerId,CreatedById,MoveToNext__c  from Case where id =: integRecord.Case__c ];
        System.assertEquals('Resolved',caseRec.Stage__c);
        ContentDocumentLink conDoc = [Select id from ContentDocumentLink where LinkedEntityId =: integRecord.Id limit 1];
        DELETE conDoc;
        
        sLI.processResponse(integRecord);
        caseRec = [Select id,OwnerId,createdByid,MoveToNext__c from Case where id =: integRecord.Case__c ];
        Group csQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ABHFL_Customer_Service_Team' Limit 1];
        System.assertEquals(csQueue.Id,caseRec.OwnerId);
        
        /*caseRec.Source__c = 'Branch';
        UPDATE caseRec;
        sLI.processResponse(integRecord);
        caseRec = [Select id,OwnerId,createdByid,MoveToNext__c from Case where id =: integRecord.Case__c ];
        System.assertEquals(caseRec.createdByid,caseRec.OwnerId);*/
        
    }
}