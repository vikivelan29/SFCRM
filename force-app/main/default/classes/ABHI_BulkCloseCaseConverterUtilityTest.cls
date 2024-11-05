@isTest 
public class ABHI_BulkCloseCaseConverterUtilityTest {
    @testSetup
    static void setupTestData(){
        List<sObject> ls = Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('ABHILLLL','Test_1');
        accRec.Client_Code__c = '352344';
        accRec.Business_Unit__c = 'ABHI';
        update accRec;
        Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        astRec.LAN__c = 'LAN1234';
        astRec.Business_Unit__c = 'ABHI';
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
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'","Case Resolved Comments":"ABC","Case Resolved Reason":"Problem Solved","Stage":"Unresolved", "Close Unresolved Reason":"Other", "Close Unresolved Details":"Sample text","Stop Communication":"TRUE"}');
        ABHI_BulkCloseCaseConverterUtility utility = new ABHI_BulkCloseCaseConverterUtility();
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
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'","Case Resolved Comments":"ABC","Case Resolved Reason":"Problem Solved","Stage":"Resolved", "Close Unresolved Reason":"Other", "Close Unresolved Details":"Sample text","Stop Communication":"TRUE"}');
        ABHI_BulkCloseCaseConverterUtility utility = new ABHI_BulkCloseCaseConverterUtility();
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
        case caserec = [select CaseNumber from Case LIMIT 1];
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'","Case Resolved Comments":"","Case Resolved Reason":"Problem Solved","Stage":"Resolved", "Close Unresolved Reason":"Other", "Close Unresolved Details":"Sample text","Stop Communication":"TRUE"}');
        ABHI_BulkCloseCaseConverterUtility utility = new ABHI_BulkCloseCaseConverterUtility();
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
        case caserec = [select CaseNumber from Case LIMIT 1];
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'","Case Resolved Comments":"ABC","Case Resolved Reason":"","Stage":"Resolved", "Close Unresolved Reason":"Other", "Close Unresolved Details":"Sample text","Stop Communication":"TRUE"}');
        ABHI_BulkCloseCaseConverterUtility utility = new ABHI_BulkCloseCaseConverterUtility();
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
        case caserec = [select CaseNumber from Case LIMIT 1];
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'","Case Resolved Comments":"ABC","Case Resolved Reason":"Problem Solved","Stage":"Unresolved", "Close Unresolved Reason":"", "Close Unresolved Details":"Sample text","Stop Communication":"TRUE"}');
        ABHI_BulkCloseCaseConverterUtility utility = new ABHI_BulkCloseCaseConverterUtility();
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
        case caserec = [select CaseNumber from Case LIMIT 1];
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'","Case Resolved Comments":"ABC","Case Resolved Reason":"Problem Solved","Stage":"Unresolved", "Close Unresolved Reason":"Other", "Close Unresolved Details":"","Stop Communication":"TRUE"}');
        ABHI_BulkCloseCaseConverterUtility utility = new ABHI_BulkCloseCaseConverterUtility();
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
        case caserec = [select CaseNumber from Case LIMIT 1];
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'","Case Resolved Comments":"ABC","Case Resolved Reason":"Problem Solved","Stage":"Resolved", "Close Unresolved Reason":"Other", "Close Unresolved Details":"Sample text","Stop Communication":""}');
        ABHI_BulkCloseCaseConverterUtility utility = new ABHI_BulkCloseCaseConverterUtility();
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
        jsonRows.put(lineitem.Id, '{"Case Resolved Comments":"ABC","Case Resolved Reason":"Problem Solved","Stage":"Resolved", "Close Unresolved Reason":"Other", "Close Unresolved Details":"Sample text","Stop Communication":"TRUE"}');
        ABHI_BulkCloseCaseConverterUtility utility = new ABHI_BulkCloseCaseConverterUtility();
        Test.startTest();
        utility.convertJSONRows(jsonRows);
        Test.stopTest();
    }
    
    @IsTest
    static void testconvertJSONRows9(){
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'test';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;
        ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
        lineitem.Bulk_Upload_Header__c = headObj.Id;
        insert lineitem;
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Case number":"ABCD","Case Resolved Comments":"ABC","Case Resolved Reason":"Problem Solved","Stage":"Resolved", "Close Unresolved Reason":"Other", "Close Unresolved Details":"Sample text","Stop Communication":"TRUE"}');
        ABHI_BulkCloseCaseConverterUtility utility = new ABHI_BulkCloseCaseConverterUtility();
        Test.startTest();
        utility.convertJSONRows(jsonRows);
        Test.stopTest();
    }
    
    @IsTest
    static void testconvertJSONRows10(){
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
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'","Case Resolved Comments":"ABC","Case Resolved Reason":"Problem Solved","Stage":"Resolved", "Close Unresolved Reason":"Other", "Close Unresolved Details":"Sample text","Stop Communication":"EMAIL"}');
        ABHI_BulkCloseCaseConverterUtility utility = new ABHI_BulkCloseCaseConverterUtility();
        Test.startTest();
        utility.convertJSONRows(jsonRows);
        Test.stopTest();
    }
    
    @IsTest
    static void testconvertJSONRows11(){
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
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'","Case Resolved Comments":"ABC","Case Resolved Reason":"Problem Solved","Stage":"", "Close Unresolved Reason":"Other", "Close Unresolved Details":"Sample text","Stop Communication":"TRUE"}');
        ABHI_BulkCloseCaseConverterUtility utility = new ABHI_BulkCloseCaseConverterUtility();
        Test.startTest();
        utility.convertJSONRows(jsonRows);
        Test.stopTest();
    }
    
    @IsTest
    static void testconvertJSONRows12(){
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
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'","Case Resolved Comments":"ABC","Case Resolved Reason":"Problem Solved","Stage":"ABC", "Close Unresolved Reason":"Other", "Close Unresolved Details":"Sample text","Stop Communication":"TRUE"}');
        ABHI_BulkCloseCaseConverterUtility utility = new ABHI_BulkCloseCaseConverterUtility();
        Test.startTest();
        utility.convertJSONRows(jsonRows);
        Test.stopTest();
    }
    
    @IsTest
    static void testconvertJSONRows13(){
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'test';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;
        ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
        lineitem.Bulk_Upload_Header__c = headObj.Id;
        insert lineitem;
        case caserec = [select Id, CaseNumber, isClosed, AccountId, RecordTypeId from Case LIMIT 1];
        caserec.AccountId = null;
        caserec.RecordTypeId = ASF_Constants.RT_INTERACTION;
        update caserec;
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'","Case Resolved Comments":"ABC","Case Resolved Reason":"Problem Solved","Stage":"Resolved", "Close Unresolved Reason":"Other", "Close Unresolved Details":"Sample text","Stop Communication":"TRUE"}');
        ABHI_BulkCloseCaseConverterUtility utility = new ABHI_BulkCloseCaseConverterUtility();
        Test.startTest();
        utility.convertJSONRows(jsonRows);
        Test.stopTest();
    }
    
    @IsTest
    static void testconvertJSONRows14(){
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'test';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;
        ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
        lineitem.Bulk_Upload_Header__c = headObj.Id;
        insert lineitem;
        case caserec = [select Id, CaseNumber, Status from Case LIMIT 1];
        caserec.Status = 'Closed';
        update caserec;
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'","Case Resolved Comments":"ABC","Case Resolved Reason":"Problem Solved","Stage":"Resolved", "Close Unresolved Reason":"Other", "Close Unresolved Details":"Sample text","Stop Communication":"TRUE"}');
        ABHI_BulkCloseCaseConverterUtility utility = new ABHI_BulkCloseCaseConverterUtility();
        Test.startTest();
        utility.convertJSONRows(jsonRows);
        Test.stopTest();
    }

    @IsTest
    static void testprepareDownloadTemplate() {        
        List<String> columnNames = new List<String>{'Case number','Case Resolved Comments','Case Resolved Reason','Stage', 'Close Unresolved Reason', 'Close Unresolved Details','Stop Communication'};
        Case caserec = [Select Id from Case LIMIT 1];
        Test.startTest();
        ABHI_BulkCloseCaseConverterUtility utility = new ABHI_BulkCloseCaseConverterUtility();
        utility.prepareDownloadTemplate(columnNames, 'Case', null, new List<String>{caserec.Id});
        Test.stopTest();

    }

    @IsTest
    static void testprepareDownloadTemplate2() {        
        List<String> columnNames = new List<String>{'Case number','Case Resolved Comments','Case Resolved Reason','Stage', 'Close Unresolved Reason', 'Close Unresolved Details','Stop Communication'};
        ListView lv = [Select Id, SobjectType, DeveloperName from ListView where SobjectType = 'Case' and DeveloperName = 'RecentlyViewedCases' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new ASF_ListViewAPIMock());
        Test.startTest();
        ABHI_BulkCloseCaseConverterUtility utility = new ABHI_BulkCloseCaseConverterUtility();
        utility.prepareDownloadTemplate(columnNames, 'Case', lv.Id, null);
        utility.prepareCtstData(new List<String>(), '');
        Test.stopTest();

    }

}