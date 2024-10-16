@isTest
public class ABHFL_LODIngetration_Test {
    @TestSetup
    static void testData(){
        //Create Account
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('ABHFLLLL','Test_1');
        //Create BranchMaster
        Branch_Master__c branchMstr = new Branch_Master__c();
        branchMstr.Branch_Queue_Id__c = [Select Id from Group where Type = 'Queue' and Name = 'ABHFL Customer Service Team' LIMIT 1].Id;
        branchMstr.UniqueKey__c = '234234';
        insert branchMstr;
        //Create Asset
        Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        astRec.LAN__c = 'Test';
        astRec.Branch__c = branchMstr.Id;
        astRec.Last_Disbursement_Date__c = Date.Today();
        update astRec;
        //Create Case Extension record
        ABHFL_Case_Detail__c caseDetail = new ABHFL_Case_Detail__c();
        caseDetail.STP_Request_Type__c = 'Email';
        insert caseDetail;
       
        //Create Case
        List<Case> caseRecList = ASF_TestDataFactory.createCaseRecords(1);
        caseRecList[0].AssetId = astRec.Id;
        caseRecList[0].ABHFL_Case_Detail__c = caseDetail.Id;
        caseRecList[0].Case_Stage_Change_Date__c = date.today();
        update caseRecList[0];
        
        ASF_TestDataFactory.createCaseCategoryConfig();

        //create ASF Integration
        ASF_Integration__c integ = new ASF_Integration__c();
        integ.External_Id__c = 'ASF_INT_01';
        integ.Display_Name__c = 'LOD';
        insert integ;
        
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Integration_Ext_Id__c = integ.External_Id__c;
        caseInt.Case__c = caseRecList[0].Id;
        insert caseInt;
        //Create document
        ContentVersion content = new ContentVersion();
        content.PathOnClient = 'Response.txt';
        content.Title = 'Response';
        content.VersionData = Blob.valueof('Test');
        insert content;
        //Link document to Case Integration
        ContentVersion conVersion = [Select ContentDocumentId from ContentVersion where id =: content.Id];
        ContentDocumentLink docLink = new ContentDocumentLink();
        docLink.LinkedEntityId = caseInt.Id;
        docLink.ContentDocumentId = conVersion.ContentDocumentId;
        docLink.ShareType = 'V';
        insert docLink;
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
    }
    
    @IsTest
    static void testEvaluate(){
        ABHFL_LODIntegration lodStp = new ABHFL_LODIntegration();
        Case caseRecord = [SELECT id,CaseNumber,AssetId,Asset.Branch__r.Queue_Id__c,ABHFL_Case_Detail__c FROM Case LIMIT 1];
        ASF_IntegrationsController.IntegrationWrapper successfulEvaluate = lodStp.evaluate(caseRecord);
        //To make Last Disbursement Date below than current Year.
        Asset astRecord = new Asset();
        astRecord.Id = caseRecord.AssetId;
        astRecord.Account_Status__c = 'Closed';
        astRecord.Last_Disbursement_Date__c = Date.today().addYears(-2);
        update astRecord;
        ASF_IntegrationsController.IntegrationWrapper evaluateFailure = lodStp.evaluate(caseRecord);
        System.assertEquals('Error',successfulEvaluate.Status,'Done');
        Asset astRec = [SELECT id,Last_Disbursement_Date__c from Asset where LAN__c='Test'];
        astRec.Last_Disbursement_Date__c = Date.today().addYears(1000);
        update astRec;
        astRecord.Last_Disbursement_Date__c = Date.today().addYears(999);
        update astRecord;
        ABHFL_Case_Detail__c assetDetail = [SELECT id,STP_Request_Type__c FROM ABHFL_Case_Detail__c where id =: caseRecord.ABHFL_Case_Detail__c];
        assetDetail.STP_Request_Type__c ='Download';
        update assetDetail;
        Test.startTest();
        ASF_IntegrationsController.IntegrationWrapper evaFailure = lodStp.evaluate(caseRecord);
        Test.stopTest();
        System.assertEquals('Error',evaluateFailure.Status,'Done');
        
    }
    @IsTest
    static void testRun(){
        ABHFL_LODIntegration lodStp = new ABHFL_LODIntegration();
        //ABHFL_LODIntegration.LODRequestWrapper wrap = new ABHFL_LODIntegration.LODRequestWrapper();
        Case caseRecord = [Select id,CaseNumber,AssetId,Asset.Branch__r.Queue_Id__c from Case limit 1];
        ASF_Integration__c integRecord = [Select id,External_Id__c,Display_Name__c from ASF_Integration__c limit 1];
        integRecord.Processing_Class__c = 'ABHFL_LODIntegration';
        update integRecord;
        ASF_IntegrationsController.IntegrationWrapper integrationResponse = lodStp.run(integRecord,caseRecord);
        System.assertEquals('Success',integrationResponse.Status,'Done');
    }
    @IsTest
    static void testProcessResponse(){
        ABHFL_LODIntegration lodStp = new ABHFL_LODIntegration();
        ASF_Case_Integration__c integRecord = [Select id,Case__c from ASF_Case_Integration__c limit 1];
        integRecord.Status__c = 'Success';
        update integRecord;
        Test.startTest();
        lodStp.processResponse(integRecord);
        Case caseRec = [Select id,Stage__c from Case where id =: integRecord.Case__c ];
        System.assertEquals('In Progress with Recovery',caseRec.Stage__c,'Done');
        ContentDocumentLink conDoc = [Select id from ContentDocumentLink where LinkedEntityId =: integRecord.Id limit 1];
        delete conDoc;
        lodStp.processResponse(integRecord);
        Test.stopTest();
        caseRec = [Select id,Asset.Branch__r.Branch_Queue_Id__c,OwnerId from Case where id =: integRecord.Case__c ];
        System.assertEquals(caseRec.Asset.Branch__r.Branch_Queue_Id__c,caseRec.OwnerId,'Done');
    }

    @IsTest
    static void testEvaluateBulk(){
        ABHFL_LODIntegration lodStp = new ABHFL_LODIntegration();
        Case caseRecord = [SELECT Id, Asset.Last_Disbursement_Date__c,Source__c,Asset.Branch__r.Branch_Queue_Id__c,Asset.LAN__c,ABHFL_Case_Detail__r.STP_Request_Type__c,OwnerId,CCC_External_Id__c,No_Auto_Communication__c,CaseNumber,Business_Unit__c FROM Case LIMIT 1];
        ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{caseRecord.Id=>caseRecord};
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> successfulEvaluate = lodStp.evaluate(new List<Case>{caseRecord});
        //To make Last Disbursement Date below than current Year.
        Asset astRecord = new Asset();
        astRecord.Id = caseRecord.AssetId;
        astRecord.Account_Status__c = 'Closed';
        astRecord.Last_Disbursement_Date__c = Date.today().addYears(-2);
        update astRecord;
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluateFailure = lodStp.evaluate(new List<Case>{caseRecord});
        // System.assertEquals('Error',successfulEvaluate.get(caseRecord.Id).Status,'Done');
        // System.assertEquals('Error',evaluateFailure.get(caseRecord.Id).Status,'Done');
        
    }
    @IsTest
    static void testRunBulk(){
        Test.startTest();
        ABHFL_LODIntegration lodStp = new ABHFL_LODIntegration();
        //ABHFL_LODIntegration.LODRequestWrapper wrap = new ABHFL_LODIntegration.LODRequestWrapper();
        Case caseRecord = [Select Id, Asset.Last_Disbursement_Date__c,Source__c,Asset.Branch__r.Branch_Queue_Id__c,Asset.LAN__c,ABHFL_Case_Detail__r.STP_Request_Type__c,OwnerId,CCC_External_Id__c,No_Auto_Communication__c,CaseNumber,Business_Unit__c from Case limit 1];
        ASF_Integration__c integRecord = [Select id,External_Id__c,Display_Name__c, Processing_Class__c from ASF_Integration__c limit 1];
        integRecord.Processing_Class__c = 'ABHFL_LODIntegration';
        update integRecord;
        ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{caseRecord.Id=>caseRecord};
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> integrationResponse = lodStp.run(new Map<Id, List<ASF_Integration__c>>{caseRecord.Id => new List<ASF_Integration__c>{integRecord}},new List<Case>{caseRecord});
        System.assertEquals('Success',integrationResponse.get(caseRecord.Id).Status,'Done');
        Test.stopTest();
    }
    
}