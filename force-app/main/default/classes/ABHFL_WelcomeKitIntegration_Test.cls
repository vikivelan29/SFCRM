@IsTest
public class ABHFL_WelcomeKitIntegration_Test {
    
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
        insert branchMstr;
        //Create Asset
        Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        astRec.LAN__c = 'Test';
        astRec.Branch__c = branchMstr.Id;
        astRec.Last_Disbursement_Date__c = Date.Today();
        update astRec;
        Asset astRec1 = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        astRec1.LAN__c = 'Test1';
        astRec1.Branch__c = branchMstr.Id;
        astRec1.Last_Disbursement_Date__c = Date.Today().addMonths(-8);
        update astRec1;
        //Create Case Extension record
        ABHFL_Case_Detail__c caseDetail = new ABHFL_Case_Detail__c();
        caseDetail.STP_Request_Type__c = 'Email';
        insert caseDetail;
        ABHFL_Case_Detail__c caseDetail1 = new ABHFL_Case_Detail__c();
        caseDetail1.STP_Request_Type__c = 'Download';
        insert caseDetail1;
        
        ASF_TestDataFactory.createCaseCategoryConfig();
        ASF_Case_Category_Config__c config = [SELECT Id, Additional_Email_Templates__c, Additional_SMS_Metadata__c
                                             FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c ='CCC-CC-CCLTD-01' LIMIT 1];
        config.Additional_Email_Templates__c = 'Resolved:dev_03,Rejected:dev_04';
        config.Additional_SMS_Metadata__c = 'Resolved:Dev_05,Rejected:Dev_06';
        update config;
        insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                          Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                          Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
       
        //Create Case
        List<Case> caseRecList = ASF_TestDataFactory.createCaseRecords(3);
        caseRecList[0].AssetId = astRec.Id;
        caseRecList[0].Source__c = 'Branch';
        caseRecList[0].ABHFL_Case_Detail__c = caseDetail.Id;
        caseRecList[1].AssetId = astRec1.Id;
        caseRecList[1].Source__c = 'WhatsApp';
        caseRecList[1].ABHFL_Case_Detail__c = caseDetail.Id;
        caseRecList[2].AssetId = astRec.Id;
        caseRecList[2].Source__c = 'Welcome BOT';
        caseRecList[2].ABHFL_Case_Detail__c = caseDetail1.Id;
        //caseRecList[0].Source__c = 'Welcome BOT';
        update caseRecList;

        //create ASF Integration
        ASF_Integration__c integ = new ASF_Integration__c();
        integ.External_Id__c = 'ASF_INT_01';
        integ.Display_Name__c = 'Welcome kit';
        integ.Processing_Class__c = 'ABHFL_WelcomeKitIntegration';
        insert integ;
        
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Integration_Ext_Id__c = integ.External_Id__c;
        caseInt.Case__c = caseRecList[0].Id;
        insert caseInt;
        ASF_Case_Integration__c caseInt1 = new ASF_Case_Integration__c();
        caseInt1.Integration_Ext_Id__c = integ.External_Id__c;
        caseInt1.Case__c = caseRecList[2].Id;
        insert caseInt1;
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
        
    }
    
    @IsTest
    static void testEvaluate(){
        	ABHFL_WelcomeKitIntegration wcStp = new ABHFL_WelcomeKitIntegration();
            Case caseRecord = [SELECT id,CaseNumber,ABHFL_Case_Detail__r.STP_Request_Type__c,AssetId,Asset.Branch__r.Queue_Id__c FROM Case WHERE Source__c ='Branch' LIMIT 1];
            Case caseRecord1 = [SELECT id,CaseNumber,ABHFL_Case_Detail__r.STP_Request_Type__c,AssetId,Asset.Branch__r.Queue_Id__c FROM Case WHERE Source__c ='Welcome BOT' LIMIT 1];
            ASF_IntegrationsController.IntegrationWrapper successfulEvaluate = wcStp.evaluate(caseRecord);
            //To make Last Disbursement Date below than current Year.
            Asset astRecord = new Asset();
            astRecord.Id = caseRecord.AssetId;
            astRecord.Account_Status__c = 'Closed';
            astRecord.Last_Disbursement_Date__c = Date.today().addYears(-2);
            update astRecord;
            ASF_IntegrationsController.IntegrationWrapper evaluateFailure = wcStp.evaluate(caseRecord);
            ASF_IntegrationsController.IntegrationWrapper evaluateFailure1 = wcStp.evaluate(caseRecord1);
        	
            System.assertEquals('Success',successfulEvaluate.status);
            //System.assertEquals('Error',evaluateFailure1.status); 
        	System.assertEquals('Error',evaluateFailure.status);  
    }
    
    @IsTest
    static void testRun(){
            ABHFL_WelcomeKitIntegration wcStp = new ABHFL_WelcomeKitIntegration();
            Case caseRecord = [Select id,CaseNumber,AssetId,Asset.Branch__r.Queue_Id__c, Asset.Lan__c from Case limit 1];
            //ABHFL_WelcomeKitIntegration.WelcomeKitRequestWrapper wrap = new ABHFL_WelcomeKitIntegration.WelcomeKitRequestWrapper(caseRecord.CaseNumber,caseRecord.Asset.Lan__c);
            ASF_Integration__c integRecord = [Select id,External_Id__c,Display_Name__c from ASF_Integration__c limit 1];
            ASF_IntegrationsController.IntegrationWrapper integrationResponse = wcStp.run(integRecord,caseRecord);
            System.assertEquals('Success',integrationResponse.Status);
    }
    
  /*  @IsTest
    static void testProcessResponse(){
            ABHFL_WelcomeKitIntegration wcStp = new ABHFL_WelcomeKitIntegration();
            ASF_Case_Integration__c integRecord = [Select id,Case__c from ASF_Case_Integration__c WHERE Case__r.Source__c ='Welcome BOT' limit 1];
            integRecord.Status__c = 'Success';
            update integRecord;
            wcStp.processResponse(integRecord);
            Group csQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ABHFL_Customer_Service_Team' Limit 1];
            Case caseRec = [Select id,OwnerId from Case where id =: integRecord.Case__c limit 1];
            System.assertEquals(csQueue.Id,caseRec.OwnerId);
    }*/


    @IsTest
    static void testEvaluateBulk(){
        	ABHFL_WelcomeKitIntegration wcStp = new ABHFL_WelcomeKitIntegration();
            Case caseRecord = [SELECT Id, CCC_External_Id__c,MoveToNext__c, Asset.LAN__c, Asset.Last_Disbursement_Date__c, Channel__c, Source__c,ABHFL_Case_Detail__r.STP_Request_Type__c, AccountId, ContactId, Attachment_Status__c, No_Auto_Communication__c, CaseNumber,Business_Unit__c FROM Case WHERE Source__c ='Branch' LIMIT 1];
            Case caseRecord1 = [SELECT Id, CCC_External_Id__c,MoveToNext__c, Asset.LAN__c, Asset.Last_Disbursement_Date__c, Channel__c, Source__c,ABHFL_Case_Detail__r.STP_Request_Type__c, AccountId, ContactId, Attachment_Status__c, No_Auto_Communication__c, CaseNumber,Business_Unit__c FROM Case WHERE Source__c ='Welcome BOT' LIMIT 1];
        	Case caseRecord2 = [SELECT Id, CCC_External_Id__c,MoveToNext__c, Asset.LAN__c, Asset.Last_Disbursement_Date__c, Channel__c, Source__c,ABHFL_Case_Detail__r.STP_Request_Type__c, AccountId, ContactId, Attachment_Status__c, No_Auto_Communication__c, CaseNumber,Business_Unit__c FROM Case WHERE Source__c ='WhatsApp' LIMIT 1];
            ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{caseRecord.Id=>caseRecord, caseRecord1.Id=>caseRecord1, caseRecord2.Id=>caseRecord2};
            Map<Id, ASF_IntegrationsController.IntegrationWrapper> successfulEvaluate = wcStp.evaluate(new List<Case>{caseRecord});
            Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluateFailure = wcStp.evaluate(new List<Case>{caseRecord2});
            Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluateFailure1 = wcStp.evaluate(new List<Case>{caseRecord1});
        	
            // System.assertEquals('Success',successfulEvaluate.get(caseRecord.Id).status);
            // System.assertEquals('Error',evaluateFailure1.get(caseRecord1.Id).status); 
        	// System.assertEquals('Error',evaluateFailure.get(caseRecord.Id).status);  
    }
    
    @IsTest
    static void testRunBulk(){
            ABHFL_WelcomeKitIntegration wcStp = new ABHFL_WelcomeKitIntegration();
            Case caseRecord = [Select Id, CCC_External_Id__c,MoveToNext__c, Asset.LAN__c, Asset.Last_Disbursement_Date__c, Channel__c, Source__c,ABHFL_Case_Detail__r.STP_Request_Type__c, AccountId, ContactId, Attachment_Status__c, No_Auto_Communication__c, CaseNumber,Business_Unit__c from Case limit 1];
            //ABHFL_WelcomeKitIntegration.WelcomeKitRequestWrapper wrap = new ABHFL_WelcomeKitIntegration.WelcomeKitRequestWrapper(caseRecord.CaseNumber,caseRecord.Asset.Lan__c);
            ASF_Integration__c integRecord = [Select id,External_Id__c,Display_Name__c, Processing_Class__c from ASF_Integration__c limit 1];
            ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{caseRecord.Id=>caseRecord};
            Map<Id, ASF_IntegrationsController.IntegrationWrapper> integrationResponse = wcStp.run(new Map<Id, List<ASF_Integration__c>>{caseRecord.Id => new List<ASF_Integration__c>{integRecord}},new List<Case>{caseRecord});
            //System.assertEquals('Success',integrationResponse.get(caseRecord.Id).Status);
    }
}