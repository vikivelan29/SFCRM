/**
* @File Name : ABHI_BulkMoveNextConverterUtilityTest.cls
* @Description : Test Class for ABHI_BulkMoveNextConverterUtility
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
@isTest
public class ABHI_BulkMoveNextConverterUtilityTest {
    
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - setupTestData
    * @description - This method will be used to create testdata setup
    *****************************************************************************************************************/
    @testSetup
    static void setupTestData(){
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
        List<Case> caseList = ASF_TestDataFactory.createCaseRecordsWithoutInsert();
        insert caseList;
        
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
        case caserec = [select CaseNumber from Case LIMIT 1];
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'"}');
        ABHI_BulkMoveNextConverterUtility utility = new ABHI_BulkMoveNextConverterUtility();
        Test.startTest();
        ASF_BulkCaseProcessorUtility.ConvertionResult objRes = utility.convertJSONRows(jsonRows);
        System.assert(objRes != null, 'Bulk JSON is null');
        Test.stopTest();
    }
	
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - testconvertJSONRows2
    * @description - Test method to test convertJSONRows - Happy path
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
        case caserec = [select CaseNumber from Case LIMIT 1];
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'"}');
        ABHI_BulkMoveNextConverterUtility utility = new ABHI_BulkMoveNextConverterUtility();
        Test.startTest();
        ASF_BulkCaseProcessorUtility.ConvertionResult objRes = utility.convertJSONRows(jsonRows);
        System.assert(objRes != null, 'Bulk JSON is null');
        Test.stopTest();
    }
	
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - testconvertJSONRows3
    * @description - Test method to test convertJSONRows - Blank case number
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
        jsonRows.put(lineitem.Id, '{"Case number":""}');
        ABHI_BulkMoveNextConverterUtility utility = new ABHI_BulkMoveNextConverterUtility();
        Test.startTest();
        ASF_BulkCaseProcessorUtility.ConvertionResult objRes = utility.convertJSONRows(jsonRows);
        System.assert(objRes != null, 'Bulk JSON is null');
        Test.stopTest();
    }
    
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - testconvertJSONRows4
    * @description - Test method to test convertJSONRows - Wrong case number
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
        jsonRows.put(lineitem.Id, '{"Case number":"ABCD"}');
        ABHI_BulkMoveNextConverterUtility utility = new ABHI_BulkMoveNextConverterUtility();
        Test.startTest();
        ASF_BulkCaseProcessorUtility.ConvertionResult objRes = utility.convertJSONRows(jsonRows);
        System.assert(objRes != null, 'Bulk JSON is null');
        Test.stopTest();
    }
    
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - testconvertJSONRows5
    * @description - Test method to test convertJSONRows - Happy path with CCC
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
        case caserec = [select CaseNumber, Stage__c, CCC_External_Id__c from Case LIMIT 1];
        ASF_Case_Stage_Config__c stageConfig = [Select Id from ASF_Case_Stage_Config__c where Case_Category_Config__r.CCC_External_Id__c = :caserec.CCC_External_Id__c and StageName__c = :caserec.Stage__c LIMIT 1];
        stageConfig.Enable_Bulk_Move_to_Next_Stage__c = true;
        update stageConfig;
        
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'"}');
        ABHI_BulkMoveNextConverterUtility utility = new ABHI_BulkMoveNextConverterUtility();
        Test.startTest();
        ASF_BulkCaseProcessorUtility.ConvertionResult objRes = utility.convertJSONRows(jsonRows);
        System.assert(objRes != null, 'Bulk JSON is null');
        Test.stopTest();
    }
    
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - testconvertJSONRows6
    * @description - Test method to test convertJSONRows - Happy path
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
        case caserec = [select Id, CaseNumber, isClosed, AccountId, RecordTypeId from Case LIMIT 1];
        caserec.AccountId = null;
        caserec.RecordTypeId = ASF_Constants.RT_INTERACTION;
        update caserec;
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'"}');
        ABHI_BulkMoveNextConverterUtility utility = new ABHI_BulkMoveNextConverterUtility();
        Test.startTest();
        ASF_BulkCaseProcessorUtility.ConvertionResult objRes = utility.convertJSONRows(jsonRows);
        System.assert(objRes != null, 'Bulk JSON is null');
        Test.stopTest();
    }
    
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - testconvertJSONRows7
    * @description - Test method to test convertJSONRows - Closed case check
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
        case caserec = [select Id, CaseNumber, Status from Case LIMIT 1];
        caserec.Status = 'Closed';
        update caserec;
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'"}');
        ABHI_BulkMoveNextConverterUtility utility = new ABHI_BulkMoveNextConverterUtility();
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
        List<String> columnNames = new List<String>{'Case number'};
        Case caserec = [Select Id from Case LIMIT 1];
        Test.startTest();
        ABHI_BulkMoveNextConverterUtility utility = new ABHI_BulkMoveNextConverterUtility();
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
        List<String> columnNames = new List<String>{'Case number'};
        ListView lv = [Select Id, SobjectType, DeveloperName from ListView where SobjectType = 'Case' and DeveloperName = 'RecentlyViewedCases' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new ASF_ListViewAPIMock());
        Test.startTest();
        ABHI_BulkMoveNextConverterUtility utility = new ABHI_BulkMoveNextConverterUtility();
        List<Map<String,String>> lstResPdt = utility.prepareDownloadTemplate(columnNames, 'Case', lv.Id, null);
        List<Map<String,String>> lstResPctst = utility.prepareCtstData(new List<String>(), '');
        System.assert(!lstResPdt.isEmpty(), 'List records for template download is null');
        System.assert(lstResPctst.isEmpty(), 'List records for ctst download is not null');
        Test.stopTest();

    }

}