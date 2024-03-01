@isTest
public class ABHFL_LODIngetration_Test {
	@TestSetup
    static void testData(){
        //Create Account
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('ABHFLLLL','Test_1');
        //Create BranchMaster
        Branch_Master__c branchMstr = new Branch_Master__c();
        branchMstr.Branch_Queue_Id__c = [Select Id from Group where Type = 'Queue' and Name LIKE '%abhfl%' LIMIT 1].Id;
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
		Case caseRecord = [SELECT id,CaseNumber,AssetId,Asset.Branch__r.Queue_Id__c FROM Case LIMIT 1];
        ASF_IntegrationsController.IntegrationWrapper successfulEvaluate = lodStp.evaluate(caseRecord);
        //To make Last Disbursement Date below than current Year.
        Asset astRecord = new Asset();
        astRecord.Id = caseRecord.AssetId;
        astRecord.Account_Status__c = 'Closed';
        astRecord.Last_Disbursement_Date__c = Date.today().addYears(-2);
        update astRecord;
        ASF_IntegrationsController.IntegrationWrapper evaluateFailure = lodStp.evaluate(caseRecord);
        System.assertEquals('Error',successfulEvaluate.Status,'Done');
        System.assertEquals('Error',evaluateFailure.Status,'Done');
        
    }
    @IsTest
    static void testRun(){
        ABHFL_LODIntegration lodStp = new ABHFL_LODIntegration();
        //ABHFL_LODIntegration.LODRequestWrapper wrap = new ABHFL_LODIntegration.LODRequestWrapper();
        Case caseRecord = [Select id,CaseNumber,AssetId,Asset.Branch__r.Queue_Id__c from Case limit 1];
        ASF_Integration__c integRecord = [Select id,External_Id__c,Display_Name__c from ASF_Integration__c limit 1];
        ASF_IntegrationsController.IntegrationWrapper integrationResponse = lodStp.run(integRecord,caseRecord);
        System.assertEquals('Success',integrationResponse.Status,'Done');
    }
    @IsTest
    static void testProcessResponse(){
        ABHFL_LODIntegration lodStp = new ABHFL_LODIntegration();
        ASF_Case_Integration__c integRecord = [Select id,Case__c from ASF_Case_Integration__c limit 1];
        integRecord.Status__c = 'Success';
        update integRecord;
        lodStp.processResponse(integRecord);
        Case caseRec = [Select id,Stage__c from Case where id =: integRecord.Case__c ];
        System.assertEquals('In Progress with Recovery',caseRec.Stage__c,'Done');
        ContentDocumentLink conDoc = [Select id from ContentDocumentLink where LinkedEntityId =: integRecord.Id limit 1];
        delete conDoc;
        lodStp.processResponse(integRecord);
        caseRec = [Select id,Asset.Branch__r.Branch_Queue_Id__c,OwnerId from Case where id =: integRecord.Case__c ];
        System.assertEquals(caseRec.Asset.Branch__r.Branch_Queue_Id__c,caseRec.OwnerId,'Done');
    }
    
}