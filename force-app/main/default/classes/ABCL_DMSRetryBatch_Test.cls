@IsTest
public class ABCL_DMSRetryBatch_Test {
@TestSetup
    static void setupTestData(){
        
        //Create Case Category Config Record
        ASF_TestDataFactory.createCaseCategoryConfig();
        insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                          Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                          Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
        //Create Case
        List<Case> caseRecList = ASF_TestDataFactory.createCaseRecords(2);
        
        //create ASF Integration
        ASF_Integration__c integ = new ASF_Integration__c();
        integ.External_Id__c = 'ASF_INT_01';
        integ.Display_Name__c = 'Welcome kit';
        insert integ;
        
        //create ASF Case Integration records
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
        
        ContentDocumentLink docLinkCase = new ContentDocumentLink();
        docLinkCase.LinkedEntityId = caseRecList[0].Id;
        docLinkCase.ContentDocumentId = conVersion.ContentDocumentId;
        docLinkCase.ShareType = 'V';
        insert docLinkCase;
        
        ContentDocumentLink docLinkCase2 = new ContentDocumentLink();
        docLinkCase2.LinkedEntityId = caseRecList[1].Id;
        docLinkCase2.ContentDocumentId = conVersion.ContentDocumentId;
        docLinkCase2.ShareType = 'V';
        insert docLinkCase2;
        
        Account accountInserted = ASF_TestDataFactory.insertBusinessAccount('test','test');
        Asset assetInserted = ASF_TestDataFactory.createAsset(accountInserted.Id,'SavingsAccount');
        Lead leadInserted = ASF_TestDataFactory.createSalesProspectRecord();
        assetInserted.Lead_Id__c ='Test';
        update assetInserted;
        caseRecList[0].AssetId = assetInserted.Id;
        caseRecList[0].Lead__c = leadInserted.Id;
        caseRecList[0].Nature__c = 'Query';
        caseRecList[0].Business_Unit__c = 'ABHFL';
        caseRecList[1].Lead__c = leadInserted.Id;
        update caseRecList;
    }
    
    @Istest
    static void testDMSRetryBatch(){
        List<Case> caseList = [Select id from Case limit 1];
        ASF_TriggerSkipperUtility.markTriggerRun('Case');
        caseList[0].Status = 'Closed';
        update caseList;
        Test.StartTest();
        	Database.ExecuteBatch(new ABCL_DMSRetryBatch());
        Test.StopTest();
    }
}