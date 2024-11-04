@SuppressWarnings('PMD.MethodNamingConventions')
@isTest
public class ABSLI_CaseDeDupeCheck_Test {
	 @TestSetup
    static void testData(){
        //Create Account
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('ABSLI','Test_1');
        Contact  cont = ASF_TestDataFactory.insertContact('Test 1@', '');
        //Create BranchMaster
        Branch_Master__c branchMstr = new Branch_Master__c();
        branchMstr.Branch_Queue_Id__c = [Select Id from Group where Type = 'Queue' LIMIT 1].Id;
        branchMstr.UniqueKey__c = '123123';
        insert branchMstr;
        
        ASF_TestDataFactory.createCaseCategoryConfig();
        
        //Create Asset
        Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        astRec.LAN__c = 'Test';
        astRec.Branch__c = branchMstr.Id;
        astRec.Last_Disbursement_Date__c = Date.Today();
        astRec.Loan_Disbursement_Status__c = 'Complete';
        update astRec;
        
        Asset astRec1 = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        astRec1.LAN__c = 'Test1';
        astRec1.Branch__c = branchMstr.Id;
        astRec1.Last_Disbursement_Date__c = Date.Today();
        astRec1.Loan_Disbursement_Status__c = 'Complete';
        update astRec1;
        
        ABSLI_Case_Detail__c detailRec = new ABSLI_Case_Detail__c();
		detailRec.WhatsApp_Opt_Out_Indicator__c = 'true';
		detailRec.Email_Id__c = 'panigrahi@abinash.com';
		detailRec.Status_Valid_For_STP__c = true;
		insert detailRec;

		Case caseRec = ASF_TestDataFactory.createInteractionCaseRecords()[0];
		caseRec.Source__c = 'Email';
		caseRec.Business_Unit__c = 'ABSLI';
		caseRec.Status = 'Open';
		caseRec.AssetId = astRec.Id;
		caseRec.ABSLI_Case_Detail__c = detailRec.Id;
		caseRec.AccountId = accRec.Id;
		caseRec.CCC_External_Id__c = 'PNFT008';
		caseRec.Client_Code_Text__c = '8895335596';
		caseRec.Technical_Source__c = 'API';
        caseRec.Is_STP__c = true;
		update caseRec;

        //create ASF Integration
        ASF_Integration__c integ = new ASF_Integration__c();
        integ.External_Id__c = 'ASF_INT_01';
        integ.Display_Name__c = 'LOD';
        insert integ;
        
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Integration_Ext_Id__c = integ.External_Id__c;
        caseInt.Case__c = caseRec.Id;
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
    static void testDedupeForInsertAndUpdate(){
        List<Case> caseList = [SELECT Id, AccountId, AssetId, Asset.LAN__c, CCC_External_Id__c,Business_Unit__c, isClosed, Issue_Type__c, ABSLI_Case_Detail__c FROM Case WHERE Business_Unit__c='ABSLI'];
		ABSLI_CasDeDupeCheck.runDuplicateCheck(caseList);
        
        List<Case> existingSR = [SELECT ID,CaseNumber FROM Case WHERE CCC_External_Id__c ='CCC-CC-CCLTD-01'];
        Case c = new Case();
        c.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
        c.Subject = 'Test Subject';
        c.CCC_External_Id__c = 'CCC-CC-CCLTD-01';
        c.Status = 'New';
		c.Stage__c='New';
        insert c;
           try{
            ABSLI_CasDeDupeCheck.runDuplicateCheck(new List<Case>{c});
        }
        catch(exception e){
            System.assertEquals(true,e.getMessage().contains('Duplicate Case found.'),'Success');
        }
    }
    
}