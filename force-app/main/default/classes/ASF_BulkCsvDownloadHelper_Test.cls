/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 06-30-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   06-28-2024   rsinghnagar@salesforce.com   Initial Version
**/
@isTest
public class ASF_BulkCsvDownloadHelper_Test {

    @TestSetup
    public static void setupData(){
    	 ASF_TestDataFactory.createCaseRecords(1);   
    }
    
    @isTest
    private static void getMetadataDetailsTest() {
        Test.startTest();
            ASF_BulkCsvController.getMetadataDetails('TestObjName'); 
        Test.stopTest();     
    }
    @isTest
    private static void getCSVTemplateTest() {
        Test.startTest();
            String result = ASF_BulkCsvController.getCSVTemplate('ABHFL_Create_Case');
        	String resultFalse = ASF_BulkCsvController.getCSVTemplate('test');
        	Assert.areNotEqual(result, '');
        Test.stopTest();     
    }
    @isTest
    private static void generateCSVFileWithDataTest() {
        Test.startTest();
        Id caseId = [select Id from case LIMIT 1].Id;
         	Object result = ASF_BulkCsvController.generateCSVFileWithData('ABHFL_Create_Case','test',caseId,'__Recent');
        	Assert.isNotNull(result);
        Test.stopTest();     
    }
    @isTest
    private static void generateCSVFileWithCtstTest() {
        Test.startTest();
        Id caseId = [select Id from case LIMIT 1].Id;
         	Object result = ASF_BulkCsvController.generateCSVFileWithCtst('ABSLI_Create_Case');
        	Assert.isNotNull(result);
        Test.stopTest();     
    }
    @isTest
    private static void fetchCSVUploadProgressTest() {
        Id caseId = [select Id from case LIMIT 1].Id;
        ASF_Bulk_Upload_Header__c headerRec = new ASF_Bulk_Upload_Header__c(Total_Rows__c=1,Status__c=' Pending',Template_Name__c='ABHFL_Create_Case');
        insert headerRec;
        ASF_Bulk_Upload_Line_Item__c bulkItemRec = new ASF_Bulk_Upload_Line_Item__c(Bulk_Upload_Header__c = headerRec.Id, Status__c = 'Failure');
        insert bulkItemRec;
        
        Test.startTest();
        ASF_BulkCsvController.CSVProgressWrapper result = ASF_BulkCsvController.fetchCSVUploadProgress(headerRec.Id, new List<Id>{caseId}, true);
        Assert.isNotNull(result);
        Object resultObj = ASF_BulkCsvController.downloadUploadResults(headerRec.Id);
        Test.stopTest();     
    }
    @isTest
    private static void getListViewSOQLTest() {
        Test.startTest();
        Id caseId = [select Id from case LIMIT 1].Id;
         	String listViewId = ASF_BulkCsvDownloadHelper.getRecentViewID('Case','__Recent');
            ASF_BulkCsvDownload_MockTest mock = new ASF_BulkCsvDownload_MockTest();
            Test.setMock(HttpCalloutMock.class, mock);
        	String resultQuery = ASF_BulkCsvDownloadHelper.getListViewSOQL('Case', listViewId);
        Test.stopTest();     
    }
}