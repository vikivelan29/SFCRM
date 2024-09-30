@isTest
public class ABSLI_AfterInsertLogic_Test {
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
        ccc.CCC_External_Id__c = 'PPAY008';
        ccc.Allowed_Issue_Types__c = 'example1';
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
        caseRecList[0].Technical_Source__c = 'LWC';
        
        
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
    static void testAfterInsert(){
        List<Case> caseRecords = [Select id,Stage__c,CCC_External_Id__c,ABSLI_Case_Detail__c,CaseNumber,AssetId,Technical_Source__c,Entity_Reference_No__c,Business_Unit__c,ABSLI_Case_Detail__r.Status_Valid_For_STP__c,ABSLI_Case_Detail__r.Outcome__c,
                                  ABSLI_Case_Detail__r.Resolution__c,AccountId,ABSLI_Case_Detail__r.PAN__c,Account.PAN__c,Asset.TDS_Indicator__c,ABSLI_Case_Detail__r.TDS_Indicator__c
                                  from Case where CCC_External_Id__c = 'PPAY008'  Limit 1];
        ABSLI_AfterInsertLogic.executeAfterInsertLogic(caseRecords);
        caseRecords[0].Technical_Source__c = 'LWC';
        update caseRecords;
        ABSLI_AfterInsertLogic.checkCreateCaseValidations(caseRecords);
        System.assertEquals(caseRecords[0].Account.PAN__c,caseRecords[0].ABSLI_Case_Detail__r.PAN__c,'Not Populated');
        System.assertEquals(caseRecords[0].Asset.TDS_Indicator__c,caseRecords[0].ABSLI_Case_Detail__r.TDS_Indicator__c,'Not Populated');
    }
    
}