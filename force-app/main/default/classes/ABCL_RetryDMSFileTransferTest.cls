@IsTest
public class ABCL_RetryDMSFileTransferTest {
    @TestSetup
    static void setupTestData(){
        List<Case> caseRecList = ASF_TestDataFactory.createCaseRecords(1);
        caseRecList[0].MoveToNext__c = true;
        caseRecList[0].Status = 'Closed';
        caseRecList[0].Nature__c = 'Query';
        ASF_TriggerSkipperUtility.markTriggerRun('Case');
        update caseRecList;
    }
    @IsTest 
    static void retryDMSFileTransferTest(){
        List<DMS_Files__c> fileRecList = new List<DMS_Files__c>();
        List<Case> caseRecords = [SELECT Id, No_Auto_Communication__c, AccountId, CCC_External_Id__c, ContactId,IsClosed FROM Case LIMIT 1];
        system.debug(caseRecords);
        for(integer i=0; i <= 1; i++){
            DMS_Files__c fileRec = new DMS_Files__c();
            fileRec.Case__c = caseRecords[0].Id;
            fileRec.ContentVersionId__c = 'test';
            fileRec.Status__c = ABHFL_Constants.PENDING;
            DateTime currentDateTime = System.now();
            fileRec.DMS_External_ID__c = String.valueOf(i)+currentDateTime.getTime();
            fileRec.Next_Retry__c = System.now().addMinutes(15);
            fileRec.Retry_Attempt__c = i;
            fileRecList.add(fileRec);
        }
        insert fileRecList;
        ABCL_RetryDMSFileTransfer.retryDMSFileTransfer(new List<DMS_Files__c>{fileRecList[1]});
    }
}