/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-16-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@IsTest
public class ABHFL_NDCSTPHandler_Test {
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
        integ.Display_Name__c = 'NDC';
        integ.Processing_Class__c = 'ABHFL_NDCSTPHandler';
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
        ABHFL_NDCSTPHandler ndcStp = new ABHFL_NDCSTPHandler();
        Case caseRecord = [Select id,CaseNumber,AssetId,Asset.Branch__r.Queue_Id__c,ABHFL_Case_Detail__c from Case limit 1];
        ASF_IntegrationsController.IntegrationWrapper caseAssignToBranch = ndcStp.evaluate(caseRecord);
        //caseRecord.Source__c = 'Branch';
        update caseRecord;
        Test.startTest();
            ASF_IntegrationsController.IntegrationWrapper caseClosed = ndcStp.evaluate(caseRecord); 
            Asset astRecord = new Asset();
            astRecord.Id = caseRecord.AssetId;
            astRecord.Account_Status__c = 'Closed';
            update astRecord;
            ASF_IntegrationsController.IntegrationWrapper successfulEvaluate = ndcStp.evaluate(caseRecord);
        	ABHFL_Case_Detail__c caseDetail = new ABHFL_Case_Detail__c();
        	caseDetail.Id = caseRecord.ABHFL_Case_Detail__c;
        	caseDetail.STP_Request_Type__c = 'Download';
        	update caseDetail;
        	ASF_IntegrationsController.IntegrationWrapper successfulEvaluateDownload = ndcStp.evaluate(caseRecord);
        Test.stopTest();
        //System.assertEquals('Error',caseAssignToBranch.Status,'PASS');
        //System.assertEquals('Error',caseClosed.Status,'PASS');
        System.assertEquals('Success',successfulEvaluate.Status,'PASS');
    }
    
    @IsTest
    static void testRun(){
        ABHFL_NDCSTPHandler ndcStp = new ABHFL_NDCSTPHandler();
        Case caseRecord = [Select id,CaseNumber,AssetId,Asset.Branch__r.Queue_Id__c,OwnerId from Case limit 1];
        ASF_Integration__c integRecord = [Select id,External_Id__c,Display_Name__c from ASF_Integration__c limit 1];
        ASF_IntegrationsController.IntegrationWrapper integrationResponse = ndcStp.run(integRecord,caseRecord);
        System.assertEquals('Success',integrationResponse.Status,'PASS');
    }
    
  /*  @IsTest
    static void testProcessResponse(){
        ABHFL_NDCSTPHandler ndcStp = new ABHFL_NDCSTPHandler();
        Test.startTest();
        ASF_Case_Integration__c integRecord = [Select id,Case__c from ASF_Case_Integration__c limit 1];
        integRecord.Status__c = 'Success';
        update integRecord;
        ndcStp.processResponse(integRecord);
        Case caseRec = [Select id,Stage__c,OwnerId from Case where id =: integRecord.Case__c limit 1];
        //System.assertEquals('Resolved',caseRec.Stage__c,'PASS');
        ContentDocumentLink conDoc = [Select id from ContentDocumentLink where LinkedEntityId =: integRecord.Id limit 1];
        delete conDoc;
        ndcStp.processResponse(integRecord);
        caseRec = [Select id,OwnerId from Case where id =: integRecord.Case__c limit 1 ];
        Group csQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ABHFL_Customer_Service_Team' Limit 1];
        System.assertEquals(csQueue.Id,caseRec.OwnerId,'PASS');
        //Case caseRecord = new Case();
        //caseRecord.Id = integRecord.Case__c;
        //caseRecord.Source__c = 'Branch';
        //update caseRecord;
        Test.stopTest();
        /*ndcStp.processResponse(integRecord);
        caseRec = [Select id,Asset.Branch__r.Branch_Queue_Id__c,OwnerId from Case where id =: integRecord.Case__c ];
        System.assertEquals(caseRec.Asset.Branch__r.Branch_Queue_Id__c,caseRec.OwnerId,'PASS');*/
  //  }

    @IsTest
    static void testEvaluateBulk(){
        ABHFL_NDCSTPHandler ndcStp = new ABHFL_NDCSTPHandler();
        Case caseRecord = [Select Id,Source__c,AccountId,CCC_External_Id__c,ContactId,Asset.LAN__c,ABHFL_Case_Detail__c,Asset.Account_Status__c,Asset.Branch__r.Branch_Queue_Id__c,ABHFL_Case_Detail__r.STP_Request_Type__c,No_Auto_Communication__c,CaseNumber,Business_Unit__c from Case limit 1];
        ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{caseRecord.Id=>caseRecord};
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> caseAssignToBranch = ndcStp.evaluate(new List<Case>{caseRecord});
        //caseRecord.Source__c = 'Branch';
        update caseRecord;
        Test.startTest();
            Map<Id, ASF_IntegrationsController.IntegrationWrapper> caseClosed = ndcStp.evaluate(new List<Case>{caseRecord}); 
            Asset astRecord = new Asset();
            astRecord.Id = caseRecord.AssetId;
            astRecord.Account_Status__c = 'Closed';
       		astRecord.LAN__c = 'test';
            update astRecord;
        	caseRecord.AssetId = astRecord.Id;
        	ABHFL_Case_Detail__c caseDetail = new ABHFL_Case_Detail__c();
        	caseDetail.Id = caseRecord.ABHFL_Case_Detail__c;
        	caseDetail.STP_Request_Type__c = 'Download';
        	update caseDetail;        	
        	caseRecord = [Select Id,Source__c,AccountId,CCC_External_Id__c,ContactId,Asset.LAN__c,ABHFL_Case_Detail__c,Asset.Account_Status__c,
                               Asset.Branch__r.Branch_Queue_Id__c,ABHFL_Case_Detail__r.STP_Request_Type__c,No_Auto_Communication__c,
                               CaseNumber,Business_Unit__c from Case limit 1];
            Map<Id, ASF_IntegrationsController.IntegrationWrapper> successfulEvaluate = ndcStp.evaluate(new List<Case>{caseRecord});
        Test.stopTest();
        // System.assertEquals('Error',caseAssignToBranch.get(caseRecord.Id).Status,'PASS');
        // System.assertEquals('Error',caseClosed.get(caseRecord.Id).Status,'PASS');
        // System.assertEquals('Success',successfulEvaluate.get(caseRecord.Id).Status,'PASS');
    }
    
    @IsTest
    static void testRunBulk(){
        ABHFL_NDCSTPHandler ndcStp = new ABHFL_NDCSTPHandler();
        Case caseRecord = [Select Id,Source__c,AccountId,CCC_External_Id__c,ContactId,Asset.LAN__c,Asset.Account_Status__c,Asset.Branch__r.Branch_Queue_Id__c,ABHFL_Case_Detail__r.STP_Request_Type__c,No_Auto_Communication__c,CaseNumber,Business_Unit__c from Case limit 1];
        ASF_Integration__c integRecord = [Select id,External_Id__c,Display_Name__c, Processing_Class__c from ASF_Integration__c limit 1];
        ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{caseRecord.Id=>caseRecord};
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> integrationResponse = ndcStp.run(new Map<Id, List<ASF_Integration__c>>{caseRecord.Id => new List<ASF_Integration__c>{integRecord}},new List<Case>{caseRecord});
        //System.assertEquals('Success',integrationResponse.get(caseRecord.Id).Status,'PASS');
    }
}