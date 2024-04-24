@IsTest
public class ABHFL_AssetFileUploader_Test {
	@IsTest
    static void testUploadFile(){
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('Test_Cmp','Test_1');
        Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        ABHFL_Asset_Detail__c assetDetail = new ABHFL_Asset_Detail__c();
        assetDetail.Asset__c = astRec.Id;
        insert assetDetail;
        ABHFL_Case_Detail__c caseDetail = new ABHFL_Case_Detail__c();
        insert caseDetail;
        List<Case> caseRecList = ASF_TestDataFactory.createCaseRecords(1);
        caseRecList[0].CCC_External_Id__c = 'HFCRARGI';
        caseRecList[0].ABHFL_Case_Detail__c = caseDetail.Id;
        update caseRecList;
        string response = ABHFL_AssetFileUploader.uploadFile('test','TestDoc.txt',caseRecList[0].Id,assetDetail.Id,'.pdf');
        string responseStr = ABHFL_AssetFileUploader.uploadFile('test','',caseRecList[0].Id,assetDetail.Id,'.pdf');
        System.assertEquals(true,response!= null,'PASS');
    }
}