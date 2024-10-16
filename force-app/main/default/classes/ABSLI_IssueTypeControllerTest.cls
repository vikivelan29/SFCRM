@IsTest
public class ABSLI_IssueTypeControllerTest {

     @TestSetup
    static void testData(){
        //Create Account
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('ABHFLLLL','Test_1');
        
        ASF_TestDataFactory.createCaseCategoryConfig();
        ASF_Case_Category_Config__c ccc = [SELECT id,IGMS_Code__c,CCC_External_Id__c FROM ASF_Case_Category_Config__c LIMIT 1];
        ccc.IGMS_Code__c = '#N/A';
        ccc.CCC_External_Id__c = 'PEMT024';
        ccc.Allowed_Issue_Types__c = 'example1';
        update ccc;
        
        Asset astRec1 = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        astRec1.LAN__c = 'Test1';
        astRec1.Issue_Date__c = Date.newInstance(2024, 6, 6);
        update astRec1;
        
        //Create Case Extension record
        ABSLI_Case_Detail__c caseDetail = new ABSLI_Case_Detail__c();
        insert caseDetail;
       
        //Create Case
        List<Case> caseRecList = ASF_TestDataFactory.createCaseRecords(0);
        caseRecList[0].AssetId = astRec1.Id;
        caseRecList[0].ABSLI_Case_Detail__c = caseDetail.Id;
        caseRecList[0].AccountId = accRec.Id;
        caseRecList[0].CCC_External_Id__c = ccc.CCC_External_Id__c;
        caseRecList[0].Business_Unit__c = 'ABSLI';        
        update caseRecList;
       }
    
     @IsTest
    static void testGetIssueTypeforCCC_ValidCase() {
        // Fetch the test case record
        Case testCase = [SELECT Id FROM Case where ccc_external_id__c = 'PEMT024' LIMIT 1];

        // Call the method and assert the expected result
        List<String> issueTypes = ABSLI_IssueTypeController.getIssueTypeforCCC(testCase.Id);
        List<String> expected = new List<String>{'example1'}; 
        System.assertEquals(expected,issueTypes,'Issue Types are not same');
        
        ASF_Case_Category_Config__c ccc = [SELECT id,IGMS_Code__c,CCC_External_Id__c FROM ASF_Case_Category_Config__c where CCC_External_Id__c= 'PEMT024' LIMIT 1];
        ccc.Allowed_Issue_Types__c = null;
        update ccc;
        ABSLI_IssueTypeController.updateIssueType(testCase.Id,'Leakage Salvage');
    }
}