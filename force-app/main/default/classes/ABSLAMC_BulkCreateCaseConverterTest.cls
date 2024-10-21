@IsTest

public with sharing class ABSLAMC_BulkCreateCaseConverterTest {
    
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
        jsonRows.put(lineitem.Id, '{"LOB":"MF","Issue Code":"MF0121", "Category": "Request", "Type":"DC Reject", "Sub-Type"  : "DC rejection-Cheque Payment", "CLIENT CODE (LOB + PAN/PEKRN)" : "345678333423", "Folio":"XLAN1234","Owner Team" : "","Owner AD ID":"1234","Source":"Email","Channel":"Online", "Caller Type":"Investor", "Critical Request flag (Y/N)" : "Yes" ,"PHD Compaint Source" : "","Description":"DescriptionXYZ", "Send Auto Communication?":"Yes"}');
        ABSLAMC_BulkCreateCaseConverterUtility utility = new ABSLAMC_BulkCreateCaseConverterUtility();
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
        jsonRows.put(lineitem.Id, '{"LOB":"","Issue Code":"MF0121", "Category": "Request", "Type":"DC Reject", "Sub-Type"  : "DC rejection-Cheque Payment", "CLIENT CODE (LOB + PAN/PEKRN)" : "345678333423", "Folio":"XLAN1234","Owner Team" : "","Owner AD ID":"1234","Source":"Email","Channel":"Online", "Caller Type":"Investor", "Critical Request flag (Y/N)" : "Yes" ,"PHD Compaint Source" : "","Description":"DescriptionXYZ", "Send Auto Communication?":"Yes"}');
        ABSLAMC_BulkCreateCaseConverterUtility utility = new ABSLAMC_BulkCreateCaseConverterUtility();
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
        jsonRows.put(lineitem.Id, '{"LOB":"MF","Issue Code":"", "Category": "Request", "Type":"DC Reject", "Sub-Type"  : "DC rejection-Cheque Payment", "CLIENT CODE (LOB + PAN/PEKRN)" : "345678333423", "Folio":"XLAN1234","Owner Team" : "","Owner AD ID":"1234","Source":"Email","Channel":"Online", "Caller Type":"", "Critical Request flag (Y/N)" : "Yes" ,"PHD Compaint Source" : "","Description":"DescriptionXYZ", "Send Auto Communication?":"Yes"}');
        ABSLAMC_BulkCreateCaseConverterUtility utility = new ABSLAMC_BulkCreateCaseConverterUtility();
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
        jsonRows.put(lineitem.Id, '{"LOB":"MF","Issue Code":"MF0121", "Category": "Request", "Type":"DC Reject", "Sub-Type"  : "DC rejection-Cheque Payment", "CLIENT CODE (LOB + PAN/PEKRN)" : "345678333423", "Folio":"XLAN1234","Owner Team" : "","Owner AD ID":"1234","Source":"Email","Channel":"Online", "Caller Type":"Investor", "Critical Request flag (Y/N)" : "" ,"PHD Compaint Source" : "","Description":"DescriptionXYZ", "Send Auto Communication?":"Yes"}');
        ABSLAMC_BulkCreateCaseConverterUtility utility = new ABSLAMC_BulkCreateCaseConverterUtility();
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
        jsonRows.put(lineitem.Id, '{"LOB":"MF","Issue Code":"MF0121", "Category": "Request", "Type":"DC Reject", "Sub-Type"  : "DC rejection-Cheque Payment", "CLIENT CODE (LOB + PAN/PEKRN)" : "", "Folio":"XLAN1234","Owner Team" : "","Owner AD ID":"1234","Source":"Email","Channel":"Online", "Caller Type":"Investor", "Critical Request flag (Y/N)" : "Yes" ,"PHD Compaint Source" : "","Description":"DescriptionXYZ", "Send Auto Communication?":"Yes"}');
        ABSLAMC_BulkCreateCaseConverterUtility utility = new ABSLAMC_BulkCreateCaseConverterUtility();
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
        jsonRows.put(lineitem.Id, '{"LOB":"MF","Issue Code":"MF0121", "Category": "Request", "Type":"DC Reject", "Sub-Type"  : "DC rejection-Cheque Payment", "CLIENT CODE (LOB + PAN/PEKRN)" : "345678333423", "Folio":"","Owner Team" : "","Owner AD ID":"1234","Source":"Email","Channel":"Online", "Caller Type":"Investor", "Critical Request flag (Y/N)" : "Yes" ,"PHD Compaint Source" : "","Description":"DescriptionXYZ", "Send Auto Communication?":"Yes"}');
        ABSLAMC_BulkCreateCaseConverterUtility utility = new ABSLAMC_BulkCreateCaseConverterUtility();
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
        jsonRows.put(lineitem.Id, '{"LOB":"MF","Issue Code":"MF0121", "Category": "Request", "Type":"DC Reject", "Sub-Type"  : "DC rejection-Cheque Payment", "CLIENT CODE (LOB + PAN/PEKRN)" : "345678333423", "Folio":"XLAN1234","Owner Team" : "","Owner AD ID":"1234","Source":"","Channel":"Online", "Caller Type":"Investor", "Critical Request flag (Y/N)" : "Yes" ,"PHD Compaint Source" : "","Description":"DescriptionXYZ", "Send Auto Communication?":"Yes"}');
        ABSLAMC_BulkCreateCaseConverterUtility utility = new ABSLAMC_BulkCreateCaseConverterUtility();
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
        jsonRows.put(lineitem.Id, '{"LOB":"MF","Issue Code":"MF0121", "Category": "Request", "Type":"DC Reject", "Sub-Type"  : "DC rejection-Cheque Payment", "CLIENT CODE (LOB + PAN/PEKRN)" : "345678333423", "Folio":"XLAN1234","Owner Team" : "","Owner AD ID":"1234","Source":"Email","Channel":"", "Caller Type":"Investor", "Critical Request flag (Y/N)" : "Yes" ,"PHD Compaint Source" : "","Description":"DescriptionXYZ", "Send Auto Communication?":"Yes"}');
        ABSLAMC_BulkCreateCaseConverterUtility utility = new ABSLAMC_BulkCreateCaseConverterUtility();
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
        jsonRows.put(lineitem.Id, '{"LOB":"MF","Issue Code":"MF0121", "Category": "Request", "Type":"DC Reject", "Sub-Type"  : "DC rejection-Cheque Payment", "CLIENT CODE (LOB + PAN/PEKRN)" : "345678333423", "Folio":"XLAN1234","Owner Team" : "","Owner AD ID":"1234","Source":"Email","Channel":"Social", "Caller Type":"Investor", "Critical Request flag (Y/N)" : "Yes" ,"PHD Compaint Source" : "","Description":"", "Send Auto Communication?":"Yes"}');
        ABSLAMC_BulkCreateCaseConverterUtility utility = new ABSLAMC_BulkCreateCaseConverterUtility();
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
        jsonRows.put(lineitem.Id, '{"LOB":"MF","Issue Code":"MF0121", "Category": "Request", "Type":"DC Reject", "Sub-Type"  : "DC rejection-Cheque Payment", "CLIENT CODE (LOB + PAN/PEKRN)" : "345678333423", "Folio":"XLAN1234","Owner Team" : "","Owner AD ID":"1234","Source":"Email","Channel":"Social", "Caller Type":"Investor", "Critical Request flag (Y/N)" : "Yes" ,"PHD Compaint Source" : "","Description":"testDesc", "Send Auto Communication?": "Email"}');
        ABSLAMC_BulkCreateCaseConverterUtility utility = new ABSLAMC_BulkCreateCaseConverterUtility();
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
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"LOB":"MF","Issue Code":"MF0121", "Category": "Request", "Type":"DC Reject", "Sub-Type"  : "DC rejection-Cheque Payment", "CLIENT CODE (LOB + PAN/PEKRN)" : "345678333423", "Folio":"XLAN1234","Owner Team" : "","Owner AD ID":"","Source":"Email","Channel":"Social", "Caller Type":"Investor", "Critical Request flag (Y/N)" : "Yes" ,"PHD Compaint Source" : "","Description":"testDesc", "Send Auto Communication?":"Yes"}');
        ABSLAMC_BulkCreateCaseConverterUtility utility = new ABSLAMC_BulkCreateCaseConverterUtility();
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
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"LOB":"MF","Issue Code":"MF0121", "Category": "Request", "Type":"DC Reject", "Sub-Type"  : "DC rejection-Cheque Payment", "CLIENT CODE (LOB + PAN/PEKRN)" : "345678333423", "Folio":"XLAN1234","Owner Team" : "","Owner AD ID":"1234","Source":"Email","Channel":"Social", "Caller Type":"Investor", "Critical Request flag (Y/N)" : "Yes" ,"PHD Compaint Source" : "","Description":"testDesc", "Send Auto Communication?":"ABCd"}');
        ABSLAMC_BulkCreateCaseConverterUtility utility = new ABSLAMC_BulkCreateCaseConverterUtility();
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
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"LOB":"MF","Issue Code":"MF0121", "Category": "Request", "Type":"DC Reject", "Sub-Type"  : "DC rejection-Cheque Payment", "CLIENT CODE (LOB + PAN/PEKRN)" : "345678333423", "Folio":"XLAN1234","Owner Team" : "","Owner AD ID":"1234","Source":"Email","Channel":"Online", "Caller Type":"", "Critical Request flag (Y/N)" : "Yes" ,"PHD Compaint Source" : "","Description":"DescriptionXYZ", "Send Auto Communication?":"Yes"}');
        ABSLAMC_BulkCreateCaseConverterUtility utility = new ABSLAMC_BulkCreateCaseConverterUtility();
        Test.startTest();
        utility.convertJSONRows(jsonRows);
        Test.stopTest();
    }
    
    @IsTest
    static void testprepareDownloadTemplate() {        
        List<String> columnNames = new List<String>{'LOB', 'Issue Code', 'Category', 'Type', 'Sub-Type','CLIENT CODE (LOB + PAN/PEKRN)','Folio','Owner Team','Owner AD ID','Source','Channel','Caller Type','Critical Request flag (Y/N)','PHD Compaint Source','Description', 'Send Auto Communication?'};
        Case caserec = [Select Id from Case LIMIT 1];
        Test.startTest();
        ABSLAMC_BulkCreateCaseConverterUtility utility = new ABSLAMC_BulkCreateCaseConverterUtility();
        utility.prepareDownloadTemplate(columnNames, 'Case', null, new List<String>{caserec.Id});
        Test.stopTest();

    }
    @IsTest
    static void testprepareDownloadTemplate2() {        
        List<String> columnNames = new List<String>{'LOB', 'Issue Code', 'Category', 'Type', 'Sub-Type','CLIENT CODE (LOB + PAN/PEKRN)','Folio','Owner Team','Owner AD ID','Source','Channel','Caller Type','Critical Request flag (Y/N)','PHD Compaint Source','Description', 'Send Auto Communication?'};
        ListView lv = [Select Id, SobjectType, DeveloperName from ListView where SobjectType = 'Case' and DeveloperName = 'RecentlyViewedCases' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new ASF_ListViewAPIMock());
        Test.startTest();
        ABSLAMC_BulkCreateCaseConverterUtility utility = new ABSLAMC_BulkCreateCaseConverterUtility();
        utility.prepareDownloadTemplate(columnNames, 'Case', lv.Id, null);
        Test.stopTest();

    }
    
    @IsTest
    static void testprepareCtstData() {        
        List<String> columnNames = new List<String>{'Issue Code', 'Case Type', 'Sub Type','Nature','Activity'};
        Test.startTest();
        ABSLAMC_BulkCreateCaseConverterUtility utility = new ABSLAMC_BulkCreateCaseConverterUtility();
        utility.prepareCtstData(columnNames, 'ABSLAMC');
        Test.stopTest();

    }

}