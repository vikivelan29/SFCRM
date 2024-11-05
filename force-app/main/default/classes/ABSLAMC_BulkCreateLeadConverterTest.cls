@isTest
public class ABSLAMC_BulkCreateLeadConverterTest {
    
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
    static void testConvertJSONRows_Success() {
        ABSLAMC_BulkCreateLeadConverterUtility utility = new ABSLAMC_BulkCreateLeadConverterUtility();
        
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'test';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;
        ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
        lineitem.Bulk_Upload_Header__c = headObj.Id;
        insert lineitem;
        
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Folio":"LAN1234","CLIENT CODE - LOB +PAN/PERKN":"ABFL1234","Assigned User - AD ID":"userFed123","LOB":"Retail","Mobile No":"1234567890","Customer Type - Prospect / Existing customer":"Prospect","First Name":"John","Last Name":"Doe","Lead Category":"Category1","Lead Type":"Type1","Lead Sub-Type":"SubType1","Comments/Remarks":"Test comment","Lead Status":"Open"}');
        
        ASF_BulkCaseProcessorUtility.ConvertionResult result = utility.convertJSONRows(jsonRows);
        
        System.assertEquals(1, result.resultRecords.size(), 'Expected one Lead record to be created');
        Lead createdLead = (Lead)result.resultRecords.get(lineitem.Id);
        System.debug('resultRecords: '+result.resultRecords);
        System.debug('Lead: '+createdLead.Account__c);
    }
    
    @IsTest
    static void testConvertJSONRows_ValidationErrors() {
        ABSLAMC_BulkCreateLeadConverterUtility utility = new ABSLAMC_BulkCreateLeadConverterUtility();
        
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'test';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;
        ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
        lineitem.Bulk_Upload_Header__c = headObj.Id;
        insert lineitem;
        
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Folio":"LAN1234","CLIENT CODE - LOB +PAN/PERKN":"ABFL1234","Assigned User - AD ID":"userFed123","LOB":"","Mobile No":"1234567890","Customer Type - Prospect / Existing customer":"Prospect","First Name":"John","Last Name":"Doe","Lead Category":"Category1","Lead Type":"Type1","Lead Sub-Type":"SubType1","Comments/Remarks":"Test comment","Lead Status":"Open"}');
        ASF_BulkCaseProcessorUtility.ConvertionResult result = utility.convertJSONRows(jsonRows);
        System.assertEquals(0, result.resultRecords.size(), 'No Leads should be created');
        String errorMessage = result.resultJSONMapRows.get(lineitem.Id).get('Message');
        System.assertEquals('lob is required', errorMessage, 'Expected LOB error message');
    }
    
    @IsTest
    static void testConvertJSONRows_MissingClientCodeForExistingCustomer() {
        ABSLAMC_BulkCreateLeadConverterUtility utility = new ABSLAMC_BulkCreateLeadConverterUtility();
        
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'test';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;
        ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
        lineitem.Bulk_Upload_Header__c = headObj.Id;
        insert lineitem;
        
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Folio":"LAN1234","CLIENT CODE - LOB +PAN/PERKN":"","Assigned User - AD ID":"userFed123","LOB":"Retail","Mobile No":"1234567890","Customer Type - Prospect / Existing customer":"Existing customer","First Name":"John","Last Name":"Doe","Lead Category":"Category1","Lead Type":"Type1","Lead Sub-Type":"SubType1","Comments/Remarks":"Test comment","Lead Status":"Open"}');
        ASF_BulkCaseProcessorUtility.ConvertionResult result = utility.convertJSONRows(jsonRows);
        System.assertEquals(0, result.resultRecords.size(), 'No Leads should be created');
        String errorMessage = result.resultJSONMapRows.get(lineitem.Id).get('Message');
        System.assertEquals('CLIENT CODE - LOB +PAN/PERKN  is required', errorMessage, 'Expected client code error for existing customer');
    }
    
    @IsTest
    static void testConvertJSONRows_MissingMobile() {
        ABSLAMC_BulkCreateLeadConverterUtility utility = new ABSLAMC_BulkCreateLeadConverterUtility();
        
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'test';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;
        ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
        lineitem.Bulk_Upload_Header__c = headObj.Id;
        insert lineitem;
        
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Folio":"LAN1234","CLIENT CODE - LOB +PAN/PERKN":"","Assigned User - AD ID":"userFed123","LOB":"Retail","Mobile No":"","Customer Type - Prospect / Existing customer":"Existing customer","First Name":"John","Last Name":"Doe","Lead Category":"Category1","Lead Type":"Type1","Lead Sub-Type":"SubType1","Comments/Remarks":"Test comment","Lead Status":"Open"}');
        ASF_BulkCaseProcessorUtility.ConvertionResult result = utility.convertJSONRows(jsonRows);
        System.assertEquals(0, result.resultRecords.size(), 'No Leads should be created');
        String errorMessage = result.resultJSONMapRows.get(lineitem.Id).get('Message');
        System.assertEquals('mobile no is required', errorMessage, 'Expected client code error for existing customer');
    }
    
    @IsTest
    static void testConvertJSONRows_MissingCustomerType() {
        ABSLAMC_BulkCreateLeadConverterUtility utility = new ABSLAMC_BulkCreateLeadConverterUtility();
        
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'test';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;
        ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
        lineitem.Bulk_Upload_Header__c = headObj.Id;
        insert lineitem;
        
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Folio":"LAN1234","CLIENT CODE - LOB +PAN/PERKN":"","Assigned User - AD ID":"userFed123","LOB":"Retail","Mobile No":"1234567890","Customer Type - Prospect / Existing customer":"","First Name":"John","Last Name":"Doe","Lead Category":"Category1","Lead Type":"Type1","Lead Sub-Type":"SubType1","Comments/Remarks":"Test comment","Lead Status":"Open"}');
        ASF_BulkCaseProcessorUtility.ConvertionResult result = utility.convertJSONRows(jsonRows);
        System.assertEquals(0, result.resultRecords.size(), 'No Leads should be created');
        String errorMessage = result.resultJSONMapRows.get(lineitem.Id).get('Message');
        System.assertEquals('Customer Type is required', errorMessage, 'Expected client code error for existing customer');
    }
    
    @IsTest
    static void testConvertJSONRows_MissingLeadCategory() {
        ABSLAMC_BulkCreateLeadConverterUtility utility = new ABSLAMC_BulkCreateLeadConverterUtility();
        
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'test';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;
        ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
        lineitem.Bulk_Upload_Header__c = headObj.Id;
        insert lineitem;
        
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Folio":"LAN1234","CLIENT CODE - LOB +PAN/PERKN":"","Assigned User - AD ID":"userFed123","LOB":"Retail","Mobile No":"1234567890","Customer Type - Prospect / Existing customer":"Existing customer","First Name":"John","Last Name":"Doe","Lead Category":"","Lead Type":"Type1","Lead Sub-Type":"SubType1","Comments/Remarks":"Test comment","Lead Status":"Open"}');
        ASF_BulkCaseProcessorUtility.ConvertionResult result = utility.convertJSONRows(jsonRows);
        System.assertEquals(0, result.resultRecords.size(), 'No Leads should be created');
        String errorMessage = result.resultJSONMapRows.get(lineitem.Id).get('Message');
        System.assertEquals('Lead Category is required', errorMessage, 'Expected client code error for existing customer');
    }
    
    @IsTest
    static void testConvertJSONRows_MissingLeadType() {
        ABSLAMC_BulkCreateLeadConverterUtility utility = new ABSLAMC_BulkCreateLeadConverterUtility();
        
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'test';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;
        ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
        lineitem.Bulk_Upload_Header__c = headObj.Id;
        insert lineitem;
        
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Folio":"LAN1234","CLIENT CODE - LOB +PAN/PERKN":"","Assigned User - AD ID":"userFed123","LOB":"Retail","Mobile No":"1234567890","Customer Type - Prospect / Existing customer":"Existing customer","First Name":"John","Last Name":"Doe","Lead Category":"Cat1","Lead Type":"","Lead Sub-Type":"SubType1","Comments/Remarks":"Test comment","Lead Status":"Open"}');
        ASF_BulkCaseProcessorUtility.ConvertionResult result = utility.convertJSONRows(jsonRows);
        System.assertEquals(0, result.resultRecords.size(), 'No Leads should be created');
        String errorMessage = result.resultJSONMapRows.get(lineitem.Id).get('Message');
        System.assertEquals('Lead Type is required', errorMessage, 'Expected client code error for existing customer');
    }
    
    @IsTest
    static void testConvertJSONRows_MissingLeadSubType() {
        ABSLAMC_BulkCreateLeadConverterUtility utility = new ABSLAMC_BulkCreateLeadConverterUtility();
        
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'test';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;
        ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
        lineitem.Bulk_Upload_Header__c = headObj.Id;
        insert lineitem;
        
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Folio":"LAN1234","CLIENT CODE - LOB +PAN/PERKN":"","Assigned User - AD ID":"userFed123","LOB":"Retail","Mobile No":"1234567890","Customer Type - Prospect / Existing customer":"Existing customer","First Name":"John","Last Name":"Doe","Lead Category":"Cat1","Lead Type":"Type1","Lead Sub-Type":"","Comments/Remarks":"Test comment","Lead Status":"Open"}');
        ASF_BulkCaseProcessorUtility.ConvertionResult result = utility.convertJSONRows(jsonRows);
        System.assertEquals(0, result.resultRecords.size(), 'No Leads should be created');
        String errorMessage = result.resultJSONMapRows.get(lineitem.Id).get('Message');
        System.assertEquals('leadSubType is required', errorMessage, 'Expected client code error for existing customer');
    }
    
    @IsTest
    static void testConvertJSONRows_MissingLastName() {
        ABSLAMC_BulkCreateLeadConverterUtility utility = new ABSLAMC_BulkCreateLeadConverterUtility();
        
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'test';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;
        ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
        lineitem.Bulk_Upload_Header__c = headObj.Id;
        insert lineitem;
        
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Folio":"LAN1234","CLIENT CODE - LOB +PAN/PERKN":"ABFL1234","Assigned User - AD ID":"userFed123","LOB":"Retail","Mobile No":"1234567890","Customer Type - Prospect / Existing customer":"Prospect","First Name":"John","Last Name":"","Lead Category":"Cat1","Lead Type":"Type1","Lead Sub-Type":"subType1","Comments/Remarks":"Test comment","Lead Status":"Open"}');
        ASF_BulkCaseProcessorUtility.ConvertionResult result = utility.convertJSONRows(jsonRows);
        System.assertEquals(0, result.resultRecords.size(), 'No Leads should be created');
        String errorMessage = result.resultJSONMapRows.get(lineitem.Id).get('Message');
        System.assertEquals('Last Name is required', errorMessage, 'Expected client code error for existing customer');
    }
    
    
    
    @IsTest
    static void testPrepareDownloadTemplate() {
        ABSLAMC_BulkCreateLeadConverterUtility utility = new ABSLAMC_BulkCreateLeadConverterUtility();
        List<String> columnNames = new List<String>{
            'LOB', 
                'Folio', 
                'CLIENT CODE - LOB +PAN/PERKN', 
                'PAN', 
                'PERKN', 
                'Mobile No', 
                'First Name', 
                'Last Name', 
                'Lead Category', 
                'Lead Type', 
                'Lead Sub-Type', 
                'Comments/Remarks', 
                'Assigned User - AD ID', 
                'Lead Status'
                };
                    
        Id listViewId = null;
        List<Id> selectedRecordIds = new List<Id>{[SELECT Id FROM Lead LIMIT 1].Id};    
        List<Map<String, String>> result = utility.prepareDownloadTemplate(columnNames, 'Lead', listViewId, selectedRecordIds);
       // Id lstviewId = '12234';
       // List<Map<String, String>> resultlstView = utility.prepareDownloadTemplate(columnNames, 'Lead', lstviewId, selectedRecordIds);
        List<Map<String,String>> result1 = utility.prepareCtstData(columnNames, 'ABSLAMC');
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Expected one record to be returned');
        System.assertNotEquals(null, result1, 'Result should not be null');
        
    }
}