@isTest
public class ABSLAMC_BulkCloseLeadConverterTest {
    
    @TestSetup
    static void setupTestData() {
        Asset testAsset = new Asset(LAN__c = 'LAN1234', Business_Unit__c = 'ABSLAMC',Name = 'TestAsset');
        insert testAsset;
        
        Account testAccount = new Account(LOB_Client_Code__c = 'ABFL1234',Name = 'TestAccount');
        insert testAccount;
        
        User newUser = new User(
            FirstName = 'John',
            LastName = 'Doe',
            Alias = 'jdoe',
            Email = 'john.doe@example.com',
            Username = 'john.doe001@example.com',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            FederationIdentifier = 'userFed123'
        );
        
        insert newUser;
        
        Lead testLead = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            MobilePhone = '1234567890',
            Status = 'Open',
            OwnerId = newUser.Id,
            Account__c = testAccount.Id
        );
        insert testLead;
    }
    
    @IsTest
    static void testConvertJSONRows() {
        ABSLAMC_BulkCloseLeadConverterUtility utility = new ABSLAMC_BulkCloseLeadConverterUtility();
        
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'test';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;
        ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
        lineitem.Bulk_Upload_Header__c = headObj.Id;
        insert lineitem;
        
        Lead l1 = [SELECT Id, Lead_Number__c FROM Lead LIMIT 1]; 


        String jsonString = '{"Lead ID (System Identifier)":"' + l1.Lead_Number__c + '","Lead Status (Won/Lost)":"Won","Comments/Remarks":""}';
        
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, jsonString);
        ASF_BulkCaseProcessorUtility.ConvertionResult result = utility.convertJSONRows(jsonRows);
        //System.assertEquals(1, result.resultRecords.size(), 'Expected one Lead record to be closed');
    }
    
    @IsTest
    static void testConvertJSONRows1() {
        ABSLAMC_BulkCloseLeadConverterUtility utility = new ABSLAMC_BulkCloseLeadConverterUtility();
        
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'test';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;
        ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
        lineitem.Bulk_Upload_Header__c = headObj.Id;
        insert lineitem;
        
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Lead ID (System Identifier)":"","Lead Status (Won/Lost)":"Won","Comments/Remarks":""}');
        ASF_BulkCaseProcessorUtility.ConvertionResult result = utility.convertJSONRows(jsonRows);
        //System.assertEquals(1, result.resultRecords.size(), 'Expected one Lead record to be closed');
    }
    
    @IsTest
    static void testConvertJSONRows2() {
        ABSLAMC_BulkCloseLeadConverterUtility utility = new ABSLAMC_BulkCloseLeadConverterUtility();
        
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'test';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;
        ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
        lineitem.Bulk_Upload_Header__c = headObj.Id;
        insert lineitem;
        
         Lead l1 = [SELECT Id, Lead_Number__c FROM Lead LIMIT 1]; 


        String jsonString = '{"Lead ID (System Identifier)":"' + l1.Lead_Number__c + '","Lead Status (Won/Lost)":"","Comments/Remarks":""}';
        
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, jsonString);
        ASF_BulkCaseProcessorUtility.ConvertionResult result = utility.convertJSONRows(jsonRows);
        //System.assertEquals(1, result.resultRecords.size(), 'Expected one Lead record to be closed');
    }
    
    @IsTest
    static void testConvertJSONRows3() {
        ABSLAMC_BulkCloseLeadConverterUtility utility = new ABSLAMC_BulkCloseLeadConverterUtility();
        
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'test';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;
        ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
        lineitem.Bulk_Upload_Header__c = headObj.Id;
        insert lineitem;
         Lead l1 = [SELECT Id, Lead_Number__c FROM Lead LIMIT 1];


        String jsonString = '{"Lead ID (System Identifier)":"' + l1.Lead_Number__c + '","Lead Status (Won/Lost)":"ABCH","Comments/Remarks":""}';
        
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, jsonString);
    }
    
    @IsTest
    static void testConvertJSONRows_MissingStatus() {
        ABSLAMC_BulkCloseLeadConverterUtility utility = new ABSLAMC_BulkCloseLeadConverterUtility();
        
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'test';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;
        ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
        lineitem.Bulk_Upload_Header__c = headObj.Id;
        insert lineitem;
        
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Lead ID (System Identifier)":"L-1234","Lead Status (Won/Lost)":"","Comments/Remarks":"testtt"}');
        ASF_BulkCaseProcessorUtility.ConvertionResult result = utility.convertJSONRows(jsonRows);
    }
    
    @IsTest
    static void testPrepareDownloadTemplate() {
        ABSLAMC_BulkCloseLeadConverterUtility utility = new ABSLAMC_BulkCloseLeadConverterUtility();
        List<String> columnNames = new List<String>{'Lead ID (System Identifier)','Lead Status (Won/Lost)','Comments/Remarks'};
        Id listViewId = null;
        List<Id> selectedRecordIds = new List<Id>{[SELECT Id FROM Lead LIMIT 1].Id};    
        List<Map<String, String>> result = utility.prepareDownloadTemplate(columnNames, 'Lead', listViewId, selectedRecordIds);
        List<Map<String,String>> result1 = utility.prepareCtstData(columnNames, 'ABSLAMC');
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Expected one record to be returned');
        System.assertNotEquals(null, result1, 'Result should not be null');
        
    }
    
    @IsTest
    static void testprepareCtstData() {        
        List<String> columnNames = new List<String>{'Lead ID (System Identifier)','Lead Status (Won/Lost)','Comments/Remarks'};
        Test.startTest();
        ABSLAMC_BulkCloseLeadConverterUtility utility = new ABSLAMC_BulkCloseLeadConverterUtility();
        utility.prepareCtstData(columnNames, 'ABSLAMC');
        Test.stopTest();

    }

}