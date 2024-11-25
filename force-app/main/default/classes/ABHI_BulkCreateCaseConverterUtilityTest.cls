/**
* @File Name : ABHI_BulkCreateCaseConverterUtilityTest.cls
* @Description : Test Class for ABHI_BulkCreateCaseConverterUtility
* @Author : Salesforce
* @Last Modified By : Aditya Jawadekar
* @Last Modified On : October 12, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 12, 2024 | Aditya Jawadekar  | Initial Version
**/
@SuppressWarnings('PMD.ApexSOQLInjection,PMD.CyclomaticComplexity,PMD.StdCyclomaticComplexity,PMD.CognitiveComplexity,PMD.ExcessivePublicCount,PMD.IfStmtsMustUseBraces,PMD.IfElseStmtsMustUseBraces,PMD.AvoidDeeplyNestedIfStmts,PMD.ExcessiveParameterList,PMD.NcssMethodCount,PMD.ClassNamingConventions,PMD.FieldNamingConventions,PMD.VariableNamingConventions')
@IsTest
public class ABHI_BulkCreateCaseConverterUtilityTest {
	/****************************************************************************************************************
    * @LOB - ABHI
    * @Function - setupTestData
    * @description - This method will be used to create testdata setup
    *****************************************************************************************************************/
    @testSetup
    static void setupTestData(){
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('ABHINEW','Test_1');
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
	
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - testconvertJSONRows
    * @description - Test method to test convertJSONRows - Happy path
    *****************************************************************************************************************/
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
        jsonRows.put(lineitem.Id, '{"Client Code":"352344","Policy":"LAN1234","Issue Code":"CCC-CC-CCLTD-01", "Source":"Email", "Description":"DescriptionXYZ", "Stop Communication":"Email"}');
        ABHI_BulkCreateCaseConverterUtility utility = new ABHI_BulkCreateCaseConverterUtility();
        Test.startTest();
        ASF_BulkCaseProcessorUtility.ConvertionResult objRes = utility.convertJSONRows(jsonRows);
        System.assert(objRes != null, 'Bulk JSON is null');
        Test.stopTest();
    }
	
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - testconvertJSONRows2
    * @description - Test method to test convertJSONRows - Issue code not found check
    *****************************************************************************************************************/
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
        jsonRows.put(lineitem.Id, '{"Client Code":"352344","Policy":"LAN1234","Issue Code":"XCCC-CC-CCLTD-01", "Source":"Email", "Description":"DescriptionXYZ", "Stop Communication":"Email"}');
        ABHI_BulkCreateCaseConverterUtility utility = new ABHI_BulkCreateCaseConverterUtility();
        Test.startTest();
        ASF_BulkCaseProcessorUtility.ConvertionResult objRes = utility.convertJSONRows(jsonRows);
        System.assert(objRes != null, 'Bulk JSON is null');
        Test.stopTest();
    }
	
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - testconvertJSONRows3
    * @description - Test method to test convertJSONRows - Policy not found check
    *****************************************************************************************************************/
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
        jsonRows.put(lineitem.Id, '{"Client Code":"352344","Policy":"XLAN1234","Issue Code":"CCC-CC-CCLTD-01", "Source":"Email", "Description":"DescriptionXYZ", "Stop Communication":"EMAIL"}');
        ABHI_BulkCreateCaseConverterUtility utility = new ABHI_BulkCreateCaseConverterUtility();
        Test.startTest();
        ASF_BulkCaseProcessorUtility.ConvertionResult objRes = utility.convertJSONRows(jsonRows);
        System.assert(objRes != null, 'Bulk JSON is null');
        Test.stopTest();
    }
    
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - testconvertJSONRows4
    * @description - Test method to test convertJSONRows - Blank check
    *****************************************************************************************************************/
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
        jsonRows.put(lineitem.Id, '{"Client Code":"","Policy":"","Issue Code":"", "Source":"", "Description":"", "Stop Communication":""}');
        ABHI_BulkCreateCaseConverterUtility utility = new ABHI_BulkCreateCaseConverterUtility();
        Test.startTest();
        ASF_BulkCaseProcessorUtility.ConvertionResult objRes = utility.convertJSONRows(jsonRows);
        System.assert(objRes != null, 'Bulk JSON is null');
        Test.stopTest();
    }
    
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - testconvertJSONRows5
    * @description - Test method to test convertJSONRows - Client code not found check
    *****************************************************************************************************************/
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
        jsonRows.put(lineitem.Id, '{"Client Code":"X352344","Policy":"LAN1234","Issue Code":"CCC-CC-CCLTD-01", "Source":"Email", "Description":"DescriptionXYZ", "Stop Communication":"Email"}');
        ABHI_BulkCreateCaseConverterUtility utility = new ABHI_BulkCreateCaseConverterUtility();
        Test.startTest();
        ASF_BulkCaseProcessorUtility.ConvertionResult objRes = utility.convertJSONRows(jsonRows);
        System.assert(objRes != null, 'Bulk JSON is null');
        Test.stopTest();
    }
    
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - testconvertJSONRows6
    * @description - Test method to test convertJSONRows - Happy Path
    *****************************************************************************************************************/
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
        jsonRows.put(lineitem.Id, '{"Client Code":"352344","Policy":"LAN1234","Issue Code":"CCC-CC-CCLTD-01", "Source":"Email", "Description":"DescriptionXYZ", "Stop Communication":"TRUE"}');
        ABHI_BulkCreateCaseConverterUtility utility = new ABHI_BulkCreateCaseConverterUtility();
        Test.startTest();
        ASF_BulkCaseProcessorUtility.ConvertionResult objRes = utility.convertJSONRows(jsonRows);
        System.assert(objRes != null, 'Bulk JSON is null');
        Test.stopTest();
    }
    
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - testconvertJSONRows7
    * @description - Test method to test convertJSONRows - Client code blank check
    *****************************************************************************************************************/
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
        jsonRows.put(lineitem.Id, '{"Client Code":"","Policy":"LAN1234","Issue Code":"CCC-CC-CCLTD-01", "Source":"Email", "Description":"DescriptionXYZ", "Stop Communication":"TRUE"}');
        ABHI_BulkCreateCaseConverterUtility utility = new ABHI_BulkCreateCaseConverterUtility();
        Test.startTest();
        ASF_BulkCaseProcessorUtility.ConvertionResult objRes = utility.convertJSONRows(jsonRows);
        System.assert(objRes != null, 'Bulk JSON is null');
        Test.stopTest();
    }
    
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - testconvertJSONRows8
    * @description - Test method to test convertJSONRows - Policy blank check
    *****************************************************************************************************************/
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
        jsonRows.put(lineitem.Id, '{"Client Code":"352344","Policy":"","Issue Code":"CCC-CC-CCLTD-01", "Source":"Email", "Description":"DescriptionXYZ", "Stop Communication":"TRUE"}');
        ABHI_BulkCreateCaseConverterUtility utility = new ABHI_BulkCreateCaseConverterUtility();
        Test.startTest();
        ASF_BulkCaseProcessorUtility.ConvertionResult objRes = utility.convertJSONRows(jsonRows);
        System.assert(objRes != null, 'Bulk JSON is null');
        Test.stopTest();
    }
    
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - testconvertJSONRows9
    * @description - Test method to test convertJSONRows - Issue code blank check
    *****************************************************************************************************************/
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
        jsonRows.put(lineitem.Id, '{"Client Code":"352344","Policy":"LAN1234","Issue Code":"", "Source":"Email", "Description":"DescriptionXYZ", "Stop Communication":"TRUE"}');
        ABHI_BulkCreateCaseConverterUtility utility = new ABHI_BulkCreateCaseConverterUtility();
        Test.startTest();
        ASF_BulkCaseProcessorUtility.ConvertionResult objRes = utility.convertJSONRows(jsonRows);
        System.assert(objRes != null, 'Bulk JSON is null');
        Test.stopTest();
    }
    
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - testconvertJSONRows10
    * @description - Test method to test convertJSONRows - Source blank check
    *****************************************************************************************************************/
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
        jsonRows.put(lineitem.Id, '{"Client Code":"352344","Policy":"LAN1234","Issue Code":"CCC-CC-CCLTD-01", "Source":"", "Description":"DescriptionXYZ", "Stop Communication":"TRUE"}');
        ABHI_BulkCreateCaseConverterUtility utility = new ABHI_BulkCreateCaseConverterUtility();
        Test.startTest();
        ASF_BulkCaseProcessorUtility.ConvertionResult objRes = utility.convertJSONRows(jsonRows);
        System.assert(objRes != null, 'Bulk JSON is null');
        Test.stopTest();
    }
    
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - testconvertJSONRows11
    * @description - Test method to test convertJSONRows - Description blank check
    *****************************************************************************************************************/
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
        jsonRows.put(lineitem.Id, '{"Client Code":"352344","Policy":"LAN1234","Issue Code":"CCC-CC-CCLTD-01", "Source":"Email", "Description":"", "Stop Communication":"TRUE"}');
        ABHI_BulkCreateCaseConverterUtility utility = new ABHI_BulkCreateCaseConverterUtility();
        Test.startTest();
        ASF_BulkCaseProcessorUtility.ConvertionResult objRes = utility.convertJSONRows(jsonRows);
        System.assert(objRes != null, 'Bulk JSON is null');
        Test.stopTest();
    }
    
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - testconvertJSONRows12
    * @description - Test method to test convertJSONRows - Stop communication blank check
    *****************************************************************************************************************/
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
        jsonRows.put(lineitem.Id, '{"Client Code":"352344","Policy":"LAN1234","Issue Code":"CCC-CC-CCLTD-01", "Source":"Email", "Description":"DescriptionXYZ", "Stop Communication":""}');
        ABHI_BulkCreateCaseConverterUtility utility = new ABHI_BulkCreateCaseConverterUtility();
        Test.startTest();
        ASF_BulkCaseProcessorUtility.ConvertionResult objRes = utility.convertJSONRows(jsonRows);
        System.assert(objRes != null, 'Bulk JSON is null');
        Test.stopTest();
    }
	
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - testprepareDownloadTemplate
    * @description - Test method to test prepareDownloadTemplate
    *****************************************************************************************************************/
    @IsTest
    static void testprepareDownloadTemplate() {        
        List<String> columnNames = new List<String>{'Client Code','Policy', 'Issue Code', 'Source', 'Description', 'Stop Communication'};
        Case caserec = [Select Id from Case LIMIT 1];
        Test.startTest();
        ABHI_BulkCreateCaseConverterUtility utility = new ABHI_BulkCreateCaseConverterUtility();
        List<Map<String,String>> lstRes = utility.prepareDownloadTemplate(columnNames, 'Case', null, new List<String>{caserec.Id});
        System.assert(!lstRes.isEmpty(), 'List records for template download is null');
        Test.stopTest();

    }
	
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - testprepareDownloadTemplate2
    * @description - Test method to test prepareCtstData
    *****************************************************************************************************************/
    @IsTest
    static void testprepareDownloadTemplate2() {        
        List<String> columnNames = new List<String>{'Client Code','Policy', 'Issue Code', 'Source', 'Description', 'Stop Communication'};
        ListView lv = [Select Id, SobjectType, DeveloperName from ListView where SobjectType = 'Case' and DeveloperName = 'RecentlyViewedCases' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new ASF_ListViewAPIMock());
        Test.startTest();
        ABHI_BulkCreateCaseConverterUtility utility = new ABHI_BulkCreateCaseConverterUtility();
        List<Map<String,String>> lstResPdt = utility.prepareDownloadTemplate(columnNames, 'Case', lv.Id, null);
        List<Map<String,String>> lstResPctst = utility.prepareCtstData(new List<String>(), '');
        System.assert(!lstResPdt.isEmpty(), 'List records for template download is null');
        System.assert(lstResPctst.isEmpty(), 'List records for ctst download is not null');
        Test.stopTest();

    }
}