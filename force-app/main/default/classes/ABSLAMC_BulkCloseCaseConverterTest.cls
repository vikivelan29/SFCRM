@isTest

public with sharing class ABSLAMC_BulkCloseCaseConverterTest {
    
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
        jsonRows.put(lineitem.Id, '{"Case Number":"12345","Closure Stage(Resolved/ Unresolved)":"Resolved", "Resolution Remarks(For Resolved Stage)": "TestComments", "Close Unresolved Details(For Unresolved Stage)":"", "Close Unresolved Reason(For Unresolved Stage)"  : "", "Send Auto Communication?" : "Yes"}');
        ABSLAMC_BulkCloseCaseConverterUtility utility = new ABSLAMC_BulkCloseCaseConverterUtility();
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
        jsonRows.put(lineitem.Id, '{"Case Number":"","Closure Stage(Resolved/ Unresolved)":"Resolved", "Resolution Remarks(For Resolved Stage)": "TestComments", "Close Unresolved Details(For Unresolved Stage)":"", "Close Unresolved Reason(For Unresolved Stage)"  : "", "Send Auto Communication?" : "Yes"}');
        ABSLAMC_BulkCloseCaseConverterUtility utility = new ABSLAMC_BulkCloseCaseConverterUtility();
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
        jsonRows.put(lineitem.Id, '{"Case Number":"12345","Closure Stage(Resolved/ Unresolved)":"Open", "Resolution Remarks(For Resolved Stage)": "TestComments", "Close Unresolved Details(For Unresolved Stage)":"", "Close Unresolved Reason(For Unresolved Stage)"  : "", "Send Auto Communication?" : "Yes"}');
        ABSLAMC_BulkCloseCaseConverterUtility utility = new ABSLAMC_BulkCloseCaseConverterUtility();
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
        jsonRows.put(lineitem.Id, '{"Case Number":"12345","Closure Stage(Resolved/ Unresolved)":"Resolved", "Resolution Remarks(For Resolved Stage)": "", "Close Unresolved Details(For Unresolved Stage)":"", "Close Unresolved Reason(For Unresolved Stage)"  : "", "Send Auto Communication?" : "Yes"}');
        ABSLAMC_BulkCloseCaseConverterUtility utility = new ABSLAMC_BulkCloseCaseConverterUtility();
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
        jsonRows.put(lineitem.Id, '{"Case Number":"12345","Closure Stage(Resolved/ Unresolved)":"Unresolved", "Resolution Remarks(For Resolved Stage)": "", "Close Unresolved Details(For Unresolved Stage)":"", "Close Unresolved Reason(For Unresolved Stage)"  : "Cancelled", "Send Auto Communication?" : "Yes"}');
        ABSLAMC_BulkCloseCaseConverterUtility utility = new ABSLAMC_BulkCloseCaseConverterUtility();
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
        jsonRows.put(lineitem.Id, '{"Case Number":"12345","Closure Stage(Resolved/ Unresolved)":"Unresolved", "Resolution Remarks(For Resolved Stage)": "", "Close Unresolved Details(For Unresolved Stage)":"Not resolved", "Close Unresolved Reason(For Unresolved Stage)"  : "", "Send Auto Communication?" : "Yes"}');
        ABSLAMC_BulkCloseCaseConverterUtility utility = new ABSLAMC_BulkCloseCaseConverterUtility();
        Test.startTest();
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
        jsonRows.put(lineitem.Id, '{"Case Number":"12345","Closure Stage(Resolved/ Unresolved)":"Unresolved", "Resolution Remarks(For Resolved Stage)": "", "Close Unresolved Details(For Unresolved Stage)":"Not resolved", "Close Unresolved Reason(For Unresolved Stage)"  : "TestReason", "Send Auto Communication?" : "Yes"}');
        ABSLAMC_BulkCloseCaseConverterUtility utility = new ABSLAMC_BulkCloseCaseConverterUtility();
        Test.startTest();
        utility.convertJSONRows(jsonRows);
        Test.stopTest();
    }
    @IsTest
    static void testconvertJSONRows7(){
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'test';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;
        ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
        lineitem.Bulk_Upload_Header__c = headObj.Id;
        insert lineitem;
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Case Number":"12345","Closure Stage(Resolved/ Unresolved)":"Unresolved", "Resolution Remarks(For Resolved Stage)": "", "Close Unresolved Details(For Unresolved Stage)":"Not resolved", "Close Unresolved Reason(For Unresolved Stage)"  : "TestReason", "Send Auto Communication?" : ""}');
        ABSLAMC_BulkCloseCaseConverterUtility utility = new ABSLAMC_BulkCloseCaseConverterUtility();
        Test.startTest();
        utility.convertJSONRows(jsonRows);
        Test.stopTest();
    }
    
    @IsTest
    static void testconvertJSONRows8(){
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'test';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;
        ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
        lineitem.Bulk_Upload_Header__c = headObj.Id;
        insert lineitem;
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Case Number":"12345","Closure Stage(Resolved/ Unresolved)":"Unresolved", "Resolution Remarks(For Resolved Stage)": "", "Close Unresolved Details(For Unresolved Stage)":"Not resolved", "Close Unresolved Reason(For Unresolved Stage)"  : "TestReason", "Send Auto Communication?" : "TestValue"}');
        ABSLAMC_BulkCloseCaseConverterUtility utility = new ABSLAMC_BulkCloseCaseConverterUtility();
        Test.startTest();
        utility.convertJSONRows(jsonRows);
        Test.stopTest();
    }
    
    @IsTest
    static void testprepareDownloadTemplate() {        
        List<String> columnNames = new List<String>{'Case Number', 'Closure Stage(Resolved/ Unresolved)', 'Resolution Remarks(For Resolved Stage)','Close Unresolved Details(For Unresolved Stage)', 'Close Unresolved Reason(For Unresolved Stage)', 'Send Auto Communication?'};
        Case caserec = [Select Id from Case LIMIT 1];
        Test.startTest();
        ABSLAMC_BulkCloseCaseConverterUtility utility = new ABSLAMC_BulkCloseCaseConverterUtility();
        utility.prepareDownloadTemplate(columnNames, 'Case', null, new List<String>{caserec.Id});
        Test.stopTest();

    }
    
    @IsTest
    static void testprepareDownloadTemplate2() {        
        List<String> columnNames = new List<String>{'Case Number', 'Closure Stage(Resolved/ Unresolved)', 'Resolution Remarks(For Resolved Stage)','Close Unresolved Details(For Unresolved Stage)', 'Close Unresolved Reason(For Unresolved Stage)', 'Send Auto Communication?'};
        ListView lv = [Select Id, SobjectType, DeveloperName from ListView where SobjectType = 'Case' and DeveloperName = 'RecentlyViewedCases' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new ASF_ListViewAPIMock());
        Test.startTest();
        ABSLAMC_BulkCloseCaseConverterUtility utility = new ABSLAMC_BulkCloseCaseConverterUtility();
        utility.prepareDownloadTemplate(columnNames, 'Case', lv.Id, null);
        Test.stopTest();

    }
    
    @IsTest
    static void testprepareCtstData() {        
        List<String> columnNames = new List<String>();
        Test.startTest();
        ABSLAMC_BulkCloseCaseConverterUtility utility = new ABSLAMC_BulkCloseCaseConverterUtility();
        utility.prepareCtstData(columnNames, 'ABSLAMC');
        Test.stopTest();

    }

}