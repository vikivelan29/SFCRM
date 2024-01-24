@isTest
public class ABHFL_CTSTHelper_Test {
	 @TestSetup
	static void testData(){
        //Create Account
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('ABHFLLLL','Test_1');
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
    static void testPreClosurePaymentCheck(){
        Case caseRecord = [Select id from Case limit 1];
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
        //Assertion when payments are not cleared.
        ASF_CaseMovementHelper.CaseStageValidationWrapper retCls =  ABHFL_PreClosurePaymentCheck.beforeStageMovement(caseRecord);
        System.assertEquals('Error',retCls.Status,'Done');
        List<ABHFL_Payment__c> relatedPayments = [SELECT id,Realization_Status__c from ABHFL_Payment__c where case__c =: caseRecord.id];
        for(ABHFL_Payment__c pay : relatedPayments){
            pay.Realization_Status__c ='Cleared';
        }
        update relatedPayments;
        //Assertion when payments are cleared.
        ASF_CaseMovementHelper.CaseStageValidationWrapper retCls2 =  ABHFL_PreClosurePaymentCheck.beforeStageMovement(caseRecord);
        System.assertEquals('Success',retCls2.Status,'Done');
        ABHFL_PreClosurePaymentCheck.afterStageMovement(caseRecord);
        
	}
    @isTest
    static void testassignCaseToQueue(){
        Test.startTest();
        Case caseRecord = [Select id,CreatedById from Case limit 1];
        caseRecord.CCC_External_Id__c='hfl060';
        caseRecord.Source__c='Branch';
		update caseRecord;
        ABHFL_CTSTHelper.assignCaseToQueue(caseRecord);
        System.assertEquals(caseRecord.CreatedById,caseRecord.CreatedById,'Done');
        caseRecord.CCC_External_Id__c='hfl060';
        caseRecord.Source__c='Call Centre';
		update caseRecord;
        ABHFL_CTSTHelper.assignCaseToQueue(caseRecord);
        caseRecord.CCC_External_Id__c='hfl061';
		update caseRecord;
        ABHFL_CTSTHelper.assignCaseToQueue(caseRecord);
        caseRecord.CCC_External_Id__c='RRSDPRSHFC01';
        ABHFL_CTSTHelper.assignCaseToQueue(caseRecord);
        caseRecord.CCC_External_Id__c='hfcrepaprod';
		update caseRecord;
        ABHFL_CTSTHelper.assignCaseToQueue(caseRecord);
        caseRecord.Source__c='Branch';
        ABHFL_CTSTHelper.assignCaseToQueue(caseRecord);
        System.assertEquals(caseRecord.CreatedById,caseRecord.CreatedById,'Done');
        Test.stopTest();
    }
    @IsTest
    static void testRequestInProgressApexClass(){
        Case caseRecord = [Select id from Case limit 1];
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
        //Assertion for Branch Assignment
        ASF_CaseMovementHelper.CaseStageValidationWrapper retCls =  ABHFL_requestInProgressApexClass.beforeStageMovement(caseRecord);
        ASF_CaseMovementHelper.CaseStageValidationWrapper retCls1 =  ABHFL_requestInProgressApexClass.afterStageMovement(caseRecord);
        System.assertEquals('Success',retCls.Status,'Done');
        
	}
    @IsTest
    static void testBranchAssignment(){
        Case caseRecord = [Select id from Case limit 1];
        
        ABHFL_CTSTHelper.assignCaseToBranch(caseRecord);
        //System.assertEquals('Success',,'Done');
        
	}
    
}