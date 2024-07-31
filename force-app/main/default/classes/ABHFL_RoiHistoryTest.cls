@IsTest
public class ABHFL_RoiHistoryTest {
	
    @TestSetup
    static void testData(){
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('ABHFLLLL','Test_1');
        
        Branch_Master__c branchMstr = new Branch_Master__c();
        branchMstr.Branch_Queue_Id__c = [Select Id from Group where Type = 'Queue' LIMIT 1].Id;
        branchMstr.UniqueKey__c = '234234';
        insert branchMstr;

        Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        astRec.LAN__c = 'Test12345';
        astRec.Branch__c = branchMstr.Id;
        astRec.Last_Disbursement_Date__c = Date.Today();
        astRec.Loan_Disbursement_Status__c = 'Fully';
        update astRec;
    }
    
    @IsTest
    static void testfetchRoiHistory(){
        ABHFL_RoiHistoryClass.RoiHistoryResponseWrapper wrapper = new ABHFL_RoiHistoryClass.RoiHistoryResponseWrapper();
        Asset ast = [SELECT Id, LAN__c,Loan_Disbursement_Status__c FROM Asset LIMIT 1];
        
        MultiStaticResourceCalloutMock mock = new MultiStaticResourceCalloutMock();
        mock.setStaticResource(ABCL_Integrations__mdt.getInstance('ROI_History_Details').EndPoint__c,'RoiHistoryMockResponse');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        wrapper = ABHFL_RoiHistoryClass.fetchRoiHistory(ast.Id);
        Test.stopTest();
        System.assertEquals('Test12345',ast.LAN__c);
    }
    
}