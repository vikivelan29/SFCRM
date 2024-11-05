@isTest
public class ABSLAMC_BulkAssignLeadConverterTest {
    @isTest
    static void testConvertJSONRows() {
        Lead lead = new Lead(LastName = 'Test Lead', Company = 'Test Company');
        insert lead;
        Lead l1 = [Select Id,Lead_Number__c from Lead LIMIT 1];
        System.debug('L: '+l1.Lead_Number__c);
        
        User user = new User(
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
        insert user;
        
        Group queue = new Group(Name = 'ABSLAMC_TestQueue', Type = 'Queue', DeveloperName = 'ABSLAMC_TestQueue');
        insert queue;
        
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'test';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;
        ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
        lineitem.Bulk_Upload_Header__c = headObj.Id;
        insert lineitem;
        
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(lineitem.Id, '{"Lead ID (System Identifier)":"00QBl00000DVsXmMAL","Assigned Team":"ABSLAMC_TestQueue","Assigned User - AD ID":"userFed123"}');
        
        ABSLAMC_BulkAssignLeadConverterUtility converterUtility = new ABSLAMC_BulkAssignLeadConverterUtility();
        ASF_BulkCaseProcessorUtility.ConvertionResult result = converterUtility.convertJSONRows(jsonRows);
        System.assertNotEquals(null, result);
        System.assertEquals(1, result.resultJSONRows.size());
    }
  
    
    @isTest
static void testConvertJSONRows_AssgnUserMissing() {
    // Insert lead record
    Lead lead = new Lead(LastName = 'Test Lead', Company = 'Test Company');
    insert lead;

    // Insert user record
    User user = new User(
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
    insert user;

    // Insert queue (group) record
    Group queue = new Group(Name = 'ABSLAMC_TestQueue', Type = 'Queue', DeveloperName = 'ABSLAMC_TestQueue');
    insert queue;

    // Insert bulk upload header and line item
    ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
    headObj.Template_Name__c = 'test';
    headObj.Total_Rows__c = 1;
    headObj.Status__c = 'Pending';
    insert headObj;

    ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
    lineitem.Bulk_Upload_Header__c = headObj.Id;
    insert lineitem;
    
   Lead l1 = [Select Id,Lead_Number__c from Lead LIMIT 1];

    // Prepare test JSON data with missing 'Assigned Team' and 'Assigned User - AD ID'
    Map<Id, String> jsonRows = new Map<Id, String>();
    String jsonString = '{"Lead ID (System Identifier)":"' + l1.Lead_Number__c + '","Assigned Team":"","Assigned User - AD ID":""}';
    jsonRows.put(lineitem.Id,jsonString);

    // Invoke the converter method
    ABSLAMC_BulkAssignLeadConverterUtility converterUtility = new ABSLAMC_BulkAssignLeadConverterUtility();
    ASF_BulkCaseProcessorUtility.ConvertionResult result = converterUtility.convertJSONRows(jsonRows);

    // Validate the result
    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(1, result.resultJSONRows.size(), 'There should be one result row');

    // Check for the correct error message in the result
    Map<String, String> resultMap = result.resultJSONMapRows.get(lineitem.Id);
    System.assertEquals('FAILURE', resultMap.get('Result'), 'Result should be FAILURE due to missing assignment info');
    //System.assertEquals('Assigned Team OR Assigned User - AD ID is required', resultMap.get('Message'), 'Error message should indicate missing assignment details');
}
    
    @isTest
static void testConvertJSONRows_MissingLeadNumber() {
    // Insert lead record
    Lead lead = new Lead(LastName = 'Test Lead', Company = 'Test Company');
    insert lead;

    // Insert user record
    User user = new User(
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
    insert user;

    // Insert queue (group) record
    Group queue = new Group(Name = 'ABSLAMC_TestQueue', Type = 'Queue', DeveloperName = 'ABSLAMC_TestQueue');
    insert queue;

    // Insert bulk upload header and line item
    ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
    headObj.Template_Name__c = 'test';
    headObj.Total_Rows__c = 1;
    headObj.Status__c = 'Pending';
    insert headObj;

    ASF_Bulk_Upload_Line_Item__c lineitem = new ASF_Bulk_Upload_Line_Item__c();
    lineitem.Bulk_Upload_Header__c = headObj.Id;
    insert lineitem;

    // Prepare test JSON data with missing 'Assigned Team' and 'Assigned User - AD ID'
    Map<Id, String> jsonRows = new Map<Id, String>();
    jsonRows.put(lineitem.Id, '{"Lead ID (System Identifier)":"","Assigned Team":"ABSLAMC_TestQueue","Assigned User - AD ID":"userFed123"}');

    // Invoke the converter method
    ABSLAMC_BulkAssignLeadConverterUtility converterUtility = new ABSLAMC_BulkAssignLeadConverterUtility();
    ASF_BulkCaseProcessorUtility.ConvertionResult result = converterUtility.convertJSONRows(jsonRows);

    // Validate the result
    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(1, result.resultJSONRows.size(), 'There should be one result row');

    // Check for the correct error message in the result
    Map<String, String> resultMap = result.resultJSONMapRows.get(lineitem.Id);
    System.assertEquals('FAILURE', resultMap.get('Result'), 'Result should be FAILURE due to missing assignment info');
    //System.assertEquals('Assigned Team OR Assigned User - AD ID is required', resultMap.get('Message'), 'Error message should indicate missing assignment details');
}


    
    
    @isTest
    static void testPrepareDownloadTemplate() {
        Lead lead = new Lead(LastName = 'Test Lead', Company = 'Test Company');
        insert lead;
        System.debug('Lead:'+lead);
        
        User user = new User(
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
        insert user;
        
        List<String> columnNames = new List<String>{'Lead ID (System Identifier)', 'Assigned Team', 'Assigned User - AD ID'};
            String objectName = 'Lead';
        Id listViewId = null; 
        List<String> selectedRecordIds = new List<String>{lead.Id};
            
            ABSLAMC_BulkAssignLeadConverterUtility converterUtility = new ABSLAMC_BulkAssignLeadConverterUtility();
        List<Map<String, String>> records = converterUtility.prepareDownloadTemplate(columnNames, objectName, listViewId, selectedRecordIds);
        System.assertNotEquals(null, records);
        System.assertEquals(1, records.size());
        System.assertEquals(' ', records[0].get('Assigned Team'));
    }
}