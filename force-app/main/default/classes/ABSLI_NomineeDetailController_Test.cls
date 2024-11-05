/**
* @description Unit Test Class for Nominee Detail Controller Integration
*
* @author Laxman R
* @date 2024-06-05
*/
@isTest
public class ABSLI_NomineeDetailController_Test {
    /**
* @description Test Data Setup for this Test Class
*/
    @testSetup
    static void setupTestData() {
        Account accRec = ASF_TestDataFactory.insertPersonAccount('testFname', 'testLname', '100');
        accRec.PersonBirthdate = Date.today();
        update accRec;
        
        Asset assetRec = ASF_TestDataFactory.createAsset(accRec.Id, 'Loans');
        assetRec.Policy_No__c = '1234';
        assetRec.Business_Unit__c = 'ABSLI';
        update assetRec;
    }
    @isTest
    static void testNomineeDetails(){
        Asset assetRec = [Select Id,Policy_No__c From Asset limit 1];
        system.debug('PolicyNo:::'+assetRec.Policy_No__c);
        /* MultiStaticResourceCalloutMock mock = new MultiStaticResourceCalloutMock();
       	mock.setStaticResource(ABCL_Integrations__mdt.getInstance('ABSLI_Policy_Nominee').EndPoint__c,'ABSLI_GetNomineeDetailsMockResponse');
        mock.setStaticResource(ABCL_Integrations__mdt.getInstance('ABSLI_Policy_Nominee').EndPoint__c,'ABSLI_GetNomineeDetailsMockResponse');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);*/
        Test.setMock(HttpCalloutMock.class, new ABSLI_NomineeDetailResponseGenerator());
        Test.startTest();
        ABSLI_NomineeDetailController.ObjRequest objreq = new ABSLI_NomineeDetailController.ObjRequest(assetRec.Policy_No__c);
        objreq.POLICY_NO= '';
        objreq.ClientIPAddress= '';
        objreq.DeviceID= '';
        objreq.OS= '';
        objreq.IMEI= '';
        ABSLI_NomineeDetailController.nomineeResponse response = ABSLI_NomineeDetailController.getNomineeFromCore(assetRec.Id);
        Test.stopTest();
        // Verify the response
        System.assert(response.bSuccess);
        System.assertEquals(1, response.nominees.size());
        System.assertEquals('Test Nominee', response.nominees[0].name);
    }
    
    public class ABSLI_NomineeDetailResponseGenerator implements HttpCalloutMock {
        /**
            * @description  Mocking failure response
            * @param req
            ** @return HTTPResponse
        */ 
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String s = '{\"ReturnCode\":\"0\",\"ReturnMessage\":\"\",\"lstDetails\":[{\"POLICY_NO\":\"1234\",\"NOMINEE_NAME\":\"Test Nominee\",\"APPOINTEE\":\"\",\"DOB_OF_NOMINEE\":\"\",\"RELATIONSHIP\":\"\",\"ALLOCATION\":\"100\",\"SEQUENCENO\":\"1\"}]}';
            res.setBody(s);
            res.setStatusCode(200);
            return res;
        }
    }
}