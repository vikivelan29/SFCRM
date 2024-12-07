@isTest
public class ABSLI_AfterInsertLogic_Test {
	 @TestSetup
    static void testData(){
        //Create Account
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('ABHFLLLL','Test_1');
        
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
        
        update caseRecList;

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