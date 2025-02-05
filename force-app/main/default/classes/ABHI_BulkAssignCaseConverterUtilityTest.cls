/**
* @File Name : ABHI_BulkAssignCaseConverterUtilityTest.cls
* @Description : Test Class for ABHI_BulkAssignCaseConverterUtility
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
public class ABHI_BulkAssignCaseConverterUtilityTest {
    
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - setupTestData
    * @description - This method will be used to create testdata setup
    *****************************************************************************************************************/
    @testSetup
    static void setupTestData(){
        List<sObject> ls = Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('ABHI','Test_1');
        accRec.Client_Code__c = '352344';
        accRec.Business_Unit__c = 'ABHI';
        update accRec;
        Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        astRec.Policy_No__c = 'LAN1234';
        astRec.Business_Unit__c = 'ABHI';
        astRec.Last_Disbursement_Date__c = Date.Today();
        update astRec;
        ABSLI_Case_Detail__c relRec = new ABSLI_Case_Detail__c(Address_Line_1__c = 'test');
        insert relRec;
        ASF_TestDataFactory.createCaseCategoryConfig();
        ASF_TestDataFactory.createC3WithPrePopulateIntegrations();
        ASF_TestDataFactory.createCaseRecords(0);
        Case caseRec = [Select CaseNumber from Case LIMIT 1];
        caseRec.ABSLI_Case_Detail__c = [Select Id from ABSLI_Case_Detail__c LIMIT 1].Id;
        update caseRec;
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
        String newOwner = [select id,name from group where type = 'Queue' and developerName LIKE 'ABHI_%' LIMIT 1].name;
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'","New Owner":"'+newOwner+'", "Internal comments":"Owner change"}');
        ABHI_BulkAssignCaseConverterUtility utility = new ABHI_BulkAssignCaseConverterUtility();
        Test.startTest();
        ASF_BulkCaseProcessorUtility.ConvertionResult objRes = utility.convertJSONRows(jsonRows);
        System.assert(objRes != null, 'Bulk JSON is null');
        Test.stopTest();
    }
    
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - testconvertJSONRowsResolved
    * @description - Test method to test convertJSONRows - multiple scenarios check
    *****************************************************************************************************************/
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
        case caserec = [select CaseNumber,status from Case LIMIT 1];
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'","New Owner":"newOwner", "Internal comments":"Owner change"}');
        ABHI_BulkAssignCaseConverterUtility utility = new ABHI_BulkAssignCaseConverterUtility();
        Test.startTest();
        utility.convertJSONRows(jsonRows);
        jsonRows.put(lineitem.Id, '{"Case number":"1234","New Owner":"newOwner", "Internal comments":"Owner change"}');
        utility.convertJSONRows(jsonRows);
        jsonRows.put(lineitem.Id, '{"Case number":"","New Owner":"newOwner", "Internal comments":"Owner change"}');
        utility.convertJSONRows(jsonRows);
        jsonRows.put(lineitem.Id, '{"Case number":"1234","New Owner":"", "Internal comments":"Owner change"}');
        utility.convertJSONRows(jsonRows);
        ASF_TriggerSkipperUtility.markTriggerRun('Case');
        caserec.status = 'Resolved';
        update caserec;
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'","New Owner":"newOwner", "Internal comments":"Owner change"}');
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
        List<String> columnNames = new List<String>{'Case number','New Owner', 'Internal comments'};
            Case caserec = [Select Id from Case LIMIT 1];
        Test.startTest();
        ABHI_BulkAssignCaseConverterUtility utility = new ABHI_BulkAssignCaseConverterUtility();
        List<Map<String,String>> lstRes = utility.prepareDownloadTemplate(columnNames, 'Case', null, new List<String>{caserec.Id});
        System.assert(!lstRes.isEmpty(), 'List records for template download is null');
        List<Map<String,String>> lstResPctst = utility.prepareCtstData(new List<String>{'Id'},'ABSLI');
        System.assert(lstResPctst.isEmpty(), 'List records for ctst download is not null');
        Test.stopTest();
        
    }
    
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - testprepareDownloadTemplate2
    * @description - Test method to test prepareCtstData
    *****************************************************************************************************************/
    @IsTest
    static void testprepareDownloadTemplate2() {        
        List<String> columnNames = new List<String>{'Case number','New Owner', 'Internal comments'};
            ListView lv = [Select Id, SobjectType, DeveloperName from ListView where SobjectType = 'Case' and DeveloperName = 'RecentlyViewedCases' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new ASF_ListViewAPIMock());
        Test.startTest();
        ABHI_BulkAssignCaseConverterUtility utility = new ABHI_BulkAssignCaseConverterUtility();
        List<Map<String,String>> lstResPdt = utility.prepareDownloadTemplate(columnNames, 'Case', lv.Id, null);
        List<Map<String,String>> lstResPctst = utility.prepareCtstData(new List<String>(), '');
        System.assert(!lstResPdt.isEmpty(), 'List records for template download is null');
        System.assert(lstResPctst.isEmpty(), 'List records for ctst download is not null');
        Test.stopTest();
        
    }
    
}