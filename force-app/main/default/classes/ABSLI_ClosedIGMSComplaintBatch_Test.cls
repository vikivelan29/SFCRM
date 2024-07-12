@isTest
public class ABSLI_ClosedIGMSComplaintBatch_Test {
    
    @testSetup
    static void setupTestData() {
        ASF_Integration__c integ = new ASF_Integration__c();
		integ.External_Id__c = 'PNFT008';
		integ.Display_Name__c = 'Closed IGMS Complaint';
		integ.Query_Fields__c = 'ABSLI_Case_Detail__r.Status_Valid_For_STP__c,CaseNumber,Account.Client_Code__c,ABSLI_Case_Detail__r.WhatsApp_Opt_Out_Indicator__c,Business_Unit__c,Technical_Source__c,Is_STP__c';
		integ.Processing_Class__c = 'ABSLI_ClosedIGMSComplaintIntegration';
		integ.When_to_Appear__c = 'Stage Entry';
		integ.Type__c = 'Process';
		integ.Auto_Run_on_Load__c = true;
		insert integ;

		Account accRec = ASF_TestDataFactory.insertPersonAccount('test', 'test', '100');
		accRec.Client_Code__c = 'ABI123';
		update accRec;

		Asset assetRec = ASF_TestDataFactory.createAsset(accRec.Id, 'Loans');
		assetRec.Policy_No__c = '1234';
		update assetRec;
        
		ABSLI_Case_Detail__c detailRec = new ABSLI_Case_Detail__c();
		detailRec.IGMS_type_of_policy__c = '1';
        detailRec.IGMS_Source_of_Complaint__c = '4';
        detailRec.Receipt_Number__c = 'ABSLI0001';
        detailRec.IGMS_Complaint_Status__c = '2';
        detailRec.IGMS_Created_Case__c = true;
        detailRec.Acknowledged_Date__c = System.today();
        detailRec.Complaint_Category__c = 'Complaint';
        detailRec.IRDAI_Token_Number__c = '43546512';
        detailRec.New_Registration_Date__c = System.today();
        detailRec.Next_Integration_Name__c = 'ABSLI_PendingIGMSComplaintIntegration';
		detailRec.Email_Id__c = 'panigrahi@abinash.com';
		detailRec.Status_Valid_For_STP__c = true;
		insert detailRec;
        
        // Create test data
        Case caseRec = ASF_TestDataFactory.createInteractionCaseRecords()[0];
		caseRec.Source__c = 'Email';
		caseRec.Business_Unit__c = 'ABSLI';
		caseRec.Status = 'Open';
		caseRec.AssetId = assetRec.Id;
        caseRec.Stage__c = 'In Progress with SA';
		caseRec.ABSLI_Case_Detail__c = detailRec.Id;
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
        ABSLI_ClosedIGMSComplaintBatch batch = new ABSLI_ClosedIGMSComplaintBatch();
        
        // Execute the batch job
        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();
        
    }
    
    @isTest
    static void testSchedulableExecution() {
        // Create instance of the batch class
        ABSLI_ClosedIGMSComplaintBatch batch = new ABSLI_ClosedIGMSComplaintBatch();
        
        // Test the Schedulable execution
        String cronExpression = '0 30 23 1/1 * ? *'; 
        
        Test.startTest();
        batch.schedule();
        System.schedule('IGMS Closed Complaints Outbound Schedulde Job', cronExpression, batch);
        Test.stopTest();
        
    }
    
    @isTest
    static void testExceptionHandling() {
        // Prepare a batch instance with invalid query to trigger exception
        ABSLI_ClosedIGMSComplaintBatch batch = new ABSLI_ClosedIGMSComplaintBatch('SELECT Business_Unit__c FROM Case');
        
        // Execute the batch job
        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();
        
    }
}