/**
 * Class              :  ABHI_OmniDocUploadCtrlTestClass
 * Description        :  Test Class for ABHI_OmniDocUploadController
 * Author             :  Arshad(msharieff@salesforce.com)
 * Created Date       :  25/09/2024
 */
@SuppressWarnings('PMD.CyclomaticComplexity,PMD.StdCyclomaticComplexity,PMD.CognitiveComplexity,PMD.ExcessivePublicCount,PMD.IfStmtsMustUseBraces,PMD.IfElseStmtsMustUseBraces,PMD.AvoidDeeplyNestedIfStmts,PMD.ExcessiveParameterList,PMD.NcssMethodCount,PMD.ClassNamingConventions,PMD.FieldNamingConventions,PMD.VariableNamingConventions')
@IsTest
public class ABHI_OmniDocUploadCtrlTestClass {
    
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - testDataSetup
    * @description - This method will be used to create testdata setup
    *****************************************************************************************************************/
    @TestSetup
    static void setupTestData() {

        Id recordTypeId =Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
        Account objAccount = new Account();
        objAccount.FirstName = 'Test FirstName';
        objAccount.LastName  = 'Test LastName';
        objAccount.Line_of_Business__c = 'ABHI';
        objAccount.Business_Unit__c = 'ABHI';
        objAccount.RecordTypeId = recordTypeId;
        INSERT objAccount;

        Asset asst1 = new Asset();
        asst1.Name = 'Test Asset';
        asst1.LAN__c = '23234432423';
        asst1.AccountId = objAccount.Id;
        asst1.Calling_Source__c = 'Ubona BOT';//RNWL
        INSERT asst1;
        
        List<ASF_Case_Category_Config__c> lstCCC = new List<ASF_Case_Category_Config__c>();
        
        ASF_Case_Category_Config__c caseCatConfig01 = new ASF_Case_Category_Config__c();
        caseCatConfig01.CCC_External_Id__c = 'CCC-CC-CCLTD-01';
    	caseCatConfig01.Overall_Case_Closure_SLA__c = 10;
        caseCatConfig01.Business_Unit__c = 'ABHI';
    	caseCatConfig01.First_Stage__c = 'Open';
    	caseCatConfig01.Type__c = 'Bureau Related';
    	caseCatConfig01.Sub_Type__c = 'CIBIL Related Details - Ownership Related';
    	caseCatConfig01.Overall_Case_Closure_SLA__c = 56;
    	caseCatConfig01.Nature__c = 'Request';
    	caseCatConfig01.Source__c = 'CEC';  // Branch
    	caseCatConfig01.Product__c = 'TFE, CV, LCV, CE, SA, GLN, RBG-CV, RBG-CE, ABG, ARB, MFI, TDF';
    	caseCatConfig01.Resolved_Case_Email_Template__c = 'TEST_EMAIL_CLOSURE_01';
    	caseCatConfig01.Resolved_Case_SMS_Metadata__c ='TEST_SMS_CLOSURE_01';
        caseCatConfig01.Recategorisation_Email_Template__c ='TEST_EMAIL_RECAT_01';
        caseCatConfig01.Recategorisation_SMS_Metadata__c ='TEST_SMS_RECAT_01';
        caseCatConfig01.Rejected_Case_Email_Template__c ='TEST_EMAIL_REJEC_01';
        caseCatConfig01.Rejected_Case_SMS_Metadata__c = 'TEST_SMS_REJEC_01';
        caseCatConfig01.Additional_Email_Templates__c = 'In Progress:TEST_EMAIL_ACK_01,Reopened:TEST_EMAIL_REOPEN_01';
        caseCatConfig01.Additional_SMS_Metadata__c = 'In Progress:TEST_SMS_ACK_01,Reopened:TEST_SMS_REOPEN_01';
        lstCCC.add(caseCatConfig01);
        
        ASF_Case_Category_Config__c caseCatConfig02 = new ASF_Case_Category_Config__c();
        caseCatConfig02.CCC_External_Id__c = 'CCC-CC-CCLTD-02';
    	caseCatConfig02.Overall_Case_Closure_SLA__c = 10;
        caseCatConfig02.Business_Unit__c = 'ABHI';
    	caseCatConfig02.First_Stage__c = 'Open';
    	caseCatConfig02.Type__c = 'Bureau Related';
    	caseCatConfig02.Sub_Type__c = 'CIBIL Related Details - Ownership Related';
    	caseCatConfig02.Overall_Case_Closure_SLA__c = 56;
    	caseCatConfig02.Nature__c = 'Request';
    	caseCatConfig02.Source__c = 'CEC';  // Branch
    	caseCatConfig02.Product__c = 'TFE, CV, LCV, CE, SA, GLN, RBG-CV, RBG-CE, ABG, ARB, MFI, TDF';
    	caseCatConfig02.Resolved_Case_Email_Template__c = 'TEST_EMAIL_CLOSURE_01';
    	caseCatConfig02.Resolved_Case_SMS_Metadata__c ='TEST_SMS_CLOSURE_01';
        caseCatConfig02.Recategorisation_Email_Template__c ='TEST_EMAIL_RECAT_01';
        caseCatConfig02.Recategorisation_SMS_Metadata__c ='TEST_SMS_RECAT_01';
        caseCatConfig02.Rejected_Case_Email_Template__c = 'TEST_EMAIL_REJEC_01';
        caseCatConfig02.Rejected_Case_SMS_Metadata__c = 'TEST_SMS_REJEC_01';
        caseCatConfig02.Additional_Email_Templates__c = 'In Progress:TEST_EMAIL_ACK_01,Reopened:TEST_EMAIL_REOPEN_01';
        caseCatConfig02.Additional_SMS_Metadata__c = 'In Progress:TEST_SMS_ACK_01,Reopened:TEST_SMS_REOPEN_01';
        lstCCC.add(caseCatConfig02);
        
        INSERT lstCCC;
        
        List<ASF_Case_Stage_Config__c> stageConfigList = new List<ASF_Case_Stage_Config__c>();
        ASF_Case_Stage_Config__c stage1 = new ASF_Case_Stage_Config__c();
    	stage1.Case_Category_Config__c = lstCCC[0].Id;
    	stage1.Order__c = 1;
    	stage1.StageName__c  = 'Open';
    	stage1.Stage_SLA_1__c = 1;
    	stage1.Status_Mapping__c = 'New';
    	stage1.SLA_Target_1_Type__c = 'Manager';
    	stage1.Query_Fields__c = 'Id,Stage__c';
    	stage1.Manual_Stage__c = false;
    	stageConfigList.add(stage1);
        
        ASF_Case_Stage_Config__c stage2 = new ASF_Case_Stage_Config__c();
    	stage2.Case_Category_Config__c = lstCCC[0].Id;
    	stage2.Order__c = 2;
    	stage2.StageName__c  = 'In Progress';
    	stage2.Stage_SLA_1__c = 53;
    	stage2.Status_Mapping__c = 'In Progress';
    	stage2.SLA_Target_1_Type__c = 'Manager';
    	stage2.Query_Fields__c = 'Id,Stage__c';
    	stage2.Manual_Stage__c = false;
    	stageConfigList.add(stage2);
        
        ASF_Case_Stage_Config__c stage3 = new ASF_Case_Stage_Config__c();
    	stage3.Case_Category_Config__c = lstCCC[0].Id;
    	stage3.Order__c = 3;
    	stage3.StageName__c  = 'Resolved';
    	stage3.Status_Mapping__c = 'Resolved';
    	stage3.Query_Fields__c = 'Id,Stage__c';
    	stage3.Manual_Stage__c = false;
    	stageConfigList.add(stage3);
        
        ASF_Case_Stage_Config__c stage4 = new ASF_Case_Stage_Config__c();
    	stage4.Case_Category_Config__c = lstCCC[0].Id;
    	stage4.Order__c = 4;
    	stage4.StageName__c  = 'Reopened';
    	stage4.Status_Mapping__c = 'New';
    	stage4.Query_Fields__c = 'Id,Stage__c';
    	stage4.Manual_Stage__c = false;
    	stageConfigList.add(stage4);
        
        ASF_Case_Stage_Config__c stage01 = new ASF_Case_Stage_Config__c();
    	stage01.Case_Category_Config__c = lstCCC[1].Id;
    	stage01.Order__c = 1;
    	stage01.StageName__c  = 'Open';
    	stage01.Stage_SLA_1__c = 1;
    	stage01.Status_Mapping__c = 'New';
    	stage01.SLA_Target_1_Type__c = 'Manager';
    	stage01.Query_Fields__c = 'Id,Stage__c';
    	stage01.Manual_Stage__c = false;
    	stageConfigList.add(stage01);
        
        ASF_Case_Stage_Config__c stage02 = new ASF_Case_Stage_Config__c();
    	stage02.Case_Category_Config__c = lstCCC[1].Id;
    	stage02.Order__c = 2;
    	stage02.StageName__c  = 'In Progress';
    	stage02.Stage_SLA_1__c = 53;
    	stage02.Status_Mapping__c = 'In Progress';
    	stage02.SLA_Target_1_Type__c = 'Manager';
    	stage02.Query_Fields__c = 'Id,Stage__c';
    	stage02.Manual_Stage__c = false;
    	stageConfigList.add(stage02);
        
        ASF_Case_Stage_Config__c stage03 = new ASF_Case_Stage_Config__c();
    	stage03.Case_Category_Config__c = lstCCC[1].Id;
    	stage03.Order__c = 3;
    	stage03.StageName__c  = 'Resolved';
    	stage03.Status_Mapping__c = 'Resolved';
    	stage03.Query_Fields__c = 'Id,Stage__c';
    	stage03.Manual_Stage__c = false;
    	stageConfigList.add(stage03);
        
        ASF_Case_Stage_Config__c stage04 = new ASF_Case_Stage_Config__c();
    	stage04.Case_Category_Config__c = lstCCC[1].Id;
    	stage04.Order__c = 4;
    	stage04.StageName__c  = 'Reopened';
    	stage04.Status_Mapping__c = 'New';
    	stage04.Query_Fields__c = 'Id,Stage__c';
    	stage04.Manual_Stage__c = false;
    	stageConfigList.add(stage04);
        
        INSERT stageConfigList;
        
        ABHI_Case_Detail__c caseDetail = new ABHI_Case_Detail__c();
        INSERT caseDetail;

        Case caseRec = new Case();
        caseRec.Business_Unit__c = 'ABHI';
        caseRec.Notes__c = 'Test Case';
        caseRec.CCC_External_Id__c = 'CCC-CC-CCLTD-01';
        caseRec.AccountId = objAccount.Id;
        caseRec.Technical_Source__c = 'LWC';
        caseRec.Type_Text__c = 'Cashless';
        caseRec.Sub_Type_Text__c = 'Claims status';
        caseRec.Source__c = 'Branch';
        caseRec.AssetId = asst1.Id;
        caseRec.ABHI_Case_Detail__c = caseDetail.Id;
        caseRec.Stage__c = 'Resolved';
        caseRec.Status = 'Resolved';
        INSERT caseRec;
    }
	
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - unitTestMethod1
    * @description - Test method to test omnidocs transfer
    *****************************************************************************************************************/
    @IsTest
    static void unitTestMethod1(){
        List<Case> lstCases = [SELECT Id,Business_Unit__c,CaseNumber,Account.Client_Code__c, Status, isClosed,
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
        
        system.assertEquals(lstCases[0].isClosed, true, 'Assert failed, Case is not in closed status');
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