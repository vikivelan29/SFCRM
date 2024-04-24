@IsTest
public with sharing class ABHFL_BulkCloseCaseConverterUtilityTest {
    @testSetup
    static void setupTestData(){
        List<sObject> ls = Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('ABHFLLLL','Test_1');
        Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        astRec.LAN__c = 'LAN1234';
        astRec.Last_Disbursement_Date__c = Date.Today();
        update astRec;
        ASF_TestDataFactory.createCaseCategoryConfig();
        ASF_TestDataFactory.createC3WithPrePopulateIntegrations();
        ASF_TestDataFactory.createCaseRecords(0);
        
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
        case caserec = [select CaseNumber from Case LIMIT 1];
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'","Resolution Comments":"", "Stage":"Unresolved","Close Unresolved Reason":"Others", "Close Unresolved Details":"Sample text"}');
        ABHFL_BulkCloseCaseConverterUtility utility = new ABHFL_BulkCloseCaseConverterUtility();
        Test.startTest();
        utility.convertJSONRows(jsonRows);
        Test.stopTest();
    }

    @IsTest
    static void testconvertJSONRows2(){
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'test';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;
        ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
        lineitem.Bulk_Upload_Header__c = headObj.Id;
        insert lineitem;
        case caserec = [select CaseNumber from Case LIMIT 1];
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'","Resolution Comments":"Comments", "Stage":"Resolved","Close Unresolved Reason":"", "Close Unresolved Details":""}');
        ABHFL_BulkCloseCaseConverterUtility utility = new ABHFL_BulkCloseCaseConverterUtility();
        Test.startTest();
        utility.convertJSONRows(jsonRows);
        Test.stopTest();
    }

    @IsTest
    static void testconvertJSONRows3(){
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'test';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;
        ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
        lineitem.Bulk_Upload_Header__c = headObj.Id;
        insert lineitem;
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Case number":"INVALID","Resolution Comments":"Comments", "Stage":"Resolved","Close Unresolved Reason":"", "Close Unresolved Details":""}');
        ABHFL_BulkCloseCaseConverterUtility utility = new ABHFL_BulkCloseCaseConverterUtility();
        Test.startTest();
        utility.convertJSONRows(jsonRows);
        Test.stopTest();
    }

    @IsTest
    static void testprepareDownloadTemplate() {        
        List<String> columnNames = new List<String>{'Case number','Resolution Comments', 'Stage', 'Close Unresolved Reason', 'Close Unresolved Details'};
        Case caserec = [Select Id from Case LIMIT 1];
        Test.startTest();
        ABHFL_BulkCloseCaseConverterUtility utility = new ABHFL_BulkCloseCaseConverterUtility();
        utility.prepareDownloadTemplate(columnNames, 'Case', null, new List<String>{caserec.Id});
        Test.stopTest();

    }

    @IsTest
    static void testprepareDownloadTemplate2() {        
        List<String> columnNames = new List<String>{'Case number','Resolution Comments', 'Stage', 'Close Unresolved Reason', 'Close Unresolved Details'};
        ListView lv = [Select Id, SobjectType, DeveloperName from ListView where SobjectType = 'Case' and DeveloperName = 'RecentlyViewedCases' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new ASF_ListViewAPIMock());
        Test.startTest();
        ABHFL_BulkCloseCaseConverterUtility utility = new ABHFL_BulkCloseCaseConverterUtility();
        utility.prepareDownloadTemplate(columnNames, 'Case', lv.Id, null);
        Test.stopTest();

    }
}