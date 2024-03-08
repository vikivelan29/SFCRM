@IsTest
public class ABHFL_StageMovementHelperTest {
    
    @TestSetup
    static void createTestData(){
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('Test_Cmp','Test_1');
        Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        ABHFL_Case_Detail__c caseDetail = new ABHFL_Case_Detail__c();
        caseDetail.STP_Request_Type__c = 'Email';
        caseDetail.As_On_Date__c = date.today();
        insert caseDetail;
        List<Case> caseRecList = ASF_TestDataFactory.createCaseRecords(1);
        caseRecList[0].ABHFL_Case_Detail__c = caseDetail.Id;
        caseRecList[0].Source__c = 'Chatbot';
        caseRecList[0].Case_Stage_Change_Date__c = date.today();
        caseRecList[0].Business_Unit__c = 'ABHFL';
        caseRecList[0].CCC_External_Id__c = 'hfl069';
        update caseRecList[0];
    }
    
    @IsTest
    static void testStageMovement(){
        List<Case> caseRecords = [Select id from Case limit 1];
        List<Asset> assetRecords = [Select id from Asset limit 1];
        ABHFL_StageMovementHelper.beforeStageMovement(caseRecords);
        ABHFL_StageMovementHelper.afterStageMovement(caseRecords);
        ABHFL_Asset_Detail__c assetDetail = new ABHFL_Asset_Detail__c();
        assetDetail.Case__c = caseRecords[0].Id;
        assetDetail.Asset__c = assetRecords[0].Id;
        insert assetDetail;
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> result = ABHFL_StageMovementHelper.afterStageMovement(caseRecords);
        System.assertEquals(result.keySet().size(),1);
    }

}