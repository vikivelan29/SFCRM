/**
 * Class              :  ABHI_OmniDocUploadCtrlTestClass
 * Description        :  Test Class for ABHI_OmniDocUploadController
 * Author             :  Arshad(msharieff@salesforce.com)
 * Created Date       :  25/09/2024
 */

@IsTest
public class ABHI_OmniDocUploadCtrlTestClass {
    
    @TestSetup
    static void setupTestData(){
        //Create Case Category Config Record
        ASF_TestDataFactory.createCaseCategoryConfig();
        insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                          Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                          Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
        //Create Case
        List<Case> lstCases = ASF_TestDataFactory.createCaseRecords(1);
        
        Account objAccount = ASF_TestDataFactory.insertBusinessAccount('test','test');
        Asset objAsset = ASF_TestDataFactory.createAsset(objAccount.Id,'SavingsAccount');
        Lead objLead = ASF_TestDataFactory.createSalesProspectRecord();
        objAsset.Lead_Id__c ='Test';
        update objAsset;

        lstCases[0].AssetId = objAsset.Id;
        lstCases[0].Lead__c = objLead.Id;
        lstCases[0].Nature__c = 'Query';
        lstCases[0].Business_Unit__c = 'ABHI';
        lstCases[0].Lead__c = objLead.Id;
        lstCases[0].Status = 'Closed';
        update lstCases;
    }

    @IsTest
    static void unitTestMethod1(){
        List<Case> lstCases = [SELECT Id,Business_Unit__c,CaseNumber,Account.Client_Code__c, Status, 
                                    Type_Text__c,Sub_Type_Text__c,Nature__c,Lead__c,CreatedDate,AssetId,Asset.LAN__c,
                                    Asset.Lead_Id__c,AccountId,Account.Phone,Account.PersonMobilePhone,Account.RecordType.Name 
                                    FROM Case LIMIT 1];

        ContentVersion objCV = new ContentVersion();
        objCV.VersionData = Blob.valueof('test');
        objCV.IsSTP__c = true;
        objCV.Title = 'Test.pdf';
        objCV.PathOnClient = 'Test.pdf';
        insert objCV;

        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:objCV.Id].ContentDocumentId;
        ContentDocumentLink objCDL = new ContentDocumentLink();
        objCDL.ContentDocumentId = ContentDocumentId;
        objCDL.LinkedEntityId = lstCases[0].Id;
        objCDL.ShareType = 'V';
        insert objCDL;

        List<ContentVersion> lstContentVersion = [Select Id,Title,ContentDocumentId,VersionNumber,FileExtension,ContentDocument.ContentSize  
                                                    from ContentVersion where ContentDocumentId =:contentDocumentId];

        Test.startTest();
        
        ABHI_OmniDocUploadController.transferFilesToOmniDoc(new List<Id>{lstCases[0].Id});

        DMS_Files__c objDMSFile = ABHI_OmniDocUploadController.prepareDMSRecord(new DMS_Files__c(), lstCases[0], lstContentVersion[0], 1);

        List<DMS_Files__c> lstDMSFiles = new List<DMS_Files__c>();
        lstDMSFiles.add(objDMSFile);
        insert lstDMSFiles;
        
        ABHI_OmniDocUploadController.prepareDMSFileTransferRecord(new DMS_File_Transfer__e(), lstCases[0], objDMSFile);
        
        ABCL_RetryDMSFileTransfer.retryDMSFileTransfer(lstDMSFiles);

        ABHI_OmniDocUploadController.retryFileTransferToOmniDoc(lstDMSFiles,new List<Id>{lstCases[0].Id});
        
        try{
            Integer zero = 0;
            Integer result = 10 / zero;
        }catch (Exception e) {
            String methodName = 'LogExceptionTest.testLogException'; 
            ABHI_OmniDocUploadController.logException(e, methodName);
        }
        
        Database.ExecuteBatch(new ABCL_DMSRetryBatch());

        Test.stopTest();
    }

}