@IsTest
public class ABHFL_MultipleLANController_Test {
    @TestSetup
    static void createTestData(){
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('Test_Cmp','Test_1');
        Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        Asset astRecNoCase = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        List<Case> caseRecList = ASF_TestDataFactory.createCaseRecords(1);
        caseRecList[0].CCC_External_Id__c = 'hfl069';
        caseRecList[0].AccountId = accRec.Id;
        update caseRecList[0];
        Asset_Detail__c assetDetail = new Asset_Detail__c();
        assetDetail.Asset__c = astRec.Id;
        assetDetail.Case__c = caseRecList[0].Id;
        insert assetDetail;
    }
	@IsTest
    static void testGetLanDataAndMetadata(){
        Case caseRecord = [Select id from Case limit 1];
        ABHFL_MultipleLANController.MultipleLanWrapper lanResponse = ABHFL_MultipleLANController.getLanDataAndMetadata(caseRecord.Id);
        System.assertEquals(true,lanResponse!=null,'PASS');
    }
	@IsTest
    static void testFetchAssetDetailsExt(){
        Case caseRecord = [Select id from Case limit 1];
        Asset assetRecord = [Select id,LAN__c from Asset limit 1];
        Asset_Detail__c assetDetails = ABHFL_MultipleLANController.fetchAssetDetailsExt(assetRecord,caseRecord.Id);
        System.assertEquals(true,assetDetails!=null,'PASS');
    } 
    @IsTest
    static void testUpsertRecords(){
        Case caseRecord = [Select id from Case limit 1];
        List<Asset_Detail__c> assetDetails = [Select id from Asset_Detail__c limit 1];
        List<Asset_Detail__c> assetDetail = ABHFL_MultipleLANController.upsertRecords(JSON.serialize(assetDetails),caseRecord.Id);
        System.assertEquals(true,assetDetail!=null,'PASS');
    } 
    @IsTest
    static void testFetchAllLANDetails(){
        Case caseRecord = [Select id from Case limit 1];
        List<Asset> assetRecords = [Select id,LAN__c from Asset];
        Object lanResponse = ABHFL_MultipleLANController.fetchAllLANDetails(assetRecords,caseRecord.Id);
        ABHFL_MultipleLANController.DataServiceContinuationWrapper multipleLan = new ABHFL_MultipleLANController.DataServiceContinuationWrapper();
       	Object state = multipleLan;
        Object lanResponseChain = ABHFL_MultipleLANController.chaining(new List<String>(),state);
        Object lanResponseContinueChain = ABHFL_MultipleLANController.chaining1(new List<String>(),state);
        Object lanResponseFinal = ABHFL_MultipleLANController.processResponse(new List<String>(),state);
        System.assertEquals(true,lanResponse!=null,'PASS');
        System.assertEquals(true,lanResponseChain!=null,'PASS');
        System.assertEquals(true,lanResponseContinueChain!=null,'PASS');
        System.assertEquals(true,lanResponseFinal!=null,'PASS');
    } 
    
}