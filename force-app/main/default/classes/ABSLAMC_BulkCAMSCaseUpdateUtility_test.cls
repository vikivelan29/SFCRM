/**
 * @description       : Test class for ABSLAMC_BulkCAMSCaseUpdateConvrtrUtility
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-Jul-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@IsTest
public with sharing class ABSLAMC_BulkCAMSCaseUpdateUtility_test {
 
    @testSetup
    static void setupTestData(){
        ASF_TestDataFactory.createCaseCategoryConfig();
        ASF_TestDataFactory.createC3WithPrePopulateIntegrations();
        ASF_TestDataFactory.createCaseRecords(0);
        
    }
    
    @IsTest
    static void testconvertJSONRows_CaseNumberRequired(){
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'test';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;
        ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
        lineitem.Bulk_Upload_Header__c = headObj.Id;
        insert lineitem;
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Case Number":"","CAMS SEBI Reportable Flag":"yes", "CAMS SEBI Reportable Category":"some text"}');
        ABSLAMC_BulkCAMSCaseUpdateConvrtrUtility update_utility = new ABSLAMC_BulkCAMSCaseUpdateConvrtrUtility();
        Test.startTest();
        ASF_BulkCaseProcessorUtility.ConvertionResult resultWrapper = update_utility.convertJSONRows(jsonRows);
        System.assertEquals(resultWrapper.resultRecords.IsEmpty(), true, 'result record should be empty.');
        System.assertEquals(resultWrapper.resultJSONMapRows.get(lineitem.Id).get('Message'), 'Case number is required', 'Case number is required');
        Test.stopTest();
    }
    
    @IsTest
    static void testconvertJSONRows_ReportableFlagRequired(){
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'test';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;
        ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
        lineitem.Bulk_Upload_Header__c = headObj.Id;
        insert lineitem;
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Case Number":"123445","CAMS SEBI Reportable Flag":"", "CAMS SEBI Reportable Category":"some text"}');
        ABSLAMC_BulkCAMSCaseUpdateConvrtrUtility update_utility = new ABSLAMC_BulkCAMSCaseUpdateConvrtrUtility();
        Test.startTest();
        ASF_BulkCaseProcessorUtility.ConvertionResult resultWrapper = update_utility.convertJSONRows(jsonRows);
        System.assertEquals(resultWrapper.resultRecords.IsEmpty(), true, 'result record should be empty.');
        System.assertEquals(resultWrapper.resultJSONMapRows.get(lineitem.Id).get('Message'), 'CAMS SEBI Reportable Flag is required', 'CAMS SEBI Reportable Flag is required');
        Test.stopTest();
    }
    
    @IsTest
    static void testconvertJSONRows_ReportableCategoryRequired(){
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'test';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;
        ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
        lineitem.Bulk_Upload_Header__c = headObj.Id;
        insert lineitem;
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Case Number":"123445","CAMS SEBI Reportable Flag":"yes", "CAMS SEBI Reportable Category":""}');
        ABSLAMC_BulkCAMSCaseUpdateConvrtrUtility update_utility = new ABSLAMC_BulkCAMSCaseUpdateConvrtrUtility();
        Test.startTest();
        ASF_BulkCaseProcessorUtility.ConvertionResult resultWrapper = update_utility.convertJSONRows(jsonRows);
        System.assertEquals(resultWrapper.resultRecords.IsEmpty(), true, 'result record should be empty.');
        System.assertEquals(resultWrapper.resultJSONMapRows.get(lineitem.Id).get('Message'), 'CAMS SEBI Reportable Category is required', 'CAMS SEBI Reportable Category is required');
        Test.stopTest();
    }
    
    
    @IsTest
    static void testconvertJSONRows_ReportableFlagMustBeYesOrNo(){
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'test';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;
        ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
        lineitem.Bulk_Upload_Header__c = headObj.Id;
        insert lineitem;
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Case Number":"123445","CAMS SEBI Reportable Flag":"true", "CAMS SEBI Reportable Category":"some text"}');
        ABSLAMC_BulkCAMSCaseUpdateConvrtrUtility update_utility = new ABSLAMC_BulkCAMSCaseUpdateConvrtrUtility();
        Test.startTest();
        ASF_BulkCaseProcessorUtility.ConvertionResult resultWrapper = update_utility.convertJSONRows(jsonRows);
        System.assertEquals(resultWrapper.resultRecords.IsEmpty(), true, 'result record should be empty.');
        System.assertEquals(resultWrapper.resultJSONMapRows.get(lineitem.Id).get('Message'), 'CAMS SEBI Reportable flag should be yes or no', 'CAMS SEBI Reportable flag should be yes or no');
        Test.stopTest();
    }
    
    
    @IsTest
    static void testprepareDownloadTemplate() {        
        List<String> columnNames = new List<String>{'Case Number','CAMS SEBI Reportable Flag','CAMS SEBI Reportable Category'};
        Case caserec = [Select Id from Case LIMIT 1];
        Test.startTest();
        ABSLAMC_BulkCAMSCaseUpdateConvrtrUtility camsutility = new ABSLAMC_BulkCAMSCaseUpdateConvrtrUtility();
        camsutility.prepareDownloadTemplate(columnNames, 'Case', null, new List<String>{caserec.Id});
        Test.stopTest();
    }
    
    @IsTest
    static void testconvertJSONRows(){
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'test';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;
        ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
        lineitem.Bulk_Upload_Header__c = headObj.Id;
        insert lineitem;
        ABSLAMC_Case_Detail__c casedetailObj = new ABSLAMC_Case_Detail__c(Caller_Type__c = 'Investor');
        insert casedetailObj;
        case caseObj = [SELECT id, CaseNumber, ABSLAMC_Case_Detail__c from case limit 1];
        caseObj.ABSLAMC_Case_Detail__c = casedetailObj.Id;
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Case Number":"'+caseObj.CaseNumber+'","CAMS SEBI Reportable Flag":"Yes", "CAMS SEBI Reportable Category":"some text"}');
        ABSLAMC_BulkCAMSCaseUpdateConvrtrUtility update_utility = new ABSLAMC_BulkCAMSCaseUpdateConvrtrUtility();
        Test.startTest();
        ASF_BulkCaseProcessorUtility.ConvertionResult resultWrapper = update_utility.convertJSONRows(jsonRows);
        System.assertEquals(resultWrapper.resultRecords.IsEmpty(), false, 'result record should not be empty.');
        Test.stopTest();
    }
    
    
    @IsTest
    static void testprepareDownloadTemplate2() {        
        List<String> columnNames = new List<String>{'Case Number','CAMS SEBI Reportable Flag','CAMS SEBI Reportable Category'};
        ListView lv = [Select Id, SobjectType, DeveloperName from ListView where SobjectType = 'Case' and DeveloperName = 'RecentlyViewedCases' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new ASF_ListViewAPIMock());
        Test.startTest();
        ABSLAMC_BulkCAMSCaseUpdateConvrtrUtility utility = new ABSLAMC_BulkCAMSCaseUpdateConvrtrUtility();
        utility.prepareDownloadTemplate(columnNames, 'Case', lv.Id, null);
        Test.stopTest();

    }

}