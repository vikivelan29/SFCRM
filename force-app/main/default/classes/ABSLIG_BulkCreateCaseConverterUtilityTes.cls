@isTest
public class ABSLIG_BulkCreateCaseConverterUtilityTes {

    @testSetup
    static void setupTestData() {

        // Create ASF_Case_Category_Config__c Records
        ASF_Case_Category_Config__c config1 = new ASF_Case_Category_Config__c(CCC_External_Id__c='ABSLIG_Req_001', Type__c='Polad', Sub_Type__c='Polad_Deletions');
        insert config1;

        // Create an Account with Client_Code__c
        Account testAccount = new Account(Name = 'Test Account', Client_Code__c = '6672118503');
        insert testAccount;
        
        // Create an Asset linked to the Account
        Asset testAsset = new Asset(Name = 'Test Asset', Policy_No__c = 'LAN1234', AccountId = testAccount.Id, Business_Unit__c = ASF_Constants.ABSLIG_BU);
        insert testAsset;
        
        // Create a Case
        Case testCase = new Case(Subject = 'Test Case');
        testCase.AssetId = testAsset.Id;
        testCase.AccountId = testAccount.Id;
        insert testCase;
    }

    @isTest
    static void testConvertJSONRowsWithInvalidData() {
        // Retrieve the created test data
        Case testCase = [SELECT Id, AssetId, AccountId FROM Case WHERE Subject = 'Test Case' LIMIT 1];

        // Prepare JSON rows
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(testCase.Id, '{"Client Code":"5672118503", "Asset":"LAN1234", "Issue Code":"", "Description":"DescriptionXYZ", "Subject":"Case Subject"}');

        // Call the method to be tested
        ABSLIG_BulkCreateCaseConverterUtility converter1 = new ABSLIG_BulkCreateCaseConverterUtility();
        ASF_BulkCaseProcessorUtility.ConvertionResult result1 = converter1.convertJSONRows(jsonRows);
        // Assert the results when issue type is null
        String issueCode = result1.resultJSONMapRows.get(testCase.Id).get('Message');
        System.assertEquals(issueCode, 'Issue Type Code is required', 'Issue Type Code is required');

        jsonRows.put(testCase.Id, '{"Client Code":"5672118503", "Asset":"LAN1234", "Issue Code":"ABSLIG_Req_001", "Description":"DescriptionXYZ", "Subject":""}');

        // Call the method to be tested
        ABSLIG_BulkCreateCaseConverterUtility converter2 = new ABSLIG_BulkCreateCaseConverterUtility();
        ASF_BulkCaseProcessorUtility.ConvertionResult result2 = converter2.convertJSONRows(jsonRows);
        // Assert the results when subject is null
        String subject = result2.resultJSONMapRows.get(testCase.Id).get('Message');
        System.assertEquals(subject, 'Subject is required', 'Subject is required');

        jsonRows.put(testCase.Id, '{"Client Code":"5672118503", "Asset":"LAN1234", "Issue Code":"ABSLIG_Req_001", "Description":null, "Subject":"Case is resolved"}');

        // Call the method to be tested
        ABSLIG_BulkCreateCaseConverterUtility converter3 = new ABSLIG_BulkCreateCaseConverterUtility();
        ASF_BulkCaseProcessorUtility.ConvertionResult result3 = converter3.convertJSONRows(jsonRows);
        // Assert the results when description is required
        String description = result3.resultJSONMapRows.get(testCase.Id).get('Message');
        System.assertEquals(description, 'Description is required', 'Description is required');

        jsonRows.put(testCase.Id, '{"Client Code":"5672118503", "Asset":"LAN1234", "Issue Code":"ABSLIG_Req_002", "Description":"DescriptionXYZ", "Subject":"Case is not resolved"}');

        // Call the method to be tested
        ABSLIG_BulkCreateCaseConverterUtility converter4 = new ABSLIG_BulkCreateCaseConverterUtility();
        ASF_BulkCaseProcessorUtility.ConvertionResult result4 = converter4.convertJSONRows(jsonRows);
        // Assert the results when issue type code is not valid
        String issueTypeCode = result4.resultJSONMapRows.get(testCase.Id).get('Message');
        System.assertEquals(issueTypeCode, 'Issue Type Code is not valid', 'Issue Type Code is not valid');

        jsonRows.put(testCase.Id, '{"Client Code":"5672118503", "Asset":"LAN_XX123", "Issue Code":"ABSLIG_Req_001", "Description":"DescriptionXYZ", "Subject":"Case is not resolved"}');

        // Call the method to be tested
        ABSLIG_BulkCreateCaseConverterUtility converter5 = new ABSLIG_BulkCreateCaseConverterUtility();
        ASF_BulkCaseProcessorUtility.ConvertionResult result5 = converter5.convertJSONRows(jsonRows);
        // Assert the results when Loan Account Number is not found
        String loanAccNo = result5.resultJSONMapRows.get(testCase.Id).get('Message');
        System.assertEquals(loanAccNo, 'Loan Account Number is not found', 'Loan Account Number is not found');

        jsonRows.put(testCase.Id, '{"Client Code":"6789056", "Asset":"LAN1234", "Issue Code":"ABSLIG_Req_001", "Description":"DescriptionXYZ", "Subject":"Case is not resolved"}');

        // Call the method to be tested
        ABSLIG_BulkCreateCaseConverterUtility converter6 = new ABSLIG_BulkCreateCaseConverterUtility();
        ASF_BulkCaseProcessorUtility.ConvertionResult result6 = converter6.convertJSONRows(jsonRows);
        // Assert the results when Loan Account Number is not found
        String clientCode = result6.resultJSONMapRows.get(testCase.Id).get('Message');
        System.assertEquals(clientCode, 'Client Code is not found', 'Client Code is not found');
    }

    @isTest
    static void testConvertJSONRowsWithValidData() {
        // Retrieve the created test data
        Case testCase = [SELECT Id FROM Case WHERE Subject = 'Test Case' LIMIT 1];

        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(testCase.Id, '{"Client Code":"6672118503", "Asset":"LAN1234", "Issue Code":"ABSLIG_Req_001", "Description":"DescriptionXYZ", "Subject":"Case Subject"}');

        // Call the method to be tested
        ABSLIG_BulkCreateCaseConverterUtility converter = new ABSLIG_BulkCreateCaseConverterUtility();
        ASF_BulkCaseProcessorUtility.ConvertionResult result = converter.convertJSONRows(jsonRows);

        // Assert the results
        System.assertEquals(1, result.resultRecords.size(), 'Case record is Found.');
    }

    @isTest
    static void testPrepareDownloadTemplate() {
        // Prepare test data
        List<String> columnNames = new List<String>{'Client Code', 'Asset', 'Issue Code', 'Description', 'Subject'};
        String objectName = 'Case';

        Case caseList = [SELECT Id FROM Case WHERE Subject = 'Test Case' LIMIT 1];
        List<Id> selectedRecordIds = new List<Id>();
        selectedRecordIds.add(caseList.Id);

        Test.startTest();
         	String listViewId = ASF_BulkCsvDownloadHelper.getRecentViewID('Case');
            ASF_BulkCsvDownload_MockTest mock = new ASF_BulkCsvDownload_MockTest();
            Test.setMock(HttpCalloutMock.class, mock);

            // Create instance of the utility class
            ABSLIG_BulkCreateCaseConverterUtility utilityWhenListViewIsNull = new ABSLIG_BulkCreateCaseConverterUtility();
            List<Map<String, String>> resultWhenListViewIsNull = utilityWhenListViewIsNull.prepareDownloadTemplate(columnNames, objectName, null, selectedRecordIds);
            // Verify results
            System.assertEquals(1, resultWhenListViewIsNull.size(), 'Result size is 1');

            // Create instance of the utility class
            ABSLIG_BulkCreateCaseConverterUtility utility = new ABSLIG_BulkCreateCaseConverterUtility();
            List<Map<String, String>> result = utility.prepareDownloadTemplate(columnNames, objectName, listViewId, new List<String>());
            // Verify results
            System.assertEquals(1, result.size(), 'Result size is 1');
        Test.stopTest();
    }
}