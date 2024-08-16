/**
 * @description       : Test class for ABSLI_BulkCreateCaseConverterUtility
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-Jul-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@IsTest
public class ABSLI_BulkCloseCaseConverter_Test {
	@testSetup
    static void setupTestData(){
        List<sObject> ls = Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('ABSLI','Test_1');
        Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        astRec.Policy_No__c = 'LAN1234';
        astRec.Business_Unit__c = ASF_Constants.ABSLI_BU;
        astRec.Last_Disbursement_Date__c = Date.Today();
        update astRec;
        ABSLI_Case_Detail__c relRec = new ABSLI_Case_Detail__c(Address_Line_1__c = 'test');
        insert relRec;
        ASF_TestDataFactory.createCaseCategoryConfig();
        ASF_TestDataFactory.createC3WithPrePopulateIntegrations();
        ASF_TestDataFactory.createCaseRecords(0);
        Case caseRec = [Select CaseNumber from Case LIMIT 1];
        caseRec.ABSLI_Case_Detail__c = [Select Id from ABSLI_Case_Detail__c LIMIT 1].Id;
        caseRec.Nature__c = 'Request';
        update caseRec;
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
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'","Team Resolution Status":"Unresolved", "Resolution Comments":"Age Proof- Unclear", "Reason for Delay":"Delay reason", "RCA Comments If any":"Sample text"}');
        ABSLI_BulkCloseCaseConverterUtility utility = new ABSLI_BulkCloseCaseConverterUtility();
        Test.startTest();
        utility.convertJSONRows(jsonRows);
        Test.stopTest();
    }
    
    @IsTest
    static void testconvertJSONRowsResolved(){
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
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'","Team Resolution Status":"Resolved", "Resolution Comments":"Email sent to Customer", "Reason for Delay":"Delay reason", "RCA Comments If any":"Sample text"}');
        ABSLI_BulkCloseCaseConverterUtility utility = new ABSLI_BulkCloseCaseConverterUtility();
        Test.startTest();
        utility.convertJSONRows(jsonRows);
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'","Team Resolution Status":"Resolved", "Resolution Comments":"Email sent to Customer", "Reason for Delay":"Delay reason", "RCA Comments If any":"Sample text"}');
        utility.convertJSONRows(jsonRows);
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'","Team Resolution Status":"test", "Resolution Comments":"Email sent to Customer", "Reason for Delay":"Delay reason", "RCA Comments If any":"Sample text"}');
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
        case caserec = [select CaseNumber from Case LIMIT 1];
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Case number":"","Team Resolution Status":"Resolved", "Resolution Comments":"Email sent to Customer", "Reason for Delay":"Delay reason", "RCA Comments If any":"Sample text"}');
        ABSLI_BulkCloseCaseConverterUtility utility = new ABSLI_BulkCloseCaseConverterUtility();
        Test.startTest();
        utility.convertJSONRows(jsonRows);
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'","Team Resolution Status":"", "Resolution Comments":"Email sent to Customer", "Reason for Delay":"Delay reason", "RCA Comments If any":"Sample text"}');
        utility.convertJSONRows(jsonRows);
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'","Team Resolution Status":"Resolved", "Resolution Comments":"", "Reason for Delay":"Delay reason", "RCA Comments If any":"Sample text"}');
        utility.convertJSONRows(jsonRows);
        Test.stopTest();
    }

    @IsTest
    static void testprepareDownloadTemplate() {        
        List<String> columnNames = new List<String>{'Case number','Team Resolution Status', 'Resolution Comments', 'Reason for Delay', 'RCA Comments If any'};
        Case caserec = [Select Id from Case LIMIT 1];
        Test.startTest();
        ABSLI_BulkCloseCaseConverterUtility utility = new ABSLI_BulkCloseCaseConverterUtility();
        utility.prepareDownloadTemplate(columnNames, 'Case', null, new List<String>{caserec.Id});
        utility.prepareCtstData(new List<String>{'Id'},'ABSLI');
        Test.stopTest();

    }

    @IsTest
    static void testprepareDownloadTemplate2() {        
        List<String> columnNames = new List<String>{'Case number','Team Resolution Status', 'Resolution Comments', 'Reason for Delay', 'RCA Comments If any'};
        ListView lv = [Select Id, SobjectType, DeveloperName from ListView where SobjectType = 'Case' and DeveloperName = 'RecentlyViewedCases' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new ASF_ListViewAPIMock());
        Test.startTest();
        ABSLI_BulkCloseCaseConverterUtility utility = new ABSLI_BulkCloseCaseConverterUtility();
        utility.prepareDownloadTemplate(columnNames, 'Case', lv.Id, null);
        Test.stopTest();

    }
}