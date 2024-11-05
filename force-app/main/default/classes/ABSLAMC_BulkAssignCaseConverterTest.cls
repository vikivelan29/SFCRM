@IsTest

public with sharing class ABSLAMC_BulkAssignCaseConverterTest {
    
    @testSetup
    static void setupTestData(){
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
        jsonRows.put(lineitem.Id, '{"Case Number":"12345","Owner Team":"", "Owner AD ID": "12345"}');
        ABSLAMC_BulkAssignCaseConverterUtility utility = new ABSLAMC_BulkAssignCaseConverterUtility();
        Test.startTest();
        utility.convertJSONRows(jsonRows);
        Test.stopTest();
    }
    @IsTest
    static void testconvertJSONRows1(){
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'test';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;
        ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
        lineitem.Bulk_Upload_Header__c = headObj.Id;
        insert lineitem;
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Case Number":"","Owner Team":"TestTeam", "Owner AD ID": "12345"}');
        ABSLAMC_BulkAssignCaseConverterUtility utility = new ABSLAMC_BulkAssignCaseConverterUtility();
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
        jsonRows.put(lineitem.Id, '{"Case Number":"12345","Owner Team":"", "Owner AD ID": ""}');
        ABSLAMC_BulkAssignCaseConverterUtility utility = new ABSLAMC_BulkAssignCaseConverterUtility();
        Test.startTest();
        utility.convertJSONRows(jsonRows);
        Test.stopTest();
    }
    
    @IsTest
    static void testprepareDownloadTemplate() {        
        List<String> columnNames = new List<String>{'Case Number', 'Owner Team', 'Owner AD ID'};
        Case caserec = [Select Id from Case LIMIT 1];
        Test.startTest();
        ABSLAMC_BulkAssignCaseConverterUtility utility = new ABSLAMC_BulkAssignCaseConverterUtility();
        utility.prepareDownloadTemplate(columnNames, 'Case', null, new List<String>{caserec.Id});
        Test.stopTest();

    }
    @IsTest
    static void testprepareDownloadTemplate2() {        
        List<String> columnNames = new List<String>{'Case Number', 'Owner Team', 'Owner AD ID'};
        ListView lv = [Select Id, SobjectType, DeveloperName from ListView where SobjectType = 'Case' and DeveloperName = 'RecentlyViewedCases' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new ASF_ListViewAPIMock());
        Test.startTest();
        ABSLAMC_BulkAssignCaseConverterUtility utility = new ABSLAMC_BulkAssignCaseConverterUtility();
        utility.prepareDownloadTemplate(columnNames, 'Case', lv.Id, null);
        Test.stopTest();

    }
    
    @IsTest
    static void testprepareCtstData() {        
        List<String> columnNames = new List<String>();
        Test.startTest();
        ABSLAMC_BulkAssignCaseConverterUtility utility = new ABSLAMC_BulkAssignCaseConverterUtility();
        utility.prepareCtstData(columnNames, 'ABSLAMC');
        Test.stopTest();

    }

}