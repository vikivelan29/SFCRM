/*********************************************************
*Class        :  ABFL_EODController_Test
*Author       :  Udit Singhal
 *Created Date :  22/03/2024
*Last Modified:
*@description  :  Test Class for ABFL_EODController
*********************************************************/
@isTest
public class ABFL_EODController_Test{
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
            UserName = 'cdefghijk5657123456@gmail.com', 
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
            Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
            SLA_Threshold_Warning__c thresholdController = SLA_Threshold_Warning__c.getOrgDefaults();
            thresholdController.Customer_Email_buffer_hours__c = 56;
            update thresholdController;
            
            List<ASF_Case_Category_Config__c> caseCat = ABFL_TestDataFactory.createCaseCategoryConfig(true);
            
            List<ASF_Case_Stage_Config__c> caseStage = ABFL_TestDataFactory.createCaseStageConfigWithTwoStages(caseCat[0].Id, true);
            ABFL_TestDataFactory.createCaseRuleEntry(caseStage);
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
    static void testEODAccountBalance(){
        Asset assetRecord = [SELECT Id
                             FROM Asset
                             LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new ABFL_EODController_Test.MockHttpResponseGenerator());
        Test.startTest();
        ABFL_EODController.ResponseWrapper res = ABFL_EODController.invokeAPI('EOD_Account_Balance', assetRecord.Id);
        Test.stopTest();
        Assert.isTrue(res.statusCode == 200, 'Status Code should not be equal to 200');
        Assert.isTrue(String.isNotBlank(res.payload), 'Payload should not be blank');
    }
    
    @isTest
    static void testEODApplicationDetails(){
        Asset assetRecord = [SELECT Id
                             FROM Asset
                             LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new ABFL_EODController_Test.MockHttpResponseGenerator());
        Test.startTest();
        ABFL_EODController.ResponseWrapper res = ABFL_EODController.invokeAPI('EOD_Application_Details', assetRecord.Id);
        Test.stopTest();
        Assert.isTrue(res.statusCode == 200, 'Status Code should not be equal to 200');
        Assert.isTrue(String.isNotBlank(res.payload), 'Payload should not be blank');
        ABFL_SOQL_Util.getFiscalYear(10,1);
    }
    
    @isTest
    static void testEODRepaymentDetails(){
        Asset assetRecord = [SELECT Id
                             FROM Asset
                             LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new ABFL_EODController_Test.MockHttpResponseGenerator());
        Test.startTest();
        ABFL_EODController.ResponseWrapper res = ABFL_EODController.invokeAPI('EOD_Repayment_Details', assetRecord.Id);
        Test.stopTest();
        Assert.isTrue(res.statusCode == 200, 'Status Code should not be equal to 200');
        Assert.isTrue(String.isNotBlank(res.payload), 'Payload should not be blank');
    }
    
    @isTest
    static void testEODDisbursementDetails(){
        Asset assetRecord = [SELECT Id
                             FROM Asset
                             LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new ABFL_EODController_Test.MockHttpResponseGenerator());
        Test.startTest();
        ABFL_EODController.ResponseWrapper res = ABFL_EODController.invokeAPI('EOD_Disbursement_Details', assetRecord.Id);
        Test.stopTest();
        Assert.isTrue(res.statusCode == 200, 'Status Code should not be equal to 200');
        Assert.isTrue(String.isNotBlank(res.payload), 'Payload should not be blank');
    }

    /****************************************************************************************************************
     * @description Class to generate Mock response for the api call
    *****************************************************************************************************************/
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        /****************************************************************************************************************
        * @description function to create and return fake http response
        * @param req
        * @return HTTPResponse
        *****************************************************************************************************************/
        public HTTPResponse respond(HTTPRequest req) {
            
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"example":"test"}');
            res.setStatusCode(200);
            return res;
        }
    }
}