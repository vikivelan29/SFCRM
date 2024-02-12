/*********************************************************
 *Class        :  ABFL_InvokeLitmusProcess_Test
 *Author       :  Udit Singhal
 *Created Date :  07/02/2024
 *Last Modified:
 *Description  :  Test Class for ABFL_InvokeLitmusProcess
 *********************************************************/
@isTest
public class ABFL_InvokeLitmusProcess_Test{
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id
                                                        FROM Profile
                                                        WHERE name = 'System Administrator'
                                                        LIMIT 1];
    /****************************************************
     * @description - To setup test data for this test class
    *****************************************************/
    @TestSetup
    static void makeData(){
        Group slaGroup = new Group();
        
        slaGroup = new Group(
            Name = 'SLAManagerGroup', 
            DeveloperName = 'SLAManagerGroup'
        );
        insert slaGroup;
        
        User userRecord1 = new User(
            Alias = 'standt', 
            Email = 'stanrduserEmails@testorg.com', 
            EmailEncodingKey = 'UTF-8', 
            LastName = 'Testing', 
            LanguageLocaleKey = 'en_US', 
            LocaleSidKey = 'en_US', 
            ProfileId = SYSTEMADMIN_PROFILE.Id, 
            TimeZoneSidKey = 'America/Los_Angeles', 
            UserName = 'cdefghijk567@gmail.com', 
            managerGroupId__c = slaGroup.Id
        );
        insert userRecord1;
        
        Test.startTest();
        PermissionSet ps = [SELECT Id
                            FROM PermissionSet
                            WHERE Name = 'Admin_User'];
        insert new PermissionSetAssignment(
            AssigneeId = userRecord1.Id, 
            PermissionSetId = ps.Id
        );
        Test.stopTest();
        
        System.runAs(userRecord1){
            List<sObject> ls = Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
            SLA_Threshold_Warning__c thresholdController = SLA_Threshold_Warning__c.getOrgDefaults();
            decimal thirdStageThreshold = thresholdController.Stage_SLA_Threshold_3__c;
            thresholdController.Customer_Email_buffer_hours__c = 56;
            update thresholdController;
            
            List<ASF_Case_Category_Config__c> caseCat = ABFL_TestDataFactory.createCaseCategoryConfig(true);
            
            List<ASF_Case_Stage_Config__c> caseStage = ABFL_TestDataFactory.createCaseStageConfigWithTwoStages(caseCat[0].Id, true);
            ABFL_TestDataFactory.createCaseRuleEntry(caseStage);
            System.debug('caseStage size: ' + caseStage.size());
            System.debug('caseStage: ' + caseStage);
            Account acc = ABFL_TestDataFactory.createAccount();
            ABFL_TestDataFactory.createContact(acc.ID);
            List<ABFL_Case_Detail__c> caseDetList = ABFL_TestDataFactory.createCaseDetail('Corporate', true);
            
            Asset assetObj = new Asset();
            assetObj.Name = '981726345';
            assetObj.AccountId = acc.Id;
            assetObj.LAN__c = '123456';
            insert assetObj;
            
            List<Case> cases = ABFL_TestDataFactory.createCaseRecords(1, caseDetList[0].Id, true);
            Case c = cases.get(0);
            c.ownerid = userInfo.getuserId();
            c.AccountId = acc.ID;
            c.AssetId = assetObj.Id;
            update c;
        }
    }
    
    @isTest
    static void testCallLitmusAPI(){
        User userRecord = [SELECT Id
                           FROM User
                           WHERE UserName = 'cdefghijk567@gmail.com'];
        System.runAs(userRecord){
            Case caseRec = [SELECT Id, ABFL_Case_Detail__c, Account.Name, Technical_Source__c, LAN__c, Business_Unit__c, CCC_External_Id__c
                            FROM Case
                            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                            LIMIT 1];
            
            ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
            caseInt.Case__c = caseRec.Id;
            caseInt.Status__c = ABFL_Constants.PENDING;
            caseInt.Type__c = ABFL_Constants.LITMUS;
            insert caseInt;
            
            Test.startTest();
            ASF_CaseMovementHelper.StageWrapper resultWrap = new ASF_CaseMovementHelper.StageWrapper();
            resultWrap = ASF_CaseMovementHelper.moveToForwardStage(caseRec, 'Resolved', 'Open');
            
            update resultWrap.caseToBeUpdated;
            
            Test.stopTest();
            
            List<ASF_Case_Integration__c> caseIntRecList = [SELECT Name FROM ASF_Case_Integration__c 
                               WHERE Case__c = :caseRec.Id 
                               AND Status__c = :ABFL_Constants.PENDING
                               AND Type__c = :ABFL_Constants.LITMUS
                               LIMIT 1];
            
            Assert.isTrue(caseIntRecList.size() > 0, 'Case Integration record for LITMUS should have been created');
        }
    }
    
    @isTest
    static void testCallLitmusAPIBranch(){
        User userRecord = [SELECT Id
                           FROM User
                           WHERE UserName = 'cdefghijk567@gmail.com'];
        System.runAs(userRecord){
            Case caseRec = [SELECT Id, ABFL_Case_Detail__c, Account.Name, Technical_Source__c, LAN__c, Business_Unit__c, CCC_External_Id__c
                            FROM Case
                            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                            LIMIT 1];
            
            caseRec.Source__c = 'Branch';
            update caseRec;
            
            Test.startTest();
            ASF_CaseMovementHelper.StageWrapper resultWrap = new ASF_CaseMovementHelper.StageWrapper();
            resultWrap = ASF_CaseMovementHelper.moveToForwardStage(caseRec, 'Resolved', 'Open');
            
            update resultWrap.caseToBeUpdated;
            
            Test.stopTest();
            
            List<ASF_Case_Integration__c> caseIntRecList = [SELECT Name FROM ASF_Case_Integration__c 
                               WHERE Case__c = :caseRec.Id 
                               AND Status__c = :ABFL_Constants.PENDING
                               AND Type__c = :ABFL_Constants.LITMUS
                               LIMIT 1];
            
            Assert.isTrue(caseIntRecList.size() > 0, 'Case Integration record for LITMUS should have been created');
        }
    }
    
    @isTest
    static void testCallLitmusAPICall_In(){
        User userRecord = [SELECT Id
                           FROM User
                           WHERE UserName = 'cdefghijk567@gmail.com'];
        System.runAs(userRecord){
            Case caseRec = [SELECT Id, ABFL_Case_Detail__c, Account.Name, Technical_Source__c, LAN__c, Business_Unit__c, CCC_External_Id__c
                            FROM Case
                            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                            LIMIT 1];
            
            caseRec.Source__c = 'Call-in';
            update caseRec;
            
            Test.startTest();
            ASF_CaseMovementHelper.StageWrapper resultWrap = new ASF_CaseMovementHelper.StageWrapper();
            resultWrap = ASF_CaseMovementHelper.moveToForwardStage(caseRec, 'Resolved', 'Open');
            
            update resultWrap.caseToBeUpdated;
            
            Test.stopTest();
            
            List<ASF_Case_Integration__c> caseIntRecList = [SELECT Name FROM ASF_Case_Integration__c 
                               WHERE Case__c = :caseRec.Id 
                               AND Status__c = :ABFL_Constants.PENDING
                               AND Type__c = :ABFL_Constants.LITMUS
                               LIMIT 1];
            
            Assert.isTrue(caseIntRecList.size() > 0, 'Case Integration record for LITMUS should have been created');
        }
    }
    
    @isTest
    static void testCallLitmusAPIChatbot(){
        User userRecord = [SELECT Id
                           FROM User
                           WHERE UserName = 'cdefghijk567@gmail.com'];
        System.runAs(userRecord){
            Case caseRec = [SELECT Id, ABFL_Case_Detail__c, Account.Name, Technical_Source__c, LAN__c, Business_Unit__c, CCC_External_Id__c
                            FROM Case
                            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                            LIMIT 1];
            
            caseRec.Source__c = 'Chatbot';
            update caseRec;
            
            Test.startTest();
            ASF_CaseMovementHelper.StageWrapper resultWrap = new ASF_CaseMovementHelper.StageWrapper();
            resultWrap = ASF_CaseMovementHelper.moveToForwardStage(caseRec, 'Resolved', 'Open');
            
            update resultWrap.caseToBeUpdated;
            
            Test.stopTest();
            
            List<ASF_Case_Integration__c> caseIntRecList = [SELECT Name FROM ASF_Case_Integration__c 
                               WHERE Case__c = :caseRec.Id 
                               AND Status__c = :ABFL_Constants.PENDING
                               AND Type__c = :ABFL_Constants.LITMUS
                               LIMIT 1];
            
            Assert.isTrue(caseIntRecList.size() > 0, 'Case Integration record for LITMUS should have been created');
        }
    }
    
    @isTest
    static void testCallLitmusAPIEmail(){
        User userRecord = [SELECT Id
                           FROM User
                           WHERE UserName = 'cdefghijk567@gmail.com'];
        System.runAs(userRecord){
            Case caseRec = [SELECT Id, ABFL_Case_Detail__c, Account.Name, Technical_Source__c, LAN__c, Business_Unit__c, CCC_External_Id__c
                            FROM Case
                            WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'
                            LIMIT 1];
            
            caseRec.Source__c = 'Email';
            update caseRec;
            
            Test.startTest();
            ASF_CaseMovementHelper.StageWrapper resultWrap = new ASF_CaseMovementHelper.StageWrapper();
            resultWrap = ASF_CaseMovementHelper.moveToForwardStage(caseRec, 'Resolved', 'Open');
            
            update resultWrap.caseToBeUpdated;
            
            Test.stopTest();
            
            List<ASF_Case_Integration__c> caseIntRecList = [SELECT Name FROM ASF_Case_Integration__c 
                               WHERE Case__c = :caseRec.Id 
                               AND Status__c = :ABFL_Constants.PENDING
                               AND Type__c = :ABFL_Constants.LITMUS
                               LIMIT 1];
            
            Assert.isTrue(caseIntRecList.size() > 0, 'Case Integration record for LITMUS should have been created');
        }
    }
    
    @isTest
    static void testEvaluateCasesForLitmusException(){
        
        Test.startTest();
        ABFL_InvokeLitmusProcess litmusProcessObj = new ABFL_InvokeLitmusProcess();
        litmusProcessObj.evaluateCasesForLitmus(null ,null);                
        Test.stopTest();
        
        List<ABCLLogRecording__c> abclLogsList = [SELECT Id
                                                  FROM ABCLLogRecording__c]; 
    }
    
    @isTest
    static void testCallLitmusAPIException(){
        
        Test.startTest();
        ABFL_InvokeLitmusProcess litmusProcessObj = new ABFL_InvokeLitmusProcess();
        litmusProcessObj.callLitmusAPI(null ,null);                
        Test.stopTest();
        
        List<ABCLLogRecording__c> abclLogsList = [SELECT Id
                                                  FROM ABCLLogRecording__c]; 
    }
}