/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-16-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public class ABHFL_AmortizationIntegration_Test {
	@TestSetup
    static void testData(){
        //Create Account
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('ABHFLLLL','Test_1');
        //Create BranchMaster
        Branch_Master__c branchMstr = new Branch_Master__c();
        branchMstr.Branch_Queue_Id__c = [Select Id from Group where Type = 'Queue' LIMIT 1].Id;
        branchMstr.UniqueKey__c = '234234';
        insert branchMstr;
        //Create Asset
        Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        astRec.LAN__c = 'Test';
        astRec.Branch__c = branchMstr.Id;
        astRec.Last_Disbursement_Date__c = Date.Today();
        astRec.Loan_Disbursement_Status__c = 'Fully';
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
        ABHFL_AmortizationIntegration amortStp = new ABHFL_AmortizationIntegration();
		Case caseRecord = [SELECT id,CaseNumber,AssetId,Asset.Branch__r.Queue_Id__c FROM Case LIMIT 1];
        ASF_IntegrationsController.IntegrationWrapper successfulEvaluate = amortStp.evaluate(caseRecord);
        //loan disbursement status to 'Partially' to test evaluation failure
        Asset astRecord = new Asset();
        astRecord.Id = caseRecord.AssetId;
        astRecord.Account_Status__c = 'Closed';
        astRecord.Loan_Disbursement_Status__c = 'Partially';
        astRecord.Last_Disbursement_Date__c = Date.today().addYears(-2);
        update astRecord;
        ASF_IntegrationsController.IntegrationWrapper evaluateFailure = amortStp.evaluate(caseRecord);
        System.assertEquals('Success',successfulEvaluate.Status,'Done');
        System.assertEquals('Error',evaluateFailure.Status,'Done');
        
    }

    @IsTest
    static void testEvaluateBulk(){
        ABHFL_AmortizationIntegration amortStp = new ABHFL_AmortizationIntegration();
		Case caseRecord = [SELECT Id, Asset.Loan_Disbursement_Status__c,Asset.LAN__c,ABHFL_Case_Detail__r.STP_Request_Type__c,CCC_External_Id__c,AccountId,ContactId, Attachment_Status__c,Source__c,No_Auto_Communication__c,CaseNumber,Business_Unit__c FROM Case LIMIT 1];
        ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{caseRecord.Id=>caseRecord};
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> successfulEvaluate = amortStp.evaluate(new List<Case>{caseRecord});
        //loan disbursement status to 'Partially' to test evaluation failure
        Asset astRecord = new Asset();
        astRecord.Id = caseRecord.AssetId;
        astRecord.Account_Status__c = 'Closed';
        astRecord.Loan_Disbursement_Status__c = 'Partially';
        astRecord.Last_Disbursement_Date__c = Date.today().addYears(-2);
        update astRecord;
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluateFailure = amortStp.evaluate(new List<Case>{caseRecord});
        //System.assertEquals('Success',successfulEvaluate.get(caseRecord.Id).Status,'Done');
        //System.assertEquals('Error',evaluateFailure.get(caseRecord.Id).Status,'Done');
        
    }
    @IsTest
    static void testRun(){
        ABHFL_AmortizationIntegration amortStp = new ABHFL_AmortizationIntegration();
        //ABHFL_AmortizationIntegration.AmmortRequestWrapper wrap = new ABHFL_AmortizationIntegration.AmmortRequestWrapper();
        Case caseRecord = [Select id,CaseNumber,AssetId,Asset.Branch__r.Queue_Id__c, Asset.LAN__c from Case limit 1];
        ASF_Integration__c integRecord = [Select id,External_Id__c,Display_Name__c from ASF_Integration__c limit 1];
        ASF_IntegrationsController.IntegrationWrapper integrationResponse = amortStp.run(integRecord,caseRecord);
        System.assertEquals('Success',integrationResponse.Status,'Done');
    }
    @IsTest
    static void testRunBulk(){
        ABHFL_AmortizationIntegration amortStp = new ABHFL_AmortizationIntegration();
        //ABHFL_AmortizationIntegration.AmmortRequestWrapper wrap = new ABHFL_AmortizationIntegration.AmmortRequestWrapper();
        Case caseRecord = [Select Id, Asset.Loan_Disbursement_Status__c,Asset.LAN__c,ABHFL_Case_Detail__r.STP_Request_Type__c,CCC_External_Id__c,AccountId,ContactId, Attachment_Status__c,Source__c,No_Auto_Communication__c,CaseNumber,Business_Unit__c from Case limit 1];
        ASF_Integration__c integRecord = [Select id,External_Id__c,Display_Name__c, Processing_Class__c from ASF_Integration__c limit 1];
        ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{caseRecord.Id=>caseRecord};
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> integrationResponse = amortStp.run(new Map<Id, List<ASF_Integration__c>>{caseRecord.Id => new List<ASF_Integration__c>{integRecord}},new List<Case>{caseRecord});
        System.assertEquals('Success',integrationResponse.get(caseRecord.Id).Status,'Done');
    }
    @IsTest
    static void testProcessResponse(){
        Test.startTest();
        ABHFL_AmortizationIntegration lodStp = new ABHFL_AmortizationIntegration();
        ASF_Case_Integration__c integRecord = [Select id,Case__c from ASF_Case_Integration__c limit 1];
        integRecord.Status__c = 'Success';
        update integRecord;
        lodStp.processResponse(integRecord);
        Case caseRec = [Select id,Stage__c from Case where id =: integRecord.Case__c ];
        //Assertion when a document is recieved
        System.assertEquals('Success',integRecord.Status__c);
        
        ContentDocumentLink conDoc = [Select id from ContentDocumentLink where LinkedEntityId =: integRecord.Id limit 1];
        delete conDoc;
        lodStp.processResponse(integRecord);
        caseRec = [Select id,Asset.Branch__r.Branch_Queue_Id__c,OwnerId from Case where id =: integRecord.Case__c ];
        Group csQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ABHFL_Customer_Service_Team' Limit 1];
        //Assertion when a document isn't recieved
        System.assertEquals(csQueue.Id,caseRec.OwnerId,'Done');
        Test.stopTest();
    }
    
}