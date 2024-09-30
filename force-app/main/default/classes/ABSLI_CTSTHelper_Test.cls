/**
 * @description       : Test class for ABSLI_CTSTHelper
 * @author            : dhinesh.t@salesforce.com
 * @group             : 
 * @last modified on  : 09-24-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   06-05-2024   dhinesh.t@salesforce.com   Initial Version
**/
@isTest
public class ABSLI_CTSTHelper_Test {
	 @TestSetup
    static void testData(){
        //Create Account
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('ABHFLLLL','Test_1');
        Contact  cont = ASF_TestDataFactory.insertContact('Test 1@', '');
        //Create BranchMaster
        Branch_Master__c branchMstr = new Branch_Master__c();
        branchMstr.Branch_Queue_Id__c = [Select Id from Group where Type = 'Queue' LIMIT 1].Id;
        branchMstr.UniqueKey__c = 'TestBranch123';
        insert branchMstr;
        
        ASF_TestDataFactory.createCaseCategoryConfig();
        ASF_Case_Category_Config__c ccc = [SELECT id,IGMS_Code__c,CCC_External_Id__c FROM ASF_Case_Category_Config__c LIMIT 1];
        ccc.IGMS_Code__c = '#N/A';
        ccc.CCC_External_Id__c = 'PEMT024';
        ccc.Allowed_Issue_Types__c = 'example1';
        ccc.Litmus_Trigger__c = TRUE;
        update ccc;
        
        //Create Asset
        Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        astRec.LAN__c = 'Test';
        astRec.Issue_Date__c = Date.newInstance(2024, 6, 6);
        update astRec;
        Asset astRec1 = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        astRec1.LAN__c = 'Test1';
        astRec1.Issue_Date__c = Date.newInstance(2024, 6, 6);
        update astRec1;
        
        //Create Case Extension record
        ABSLI_Case_Detail__c caseDetail = new ABSLI_Case_Detail__c();
        insert caseDetail;
       
        //Create Case
        List<Case> caseRecList = ASF_TestDataFactory.createCaseRecords(2);
        caseRecList[0].AssetId = astRec.Id;
        caseRecList[0].ABSLI_Case_Detail__c = caseDetail.Id;
        caseRecList[0].Case_Stage_Change_Date__c = date.today();
        caseRecList[0].Business_Unit__c = 'ABSLI';
        caseRecList[0].AccountId = accRec.Id;
        
        
       	caseRecList[1].AssetId = astRec1.Id;
        caseRecList[1].ABSLI_Case_Detail__c = caseDetail.Id;
        caseRecList[1].AccountId = accRec.Id;
        caseRecList[1].CCC_External_Id__c = ccc.CCC_External_Id__c;
        caseRecList[1].Business_Unit__c = 'ABSLI';
        
        
        caseRecList[2].AssetId = astRec1.Id;
        caseRecList[2].ABSLI_Case_Detail__c = caseDetail.Id;
        caseRecList[2].AccountId = accRec.Id;
        caseRecList[2].CCC_External_Id__c = ccc.CCC_External_Id__c;
        caseRecList[2].Business_Unit__c = 'ABSLI';
        
        //caseRecList[0].ABHFL_Case_Detail__c = caseDetail.Id;
        
        update caseRecList;

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
    static void testABSLI_RequestResolutionBeforeStage(){
        Test.startTest();
        Case caseRecord = [Select id,Stage__c,FTR__c,CCC_External_Id__c,AssetId,Technical_Source__c,ABSLI_Case_Detail__r.Status_Valid_For_STP__c,ABSLI_Case_Detail__r.Outcome__c,ABSLI_Case_Detail__r.Resolution__c  from Case limit 1];
         Task taskRecord = new Task(
            WhatId = caseRecord.Id,
            Status = 'Not Started', 
            Subject = 'Test Task for Validation'
        );
        insert taskRecord;
        //Assertion
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> retCls =  ABSLI_RequestResolutionBeforeStage.beforeStageMovement(new List<Case>{caseRecord});
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> retCls1 =  ABSLI_RequestResolutionBeforeStage.afterStageMovement(new List<Case>{caseRecord});
        System.assertEquals('Error',retCls.get(caseRecord.Id).Status,'Field is empty');
        //for surivial cert validation
        caseRecord.CCC_External_Id__c = ABSLI_Constants.SURVIVALCTST;
        update caseRecord;
        //for open bank validation
        List<Case> caseRecords = [Select id,Stage__c,CCC_External_Id__c,AssetId,Technical_Source__c,ABSLI_Case_Detail__r.Status_Valid_For_STP__c,ABSLI_Case_Detail__r.Outcome__c,ABSLI_Case_Detail__r.Resolution__c  from Case];
        caseRecords[1].CCC_External_Id__c = 'PNFT034';
        update caseRecords;
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> retCls2 =  ABSLI_RequestResolutionBeforeStage.beforeStageMovement(new List<Case>{caseRecord});
        System.assertEquals('Error',retCls.get(caseRecord.Id).Status,'Field is empty');
        Test.stopTest();
    }
    
    @isTest
    public static void validateFromDateToDateTest(){
        Case caseList = [SELECT Id, AccountId, AssetId, Asset.LAN__c, ABSLI_Case_Detail__c, CCC_External_Id__c,Business_Unit__c,ABSLI_Case_Detail__r.To_Date__c,ABSLI_Case_Detail__r.From_Date__c,Asset.Issue_Date__c,Status FROM Case WHERE Business_Unit__c='ABSLI' and CCC_External_Id__c ='PEMT024' Limit 1];
        ABSLI_Case_Detail__c caseDetail = [SELECT id,Complaint_Category__c FROM ABSLI_Case_Detail__c where id =: caseList.ABSLI_Case_Detail__c];
        caseDetail.To_Date__c = Date.newInstance(2023, 5, 6);
        update caseDetail;
        Test.startTest();
        try {
            Update caseList;
            System.assert(false, 'Expected DmlException was not thrown');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('To Date/From Date should be greater than or equal to the Policy Issued Date'));
        }
        //From Date Greater than to date
        caseDetail.From_date__c = Date.newInstance(2024, 5, 6);
        update caseDetail;
        try {
            Update caseList;
            System.assert(false, 'Expected DmlException was not thrown');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('From Date should not be greater than To Date'));
        }
        //checkComplaintApplicabilityTest
        caseList.Nature__c = 'Complaint';
        caseList.Technical_Source__c = 'LWC';
        caseDetail.Complaint_Category__c = 'Complaint';
        caseDetail.To_Date__c = Date.newInstance(2025, 5, 6);
     	try {
            update caseDetail;
            Update caseList;
            System.assert(true, 'Expected DmlException was not thrown');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Category Type of "Complaint" is not applicable for Non-IGMS cases'));
        }
        //restrictComplaintRejectionTest
        caseList.IRDAI_Token_Number__c = '12312312';
        caseList.Stage__c = 'Unresolved';
        try {
            Update caseList;
            System.assert(false, 'Expected DmlException was not thrown');
        } catch (DmlException e) {
        }
        
        //3PM test
		caseList.CCC_External_Id__c = 'PNFT042';
		caseDetail.Branch_Receive_Date__c = Date.Today() + 1;  
        caseDetail.Before_3_PM__c = 'Yes';
        try {
            Update caseList;
            System.assert(false, 'Expected DmlException was not thrown');
        } catch (DmlException e) {
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testABSLI_ComplaintsResolveStageBefore(){
        Case caseRecord = [Select id,Stage__c,CCC_External_Id__c,Technical_Source__c,ABSLI_Case_Detail__r.IGMS_Complaint_Status__c,ABSLI_Case_Detail__r.Resolve_case__c,ABSLI_Case_Detail__r.Resolution_Comments__c,ABSLI_Case_Detail__r.Investigation_Comment__c,ABSLI_Case_Detail__r.Acknowledgement_contacted__c  from Case limit 1];
        Task taskRecord = new Task(
            WhatId = caseRecord.Id,  
            Status = 'Not Started',  
            Subject = 'Test Task for Validation'
        );
        //Assertion
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> retCls =  ABSLI_ComplaintsResolveStageBefore.beforeStageMovement(new List<Case>{caseRecord});
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> retCls1 =  ABSLI_ComplaintsResolveStageBefore.afterStageMovement(new List<Case>{caseRecord});
        System.assertEquals('Error',retCls.get(caseRecord.Id).Status,'Field is empty');
    }
	
    @IsTest
    static void testABSLI_BeforeUpdateTriggerLogic(){
        Case caseRecord = [Select id,Stage__c,CCC_External_Id__c,Technical_Source__c,ABSLI_Case_Detail__r.Resolve_case__c  from Case limit 1];
        ABSLI_Case_Detail__c caseDetail = [SELECT id,Complaint_Category__c FROM ABSLI_Case_Detail__c where id =: caseRecord.ABSLI_Case_Detail__c];
        caseDetail.Complaint_Category__c = 'Complaint';
		update caseDetail;
        caseRecord.IRDAI_Token_Number__c = 'Test123';
		caseRecord.Nature__c = 'Complaint';
        caseRecord.Technical_Source__c = 'LWC';
		update CaseRecord;
    }
    
     @IsTest
    static void testvalidateOpenStageFieldForReinstatement(){
        List<Case> caseRecords = [Select id,Stage__c,CCC_External_Id__c,ABSLI_Case_Detail__r.PX_Response__c,AssetId  from Case limit 1];
        Map<Id, ABSLI_CTSTHelper.FieldValidationResult> resultsMap1 = new Map<Id, ABSLI_CTSTHelper.FieldValidationResult>();
        resultsMap1= ABSLI_CTSTHelper.validateOpenStageFieldForReinstatement(caseRecords);
        System.assertEquals(true, resultsMap1.get(caseRecords[0].Id).result);
        
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        
        ABSLI_CTSTHelper.checkIfOpenBankUpdateCase(caseRecords,resultMap);
    }
    
    @IsTest
    static void testABSLI_LitmusIntegration(){
        Test.startTest();
        Case caseRecord = [Select id,Stage__c,CCC_External_Id__c,AccountId,Business_Unit__c,AssetId,ABSLI_Case_Detail__c  from Case where CCC_External_Id__c = 'PEMT024' limit 1];
        ABSLI_Case_Detail__c caseDetail = [SELECT id,Complaint_Category__c,Source_Request_submitted_by__c FROM ABSLI_Case_Detail__c where id =: caseRecord.ABSLI_Case_Detail__c];
        caseDetail.Source_Request_submitted_by__c = 'Customer';
        update caseDetail;
        caseRecord.Status = 'Resolved';
        caseRecord.Stage__c = 'Resolved';
        update caseRecord;
        Test.stopTest(); 
    }
    
}