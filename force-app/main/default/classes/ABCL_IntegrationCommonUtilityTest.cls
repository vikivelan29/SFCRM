@IsTest
public class ABCL_IntegrationCommonUtilityTest {
	
    @TestSetup
    static void setupTestData(){
        
        //Create Case Category Config Record
        ASF_TestDataFactory.createCaseCategoryConfig();
        insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                          Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                          Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
        //Create Case
        List<Case> caseRecList = ASF_TestDataFactory.createCaseRecords(1);
        
        //create ASF Integration
        ASF_Integration__c integ = new ASF_Integration__c();
        integ.External_Id__c = 'ASF_INT_01';
        integ.Display_Name__c = 'Welcome kit';
        insert integ;
        
        //create ASF Case Integration records
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Integration_Ext_Id__c = integ.External_Id__c;
        caseInt.Case__c = caseRecList[0].Id;
        insert caseInt;
        
        //Create document
        ContentVersion content = new ContentVersion();
        content.PathOnClient = 'Response.txt';
        content.Title = 'Response';
        content.VersionData = Blob.valueof('Test');
        insert content;
        
        //Link document to Case Integration
        ContentVersion conVersion = [Select ContentDocumentId from ContentVersion where id =: content.Id];
        ContentDocumentLink docLink = new ContentDocumentLink();
        docLink.LinkedEntityId = caseInt.Id;
        docLink.ContentDocumentId = conVersion.ContentDocumentId;
        docLink.ShareType = 'V';
        insert docLink;
    }
    
    @IsTest
    static void testTransferAttachments(){
        List<ASF_Case_Integration__c> caseIntegrationRecords = [SELECT Id, Case__c FROM ASF_Case_Integration__c LIMIT 1];
        Test.startTest();
            Boolean isSuccess = ABCL_IntegrationCommonUtility.transferAttachments(caseIntegrationRecords[0]);
        Test.stopTest();
        System.assertEquals(true,isSuccess);
    }
    
    @IsTest
    static void testCreatePELogAndinvokeCommPEevent(){
        List<Case> caseRecords = [SELECT Id, No_Auto_Communication__c, AccountId, CCC_External_Id__c, ContactId FROM Case LIMIT 1];
        Test.startTest();
        	Database.SaveResult eventResult = ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRecords[0], 'dev_01', 'Dev_02', true);
        Test.stopTest();
        System.assertEquals(true,eventResult.IsSuccess());
    }
    
    @IsTest
    static void testBranchAssignmentNotification(){
        List<Case> caseRecords = [SELECT Id, CreatedById FROM Case LIMIT 1];
        Test.startTest();
        	ABCL_IntegrationCommonUtility.branchAssignmentNotification(caseRecords[0], 'Welcome Kit', 'STP Document Retrieval Failure');
        Test.stopTest();
    }
    
    @IsTest
    static void testFetchStpTemplates(){
        String templateString = 'Resolved:template_1,Rejected:template_2';
        Test.startTest();
        	Map<String, String> templateMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(templateString);
        Test.stopTest();
        system.assertEquals(templateMap.get('Resolved'),'template_1');
    }
    
    @IsTest
    static void testTransferFilesToDMS(){
        List<Case> caseRecords = [SELECT Id, CreatedById FROM Case LIMIT 1];
        ContentVersion cv = new ContentVersion();
        cv.VersionData = Blob.valueof('test');
        cv.IsSTP__c = true;
        cv.Title = 'Test.pdf';
        cv.PathOnClient = 'Test.pdf';
        insert cv;
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = ContentDocumentId;
        cdl.LinkedEntityId = caseRecords[0].Id;
        cdl.ShareType = 'V';
        insert cdl;
        Test.startTest();
        ABCL_IntegrationCommonUtility.transferFilesToDMS(new List<String>{caseRecords[0].Id});
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateErrorMessage(){
        List<Case> caseRecords = [SELECT Id, CreatedById FROM Case LIMIT 1];
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Request__c = JSON.serialize(new Case_Integration_Outbound__e(Integration_Name__c = 'Test'));
        ABCL_IntegrationCommonUtility.stpResponseWrapper respWrapper = new ABCL_IntegrationCommonUtility.stpResponseWrapper();
        respWrapper.operationStatus = '0';
        respWrapper.operationMessage = 'Test';
        caseInt.Response__c = JSON.serialize(respWrapper);
        insert caseInt;
        Test.startTest();
        ABCL_IntegrationCommonUtility.updateErrorMessage(caseInt);
        caseInt.Request__c = JSON.serialize(new Case_Integration_Outbound__e(Integration_Name__c = 'Sanction Letter'));
        ABCL_IntegrationCommonUtility.reportingResponseWrapper responseWrapper = new ABCL_IntegrationCommonUtility.reportingResponseWrapper();
        responseWrapper.returnCode = '0';
        responseWrapper.returnMessage = 'Test';
        caseInt.Response__c = JSON.serialize(responseWrapper);
        update caseInt;
        ABCL_IntegrationCommonUtility.updateErrorMessage(caseInt);
        Test.stopTest();
    }
    
}