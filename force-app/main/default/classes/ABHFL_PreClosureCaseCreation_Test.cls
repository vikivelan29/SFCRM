/*********************************************************
*@Class        :  ABHFL_PreClosureCaseCreation_Test
*@Author       :  Anjali Sharma
*@Created Date :  12/12/2023 
*@Last Modified:  
*@description  :  Class for ABHFL_PreClosureCaseCreation
*********************************************************/

@IsTest
public class ABHFL_PreClosureCaseCreation_Test {
    @TestSetup
    static void createData(){
        Test.startTest();
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('Test_Cmp','Test_1');
        Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        astRec.LAN__c = 'Test';
        update astRec;
        ABHFL_Case_Detail__c caseDetail = new ABHFL_Case_Detail__c();
        caseDetail.From_Date__c = Date.newInstance(2023, 02, 04);
        caseDetail.To_Date__c = Date.newInstance(2023, 10, 15);
        insert caseDetail;
        List<Case> caseRecList = ASF_TestDataFactory.createCaseRecords(1);
        caseRecList[0].AssetId = astRec.Id;
        caseRecList[0].AccountId = accRec.Id;
        caseRecList[0].ABHFL_Case_Detail__c = caseDetail.Id;
        caseRecList[0].Case_Stage_Change_Date__c = date.today();
        update caseRecList[0];
        
        //create Asset Detail
        ABHFL_Asset_Detail__c assetDetail = new ABHFL_Asset_Detail__c();
        assetDetail.Asset__c = astRec.Id;
        assetDetail.Case__c = caseRecList[0].Id;
        
        ABHFL_Asset_Detail__c assetDetail1 = new ABHFL_Asset_Detail__c();
        assetDetail1.Asset__c = astRec.Id;
        assetDetail1.Case__c = caseRecList[0].Id;         
        
        insert assetDetail;
        insert assetDetail1;
        
        
        Test.stopTest();
    }

    @IsTest
    static void testEvaluate() {        
        Case caseRec = [SELECT id,Account.Client_Code__c,Source__c,Technical_Source__c,Nature__c FROM case LIMIT 1];
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> retCls = ABHFL_PreClosureCaseCreation.afterStageMovement(new List<Case>{caseRec});

        System.assertEquals('Success', retCls.get(caseRec.Id).Status);
    }
}