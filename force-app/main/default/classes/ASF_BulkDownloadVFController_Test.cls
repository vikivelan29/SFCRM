@isTest
public class ASF_BulkDownloadVFController_Test {

    @isTest
    static void testController() {
        ASF_TestDataFactory.createCaseRecords(2);
        
        List<Case> testCases = [select id from case];
        ApexPages.StandardSetController standardController = new ApexPages.StandardSetController(testCases);
        standardController.setSelected(testCases);
        ASF_BulkDownloadVFController controller = new ASF_BulkDownloadVFController(standardController);
        System.assertEquals(testCases.size(), controller.selectedRecordsList.size(), 'Selected cases list should match inserted cases');
    }
}