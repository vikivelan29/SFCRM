@IsTest
public class ABHFL_DataServiceTest {

    @TestSetup
    static void testData(){
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('ABHFLLLL','Test_1');
        
        Branch_Master__c branchMstr = new Branch_Master__c();
        branchMstr.Branch_Queue_Id__c = [Select Id from Group where Type = 'Queue' LIMIT 1].Id;
        insert branchMstr;

        Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        astRec.LAN__c = 'Test12345';
        astRec.Branch__c = branchMstr.Id;
        astRec.Last_Disbursement_Date__c = Date.Today();
        astRec.Loan_Disbursement_Status__c = 'Fully';
        update astRec;
    }
    
    @IsTest
    static void testFetchSections(){
        List<ABHFL_DataServiceClass.DataServiceWrapper> wrapperList = new List<ABHFL_DataServiceClass.DataServiceWrapper>();
        List<ABHFL_DataServiceDetailsController.DataServiceWrapper> wrapperList1 = new List<ABHFL_DataServiceDetailsController.DataServiceWrapper>();
        Asset ast = [SELECT Id, LAN__c,Loan_Disbursement_Status__c FROM Asset LIMIT 1];
        wrapperList = ABHFL_DataServiceClass.fetchSections(ast.Id);
        wrapperList1 = ABHFL_DataServiceDetailsController.fetchAllSections();
        System.assertEquals('Test12345',ast.LAN__c);
    }
    
}