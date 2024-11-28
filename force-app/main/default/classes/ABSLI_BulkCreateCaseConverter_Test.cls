/**
 * @description       : Test class for ABSLI_BulkCreateCaseConverterUtility
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-Jul-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@IsTest
public class ABSLI_BulkCreateCaseConverter_Test {
    @testSetup
    static void setupTestData(){
        List<sObject> ls = Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('ABSLI','Test_1');
        Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        astRec.Policy_No__c = 'LAN1234';
        astRec.Business_Unit__c = ASF_Constants.ABSLI_BU;
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
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Policy Number":"LAN1234","Issue Code":"XCCC-CC-CCLTD-01", "Issue Type Dropdown":"", "Source":"Email", "Description":"DescriptionXYZ"}');
        ABSLI_BulkCreateCaseConverterUtility utility = new ABSLI_BulkCreateCaseConverterUtility();
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
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Policy Number":"LAN1234","Issue Code":"CCC-CC-CCLTD-01", "Issue Type Dropdown":"", "Source":"Email", "Description":"DescriptionXYZ"}');
        ABSLI_BulkCreateCaseConverterUtility utility = new ABSLI_BulkCreateCaseConverterUtility();
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
        jsonRows.put(lineitem.Id, '{"Policy Number":"LAN1234","Issue Code":"", "Issue Type Dropdown":"", "Source":"Email", "Description":"DescriptionXYZ"}');
        ABSLI_BulkCreateCaseConverterUtility utility = new ABSLI_BulkCreateCaseConverterUtility();
        Test.startTest();
        utility.convertJSONRows(jsonRows);
        Test.stopTest();
    } 
    @IsTest
    static void testconvertJSONRows4(){
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'test';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;
        ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
        lineitem.Bulk_Upload_Header__c = headObj.Id;
        insert lineitem;
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Policy Number":"","Issue Code":"CCC-CC-CCLTD-01", "Issue Type Dropdown":"", "Source":"Email", "Description":"DescriptionXYZ"}');
        ABSLI_BulkCreateCaseConverterUtility utility = new ABSLI_BulkCreateCaseConverterUtility();
        Test.startTest();
        utility.convertJSONRows(jsonRows);
        Test.stopTest();
    } 
    @IsTest
    static void testconvertJSONRows5(){
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'test';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;
        ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
        lineitem.Bulk_Upload_Header__c = headObj.Id;
        insert lineitem;
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Policy Number":"LAN1234","Issue Code":"CCC-CC-CCLTD-01", "Issue Type Dropdown":"", "Source":"", "Description":"DescriptionXYZ"}');
        ABSLI_BulkCreateCaseConverterUtility utility = new ABSLI_BulkCreateCaseConverterUtility();
        Test.startTest();
        utility.convertJSONRows(jsonRows);
        jsonRows.put(lineitem.Id, '{"Policy Number":"LAN124","Issue Code":"CCC-CC-CCLTD-01", "Issue Type Dropdown":"", "Source":"", "Description":"DescriptionXYZ"}');
        utility.convertJSONRows(jsonRows);
        Test.stopTest();
    } 
    @IsTest
    static void testconvertJSONRows6(){
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'test';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;
        ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
        lineitem.Bulk_Upload_Header__c = headObj.Id;
        insert lineitem;
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Policy Number":"LAN1234","Issue Code":"CCC-CC-CCLTD-01", "Issue Type Dropdown":"", "Source":"Email", "Description":""}');
        ABSLI_BulkCreateCaseConverterUtility utility = new ABSLI_BulkCreateCaseConverterUtility();
        Test.startTest();
        utility.convertJSONRows(jsonRows);
        Test.stopTest();
    } 

    @IsTest
    static void testprepareDownloadTemplate() {        
        List<String> columnNames = new List<String>{'Policy Number','Issue Code', 'Issue Type Dropdown', 'Source', 'Description'};
        Case caserec = [Select Id from Case LIMIT 1];
        Test.startTest();
        ABSLI_BulkCreateCaseConverterUtility utility = new ABSLI_BulkCreateCaseConverterUtility();
        List<Map<String,String>> result = utility.prepareDownloadTemplate(columnNames, 'Case', null, new List<String>{caserec.Id});
        Assert.isNotNull(result);
        Test.stopTest();

    }
    @IsTest
    static void testprepareDownloadCtst() {        
        List<String> columnNames = new List<String>{'Issue Code', 'Case Type', 'Sub Type', 'Nature','Issue Type'};
        ASF_Case_Category_Config__c ccccrec = [Select Id, Business_Unit__c from ASF_Case_Category_Config__c LIMIT 1];
        ccccrec.Business_Unit__c = 'ABSLI';
        update ccccrec;
        Test.startTest();
        ABSLI_BulkCreateCaseConverterUtility utility = new ABSLI_BulkCreateCaseConverterUtility();
        List<Map<String,String>> result = utility.prepareCtstData(columnNames, 'ABSLI');
        Assert.isNotNull(result);
        Test.stopTest();

    }

    @IsTest
    static void testprepareDownloadTemplate2() {        
        List<String> columnNames = new List<String>{'Policy Number','Issue Code', 'Issue Type Dropdown', 'Source', 'Description'};
        ListView lv = [Select Id, SobjectType, DeveloperName from ListView where SobjectType = 'Case' and DeveloperName = 'RecentlyViewedCases' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new ASF_ListViewAPIMock());
        Test.startTest();
        ABSLI_BulkCreateCaseConverterUtility utility = new ABSLI_BulkCreateCaseConverterUtility();
        utility.prepareDownloadTemplate(columnNames, 'Case', lv.Id, null);
        Test.stopTest();

    }
}