/*********************************************************
*Class        :  ABHI_CTSTHelper_Test 
*Author       :  Shubham Sinha
*Created Date :  14/10/2024
*@description  : Test class for ABHI_CTSTHelper
***********************************************************/ 
@isTest
public class ABHI_CTSTHelper_Test {
     @TestSetup
    static void testData(){
        //Create Account
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('ABHILL','Test_1');
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
        ABHI_Case_Detail__c caseDetail = new ABHI_Case_Detail__c();
        insert caseDetail;
       
        Case caseRec = ASF_TestDataFactory.createInteractionCaseRecords()[0];
    caseRec.Source__c = 'Email';
    caseRec.Business_Unit__c = 'ABHI';
    caseRec.Status = 'Open';
    caseRec.AssetId = astRec1.Id;
    caseRec.Stage__c = 'In Progress with SA';
    caseRec.ABHI_Case_Detail__c = caseDetail.Id;
    caseRec.AccountId = accRec.Id;
    caseRec.CCC_External_Id__c = 'PNFT008';
    caseRec.Client_Code_Text__c = '8895335596';
    caseRec.Technical_Source__c = 'API';
        caseRec.Is_STP__c = true;
        caseRec.IGMS_Complaint_Type_Code__c = '1';
    update caseRec;
        
        //create ASF Integration
        ASF_Integration__c integ = new ASF_Integration__c();
        integ.External_Id__c = 'ASF_INT_01';
        integ.Display_Name__c = 'LOD';
        insert integ;
        
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Integration_Ext_Id__c = integ.External_Id__c;
        caseInt.Case__c = caseRec.Id;
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
    static void testvalidateOpenStageFieldForReinstatement(){
        List<Case> caseRecords = [Select id,Stage__c,ABHI_Case_Detail__c,ABHI_Case_Detail__r.Outcome__c,ABHI_Case_Detail__r.Resolution__c,CCC_External_Id__c,AssetId  from Case limit 1];
        Map<Id, ABHI_CTSTHelper.FieldValidationResult> resultsMap1 = new Map<Id, ABHI_CTSTHelper.FieldValidationResult>();
        resultsMap1= ABHI_CTSTHelper.validateResolutionfields (caseRecords);
        System.assertEquals(true, resultsMap1.get(caseRecords[0].Id).result);
        
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        
        ABHI_CTSTHelper.validateResolutionfieldComplaints (caseRecords);
    }
    

    
}