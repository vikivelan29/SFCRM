@IsTest
public class ABHFL_StageMovementHelperTest {
    
    @TestSetup
    static void createTestData(){
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('Test_Cmp','Test_1');
        Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        ASF_TestDataFactory.createCaseCategoryConfig();
        ABHFL_Case_Detail__c caseDetail = new ABHFL_Case_Detail__c();
        caseDetail.STP_Request_Type__c = 'Email';
        caseDetail.As_On_Date__c = date.today();
        insert caseDetail;
        List<Case> caseRecList = ASF_TestDataFactory.createCaseRecords(1);
        caseRecList[0].ABHFL_Case_Detail__c = caseDetail.Id;
        caseRecList[0].Source__c = 'Chatbot';
        caseRecList[0].Case_Stage_Change_Date__c = date.today();
        caseRecList[0].Business_Unit__c = 'ABHFL';
        caseRecList[0].CCC_External_Id__c = 'hfl074';//comment
        caseRecList[0].Technical_Source__c = 'LWC';
        update caseRecList[0];
    }
    
    @IsTest
    static void testStageMovement(){
        List<Case> caseRecords = [Select id,CCC_External_Id__c from Case limit 1];
        List<Asset> assetRecords = [Select id from Asset limit 1];
        List<ASF_Case_Category_Config__c> caseCatCon = [SELECT Id, Additional_Email_Templates__c, Additional_SMS_Metadata__c FROM ASF_Case_Category_Config__c LIMIT 1];
        caseCatCon[0].Additional_Email_Templates__c = 'abc_template';
        caseCatCon[0].Additional_SMS_Metadata__c = 'bcd_template';
        caseCatCon[0].CCC_External_Id__c = 'hfl074';
        update caseCatCon;
        ABHFL_StageMovementHelper.beforeStageMovement(caseRecords);
        ABHFL_StageMovementHelper.afterStageMovement(caseRecords);
        ABHFL_Asset_Detail__c assetDetail = new ABHFL_Asset_Detail__c();
        assetDetail.Case__c = caseRecords[0].Id;
        assetDetail.Asset__c = assetRecords[0].Id;
        insert assetDetail;
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> result = ABHFL_StageMovementHelper.afterStageMovement(caseRecords);
        caseRecords[0].CCC_External_Id__c = 'RLOAPRONHFC';
        caseRecords[0].Stage__c = 'Resolved';
        update caseRecords;
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> resultAttachment = ABHFL_StageMovementHelper.afterStageMovement(caseRecords);
        System.assertEquals(result.keySet().size(),1);
        System.assertEquals(resultAttachment.keySet().size(),1);
    }

}