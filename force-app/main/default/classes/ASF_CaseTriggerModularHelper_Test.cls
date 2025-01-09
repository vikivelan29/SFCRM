@SuppressWarnings('PMD.MethodNamingConventions')
@isTest
public class ASF_CaseTriggerModularHelper_Test {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];

    @TestSetup
    public static void setup(){
        
        

        User manager1 = new User(profileId = SYSTEMADMIN_PROFILE.Id, email = 'manager1@salesforce.com',
        Username = 'manager1'+String.valueOf(Integer.valueof((Math.random() * 10)))+'@mock.com',
        alias = 'manager1', lastname = 'lastname', emailencodingkey = 'UTF-8', localesidkey = 'en_US',
        languagelocalekey = 'en_US', timezonesidkey = 'GMT',IsActive = true);
        
        insert manager1;

        User objUser = new User(profileId = SYSTEMADMIN_PROFILE.Id, email = 'test0@salesforce.com',
                           Username = 'Test'+String.valueOf(Integer.valueof((Math.random() * 10)))+'@mock.com',
                           alias = 'uqusr', lastname = 'lastname', emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                           languagelocalekey = 'en_US', timezonesidkey = 'GMT',IsActive = true,ManagerId=manager1.Id,Business_Unit__c='ABHFL');
        insert objUser;
        
        insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
        Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
        Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
        ASF_TestDataFactory.createCaseRecords(1);
    }
    
    @isTest
    public static void test_populateFrameworkFieldsForCase1(){
        ASF_TestDataFactory.createCaseCategoryConfig();
        Test.startTest();
        List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsert();
        casesList[0].Technical_Source__c = 'LWC';
        ASF_BulkCaseProcessorUtility.isBulkProcessing = true;
        insert casesList;

        ASF_TestDataFactory.createCaseCategoryConfigWithSTP();
        List<Case> casesListAPI = ASF_TestDataFactory.createCaseRecordsWithoutInsert();
        //casesListAPI[0].Technical_Source__c = 'API';
        casesListAPI[0].Attachment_Status__c = 'Completed';
        casesListAPI[0].CCC_External_Id__c = 'CCC-CC-CCLTD-02-STP';
        insert casesListAPI;

        casesList[0].CCC_External_Id__c = 'CCC-CC-CCLTD-02-STP';
        update casesList;
        Test.stopTest();
        List<Case> frameworkCase2 = [Select Id, Subject from Case where RecordType.Name = 'Framework'];
        Assert.areEqual(4, frameworkCase2.size(), 'Expected 4, Not found');
    }

    @IsTest
    static void test_checkAndProcessReopenCase1(){
        ASF_TestDataFactory.createCaseCategoryConfigWithSTP();
        ASF_Case_Category_Config__c config = [Select Id from ASF_Case_Category_Config__c limit 1];
        config.Reopen_Style__c = 'Move To First Stage';
        update config;
        List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsertSTP();
        casesList[0].Technical_Source__c = 'LWC';
        insert casesList;
        casesList[0].Stage__c = 'Closed';
        update casesList;
        Test.startTest();
        casesList[0].Reopened_DateTime__c = System.now();
        casesList[0].Reopened__c = true;
        ASF_TriggerSkipperUtility.resetTriggerRun('Case');
        update casesList;
        Test.stopTest();
        Case caseRec = [Select Id, Stage__c from Case LIMIT 1];
        //Assert.areEqual('Pending with Initiator', caseRec.Stage__c, 'Stage is not Pending with initiator');
    }
    @IsTest
    static void test_checkAndProcessReopenCase2(){
        ASF_TestDataFactory.createCaseCategoryConfigWithSTP();
        ASF_Case_Category_Config__c config = [Select Id from ASF_Case_Category_Config__c limit 1];
        config.Reopen_Style__c = 'Reopen Stage With Movement';
        update config;
        List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsertSTP();
        casesList[0].Technical_Source__c = 'LWC';
        insert casesList;
        Test.startTest();
        //casesList[0].Stage__c = 'Resolved';
        //update casesList;
        casesList[0].Reopened_DateTime__c = System.now();
        casesList[0].Reopened__c = true;
        ASF_TriggerSkipperUtility.resetTriggerRun('Case');
        update casesList;
        Test.stopTest();
        Case caseRec = [Select Id, Stage__c from Case LIMIT 1];
        //Assert.areEqual('Reopened', caseRec.Stage__c, 'Stage is not Reopened');
    }

    @IsTest
    static void test_checkAndProcessMoveToNextStage(){
        ASF_TestDataFactory.createCaseCategoryConfigWithSTP();
        Test.startTest();
        List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsertSTP();
        //casesList[0].Technical_Source__c = 'API';
        casesList[0].MoveToNext__c = true;
        insert casesList;

        ASF_TriggerSkipperUtility.markTriggerRun('Case');
        casesList[0].MoveToNext__c = false;
        update casesList;
        ASF_TriggerSkipperUtility.resetTriggerRun('Case');

        casesList[0].MoveToNext__c = true;
        update casesList;

        Test.stopTest();
    }

    @IsTest
    static void test_checkAndProcessManualStageMovement(){
        ASF_TestDataFactory.createCaseCategoryConfigWithSTP();
        Test.startTest();
        List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsertSTP();
        //casesList[0].Technical_Source__c = 'API';
        insert casesList;

        casesList[0].Stage__c = 'In Progress with Recovery';
        casesList[0].pending_clarification__c = true;
        update casesList;

        casesList[0].Stage__c = 'Pending with Initiator';
        ASF_TriggerSkipperUtility.resetTriggerRun('Case');
        update casesList;
        Test.stopTest();
        Case caseRec = [Select Id, Stage__c from Case LIMIT 1];
        Assert.areEqual('Pending with Initiator', caseRec.Stage__c, 'Stage should come back to Pending with initator');
    }

    @IsTest
    static void test_checkAndPopulateOwnerOnCaseCreation(){
        Test.startTest();
        Case newCase = new Case(Origin = 'Web', Subject = 'Test Case Creation', Stage__c = 'Pending with Initiator',
                                SLA_Target_1__c = 'test@salesforce.com', CSAT__c = 20, DB_Hours__c = 5, has_CheckLists__c=TRUE, Reopen_Days__c=30 );
            newCase.Stage_SLA_1__c = System.now();
            newCase.Stage_SLA_2__c = System.now()+1;
            newCase.Stage_SLA_3__c = System.now()+2;
            newCase.CCC_External_Id__c = 'CCC-CC-CCLTD-01';
        	newCase.Technical_Source__c = 'API';
        	newCase.Source__c = 'Branch';
        	newCase.Is_Approval_Stage__c = true;
            newCase.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
            insert newCase;
        
            newCase.Is_Approval_Stage__c = true;
            ASF_TriggerSkipperUtility.resetTriggerRun('Case');
            update newCase;
        
        Test.stopTest();
        Case caseRec = [Select Id, Stage__c, OwnerId from Case LIMIT 1];
        //Assert.isTrue(String.valueOf(caseRec.OwnerId).startsWith('00G'), 'should be assigned to a queue');
    }

    @IsTest
    static void test_onCreateCloseServiceRequest(){
        ASF_TestDataFactory.createCaseCategoryConfigWithSTP();
        Test.startTest();
        List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsertSTP();
        //casesList[0].Technical_Source__c = 'API';
        casesList[0].OnCreateCloseSR__c = true;
        insert casesList;
        
        Test.stopTest();
    }

    @IsTest
    static void test_rejectFrameworkCaseBeforeUpdate(){
        ASF_TestDataFactory.createCaseCategoryConfigWithSTP();
        Test.startTest();
        List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsertSTP();
        //casesList[0].Technical_Source__c = 'API';
        insert casesList;
        casesList[0].Reject_Case__c = true;
        ASF_TriggerSkipperUtility.resetTriggerRun('Case');
        update casesList;
        Test.stopTest();
    }
    @IsTest
    static void test_rejectFrameworkCaseBeforeUpdate2(){
        ASF_TestDataFactory.createCaseCategoryConfigWithSTP();
        Test.startTest();
        List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsertSTP();
        //casesList[0].Technical_Source__c = 'API';
        insert casesList;
        casesList[0].Is_Duplicate__c = true;
        casesList[0].Is_Approval_Stage__c = true;
        ASF_TriggerSkipperUtility.resetTriggerRun('Case');
        update casesList;
        
        Test.stopTest();
    }

    @IsTest
    static void test_validateOwnerCheckerStage(){
        ASF_TestDataFactory.createCaseCategoryConfig();
        ASF_Case_Stage_Config__c caseStgConfig = [Select Id from ASF_Case_Stage_Config__c where Order__c = 1 LIMIT 1];
        caseStgConfig.Has_Same_Owner_Check__c = true;
        caseStgConfig.Owner_Check_Stages__c = 'Pending with Initiator';
        update caseStgConfig;
        Test.startTest();
        List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsert();
        casesList[0].Technical_Source__c = 'LWC';
        casesList[0].CCC_External_Id__c = 'CCC-CC-CCLTD-11';
        insert casesList;

        casesList[0].OwnerId = UserInfo.getUserId();
        ASF_TriggerSkipperUtility.resetTriggerRun('Case');
        try{
            update casesList;
        }catch(DMLException e){
            Assert.isTrue(e.getDmlMessage(0) == Label.Maker_Owner_Error_Message, 'Should encounter error');
        }
        Test.stopTest();
        
    }

    @IsTest
    static void test_caseOwnerChangeValidation(){
        User objUser = [select id from user where email = 'test0@salesforce.com'];
        insert new PermissionSetAssignment(AssigneeId=objUser.Id,
                                   PermissionSetId=[Select Id from PermissionSet where Name = 'Admin_User' LIMIT 1].Id);
        
        
        Test.startTest();
        System.runAs(objUser){
            ASF_TestDataFactory.createCaseCategoryConfigWithSTP();
            List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsertSTP();
            //casesList[0].Technical_Source__c = 'API';
            insert casesList;

            casesList[0].OwnerId = UserInfo.getUserId();
            ASF_TriggerSkipperUtility.resetTriggerRun('Case');
            try{
                update casesList;
            }catch(DMLException e){
                Assert.isTrue(e.getDmlMessage(0) != null, 'Should encounter error');
            }
        }
        Test.stopTest();
        
    } 
    @IsTest
    static void test_caseOwnerChangeAccessValidation(){
        
        Test.startTest();
        List<Case> casesList = [select id, ownerId from case LIMIT 1];
        User objUser = [select Id, managerGroupId__c,managerId,manager.Id,manager.manager.Id,
                                                   manager.manager.manager.id,manager.manager.manager.manager.id,
                                                   manager.manager.manager.manager.manager.id 
                                                   from user where id !=: casesList[0].ownerId LIMIT 1];
        User objUser1 = new User(profileId = SYSTEMADMIN_PROFILE.Id, email = 'test0@salesforce.com',
                           Username = 'Test1'+String.valueOf(Integer.valueof((Math.random() * 10)))+'@mock.com',
                           alias = 'uquss', lastname = 'lastname', emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                           languagelocalekey = 'en_US', timezonesidkey = 'GMT',IsActive = true);
        insert objUser1;
        
        //casesList[0].ownerId = objUser.Id;
         Group queue = new Group(Name = 'Test Case Queue', Type = 'Queue');
        insert queue;
        casesList[0].ownerId = queue.Id;
        ASF_TriggerSkipperUtility.resetTriggerRun('Case');
        try{
            System.runAs(objUser1){
                update casesList;
            }
        }catch(DMLException e){
           	Assert.isTrue(e.getDmlMessage(0) == Label.ASF_Owner_Change_Access_Val_Msg, 'Should encounter error');
        }
        Test.stopTest();        
    }
    
    @IsTest
    static void test_caseOwnerChangeAccessValidation2(){
         Group queue = new Group(Name = 'Test Case Queue', Type = 'Queue');
        insert queue;
        
    	QueueSobject queueSobject = new QueueSobject(
            QueueId = queue.Id,
            SobjectType = 'Case'
        );
        insert queueSobject;
        
        Test.startTest();

        User objUser1 = new User(profileId = SYSTEMADMIN_PROFILE.Id, email = 'test0@salesforce.com',
                           Username = 'Test1'+String.valueOf(Integer.valueof((Math.random() * 10)))+'@mock.com',
                           alias = 'uquss', lastname = 'lastname', emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                           languagelocalekey = 'en_US', timezonesidkey = 'GMT',IsActive = true);
        insert objUser1;
        
        ASF_TriggerSkipperUtility.resetTriggerRun('Case');
        try{
            System.runAs(objUser1){
                List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsert();
                casesList[0].Technical_Source__c = 'LWC';
                casesList[0].CCC_External_Id__c = 'CCC-CC-CCLTD-11';
                casesList[0].ownerId = queue.Id;
                insert casesList;
                
                casesList[0].ownerId = objUser1.Id;
                
                update casesList;
                Map<Id, Case> oldMap = new Map<Id, Case>([select id, ownerId from case]);
                ASF_CaseTriggerModularHelper.caseOwnerChangeValidation(casesList, oldMap);
                casesList[0].ownerId = queue.Id;
                update casesList;
                casesList[0].ownerId = objUser1.Id;
                update casesList;
                
            }
        }catch(DMLException e){
            //Assert.isTrue(e.getDmlMessage(0) == Label.ASF_Owner_Change_Access_Val_Msg, 'Should encounter error');
        }
        Test.stopTest();        
    }

    @IsTest
    static void test_validateCCCOnUpdate(){
        ASF_TestDataFactory.createCaseCategoryConfig();
        List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsert();
        casesList[0].Technical_Source__c = 'LWC';
        insert casesList;
        ASF_TestDataFactory.createCaseCategoryConfigWithSTP();
        Test.startTest();
        ASF_TriggerSkipperUtility.resetTriggerRun('Case');
        casesList[0].CCC_External_Id__c = 'CCC-CC-CCLTD-02-STP';
        update casesList;
        Test.stopTest();
        
    }
    @IsTest
    static void testManualSkipper(){
        ASF_TestDataFactory.createCaseCategoryConfig();
        List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsert();
        ABSLI_Case_Detail__c caseDet = new ABSLI_Case_Detail__c(Address_Line_1__c = 'Test');
        insert caseDet;
        casesList[0].Technical_Source__c = 'LWC';
        casesList[0].ABSLI_Case_Detail__c = caseDet.Id;
        insert casesList;
        ASF_TestDataFactory.createCaseCategoryConfigWithSTP();
        Test.startTest();
         Map<Id, Set<String>> recIdToSkipperFlag = new Map<Id, Set<String>>();
        recIdToSkipperFlag.put(casesList[0].Id, new Set<String>{ASF_Constants.SKIP_VALIDATE_CHECKLISTS,ASF_Constants.SKIP_VALIDATE_TASKS});
        ASF_CaseTriggerModularHelper.setManualSkipperFlags(recIdToSkipperFlag, null);
        ASF_BulkCaseProcessorUtility.isBulkProcessing = true;
        casesList[0].Bulk_CaseDetail_JSON__c = '{"attributes":{"type":"ABSLI_Case_Detail__c"},"Address_Line_1__c":"Test"}';
        update casesList;
        Test.stopTest();
        
    }

    /*
    @IsTest
    static void test_lwcCaseValidationBeforeInsertUpdate(){
        ASF_TestDataFactory.createCaseCategoryConfigWithSTP();
        
        List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsertSTP();
        casesList[0].Technical_Source__c = 'API';
        insert casesList;
        Test.startTest();
        casesList[0].Stage__c = 'In Progress with Recovery';
        ASF_TriggerSkipperUtility.resetTriggerRun('Case');
        try{
            update casesList;
        }catch(DMLException e){
            Assert.isTrue(e.getDmlMessage(0) == 'Stage entry rule not meeting', 'Should encounter error');
        }
        Test.stopTest();
        
    }
    */
 @isTest
    static void insertABHICaseTest(){
        //Create Account
        
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('ABHILL','Test_1');
        Contact  cont = ASF_TestDataFactory.insertContact('Test 1@', '');
        //Create BranchMaster
        Branch_Master__c branchMstr = new Branch_Master__c();
        branchMstr.Branch_Queue_Id__c = [Select Id from Group where Type = 'Queue' LIMIT 1].Id;
        branchMstr.UniqueKey__c = 'TestBranch123';
        insert branchMstr;
        
        ASF_TestDataFactory.createCaseCategoryConfig();
        ASF_Case_Category_Config__c ccc = [SELECT id,IGMS_Code__c,CCC_External_Id__c FROM ASF_Case_Category_Config__c LIMIT 1];
        ccc.IGMS_Code__c = '#N/A';
        ccc.CCC_External_Id__c = 'PEMT024';
        ccc.Allowed_Issue_Types__c = 'example1';
        ccc.Litmus_Trigger__c = TRUE;
        update ccc;
        
        //Create Asset
        Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        astRec.LAN__c = 'Test';
        astRec.Issue_Date__c = Date.newInstance(2024, 6, 6);
        update astRec;
        Asset astRec1 = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        astRec1.LAN__c = 'Test1';
        astRec1.Issue_Date__c = Date.newInstance(2024, 6, 6);
        update astRec1;
        
        //Create Case Extension record
        ABHI_Case_Detail__c caseDetail = new ABHI_Case_Detail__c();
        insert caseDetail;
        Test.startTest();
        //Case caseRec = ASF_TestDataFactory.createInteractionCaseRecords()[0];
        Case caseRec = new Case(Status = 'Open', Origin = 'Email', Subject = 'Test Case Creation', Stage__c = 'Open',
                                SLA_Target_1__c = 'test2@salesforce.com' , CSAT__c = 20, DB_Hours__c = 5, has_CheckLists__c=TRUE, Reopen_Days__c=30 );
        caseRec.Source__c = 'Email';
        caseRec.Business_Unit__c = 'ABHI';
        caseRec.Status = 'Open';
        caseRec.AssetId = astRec1.Id;
        caseRec.Stage__c = 'In Progress with SA';
        caseRec.ABHI_Case_Detail__c = caseDetail.Id;
        caseRec.AccountId = accRec.Id;
        caseRec.CCC_External_Id__c = 'PNFT008';
        caseRec.Client_Code_Text__c = '8895335596';
        caseRec.Technical_Source__c = 'API';
        caseRec.Is_STP__c = true;
        caseRec.IGMS_Complaint_Type_Code__c = '1';
        insert caseRec;
        caseRec.IGMS_Complaint_Type_Code__c = '2';
        update caseRec;
        Test.stopTest();
    }
    @isTest
    static void insertABHFLCaseTest(){
        //Create Account
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('ABHFLLLL','Test_1');
        Contact  cont = ASF_TestDataFactory.insertContact('Test 1@', '');
        //Create BranchMaster
        Branch_Master__c branchMstr = new Branch_Master__c();
        branchMstr.Branch_Queue_Id__c = [Select Id from Group where Type = 'Queue' LIMIT 1].Id;
        branchMstr.UniqueKey__c = 'ABHFL_250004_MEEUP21_2/507#MEERUT';
        insert branchMstr;
        
        ASF_TestDataFactory.createCaseCategoryConfig();
		
        
        //Create Asset
        Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        astRec.LAN__c = 'Test';
        astRec.Branch__c = branchMstr.Id;
        astRec.Last_Disbursement_Date__c = Date.Today();
        astRec.Loan_Disbursement_Status__c = 'Complete';
        update astRec;
        Asset astRec1 = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        astRec1.LAN__c = 'Test1';
        astRec1.Branch__c = branchMstr.Id;
        astRec1.Last_Disbursement_Date__c = Date.Today();
        astRec1.Loan_Disbursement_Status__c = 'Complete';
        update astRec1;
        
        //Create Case Extension record
        ABHFL_Case_Detail__c caseDetail = new ABHFL_Case_Detail__c();
        caseDetail.STP_Request_Type__c = 'Email';
        caseDetail.Preferred_Branch__c = branchMstr.UniqueKey__c;
        insert caseDetail;
        Test.startTest();
        //Case caseRec = ASF_TestDataFactory.createInteractionCaseRecords()[0];
        Case caseRec = new Case(Status = 'Open', Origin = 'Email', Subject = 'Test Case Creation', Stage__c = 'Open',
                                SLA_Target_1__c = 'test2@salesforce.com' , CSAT__c = 20, DB_Hours__c = 5, has_CheckLists__c=TRUE, Reopen_Days__c=30 );
        caseRec.AssetId = astRec.Id;
        caseRec.ABHFL_Case_Detail__c = caseDetail.Id;
        caseRec.Case_Stage_Change_Date__c = date.today();
        caseRec.business_unit__c = 'ABHFL';
        insert caseRec;
        Test.stopTest();
    }


}
