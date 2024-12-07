@IsTest
public class ABHFL_PaymentLinkHandler_Test {
    @TestSetup
    static void createTestData(){
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('Test_Cmp','Test_1');
        Account accIndRec = ASF_TestDataFactory.insertPersonAccount('Test_FN','Test_LN','Test_2');
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
        caseDetail.Payable_Charges__c=1000;
        insert caseDetail;
        List<Case> caseRecList = ASF_TestDataFactory.createCaseRecords(1);
        caseRecList[0].AssetId = astRec.Id;
        caseRecList[0].ABHFL_Case_Detail__c = caseDetail.Id;
        caseRecList[0].Source__c = 'Chatbot';
        caseRecList[0].Case_Stage_Change_Date__c = date.today();
        caseRecList[0].Business_Unit__c = 'ABHFL';
        caseRecList[0].AccountId = accRec.Id;
        caseRecList[0].CCC_External_Id__c  = 'hfl069';
        update caseRecList[0];
        
        ASF_TestDataFactory.createCaseCategoryConfig();
        ASF_Case_Category_Config__c cccRec = [SELECT id FROM ASF_Case_Category_Config__c LIMIT 1];
        cccRec.CCC_External_Id__c = 'hfl069';
        update cccRec;
        
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
        ABHFL_PaymentLinkHandler paymentHandler = new ABHFL_PaymentLinkHandler();
        Case caseRecord = [Select id,AccountId from Case limit 1];
        ASF_IntegrationsController.IntegrationWrapper businessAccountEmailMissing = paymentHandler.evaluate(caseRecord);
        System.assertEquals('Error',businessAccountEmailMissing.Status,'PASS');
        Account accountRecord = [Select id from Account where RecordType.Name = 'Individual' limit 1];
		caseRecord.AccountId = accountRecord.Id;
        update caseRecord;
        ASF_IntegrationsController.IntegrationWrapper personAccountEmailMissing = paymentHandler.evaluate(caseRecord);
        System.assertEquals('Error',personAccountEmailMissing.Status,'PASS');  
    }
    
    @IsTest
    static void testRun(){
        ABHFL_PaymentLinkHandler paymentHandler = new ABHFL_PaymentLinkHandler();
        Case caseRecord = [Select id,CaseNumber,AssetId,Asset.Branch__r.Queue_Id__c,OwnerId from Case limit 1];
        ASF_Integration__c integRecord = [Select id,External_Id__c,Display_Name__c from ASF_Integration__c limit 1];
        ASF_Case_Integration__c caseIntRecord = [Select id from ASF_Case_Integration__c limit 1];
        MultiStaticResourceCalloutMock mock = new MultiStaticResourceCalloutMock();
        mock.setStaticResource(ABCL_Integrations__mdt.getInstance('Paytm_Link').EndPoint__c,'PaytmLinkMockResponse');
        mock.setStaticResource(ABCL_Integrations__mdt.getInstance('Payment_Link').EndPoint__c,'PaymentLinkMockResponse');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        Test.StartTest();
        ASF_IntegrationsController.IntegrationWrapper integrationResponse = paymentHandler.run(integRecord,caseRecord);
        paymentHandler.processResponse(caseIntRecord);
        System.assertEquals('Success',integrationResponse.Status,'PASS');
        Test.StopTest();
    }

    @IsTest
    static void testEvaluateBulk(){
        ABHFL_PaymentLinkHandler paymentHandler = new ABHFL_PaymentLinkHandler();
        Case caseRecord = [Select id,AccountId from Case limit 1];
        Account accountRecord = [Select id from Account where RecordType.Name = 'Individual' limit 1];
		caseRecord.AccountId = accountRecord.Id;
        update caseRecord;
        paymentHandler.evaluate(new List<Case>{caseRecord});
        
    }
    
    @IsTest
    static void testRunBulk(){
        ABHFL_PaymentLinkHandler paymentHandler = new ABHFL_PaymentLinkHandler();
        Case caseRecord = [Select id,CaseNumber,AssetId,Asset.Branch__r.Queue_Id__c,OwnerId from Case limit 1];
        ASF_Integration__c integRecord = [Select id,External_Id__c,Display_Name__c from ASF_Integration__c limit 1];
        ASF_Case_Integration__c caseIntRecord = [Select id from ASF_Case_Integration__c limit 1];
        MultiStaticResourceCalloutMock mock = new MultiStaticResourceCalloutMock();
        mock.setStaticResource(ABCL_Integrations__mdt.getInstance('Paytm_Link').EndPoint__c,'PaytmLinkMockResponse');
        mock.setStaticResource(ABCL_Integrations__mdt.getInstance('Payment_Link').EndPoint__c,'PaymentLinkMockResponse');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        Test.StartTest();
        paymentHandler.run(new Map<Id, List<ASF_Integration__c>>{caseRecord.Id => new List<ASF_Integration__c>{integRecord}},new List<Case>{caseRecord});
        
        Test.StopTest();
    }
}
