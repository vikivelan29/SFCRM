/**
* @description       : 
* @author            : rsinghnagar@salesforce.com
* @group             : 
* @last modified on  : 11-13-2024
* @last modified by  : rsinghnagar@salesforce.com
* Modifications Log
* Ver   Date         Author                       Modification
* 1.0   11-01-2024   rsinghnagar@salesforce.com   Initial Version
**/
@IsTest
public class Wellness_BulkCloseCaseConverterTest {
    @testSetup
    static void setupTestData(){
        User userRecord = MCRM_TestDataFactory.createWellnessUser();       
        system.runAs(userRecord)
        {
            List<sObject> ls = Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
            Id recordTypeId =Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
            Account accRec = new Account();
            accRec.FirstName = 'TestFirstName';
            accRec.LastName = 'TestFirstName';
            accRec.Client_Code__c = 'Test_145';
            accRec.RecordTypeId = recordTypeId;
            if(Schema.sObjectType.Account.isCreateable()){
                insert accRec;
            }            
            Asset asset = new Asset();
            asset.Name = 'Test Asset';
            asset.AccountId =accRec.Id;
            asset.Type__c = 'Loans';
            asset.ContractId__c = 'LAN1234';
            if(Schema.sObjectType.Asset.isCreateable()){
                insert asset;
            }
            ASF_TestDataFactory.createCaseCategoryConfig();
            ASF_TestDataFactory.createC3WithPrePopulateIntegrations();
            ASF_TestDataFactory.createCaseRecords(0);
        }
    }
    
    @IsTest
    static void testconvertJSONRows0(){
        User usr = [SELECT Id FROM User WHERE Username = 'cdefghijk5657123456@gmail.com' LIMIT 1];
        system.runAs(usr)
        { 
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
            jsonRows.put(lineitem.Id, '{"Case number":"","Resolution Comments":"", "Description":"Desc"}');
            Wellness_BulkCloseCaseConverterUtility utility = new Wellness_BulkCloseCaseConverterUtility();
            Test.startTest();
            utility.convertJSONRows(jsonRows);
            Test.stopTest();
        }
    }
    
    @IsTest
    static void testconvertJSONRows(){
        User usr = [SELECT Id FROM User WHERE Username = 'cdefghijk5657123456@gmail.com' LIMIT 1];
        system.runAs(usr)
        { 
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
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'","Resolution Comments":"", "Description":"Desc"}');
        Wellness_BulkCloseCaseConverterUtility utility = new Wellness_BulkCloseCaseConverterUtility();
        Test.startTest();
        utility.convertJSONRows(jsonRows);
        Test.stopTest();
        }
    }
    
    @IsTest
    static void testconvertJSONRows4(){
        User usr = [SELECT Id FROM User WHERE Username = 'cdefghijk5657123456@gmail.com' LIMIT 1];
        system.runAs(usr)
        { 
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
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'","Resolution Comments":"Sample Comments", "Description":"Desc"}');
        Wellness_BulkCloseCaseConverterUtility utility = new Wellness_BulkCloseCaseConverterUtility();
        Test.startTest();
        utility.convertJSONRows(jsonRows);
        Test.stopTest();
        }
    }
    @IsTest
    static void testconvertJSONRows5(){
        User usr = [SELECT Id FROM User WHERE Username = 'cdefghijk5657123456@gmail.com' LIMIT 1];
        system.runAs(usr)
        { 
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
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'","Resolution Comments":"Sample Comments","Resolution Reason":"Sample Reason", "Description":"Desc"}');
        Wellness_BulkCloseCaseConverterUtility utility = new Wellness_BulkCloseCaseConverterUtility();
        Test.startTest();
        utility.convertJSONRows(jsonRows);
        Test.stopTest();
        }
    }
    
    @IsTest
    static void testconvertJSONRows2(){
        User usr = [SELECT Id FROM User WHERE Username = 'cdefghijk5657123456@gmail.com' LIMIT 1];
        system.runAs(usr)
        { 
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
        jsonRows.put(lineitem.Id, '{"Case number":"'+caserec.CaseNumber+'","Resolution Comments":"", "Description":"Desc"}');
        Wellness_BulkCloseCaseConverterUtility utility = new Wellness_BulkCloseCaseConverterUtility();
        Test.startTest();
        utility.convertJSONRows(jsonRows);
        Test.stopTest();
        }
    }
    
    @IsTest
    static void testconvertJSONRows3(){
        User usr = [SELECT Id FROM User WHERE Username = 'cdefghijk5657123456@gmail.com' LIMIT 1];
        system.runAs(usr)
        { 
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'test';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;
        ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
        lineitem.Bulk_Upload_Header__c = headObj.Id;
        insert lineitem;
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Case number":"INVALID","Resolution Comments":"", "Description":"Desc"}');
        Wellness_BulkCloseCaseConverterUtility utility = new Wellness_BulkCloseCaseConverterUtility();
        Test.startTest();
        utility.convertJSONRows(jsonRows);
        Test.stopTest();
        }
    }
    
    @IsTest
    static void testprepareDownloadTemplate() {  
        User usr = [SELECT Id FROM User WHERE Username = 'cdefghijk5657123456@gmail.com' LIMIT 1];
        system.runAs(usr)
        { 
        List<String> columnNames = new List<String>{'Case number','Resolution Comments','Resolution Reason', 'Description'};
            WellnessCaseDetail__c wellnessCaseDetailRec = new WellnessCaseDetail__c();
        wellnessCaseDetailRec.Resolution_Reason__c = 'Problem Solved';
        wellnessCaseDetailRec.Resolution_Comments__c = '';
        insert wellnessCaseDetailRec;
        Case caserec = [Select Id,WellnessCaseDetail__c,WellnessCaseDetail__r.Resolution_Reason__c from Case LIMIT 1];
        caserec.WellnessCaseDetail__c = wellnessCaseDetailRec.Id;
        Update caserec;
        Test.startTest();
        Wellness_BulkCloseCaseConverterUtility utility = new Wellness_BulkCloseCaseConverterUtility();
        utility.prepareDownloadTemplate(columnNames, 'Case', null, new List<String>{caserec.Id});
        Test.stopTest();
        }
    }
    
    @IsTest
    static void testprepareDownloadTemplate2() {  
        User usr = [SELECT Id FROM User WHERE Username = 'cdefghijk5657123456@gmail.com' LIMIT 1];
        system.runAs(usr)
        { 
        List<String> columnNames = new List<String>{'Case number','Resolution Comments','Resolution Reason', 'Description'};
            ListView lv = [Select Id, SobjectType, DeveloperName from ListView where SobjectType = 'Case' and DeveloperName = 'RecentlyViewedCases' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new ASF_ListViewAPIMock());
        Test.startTest();
        Wellness_BulkCloseCaseConverterUtility utility = new Wellness_BulkCloseCaseConverterUtility();
        utility.prepareDownloadTemplate(columnNames, 'Case', lv.Id, null);
        Test.stopTest();
        }
    }
}