@isTest
public class ASF_BulkCaseProcessorTrigger_Test {
    
    @TestSetup
    public static void setupData(){
        
        ASF_TestDataFactory.createCaseRecords(1);
    }
    @isTest
    private static void BulkCaseProcessorTriggerTest() {
        List<Case> caseList = [select Id, CCC_External_Id__c, Stage__c, pending_clarification__c from case];
        
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'ABHFL_Create_Case';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;
        
        Test.startTest();
        List<String> recordIds = new List<String> {caseList[0].Id, caseList[0].Id};
            ASF_Bulk_Case_Processor__e chunkPE = new ASF_Bulk_Case_Processor__e();
            chunkPE.Template_Name__c = 'ABHFL_Create_Case';
            chunkPE.Record_IDs__c = String.valueOf(caseList[0].Id);
            chunkPE.Header_Row_Id__c = headObj.Id;
        EventBus.publish(chunkPE);
        Test.stopTest();
    }
    
    
}