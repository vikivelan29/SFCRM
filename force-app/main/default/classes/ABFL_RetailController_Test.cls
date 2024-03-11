/*********************************************************
 *Class        :  ABFL_RetailController_Test
 *Author       :  Udit Singhal
 *Created Date :  27/02/2024
 *Last Modified:
 *Description  :  Test Class for ABFL_RetailController
 *********************************************************/
@isTest
public class ABFL_RetailController_Test{
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id
                                                        FROM Profile
                                                        WHERE name = 'System Administrator'
                                                        LIMIT 1];
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
    static void testRealTimeLoanDetails(){
        Asset assetRecord = [SELECT Id
                             FROM Asset
                             LIMIT 1];
        Test.startTest();
        ABFL_RetailController.ResponseWrapper res = ABFL_RetailController.getDynamicScreen('RTL_RealTime_LoanDetails', assetRecord.Id);
        Test.stopTest();
        Assert.isTrue(String.isNotBlank(res.title), 'Title should not be blank in response');
        Assert.isTrue(res.secWrap.size() > 0, 'secWrap list should have some records');
    }

    @isTest
    static void testRealTimeBasicCustInfo(){
        Asset assetRecord = [SELECT Id
                             FROM Asset
                             LIMIT 1];
        Test.startTest();
        ABFL_RetailController.ResponseWrapper res = ABFL_RetailController.getDynamicScreen('RTL_RealTime_BasicCustInfo', assetRecord.Id);
        Test.stopTest();
        Assert.isTrue(String.isNotBlank(res.title), 'Title should not be blank in response');
        Assert.isTrue(res.secWrap.size() > 0, 'secWrap list should have some records');
    }

    @isTest
    static void testRealTimeGCCPropertyDetails(){
        Asset assetRecord = [SELECT Id
                             FROM Asset
                             LIMIT 1];
        Test.startTest();
        ABFL_RetailController.ResponseWrapper res = ABFL_RetailController.getDynamicScreen('RTL_RealTIme_GCCPropertyDetails', assetRecord.Id);
        Test.stopTest();
        Assert.isTrue(String.isNotBlank(res.title), 'Title should not be blank in response');
        Assert.isTrue(res.secWrap.size() > 0, 'secWrap list should have some records');
    }

    @isTest
    static void testRealTimeLoanMIS(){
        Asset assetRecord = [SELECT Id
                             FROM Asset
                             LIMIT 1];
        Test.startTest();
        ABFL_RetailController.ResponseWrapper res = ABFL_RetailController.getDynamicScreen('RTL_RealTime_LoanMIS', assetRecord.Id);
        Test.stopTest();
        Assert.isTrue(String.isNotBlank(res.title), 'Title should not be blank in response');
        Assert.isTrue(res.secWrap.size() > 0, 'secWrap list should have some records');
    }

    @isTest
    static void testRealTimeInstallPmntDtls(){
        Asset assetRecord = [SELECT Id
                             FROM Asset
                             LIMIT 1];
        Test.startTest();
        ABFL_RetailController.ResponseWrapper res = ABFL_RetailController.getDynamicScreen('RTL_RealTime_InstallPmntDtls', assetRecord.Id);
        Test.stopTest();
        Assert.isTrue(String.isNotBlank(res.title), 'Title should not be blank in response');
        Assert.isTrue(res.secWrap.size() > 0, 'secWrap list should have some records');
    }
    
    @isTest
    static void testRealTimeIGetCRMDetails(){
        Asset assetRecord = [SELECT Id
                             FROM Asset
                             LIMIT 1];
        Test.startTest();
        ABFL_RetailController.ResponseWrapper res = ABFL_RetailController.getDynamicScreen('RTL_RealTime_GetCRMDetails', assetRecord.Id);
        Test.stopTest();
        Assert.isTrue(String.isNotBlank(res.title), 'Title should not be blank in response');
        Assert.isTrue(res.secWrap.size() > 0, 'secWrap list should have some records');
    }
}