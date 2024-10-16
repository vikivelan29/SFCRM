@IsTest
public class ABHFL_ComplaintInvestigationTest {
	@TestSetup
    static void testData(){

        //Create Account
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('ABHFLLLL','Test_1');
        
        ASF_TestDataFactory.createCaseCategoryConfig();
        insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                          Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                          Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
        
        //Create BranchMaster
        Branch_Master__c branchMstr = new Branch_Master__c();
        branchMstr.Branch_Queue_Id__c = [Select Id from Group where Type = 'Queue' LIMIT 1].Id;
        branchMstr.UniqueKey__c = '234234';
        insert branchMstr;
        //Create Asset
        Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        astRec.LAN__c = 'Test';
        astRec.Branch__c = branchMstr.Id;
        astRec.Last_Disbursement_Date__c = Date.Today();
        update astRec;
        
        LAN_Mapping__c lmp = new LAN_Mapping__c();
        lmp.LAN__c = astRec.Id;
        lmp.Applicant_Type__c = 'BORROWER';
        lmp.Customer__c = accRec.Id;
        insert lmp;
        LAN_Mapping__c lmp1 = new LAN_Mapping__c();
        lmp1.LAN__c = astRec.Id;
        lmp1.Applicant_Type__c = 'COBORROWER';
        lmp1.Customer__c = accRec.Id;
        insert lmp1;
        
        //Create Case Extension record
        ABHFL_Case_Detail__c caseDetail = new ABHFL_Case_Detail__c();
        caseDetail.STP_Request_Type__c = 'Email';
        insert caseDetail;

        List<Case> caseRecList = ASF_TestDataFactory.createCaseRecords(1);
        caseRecList[0].AssetId = astRec.Id;
        caseRecList[0].ABHFL_Case_Detail__c = caseDetail.Id;
        caseRecList[0].Source__c = 'Welcome BOT';
        caseRecList[0].AccountId = accRec.Id;
        //caseRecList[0].Source__c = 'Welcome BOT';
        update caseRecList;
        
    }
    
    @IsTest
    static void testfetchDetails(){
        ABHFL_ComplaintInvestigationController controller = new ABHFL_ComplaintInvestigationController();
        Case caseRecord = [SELECT id,AccountId,CaseNumber,AssetId,Asset.Branch__r.Queue_Id__c FROM Case WHERE Source__c ='Welcome BOT' LIMIT 1];
        
        MultiStaticResourceCalloutMock mock = new MultiStaticResourceCalloutMock();
        mock.setStaticResource(ABCL_Integrations__mdt.getInstance('Complaint_Investigation_Details').EndPoint__c,'ComplaintInvestigationMockResponse');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        ABHFL_ComplaintInvestigationController.fetchDetails(caseRecord.Id);
        ABHFL_ComplaintInvestigationController.fetchDetailsOnLoad(caseRecord.Id);
        Test.stopTest();
        List<Object> pdfContent = new List<Object>();
        String response =ABHFL_ComplaintInvestigationController.generatePDF('pdfHeaderValue', pdfContent, caseRecord.Id);
        String res = '?pdfHeader=pdfHeaderValue&pdfContent=<table border="1"><tr><td style="color:blue">Current cibil score</td><td>null</td></tr><tr><td style="color:blue">Applicant profile at a time of onboarding</td><td>null</td></tr><tr><td style="color:blue">Current cibil review</td><td>null</td></tr><tr><td style="color:blue">';
        System.assertEquals(res.contains('pdfHeader'),response.contains('pdfHeader'));
    }
}