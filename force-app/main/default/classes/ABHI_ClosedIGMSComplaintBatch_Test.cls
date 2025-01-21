/*********************************************************
*Class        :  ABHI_ClosedIGMSComplaintBatch_Test 
*Author       :  Shubham Sinha
*Created Date :  14/10/2024
*@description  : Test class for ABHI_ClosedIGMSComplaintBatch 
***********************************************************/
@isTest
public class ABHI_ClosedIGMSComplaintBatch_Test {
    
    @testSetup
    static void setupTestData() {
        ASF_Integration__c integ = new ASF_Integration__c();
    integ.External_Id__c = 'PNFT008';
    integ.Display_Name__c = 'Closed IGMS Complaint';
    integ.Query_Fields__c = 'ABHI_Case_Detail__r.Status_Valid_For_STP__c,IGMS_Complaint_Type_Code__c ,ABHI_Case_Detail__r.Type_of_Disposal__c CaseNumber,Account.Client_Code__c,Business_Unit__c,Technical_Source__c,Is_STP__c';
    integ.Processing_Class__c = 'ABHI_ClosedIGMSComplaintIntegration';
    integ.When_to_Appear__c = 'Stage Entry';
    integ.Type__c = 'Process';
    integ.Auto_Run_on_Load__c = true;
    insert integ;

    Account accRec = ASF_TestDataFactory.insertPersonAccount('test', 'test', '100');
    accRec.Client_Code__c = 'ABHI123';
    update accRec;

    Asset assetRec = ASF_TestDataFactory.createAsset(accRec.Id, 'Loans');
    assetRec.Policy_No__c = '1234';
    update assetRec;
        
    ABHI_Case_Detail__c detailRec = new ABHI_Case_Detail__c();
    detailRec.IGMS_type_of_policy__c = '5';
        detailRec.IGMS_Source_of_Complaint__c = '4';
        detailRec.Receipt_Number__c = 'ABHI0001';
        detailRec.IGMS_Complaint_Status__c = '2';
        detailRec.IGMS_Created_Case__c = true;
        detailRec.Acknowledged_Date__c = System.today();
        detailRec.Complaint_Category__c = 'Complaint';
        detailRec.IRDAI_Token_Number__c = '43546512';
        detailRec.New_Registration_Date__c = System.today();
        detailRec.Next_Integration_Name__c = 'ABSLI_PendingIGMSComplaintIntegration';
        detailRec.Status_Valid_For_STP__c = true;
        insert detailRec;
        
        // Create test data
        Case caseRec = ASF_TestDataFactory.createInteractionCaseRecords()[0];
    caseRec.Source__c = 'Email';
    caseRec.Business_Unit__c = 'ABHI';
    caseRec.Status = 'Open';
    caseRec.AssetId = assetRec.Id;
        caseRec.Stage__c = 'In Progress with SA';
    caseRec.ABHI_Case_Detail__c = detailRec.Id;
    caseRec.AccountId = accRec.Id;
    caseRec.CCC_External_Id__c = 'PNFT008';
    caseRec.Client_Code_Text__c = '8895335596';
    caseRec.Technical_Source__c = 'API';
        caseRec.Is_STP__c = true;
        caseRec.IGMS_Complaint_Type_Code__c = '1';
        caseRec.Subject = 'Test Case 1';
        caseRec.Nature__c = 'Complaint';
        caseRec.IRDAI_Token_Number__c = '12345';
    update caseRec;
        
    }
    
    @isTest
    static void testBatchableExecution() {
        // Prepare test data
        ABHI_ClosedIGMSComplaintBatch batch = new ABHI_ClosedIGMSComplaintBatch();
        
        // Execute the batch job
        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();
        
    }
       
      @isTest
    static void testBatchJobExecution() {
        String cronExpression = '0 0 3 * * ?';  // 2 AM daily
        ABHI_ClosedIGMSComplaintBatch batchJob = new ABHI_ClosedIGMSComplaintBatch();
        Test.startTest();
        String jobId = System.schedule('Test ABHI_ClosedIGMSComplaintBatch Job', cronExpression, batchJob);
        Test.stopTest();

       

    }
  
    @isTest
    static void testExceptionHandling() {
        // Prepare a batch instance with invalid query to trigger exception
        ABHI_ClosedIGMSComplaintBatch batch = new ABHI_ClosedIGMSComplaintBatch('SELECT Business_Unit__c FROM Case');
        
        // Execute the batch job
        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();
        
    }
}