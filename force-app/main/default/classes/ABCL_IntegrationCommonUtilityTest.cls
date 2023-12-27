@IsTest
public class ABCL_IntegrationCommonUtilityTest {
	
    @TestSetup
    static void setupTestData(){
        
        //Create Case Category Config Record
        ASF_TestDataFactory.createCaseCategoryConfig();
        
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
        List<Case> caseRecords = [SELECT Id, AccountId, CCC_External_Id__c, ContactId FROM Case LIMIT 1];
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
    
}