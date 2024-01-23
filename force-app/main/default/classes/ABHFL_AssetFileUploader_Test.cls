@IsTest
public class ABHFL_AssetFileUploader_Test {
	@IsTest
    static void testUploadFile(){
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('Test_Cmp','Test_1');
        Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        Asset_Detail__c assetDetail = new Asset_Detail__c();
        assetDetail.Asset__c = astRec.Id;
        insert assetDetail;
        List<Case> caseRecList = ASF_TestDataFactory.createCaseRecords(1);
        string response = ABHFL_AssetFileUploader.uploadFile('test','TestDoc.txt',caseRecList[0].Id,assetDetail.Id);
        System.assertEquals(true,response!= null,'PASS');
    }
}