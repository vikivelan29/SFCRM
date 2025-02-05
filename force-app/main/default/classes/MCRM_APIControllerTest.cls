/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 11-13-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   11-13-2024   rsinghnagar@salesforce.com   Initial Version
**/
@isTest
private class MCRM_APIControllerTest {
    @testSetup
    static void setupTestData() {
        //Create wellness user
        User userRecord = MCRM_TestDataFactory.createWellnessUser();
        System.runAs(userRecord){
            // Create ASF_Case_Category_Config__c Records
            ASF_Case_Category_Config__c config1 = new ASF_Case_Category_Config__c(CCC_External_Id__c='Wellness_Req_001', Type__c='Polad', Sub_Type__c='Polad_Deletions');
            insert config1;

            // Create an Account with Client_Code__c
            Account testAccount = new Account(Name = 'Test Account', Client_Code__c = '6672118503');
            insert testAccount;
            
            // Create an Asset linked to the Account
            Asset testAsset = new Asset(Name = 'Test Asset', Policy_No__c = 'LAN1234', AccountId = testAccount.Id, Business_Unit__c = System.label.Wellness_BU);
            insert testAsset;
            
            // Create a Case
            Case testCase = new Case(Subject = 'Test Case');
            testCase.AssetId = testAsset.Id;
            testCase.AccountId = testAccount.Id;
            insert testCase;
        }
    }
    
	@isTest
    static void fetchTableMetadata(){
        User userRecord = [
            SELECT Id 
            FROM User
            WHERE Alias = 'standt'
            LIMIT 1
        ];
        System.runAs(userRecord){
            Test.startTest();
            List<Asf_Dynamic_Datatable_Child__mdt> childConfigs = MCRM_APIController.fetchTableMetadata('MCRM_TotalActiveDays');
            Assert.isTrue(childConfigs.size() > 0, 'Metadata should not be empty');
            Test.stopTest();
        }
    }

	@isTest
    static void invokeAPIwithParams_Account(){
        User userRecord = [
            SELECT Id 
            FROM User
            WHERE Alias = 'standt'
            LIMIT 1
        ];
        System.runAs(userRecord){
            Test.startTest();
            Account acc = [SELECT Id FROM Account LIMIT 1];
            Test.setMock(HttpCalloutMock.class, new MCRM_APIControllerTest.MockHttpResponseGenerator());
            MCRM_APIController.ResponseWrapper response = MCRM_APIController.invokeAPIwithParams(acc.Id,'MCRM_Wallet_Transaction', new Map<String, Object>{'param1'=>'Test1','param2'=>'Test2'});
            Test.stopTest();
            Assert.isTrue(response.statusCode == 200, 'Status Code should not be equal to 200');
            Assert.isTrue(String.isNotBlank(response.payload), 'Payload should not be blank');
        }
    }

	@isTest
    static void invokeAPIwithParams_Asset(){
        User userRecord = [
            SELECT Id 
            FROM User
            WHERE Alias = 'standt'
            LIMIT 1
        ];
        System.runAs(userRecord){
            Test.startTest();
            Asset asst = [select id from Asset];
            Test.setMock(HttpCalloutMock.class, new MCRM_APIControllerTest.MockHttpResponseGenerator());

            MCRM_APIController.ResponseWrapper response = MCRM_APIController.invokeAPIwithParams(asst.Id,'MCRM_Wallet_Transaction', new Map<String, Object>{'param1'=>'Test1','param2'=>'Test2'});
            Assert.isTrue(response.statusCode == 200, 'Status Code should not be equal to 200');
            Assert.isTrue(String.isNotBlank(response.payload), 'Payload should not be blank'); 
        }   
    }

	@isTest
    static void invokeAPIwithParamsWithDates(){
        User userRecord = [
            SELECT Id 
            FROM User
            WHERE Alias = 'standt'
            LIMIT 1
        ];
        System.runAs(userRecord){
            Test.startTest();
            Account acc = [SELECT Id FROM Account LIMIT 1];
            Test.setMock(HttpCalloutMock.class, new MCRM_APIControllerTest.MockHttpResponseGenerator());

            MCRM_APIController.ResponseWrapper response = MCRM_APIController.invokeAPIwithParams(acc.Id,'MCRM_Lifestyle_Voucher', new Map<String, Object>{'param1'=>'Test1','param2'=>'Test2','startDate'=>Datetime.now().addDays(-5).format('YYYY-MM-DD'),'endDate'=>Datetime.now().format('YYYY-MM-DD')});
            Assert.isTrue(response.statusCode == 200, 'Status Code should not be equal to 200');
            Assert.isTrue(String.isNotBlank(response.payload), 'Payload should not be blank');
        }
    }

	@isTest
    static void invokeAPIwithParamsWithDates_MCRM_ActiveDayURL(){
        User userRecord = [
            SELECT Id 
            FROM User
            WHERE Alias = 'standt'
            LIMIT 1
        ];
        System.runAs(userRecord){
            Test.startTest();
            Account acc = [SELECT Id FROM Account LIMIT 1];
            Test.setMock(HttpCalloutMock.class, new MCRM_APIControllerTest.MockHttpResponseGenerator());

            MCRM_APIController.ResponseWrapper response = MCRM_APIController.invokeAPIwithParams(acc.Id,'MCRM_ActiveDayURL', new Map<String, Object>{'param1'=>'Test1','param2'=>'Test2','startDate'=>Datetime.now().addDays(-5).format('YYYY-MM-DD'),'endDate'=>Datetime.now().format('YYYY-MM-DD')});
            Assert.isTrue(response.statusCode == 200, 'Status Code should not be equal to 200');
            Assert.isTrue(String.isNotBlank(response.payload), 'Payload should not be blank');
        }
    }

    @isTest
    static void invokeAPIwithParamsWithDatesException(){
        User userRecord = [
            SELECT Id 
            FROM User
            WHERE Alias = 'standt'
            LIMIT 1
        ];
        System.runAs(userRecord){
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MCRM_APIControllerTest.MockHttpResponseGenerator());
            try {
                MCRM_APIController.ResponseWrapper response = MCRM_APIController.invokeAPIwithParams(null,null, null);
            } catch (Exception ex) {
                System.assertEquals(true,ex != null,'Exception should not be null');
            }
        }
    }

    @isTest
    static void invokeAPIwithParamsWithDates_MCRM_Devices(){
        User userRecord = [
            SELECT Id 
            FROM User
            WHERE Alias = 'standt'
            LIMIT 1
        ];
        System.runAs(userRecord){
            Test.startTest();
            Account acc = [SELECT Id FROM Account LIMIT 1];
            Test.setMock(HttpCalloutMock.class, new MCRM_APIControllerTest.DevicesMockHttpResponseGenerator());

            MCRM_APIController.ResponseWrapper response = MCRM_APIController.invokeAPIwithParams(acc.Id,'MCRM_Devices', new Map<String, Object>{'param1'=>'Test1','param2'=>'Test2','startDate'=>Datetime.now().addDays(-5).format('YYYY-MM-DD'),'endDate'=>Datetime.now().format('YYYY-MM-DD')});
            Assert.isTrue(response.statusCode == 200, 'Status Code should not be equal to 200');
            Assert.isTrue(String.isNotBlank(response.payload), 'Payload should not be blank');
        }
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
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"example":"test"}');
            response.setStatusCode(200);
            return response;
        }
    }

    /****************************************************************************************************************
     * @description Class to generate Mock response for the api call
    *****************************************************************************************************************/
    public class DevicesMockHttpResponseGenerator implements HttpCalloutMock {
        /****************************************************************************************************************
        * @description function to create and return fake http response
        * @param req
        * @return HTTPResponse
        *****************************************************************************************************************/
        public HTTPResponse respond(HTTPRequest req) {
            
            // Create a fake response
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"Content":"vVaARzYilnUCEbspORVGI0tv3TDveZjnkoYiug1me+gqgoCfwSrlLg16XYx/jKZsxf6anG7RSHhe2V8Y7Dc+jA==","StatusCode":"1001","Message":"DeviceDetails Failure"}');
            response.setStatusCode(200);
            return response;
        }
    }
}