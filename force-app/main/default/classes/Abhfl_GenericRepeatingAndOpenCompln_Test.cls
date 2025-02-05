/****************************************************************************************************************
  * Author       - Anirudh Raturi
  * Date         - 08-Feb-2024
  * @LOB         - ABHFL
  * @description -  Test class for Abhfl_GenericRepeatingAndOpenComplntClas class.
*****************************************************************************************************************/

@isTest
public with sharing class Abhfl_GenericRepeatingAndOpenCompln_Test {

    /****************************************************
       * @description - Test Method for evaluate Method
    *****************************************************/
    @isTest 
    static void genericFetchQuery_TestMethod() {

        List<Case> sobJRec = (List<Case>) Abhfl_GenericRepeatingAndOpenComplntClas.genericFetchQuery('id', 'Case', '');
       // System.assertEquals(sobJRec.size(), 0);
    }
    
    @TestSetup
    static void createTestData(){
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('Test_Cmp','Test_1');
        Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        Asset astRecNoCase = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        List<Case> caseRecList = ASF_TestDataFactory.createCaseRecords(1);
        caseRecList[0].CCC_External_Id__c = 'hfl069';
        caseRecList[0].AccountId = accRec.Id;
        update caseRecList[0];
        ABHFL_Asset_Detail__c assetDetail = new ABHFL_Asset_Detail__c();
        assetDetail.Asset__c = astRec.Id;
        assetDetail.Case__c = caseRecList[0].Id;
        insert assetDetail;
    }
    
    @IsTest
    static void testGetLanDataAndMetadata(){
    Case caseRecord = [Select id,AccountId from Case limit 1];
        Abhfl_GenericRepeatingAndOpenComplntClas.Survrespwrapper lanResponse = Abhfl_GenericRepeatingAndOpenComplntClas.getSurveyResponseFieldsByAccountId(caseRecord.AccountId);
    }  
}