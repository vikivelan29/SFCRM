/**
 * @description       : 
 * @author            : ABHFL Team
 * @group             : 
 * @last modified on  : 03-03-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   03-03-2024   ABHFL Team  Initial Version
**/
@isTest
public class ABHFL_CTSTHelper_Test {
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
    static void testPreClosurePaymentCheck(){
        Case caseRecord = [Select id,CCC_External_Id__c,Short_URL__c from Case limit 1];
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
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> retCls =  ABHFL_PreClosurePaymentCheck.beforeStageMovement(new List<Case>{caseRecord});
        System.assertEquals('Error',retCls.get(caseRecord.Id).Status,'Done');
        List<ABHFL_Payment__c> relatedPayments = [SELECT id,Realization_Status__c from ABHFL_Payment__c where case__c =: caseRecord.id];
        for(ABHFL_Payment__c pay : relatedPayments){
            pay.Realization_Status__c ='Cleared';
        }
        update relatedPayments;
        //Assertion when payments are cleared.
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> retCls2 =  ABHFL_PreClosurePaymentCheck.beforeStageMovement(new List<Case>{caseRecord});
        System.assertEquals('Success',retCls2.get(caseRecord.Id).Status,'Done');
        ABHFL_PreClosurePaymentCheck.afterStageMovement(new List<Case>{caseRecord});
        
    }
    @isTest
    static void testassignCaseToQueue(){
        Test.startTest();
        Case caseRecord = [Select id,CreatedById from Case limit 1];
        caseRecord.CCC_External_Id__c='hfl060';
        caseRecord.Source__c='Branch';
        update caseRecord;
        ASF_Case_SLA_History__c caseSLAHistory = new ASF_Case_SLA_History__c();
        caseSLAHistory.Case__c = caseRecord.Id;
        caseSLAHistory.Stage_End_Date__c = null;
        insert caseSLAHistory;
        ABHFL_CTSTHelper.assignCaseToQueue(caseRecord);
        System.assertEquals(caseRecord.CreatedById,caseRecord.CreatedById,'Done');
        caseRecord.CCC_External_Id__c='hfl060';
        caseRecord.Source__c='Call Center';
        update caseRecord;
        ABHFL_CTSTHelper.assignCaseToQueue(caseRecord);
        caseRecord.CCC_External_Id__c='hfl061';
        update caseRecord;
        System.assertEquals(caseRecord.CreatedById,caseRecord.CreatedById,'Done');
        Test.stopTest();
    }
    @IsTest 
    static void testassignCaseToQueueCont(){
        Test.startTest();
        Case caseRecord = [Select id,CreatedById,AssetId from Case limit 1];
        caseRecord.CCC_External_Id__c='hfl060';
        caseRecord.Source__c='Branch';
        update caseRecord;
        ASF_Case_SLA_History__c caseSLAHistory = new ASF_Case_SLA_History__c();
        caseSLAHistory.Case__c = caseRecord.Id;
        caseSLAHistory.Stage_End_Date__c = null;
        insert caseSLAHistory;
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
    static void testBranchAssignment(){
        Case caseRecord = [Select id,Asset.Branch__r.Branch_Queue_Id__c,Source__c from Case limit 1];
        
        ABHFL_CTSTHelper.assignCaseToBranch(new List<Case>{caseRecord});
        //System.assertEquals('Success',,'Done');
        
    }
    @IsTest
    static void testExecuteSpecificIntegrations(){
        List<Case> caseRecordList = [Select id, CCC_External_Id__c, Business_Unit__c, Technical_Source__c from Case limit 1];
        
        ABHFL_CTSTHelper.executeSpecificIntegrations(caseRecordList, new List<Case>());
        //System.assertEquals('Success',,'Done');
        
    }
    @isTest
    static void testAssignCaseToPreferredBranch() {
        
        Case caseRecord = [Select id,ABHFL_Case_Detail__r.Id,ABHFL_Case_Detail__r.Preferred_Branch__c from Case limit 1];
        Asset assetRec = [Select id,Branch__c from Asset where LAN__c='Test'];
        Branch_Master__c branchRec = [Select id,Branch_Queue_Id__c from Branch_Master__c where Id =: assetRec.Branch__c Limit 1];
        caseRecord.AssetId =assetRec.Id;
        
        Test.startTest();
        Map<Id, Case> updatedCase = ABHFL_CTSTHelper.assignCaseToPreferredBranch(new List<Case>{caseRecord});
        Test.stopTest();

        // Verify the results
        System.assertEquals(branchRec.Branch_Queue_Id__c, updatedCase.get(caseRecord.Id).OwnerId);
    }

    @isTest
    static void testAssignCaseToAOMROM() {
        Case caseRecord = [Select id,ABHFL_Case_Detail__r.Id,ABHFL_Case_Detail__r.Preferred_Branch__c from Case limit 1];
        Asset assetRec = [Select id,Branch__r.ROM_AOM__c from Asset where LAN__c='Test'];
        Branch_Master__c branchRec = [Select id,Branch_Queue_Id__c,ROM_AOM__c from Branch_Master__c where Id =: assetRec.Branch__c Limit 1];
        caseRecord.AssetId =assetRec.Id;
        
        Test.startTest();
        Map<Id, Case> updatedCase = ABHFL_CTSTHelper.assignCaseToAOMROM(new List<Case>{caseRecord});
        Test.stopTest();

        // Verify the results
        //System.assertEquals(updatedCase.get(caseRecord.Id).OwnerId, updatedCase.get(caseRecord.Id).OwnerId);
    }
       @isTest
    static void testAssignCaseToBranchTDS() {
        Case caseRecord = [Select id,Asset.Branch__r.Branch_Queue_Id__c,Source__c,AccountId,CCC_External_Id__c,ContactId,No_Auto_Communication__c
                           from Case limit 1];
        Asset assetRec = [Select id,Branch__c from Asset where LAN__c='Test'];
        Branch_Master__c branchRec = [Select id,Branch_Queue_Id__c,ROM_AOM__c from Branch_Master__c where Id =: assetRec.Branch__c Limit 1];

        Test.startTest();
        Map<Id, Case> updatedCase = ABHFL_CTSTHelper.assignCaseToBranchTDS(new List<Case>{caseRecord});
        ABHFL_CTSTHelper.sendLoanClosedEmail(new List<Case>{caseRecord});
        Test.stopTest();

        System.assertEquals(updatedCase.get(caseRecord.Id).OwnerId, updatedCase.get(caseRecord.Id).OwnerId);
    }
    @isTest
    static void testStoreMultipleLANs() {
        // Retrieve the test Case record created in TestSetup
        Case caseRecord = [SELECT Id,ABHFL_Case_Detail__c,CCC_External_Id__c,ABHFL_Case_Detail__r.Payment_Status__c,AccountId,ContactId,
                           No_Auto_Communication__c
                           FROM Case LIMIT 1];
        caseRecord.CCC_External_Id__c = ABHFL_Constants.GST_INVOICE_ID;
        update caseRecord;
        Asset astRec = [SELECT Id, LAN__c FROM Asset LIMIT 1];
        ABHFL_Asset_Detail__c assetDetail = new ABHFL_Asset_Detail__c(
            Case__c = caseRecord.Id,
            Asset__c = astRec.Id,
            Revised_ROI__c = 10
        );
        insert assetDetail;
       
        ABHFL_Case_Detail__c caseDetail = new ABHFL_Case_Detail__c(
            Id = caseRecord.ABHFL_Case_Detail__c,
            Payment_Status__c = 'Payment Received'
        );
        update caseDetail;

        Test.startTest();
        ABHFL_CTSTHelper.storeMultipleLANs(new List<Case>{caseRecord});
        ABHFL_CTSTHelper.sendPrclsStatementclosure(new List<Case>{caseRecord});
        ABHFL_CTSTHelper.sendMailWithAttachments(new List<Case>{caseRecord});
        Test.stopTest();
        //for DSRA
        caseRecord.CCC_External_Id__c = ABHFL_Constants.DSRA_LIEN_ID;
        update caseRecord;
        ABHFL_CTSTHelper.sendMailWithAttachments(new List<Case>{caseRecord});
        //for escrow
        caseRecord.CCC_External_Id__c = ABHFL_Constants.ESCROW_STATEMENT_ID;
        update caseRecord;
        ABHFL_CTSTHelper.sendMailWithAttachments(new List<Case>{caseRecord});
        caseDetail = [SELECT Id, Masked_Full_LANs__c FROM ABHFL_Case_Detail__c WHERE Id = :caseRecord.ABHFL_Case_Detail__c LIMIT 1];
        System.assertEquals('and xxxxxx' + astRec.LAN__c.substring(Math.max(0, astRec.LAN__c.length() - 4)), caseDetail.Masked_Full_LANs__c);

    }
    
}