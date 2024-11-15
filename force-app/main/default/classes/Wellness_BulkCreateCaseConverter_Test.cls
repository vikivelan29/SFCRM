/**
 * @description       : Test class for Wellness_BulkCreateCaseConverterUtility
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-15-2024
 * @last modified by  : rsinghnagar@salesforce.com
**/
@IsTest
public class Wellness_BulkCreateCaseConverter_Test {
    @testSetup
    static void setupTestData(){
        List<sObject> ls = Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
        Account accRec = ASF_TestDataFactory.insertPersonAccount('FirstName','LastName','Test_145');
        Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        astRec.ContractId__c = 'LAN1234';
        astRec.Business_Unit__c = System.Label.Wellness_BU;
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
        jsonRows.put(lineitem.Id, '{"Contract Number":"LAN1234","Member Id/Customer Number":"Test_145","Issue Type Code":"XCCC-CC-CCLTD-01","Source":"Email", "Description":"DescriptionXYZ","Block Customer Communication":"Email;SMS"}');
        Wellness_BulkCreateCaseConverterUtility utility = new Wellness_BulkCreateCaseConverterUtility();
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
        jsonRows.put(lineitem.Id, '{"Contract Number":"LAN1234","Member Id/Customer Number":"Test_145","Issue Type Code":"CCC-CC-CCLTD-01","Source":"Email", "Description":"DescriptionXYZ","Block Customer Communication":"Email;SMS"}');
        Wellness_BulkCreateCaseConverterUtility utility = new Wellness_BulkCreateCaseConverterUtility();
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
        jsonRows.put(lineitem.Id, '{"Contract Number":"LAN1234","Issue Type Code":"","Member Id/Customer Number":"","Source":"Email", "Description":"DescriptionXYZ","Block Customer Communication":"Email;SMS"}');
        Wellness_BulkCreateCaseConverterUtility utility = new Wellness_BulkCreateCaseConverterUtility();
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
        jsonRows.put(lineitem.Id, '{"Contract Number":"","Member Id/Customer Number":"Test_145","Issue Type Code":"CCC-CC-CCLTD-01","Source":"Email", "Description":"DescriptionXYZ","Block Customer Communication":"Email;SMS"}');
        Wellness_BulkCreateCaseConverterUtility utility = new Wellness_BulkCreateCaseConverterUtility();
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
        jsonRows.put(lineitem.Id, '{"Contract Number":"LAN1234","Member Id/Customer Number":"Test_145","Issue Type Code":"CCC-CC-CCLTD-01","Source":"", "Description":"DescriptionXYZ","Block Customer Communication":"Email;SMS"}');
        Wellness_BulkCreateCaseConverterUtility utility = new Wellness_BulkCreateCaseConverterUtility();
        Test.startTest();
        utility.convertJSONRows(jsonRows);
        jsonRows.put(lineitem.Id, '{"Contract Number":"LAN124","Member Id/Customer Number":"Test_145","Issue Type Code":"CCC-CC-CCLTD-01","Source":"", "Description":"DescriptionXYZ","Block Customer Communication":"Email;SMS"}');
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
        jsonRows.put(lineitem.Id, '{"Contract Number":"LAN1234","Member Id/Customer Number":"Test_145","Issue Type Code":"CCC-CC-CCLTD-01","Source":"Email", "Description":""}');
        Wellness_BulkCreateCaseConverterUtility utility = new Wellness_BulkCreateCaseConverterUtility();
        Test.startTest();
        utility.convertJSONRows(jsonRows);
        Test.stopTest();
    } 

    @IsTest
    static void testprepareDownloadTemplate() {        
        List<String> columnNames = new List<String>{'Contract Number','Member Id/Customer Number','Issue Type Code','Source', 'Description','Block Customer Communication'};
        Case caserec = [Select Id from Case LIMIT 1];
        Test.startTest();
        Wellness_BulkCreateCaseConverterUtility utility = new Wellness_BulkCreateCaseConverterUtility();
        List<Map<String,String>> result = utility.prepareDownloadTemplate(columnNames, 'Case', null, new List<String>{caserec.Id});
        Assert.isNotNull(result);
        Test.stopTest();

    }

    @IsTest
    static void testprepareDownloadTemplate2() {        
        List<String> columnNames = new List<String>{'Contract Number','Member Id/Customer Number','Issue Type Code','Source', 'Description','Block Customer Communication'};
        ListView lv = [Select Id, SobjectType, DeveloperName from ListView where SobjectType = 'Case' and DeveloperName = 'RecentlyViewedCases' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new ASF_ListViewAPIMock());
        Test.startTest();
        Wellness_BulkCreateCaseConverterUtility utility = new Wellness_BulkCreateCaseConverterUtility();
        utility.prepareDownloadTemplate(columnNames, 'Case', lv.Id, null);
        Test.stopTest();

    }
}