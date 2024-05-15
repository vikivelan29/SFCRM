/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 05-02-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   05-02-2024   rsinghnagar@salesforce.com   Initial Version
**/
@IsTest
public class ABCL_RetryDMSFileTransferTest {
    @TestSetup
    static void setupTestData(){
        List<Case> caseRecList = ASF_TestDataFactory.createCaseRecords(2);
        caseRecList[0].MoveToNext__c = true;
        caseRecList[0].Status = 'Closed';
        caseRecList[0].Nature__c = 'Query';
        ASF_TriggerSkipperUtility.markTriggerRun('Case');
        caseRecList[1].MoveToNext__c = true;
        caseRecList[1].Status = 'Closed';
        caseRecList[1].Nature__c = 'Query';
        caseRecList[1].Business_Unit__c = ABFL_Constants.ABFL;
        ASF_TriggerSkipperUtility.markTriggerRun('Case');
        update caseRecList;
    }
    @IsTest 
    static void retryDMSFileTransferTest(){
        List<DMS_Files__c> fileRecList = new List<DMS_Files__c>();
        List<Case> caseRecords = [SELECT Id, No_Auto_Communication__c, AccountId, CCC_External_Id__c, ContactId,IsClosed FROM Case];
        for(integer i=0; i <= 1; i++){
            DMS_Files__c fileRec = new DMS_Files__c();
            fileRec.Case__c = caseRecords[i].Id;
            fileRec.ContentVersionId__c = 'test';
            fileRec.Status__c = ABFL_Constants.PENDING;
			fileRec.Business_Unit__c = ABHFL_Constants.BUSINESS_UNIT_ABHFL;
            DateTime currentDateTime = System.now();
            fileRec.DMS_External_ID__c = String.valueOf(i)+currentDateTime.getTime();
            fileRec.Next_Retry__c = System.now().addMinutes(15);
            fileRec.Retry_Attempt__c = 1;
            fileRecList.add(fileRec);
        }
        insert fileRecList;
        ABCL_RetryDMSFileTransfer.retryDMSFileTransfer(fileRecList);

        List<DMS_Files__c> updatedDMSFilesList = [SELECT Id FROM DMS_Files__c];
		Assert.isTrue(updatedDMSFilesList.size() > 2, 'New DMS files should have been inserted');
    }
    
    @IsTest 
    static void abflRetryDMSFileTransferTest(){
        List<DMS_Files__c> fileRecList = new List<DMS_Files__c>();
        List<Case> caseRecords = [SELECT Id, No_Auto_Communication__c, AccountId, CCC_External_Id__c, ContactId,IsClosed FROM Case];
        for(integer i=0; i <= 1; i++){
            DMS_Files__c fileRec = new DMS_Files__c();
            fileRec.Case__c = caseRecords[i].Id;
            fileRec.ContentVersionId__c = 'test';
            fileRec.Status__c = ABHFL_Constants.PENDING;
            DateTime currentDateTime = System.now();
            fileRec.DMS_External_ID__c = String.valueOf(i)+currentDateTime.getTime();
            fileRec.Next_Retry__c = System.now().addMinutes(15);
            fileRec.Retry_Attempt__c = 1;
            fileRecList.add(fileRec);
        }
        insert fileRecList;
        
        Test.startTest();
        ABCL_RetryDMSFileTransfer.retryDMSFileTransfer(fileRecList);
		Test.stopTest();
        
        List<DMS_Files__c> updatedDMSFilesList = [SELECT Id FROM DMS_Files__c];
		Assert.isTrue(updatedDMSFilesList.size() > 2, 'New DMS files should have been inserted');
    }
}