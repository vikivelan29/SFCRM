@isTest(seeAllData=false)
public class ASF_DownloadCCController_Test {

    @TestSetup
    public static void setupData(){
    	 ASF_TestDataFactory.createCaseCategoryConfig();   
    }
    
    @isTest
    private static void constructorTest() {
        Test.startTest();
        ASF_Case_Category_Config__c caseCatConfig = [select Id from ASF_Case_Category_Config__c LIMIT 1];
        ApexPages.StandardController stdController = new ApexPages.StandardController(caseCatConfig);
        ASF_DownloadCCCController controller = new ASF_DownloadCCCController(stdController);
        System.assertEquals(caseCatConfig.Id, controller.cccId);
        Test.stopTest();     
    }
    @isTest
    private static void getConfigDataTest() {
        Test.startTest();
        ASF_Case_Category_Config__c caseCatConfig = [select Id from ASF_Case_Category_Config__c LIMIT 1];
        List<Map<String,Object>> result = ASF_DownloadCCCController.getConfigData(caseCatConfig.Id);
        Test.stopTest();     
    }
}