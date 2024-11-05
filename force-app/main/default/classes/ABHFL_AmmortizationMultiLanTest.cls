@IsTest
public class ABHFL_AmmortizationMultiLanTest {

    @TestSetup
    static void testData(){

        // Create a unique UserName
        /*String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
         UserName=uniqueUserName);*/
        //Create Account
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('ABHFLLLL','Test_1');
        //Create BranchMaster
        Branch_Master__c branchMstr = new Branch_Master__c();
        branchMstr.Branch_Queue_Id__c = [Select Id from Group where Type = 'Queue' LIMIT 1].Id;
        branchMstr.UniqueKey__c = '234234';
        insert branchMstr;
        
        ASF_TestDataFactory.createCaseCategoryConfig();
        insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                          Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                          Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
        
        //Create Asset
        Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        astRec.LAN__c = 'Test123456';
        astRec.Branch__c = branchMstr.Id;
        astRec.Last_Disbursement_Date__c = Date.Today();
        astRec.Loan_Disbursement_Status__c = 'Fully';
        update astRec;
        Asset astRec1 = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        astRec1.LAN__c = 'Test789101';
        astRec1.Branch__c = branchMstr.Id;
        astRec1.Last_Disbursement_Date__c = Date.Today();
        astRec1.Loan_Disbursement_Status__c = 'Partially';
        update astRec1;
        //Create Case Extension record
        ABHFL_Case_Detail__c caseDetail = new ABHFL_Case_Detail__c();
        caseDetail.STP_Request_Type__c = 'Email';
        insert caseDetail;
       
        //Create Case
        List<Case> caseRecList = ASF_TestDataFactory.createCaseRecords(2);
        caseRecList[0].AssetId = astRec.Id;
        caseRecList[0].ABHFL_Case_Detail__c = caseDetail.Id;
        caseRecList[1].AssetId = astRec1.Id;
        caseRecList[1].Source__c = 'Welcome BOT';
        caseRecList[1].ABHFL_Case_Detail__c = caseDetail.Id;
        //caseRecList[0].Source__c = 'Welcome BOT';
        update caseRecList;
        
        //create Asset Detail
        ABHFL_Asset_Detail__c assetDetail = new ABHFL_Asset_Detail__c();
        assetDetail.Asset__c = astRec.Id;
        assetDetail.Case__c = caseRecList[0].Id;
        assetDetail.AmmortApiStatus__c = false;
        ABHFL_Asset_Detail__c assetDetail1 = new ABHFL_Asset_Detail__c();
        assetDetail1.Asset__c = astRec1.Id;
        assetDetail1.Case__c = caseRecList[0].Id;
        assetDetail1.AmmortApiStatus__c = false;
        /*assetDetails[1].Asset__c = astRec.Id;
        assetDetails[1].Case__c = caseRecList[0].Id;
        assetDetails[1].AmmortApiStatus__c = false;*/
		insert assetDetail;
        insert assetDetail1;
        
        

        //create ASF Integration
        ASF_Integration__c integ = new ASF_Integration__c();
        integ.External_Id__c = 'ASF_INT_01';
        integ.Display_Name__c = 'Multiple Ammortization';
        insert integ;
        
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Integration_Ext_Id__c = integ.External_Id__c;
        caseInt.Case__c = caseRecList[0].Id;
        caseInt.Business_External_Id__c = 'Test123456';
        insert caseInt;
        ASF_Case_Integration__c caseInt1 = new ASF_Case_Integration__c();
        caseInt1.Integration_Ext_Id__c = integ.External_Id__c;
        caseInt1.Case__c = caseRecList[0].Id;
        caseInt1.Business_External_Id__c = 'Test789101';
        insert caseInt1;
        //Create document
        ContentVersion content = new ContentVersion();
        content.PathOnClient = 'Response.txt';
        content.Title = 'Response';
        content.VersionData = Blob.valueof('Test');
        insert content;
        ContentVersion content1 = new ContentVersion();
        content1.PathOnClient = 'Response1.txt';
        content1.Title = 'Response1';
        content1.VersionData = Blob.valueof('Test1');
        insert content1;
        //Link document to Case Integration
        ContentVersion conVersion = [Select ContentDocumentId from ContentVersion where id =: content.Id];
        ContentVersion conVersion1 = [Select ContentDocumentId from ContentVersion where id =: content1.Id];
        ContentDocumentLink docLink = new ContentDocumentLink();
        docLink.LinkedEntityId = caseInt.Id;
        docLink.ContentDocumentId = conVersion.ContentDocumentId;
        docLink.ShareType = 'V';
        insert docLink;
        ContentDocumentLink docLink1 = new ContentDocumentLink();
        docLink1.LinkedEntityId = caseInt1.Id;
        docLink1.ContentDocumentId = conVersion1.ContentDocumentId;
        docLink1.ShareType = 'V';
        insert docLink1;
        
    }
    
    @IsTest
    static void testEvaluate(){
        	ABHFL_AmmortizationMultiLanIntegration ammStp = new ABHFL_AmmortizationMultiLanIntegration();
            Case caseRecord = [SELECT id,CaseNumber,AssetId,Asset.Branch__r.Queue_Id__c FROM Case WHERE Source__c !='Welcome BOT' LIMIT 1];
            Case caseRecord1 = [SELECT id,CaseNumber,AssetId,Asset.Branch__r.Queue_Id__c FROM Case WHERE Source__c ='Welcome BOT' LIMIT 1];
            ASF_IntegrationsController.IntegrationWrapper successfulEvaluate = ammStp.evaluate(caseRecord);
            ASF_IntegrationsController.IntegrationWrapper evaluateFailure1 = ammStp.evaluate(caseRecord1);
        	
            System.assertEquals('Success',successfulEvaluate.status);
            System.assertEquals('Error',evaluateFailure1.status);   
    }
    
    @IsTest
    static void testRun(){
            ABHFL_AmmortizationMultiLanIntegration ammStp = new ABHFL_AmmortizationMultiLanIntegration();
            Case caseRecord = [Select id,CaseNumber,AssetId,Asset.Branch__r.Queue_Id__c, Asset.Lan__c from Case limit 1];
            //ABHFL_AmmortizationMultiLanIntegration.AmmortRequestWrapper wrap = new ABHFL_AmmortizationMultiLanIntegration.AmmortRequestWrapper(caseRecord.Asset.Lan__c, caseRecord);
            ASF_Integration__c integRecord = [Select id,External_Id__c,Display_Name__c from ASF_Integration__c limit 1];
            ASF_IntegrationsController.IntegrationWrapper integrationResponse = ammStp.run(integRecord,caseRecord);
            System.assertEquals('Success',integrationResponse.Status);
    }
    
    @IsTest
    static void testProcessResponse(){
            ABHFL_AmmortizationMultiLanIntegration ammStp = new ABHFL_AmmortizationMultiLanIntegration();
            List<ASF_Case_Integration__c> caseIntegRecord = [Select id,Case__c, Business_External_Id__c 
                                                             from ASF_Case_Integration__c
                                                            WHERE Business_External_Id__c IN ( 'Test123456','Test789101')];
            caseIntegRecord[0].Status__c = 'Success';
        	caseIntegRecord[1].Status__c = 'Success';
            update caseIntegRecord;
            ammStp.processResponse(caseIntegRecord[0]);
        	ammStp.processResponse(caseIntegRecord[1]);
            /*Group csQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ABHFL_Customer_Service_Team' Limit 1];
            Case caseRec = [Select id,OwnerId from Case where id =: integRecord.Case__c ];*/
            System.assertEquals(caseIntegRecord[0].Status__c,'Success');
    }
    
}