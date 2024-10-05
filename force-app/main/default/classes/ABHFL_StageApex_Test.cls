@isTest
public class ABHFL_StageApex_Test {
 @TestSetup
	static void testData(){
        //Create Account
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('ABHFLLLL','Test_1');
        Contact  cont = ASF_TestDataFactory.insertContact('Test 1@', '');
        //Create BranchMaster
        Branch_Master__c branchMstr = new Branch_Master__c();
        branchMstr.Branch_Queue_Id__c = [Select Id from Group where Type = 'Queue' LIMIT 1].Id;
        insert branchMstr;
        //Create Asset
        Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        astRec.LAN__c = 'Test';
        astRec.Branch__c = branchMstr.Id;
        astRec.Last_Disbursement_Date__c = Date.Today();
        astRec.Loan_Disbursement_Status__c = 'Complete';
        update astRec;
        //Create Case Extension record
        ABHFL_Case_Detail__c caseDetail = new ABHFL_Case_Detail__c();
        caseDetail.STP_Request_Type__c = 'Email';
        insert caseDetail;
       
        //Create Case
        List<Case> caseRecList = ASF_TestDataFactory.createCaseRecords(1);
        caseRecList[0].AssetId = astRec.Id;
        caseRecList[0].ABHFL_Case_Detail__c = caseDetail.Id;
        caseRecList[0].Case_Stage_Change_Date__c = date.today();
       // caseRecList[0].Business_Unit__c = 'ABHFL';
        update caseRecList[0];
        
        ASF_TestDataFactory.createCaseCategoryConfig();

        //create ASF Integration
        ASF_Integration__c integ = new ASF_Integration__c();
        integ.External_Id__c = 'ASF_INT_01';
        integ.Display_Name__c = 'LOD';
        insert integ;
        
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Integration_Ext_Id__c = integ.External_Id__c;
        caseInt.Case__c = caseRecList[0].Id;
        insert caseInt;
        //Create document
        ContentVersion content = new ContentVersion();
        content.PathOnClient = 'Response.txt';
        content.Title = 'Response';
        content.VersionData = Blob.valueof('Test');
        insert content;
        //Link document to Case Integration
        ContentVersion conVersion = [Select ContentDocumentId from ContentVersion where id =: content.Id];
        ContentDocumentLink docLink = new ContentDocumentLink();
        docLink.LinkedEntityId = caseInt.Id;
        docLink.ContentDocumentId = conVersion.ContentDocumentId;
        docLink.ShareType = 'V';
        insert docLink;
        SLA_Threshold_Warning__c slaThreshold = SLA_Threshold_Warning__c.getOrgDefaults();
        slaThreshold.Stage_SLA_Threshold_1__c = .5;
        slaThreshold.Stage_SLA_Threshold_2__c = .75;
        slaThreshold.Stage_SLA_Threshold_3__c = 1;
        slaThreshold.Case_SLA_Threshold_1_Label__c = '50%';
        slaThreshold.Case_SLA_Threshold_2_Label__c = '75%';
        slaThreshold.Case_SLA_Threshold_3_Label__c = '100%';
        slaThreshold.Case_SLA_Threshold_1__c = .5;
        slaThreshold.Case_SLA_Threshold_2__c = .75;
        slaThreshold.Case_SLA_Threshold_3__c = 1;
        upsert slaThreshold SLA_Threshold_Warning__c.Id;
	 }
    @IsTest
    static void testPreClsStatementStageApexClass(){
        Case caseRecord = [Select id,Stage__c,CCC_External_Id__c, Previous_Stage__c,ABHFL_Case_Detail__r.As_On_Date__c  from Case limit 1];
        List<ABHFL_Payment__c> dummyPayments = new List<ABHFL_Payment__c>();
    	for (Integer i = 0; i < 5; i++) {  // Create 5 dummy payments
        	ABHFL_Payment__c payment = new ABHFL_Payment__c(
            Case__c = caseRecord.Id,
            Realization_Status__c = 'Bounce',
            Date__c = Date.Today(),
            Amount__c=5000,
            Mode_of_Payment__c='Escrow',
            Payment_Identifier__c='43234234'
            );
        dummyPayments.add(payment);
    	}
        insert dummyPayments;
        //Assertion 
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> retCls =  ABHFL_PreClsStatementStageApex.beforeStageMovement(new List<Case>{caseRecord});
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> retCls1 =  ABHFL_PreClsStatementStageApex.afterStageMovement(new List<Case>{caseRecord});
        System.assertEquals('Success',retCls.get(caseRecord.Id).Status,'Done');
        
	}
    @IsTest
    static void testPreClosureStageApexClass(){
        Case caseRecord = [Select id,Stage__c,CCC_External_Id__c,Short_URL__c,ABHFL_Case_Detail__r.Preferred_Branch__c  from Case limit 1];
        List<ABHFL_Payment__c> dummyPayments = new List<ABHFL_Payment__c>();
    	for (Integer i = 0; i < 5; i++) {  // Create 5 dummy payments
        	ABHFL_Payment__c payment = new ABHFL_Payment__c(
            Case__c = caseRecord.Id,
            Realization_Status__c = 'Bounce',
            Date__c = Date.Today(),
            Amount__c=5000,
            Mode_of_Payment__c='Escrow',
            Payment_Identifier__c='43234234'
            );
        dummyPayments.add(payment);
    	}
        insert dummyPayments;
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> retCls =  ABHFL_PreClosureStageApex.beforeStageMovement(new List<Case>{caseRecord});
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> retCls1 =  ABHFL_PreClosureStageApex.afterStageMovement(new List<Case>{caseRecord});
        System.assertEquals('Success',retCls.get(caseRecord.Id).Status,'Done');
        //for stage Hub location
        caseRecord.Stage__c='Hub Location';
        caseRecord.Stage__c='Branch';
        caseRecord.Stage__c='AOM/ROM';
        update caseRecord;
        
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> retCls2 =  ABHFL_PreClosureStageApex.beforeStageMovement(new List<Case>{caseRecord});
        System.assertEquals('Success',retCls2.get(caseRecord.Id).Status,'Done');
	}
    
    @IsTest
    static void testReqResolvedStageApexClass(){
        Case caseRecord = [Select id,Stage__c,CCC_External_Id__c  from Case limit 1];
        List<ABHFL_Payment__c> dummyPayments = new List<ABHFL_Payment__c>();
    	for (Integer i = 0; i < 5; i++) {  // Create 5 dummy payments
        	ABHFL_Payment__c payment = new ABHFL_Payment__c(
            Case__c = caseRecord.Id,
            Realization_Status__c = 'Bounce',
            Date__c = Date.Today(),
            Amount__c=5000,
            Mode_of_Payment__c='Escrow',
            Payment_Identifier__c='43234234'
            );
        dummyPayments.add(payment);
    	}
        insert dummyPayments;
        //Assertion
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> retCls =  ABHFL_ReqResolvedStageApex.beforeStageMovement(new List<Case>{caseRecord});
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> retCls1 =  ABHFL_ReqResolvedStageApex.afterStageMovement(new List<Case>{caseRecord});
        System.assertEquals('Success',retCls.get(caseRecord.Id).Status,'Done');
        
	}
    @IsTest
    static void testRequestInProgressApexClass(){
        Case caseRecord = [Select id,Stage__c,CCC_External_Id__c, AssetId,Asset.Branch__r.Branch_Queue_Id__c, Source__c  from Case limit 1];
        List<ABHFL_Payment__c> dummyPayments = new List<ABHFL_Payment__c>();
    	for (Integer i = 0; i < 5; i++) {  // Create 5 dummy payments
        	ABHFL_Payment__c payment = new ABHFL_Payment__c(
            Case__c = caseRecord.Id,
            Realization_Status__c = 'Bounce',
            Date__c = Date.Today(),
            Amount__c=5000,
            Mode_of_Payment__c='Escrow',
            Payment_Identifier__c='43234234'
            );
        dummyPayments.add(payment);
    	}
        insert dummyPayments;
        //Assertion
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> retCls =  ABHFL_requestInProgressApexClass.beforeStageMovement(new List<Case>{caseRecord});
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> retCls1 =  ABHFL_requestInProgressApexClass.afterStageMovement(new List<Case>{caseRecord});
        caseRecord.CCC_External_Id__c = 'hfl003';
        update caseRecord;
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> retCls3 =  ABHFL_requestInProgressApexClass.beforeStageMovement(new List<Case>{caseRecord});
        System.assertEquals('Success',retCls.get(caseRecord.Id).Status,'Done');
        
	}
     @IsTest
    static void testsendPaymentLinkMultiLAN(){
        Case caseRecord = [Select id,Stage__c,CCC_External_Id__c,ABHFL_Case_Detail__c  from Case limit 1];
        List<ABHFL_Payment__c> dummyPayments = new List<ABHFL_Payment__c>();
    	for (Integer i = 0; i < 5; i++) {  // Create 5 dummy payments
        	ABHFL_Payment__c payment = new ABHFL_Payment__c(
            Case__c = caseRecord.Id,
            Realization_Status__c = 'Bounce',
            Date__c = Date.Today(),
            Amount__c=5000,
            Mode_of_Payment__c='Escrow',
            Payment_Identifier__c='43234234'
            );
        dummyPayments.add(payment);
    	}
        insert dummyPayments;
        //Assertion
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> retCls =  ABHFL_sendPaymentLinkMultiLAN.beforeStageMovement(new List<Case>{caseRecord});
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> retCls1 =  ABHFL_sendPaymentLinkMultiLAN.afterStageMovement(new List<Case>{caseRecord});
        System.assertEquals('Success',retCls.get(caseRecord.Id).Status,'Done');
        
	}
}
