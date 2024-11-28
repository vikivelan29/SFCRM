@isTest
public class ABHFL_ComplaintsStageApexClassTest {
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
        caseDetail.Refund_Amount__c = 200;
        caseDetail.Disputed_Amount__c = 100;
        insert caseDetail;
       
        //Create Case
        List<Case> caseRecList = ASF_TestDataFactory.createCaseRecords(1);
        caseRecList[0].AssetId = astRec.Id;
        caseRecList[0].Nature__c='Complaint';
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
    static void testValidateOnResolvedStage(){
        Case caseRecord = [Select id,Nature__c,ABHFL_Case_Detail__r.Final_resolution__c,ABHFL_Case_Detail__r.Case_Categorization__c,
                           ABHFL_Case_Detail__r.Action_Taken__c, ABHFL_Case_Detail__r.Voice_of_Customer__c,
                           ABHFL_Case_Detail__r.Repeat_interaction__c,ABHFL_Case_Detail__r.Gap_IT__c,
                           ABHFL_Case_Detail__r.Gap_People__c,ABHFL_Case_Detail__r.Gap_Process__c,
                           ABHFL_Case_Detail__r.Refund_Amount__c,ABHFL_Case_Detail__r.Disputed_Amount__c,
                           ABHFL_Case_Detail__r.Gap_Product__c, ABHFL_Case_Detail__r.Regulator_Initiated__c,OwnerId from Case limit 1];
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> retCls =  ABHFL_ComplaintsValidateOnResolvedStage.beforeStageMovement(new List<Case>{caseRecord});
        ABHFL_ComplaintsValidateOnResolvedStage.afterStageMovement(new List<Case>{caseRecord});
        System.assertEquals('Error',retCls.get(caseRecord.Id).Status);
        
    }
    @IsTest
    static void testInProgressStageClass(){
        Case caseRecord = [Select id,CCC_External_Id__c,Short_URL__c,AccountId,ContactId,No_Auto_Communication__c from Case limit 1];
        ASF_Case_Category_Config__c ccc = [SELECT Id, New_Case_Email_Template__c,New_Case_SMS_Metadata__c FROM ASF_Case_Category_Config__c 
                                           WHERE CCC_External_Id__c = :caseRecord.CCC_External_Id__c LIMIT 1];
        ccc.New_Case_Email_Template__c='email_Template1,email_Template2';
        ccc.New_Case_SMS_Metadata__c='sms_Template1,sms_Template2';
        update ccc;
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> retCls =  ABHFL_ComplaintInProgressCaseMovement.beforeStageMovement(new List<Case>{caseRecord});
        ABHFL_ComplaintInProgressCaseMovement.afterStageMovement(new List<Case>{caseRecord});
        System.assertEquals('Success',retCls.get(caseRecord.Id).Status);
        
    }
    
}