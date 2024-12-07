@isTest
public class ABSLIG_BulkCloseCaseConverterUtilityTest {
    
    @testSetup
    static void setupTestData() {

        Id preFrameworkRecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByName().get('Interaction').getRecordTypeId();

        // Create ASF_Case_Category_Config__c Records
        ASF_Case_Category_Config__c config1 = new ASF_Case_Category_Config__c(CCC_External_Id__c='ABSLIG_Req_001', Type__c='Polad', Sub_Type__c='Polad_Deletions');
        insert config1;

        // Create an Account with Client_Code__c
        Account testAccount = new Account(Name = 'Test Account', Client_Code__c = '6672118503');
        insert testAccount;
        
        // Create an Asset linked to the Account
        Asset testAsset = new Asset(Name = 'Test Asset', Policy_No__c = 'LAN1234', AccountId = testAccount.Id, Business_Unit__c = ASF_Constants.ABSLIG_BU);
        insert testAsset;
        
        List<Case> csList = new List<Case>();
        // Create a Case
        Case testCase = new Case(Subject = 'Test Case', Stage__c = 'New');
        testCase.AssetId = testAsset.Id;
        testCase.AccountId = testAccount.Id;
        testCase.Stage__c = 'New';
        csList.add(testCase);

        // Create a Case
        Case preFrameworkCase = new Case(Subject = 'Test Case 2', Stage__c = 'New',RecordTypeId = preFrameworkRecordTypeId, AccountId = null); 
        csList.add(preFrameworkCase);              

        Case case3 = new Case(Subject = 'Test Case 3', Stage__c = 'New', AccountId = testAccount.Id);      
        csList.add(case3); 
        insert csList;
    }
    
    @isTest
    static void testConvertJSONRowsValidCase() {
        // Retrieve the created test data
        Case testCase = [SELECT Id, AssetId, AccountId, CaseNumber FROM Case WHERE Subject = 'Test Case' LIMIT 1];
        String casenum = testCase.CaseNumber;
        // Prepare input data
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(testCase.Id, '{"Case number": "'+casenum+'","Stage":"Resolved","Close Unresolved Reason":"Others","Close Unresolved Details":"Sample text"}');
        // Call method
        ABSLIG_BulkCloseCaseConverterUtility utility = new ABSLIG_BulkCloseCaseConverterUtility();
        ASF_BulkCaseProcessorUtility.ConvertionResult result = utility.convertJSONRows(jsonRows);
        // Assert results
        System.assertEquals(1, result.resultRecords.size(), 'Expected one record to be processed');
        }
    
    @isTest
    static void testConvertJSONRowsInvalidCaseNumber() {
        
        Case testCase   = new Case();
        Case testCase2  = new Case();
        Case case3      = new Case();

        List<Case> testCaseList = [SELECT Id, RecordTypeId, Subject, AssetId, AccountId, CaseNumber, 
                                    IsClosed, Stage__c FROM Case];
        for(Case cs : testCaseList) {
            String subject = cs?.Subject ?? '';
            if(subject == 'Test Case') {
                testCase = cs;
            }
            else if(subject == 'Test Case 2') {
                testCase2 = cs;
            }
            else if(subject == 'Test Case 3') {
                case3 = cs;
            }
        }

        String casenum = testCase.CaseNumber;

        // Prepare JSON rows
        Map<Id, String> jsonRows = new Map<Id, String>();
        jsonRows.put(testCase.Id, '{"Case number":"","Stage":"Resolved","Close Unresolved Reason":"Others","Close Unresolved Details":"Sample text"}');
        
        // Call method
        ABSLIG_BulkCloseCaseConverterUtility utility1 = new ABSLIG_BulkCloseCaseConverterUtility();
        ASF_BulkCaseProcessorUtility.ConvertionResult result1 = utility1.convertJSONRows(jsonRows);

        // Assert results
        System.assertEquals(result1.resultJSONMapRows.get(testCase.Id).get('Message'), 'Case number is required', 'Case number is required');
        
        jsonRows.put(testCase.Id, '{"Case number": "'+casenum+'","Stage":"","Close Unresolved Reason":"Others","Close Unresolved Details":"Sample text"}');
        // Call method
        ABSLIG_BulkCloseCaseConverterUtility utility2 = new ABSLIG_BulkCloseCaseConverterUtility();
        ASF_BulkCaseProcessorUtility.ConvertionResult result2 = utility2.convertJSONRows(jsonRows);

        // Assert results
        System.assertEquals(result2.resultJSONMapRows.get(testCase.Id).get('Message'),'Stage is required','Stage is required');
        
        jsonRows.put(testCase.Id, '{"Case number": "000000","Stage":"Resolved","Close Unresolved Reason":"Others","Close Unresolved Details":"Sample text"}');
        // Call method
        ABSLIG_BulkCloseCaseConverterUtility utility4 = new ABSLIG_BulkCloseCaseConverterUtility();
        ASF_BulkCaseProcessorUtility.ConvertionResult result4 = utility4.convertJSONRows(jsonRows);

        // Assert results
        System.assertEquals(result4.resultJSONMapRows.get(testCase.Id).get('Message'),'Invalid Case Number','Invalid Case Number');
        
        jsonRows.put(testCase.Id, '{"Case number": "000000","Stage":"unresolved"}');
        // Call method
        ABSLIG_BulkCloseCaseConverterUtility utility5 = new ABSLIG_BulkCloseCaseConverterUtility();
        ASF_BulkCaseProcessorUtility.ConvertionResult result5 = utility5.convertJSONRows(jsonRows);

        // Assert results
        System.assertEquals(result5.resultJSONMapRows.get(testCase.Id).get('Message'),'Close Unresolved Reason is required', 'Close Unresolved Reason is required');

        testCase.Status = 'Closed';
        update testCase;

        jsonRows.put(testCase.Id, '{"Case number": "'+casenum+'","Stage":"Closed"}');
        // Call method
        ABSLIG_BulkCloseCaseConverterUtility utility6 = new ABSLIG_BulkCloseCaseConverterUtility();
        ASF_BulkCaseProcessorUtility.ConvertionResult result6 = utility6.convertJSONRows(jsonRows);
        System.assertEquals(result6.resultJSONMapRows.get(testCase.Id).get('Result'),'FAILURE', 'FAILURE');


        jsonRows.clear();
        jsonRows.put(testCase2.Id, '{"Case number": "'+testCase2.CaseNumber+'","Stage":"Open"}');
        // Call method
        ABSLIG_BulkCloseCaseConverterUtility utility7 = new ABSLIG_BulkCloseCaseConverterUtility();
        ASF_BulkCaseProcessorUtility.ConvertionResult result7 = utility7.convertJSONRows(jsonRows);
        System.assertEquals(result7.resultJSONMapRows.get(testCase2.Id).get('Result'),'FAILURE', 'FAILURE');

        jsonRows.put(case3.Id, '{"Case number": "'+case3.CaseNumber+'","Stage":"Unresolved","Close Unresolved Reason":"Others"}');
        // Call method
        ABSLIG_BulkCloseCaseConverterUtility utility8 = new ABSLIG_BulkCloseCaseConverterUtility();
        ASF_BulkCaseProcessorUtility.ConvertionResult result8 = utility8.convertJSONRows(jsonRows);
        System.assertEquals(result8.resultRecords.get(case3.Id).get('Status'),'Unresolved', 'Unresolved');
        
        jsonRows.put(case3.Id, '{"Case number": "'+case3.CaseNumber+'","Stage":"In Progress","Close Unresolved Reason":"Others"}');
        // Call method
        ABSLIG_BulkCloseCaseConverterUtility utility9 = new ABSLIG_BulkCloseCaseConverterUtility();
        ASF_BulkCaseProcessorUtility.ConvertionResult result9 = utility9.convertJSONRows(jsonRows);
        System.assertEquals(result9.resultJSONMapRows.get(case3.Id).get('Result'),'FAILURE', 'FAILURE');
    }
    
    @isTest
    static void testPrepareDownloadTemplateWithListView() { 
        List<String> columnNames = new List<String>{'Case number', 'Stage', 'Close Unresolved Reason', 'Close Unresolved Details'};
        
        Case caseList = [SELECT Id, CaseNumber FROM Case WHERE Subject = 'Test Case' LIMIT 1];
        List<Id> selectedRecordIds = new List<Id>();
        selectedRecordIds.add(caseList.Id);
        Test.startTest();
        
        	String listViewId = ASF_BulkCsvDownloadHelper.getRecentViewID('Case','RecentlyViewedCases');
        	ASF_BulkCsvDownload_MockTest mock = new ASF_BulkCsvDownload_MockTest();
            Test.setMock(HttpCalloutMock.class, mock);
        	// Call method
        	ABSLIG_BulkCloseCaseConverterUtility utility = new ABSLIG_BulkCloseCaseConverterUtility();
        	List<Map<String, String>> result = utility.prepareDownloadTemplate(columnNames, 'Case', listViewId, null);

        // Assert results
        
        System.assertEquals(caseList.CaseNumber, result[0].get('Case number'), 'Expected Case number to match');
    }
}