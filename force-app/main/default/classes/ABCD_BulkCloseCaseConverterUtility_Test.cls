@IsTest
public class ABCD_BulkCloseCaseConverterUtility_Test {

    Public static string interactionId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Interaction').getRecordTypeId();
    @testSetup
    static void setupTestData(){
        List<sObject> ls = Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
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
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'", "Resolution Comments":"Test Comments"}');
        ABCD_BulkCloseCaseConverterUtility utility = new ABCD_BulkCloseCaseConverterUtility();
        Test.startTest();
        utility.convertJSONRows(jsonRows);
        
        ASF_TestDataFactory.createInteractionCaseRecords();
        
        case caserecInt = [select CaseNumber from Case where RecordTypeId =: interactionId LIMIT 1];
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserecInt.CaseNumber+'", "Resolution Comments":"Test Comments"}');
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
        case caserec = [select CaseNumber,Stage__c,Status from Case LIMIT 1];
        Map<Id, String> jsonRows = new Map<Id, String>();
        Test.startTest();
        ABCD_BulkCloseCaseConverterUtility utility = new ABCD_BulkCloseCaseConverterUtility();
        
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'","Resolution Comments":"Test comments"}');
        utility.convertJSONRows(jsonRows);

        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'","Resolution Comments":""}');
        utility.convertJSONRows(jsonRows);
        
        caserec.Status = 'Resolved';
        update caserec;
        
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'","Resolution Comments":"Test comments"}');
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
        Test.startTest();
        ABCD_BulkCloseCaseConverterUtility utility = new ABCD_BulkCloseCaseConverterUtility();
        jsonRows.put(lineitem.Id, '{"Case number":"INVALID","Resolution Comments":""}');
        
        utility.convertJSONRows(jsonRows);
        
        jsonRows.put(lineitem.Id, '{"Case number":"","Resolution Comments":"testing"}');
        utility.convertJSONRows(jsonRows);
        
        jsonRows.put(lineitem.Id, '{"Case number":"INVALID","Resolution Comments":"test"}');
        utility.convertJSONRows(jsonRows);
    
        Test.stopTest();
    }

    @IsTest
    static void testprepareDownloadTemplate() {        
        List<String> columnNames = new List<String>{'Case number','Resolution Comments'};
        Case caserec = [Select Id from Case LIMIT 1];
        Test.startTest();
        ABCD_BulkCloseCaseConverterUtility utility = new ABCD_BulkCloseCaseConverterUtility();
        utility.prepareDownloadTemplate(columnNames, 'Case', null, new List<String>{caserec.Id});
        Test.stopTest();

    }

    @IsTest
    static void testprepareDownloadTemplate2() {        
        List<String> columnNames = new List<String>{'Case number','Resolution Comments'};
        ListView lv = [Select Id, SobjectType, DeveloperName from ListView where SobjectType = 'Case' and DeveloperName = 'RecentlyViewedCases' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new ASF_ListViewAPIMock());
        Test.startTest();
        ABCD_BulkCloseCaseConverterUtility utility = new ABCD_BulkCloseCaseConverterUtility();
        utility.prepareDownloadTemplate(columnNames, 'Case', lv.Id, null);
        utility.prepareCtstData(columnNames, 'ABCD');
        Test.stopTest();

    }
}