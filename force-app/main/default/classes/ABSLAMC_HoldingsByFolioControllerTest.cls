@IsTest
public class ABSLAMC_HoldingsByFolioControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Insert test Asset records
        Asset testAssetSIP = new Asset(
            Name = 'Test Asset SIP',
            LAN__c = '1043128322',
            Business_Unit__c = ABSLAMC_Constants.ABSLAMCBU
        );
        insert testAssetSIP;
        
        Asset testAssetHolding = new Asset(
            Name = 'Test Asset Holdings',
            LAN__c = '1043128326',
            Business_Unit__c = ABSLAMC_Constants.ABSLAMCBU
        );
        insert testAssetHolding;
    }
    
    // Mock for the SIP success callout response
    public class MockIntegrationSIPCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String jsonString = '{\"ReturnCode\": \"1\", \"ReturnMessage\": \"Record Retrieved Successfully.\", \"listObject\": [{\"LOB\": \"MF\", \"FOLIO\": \"1043128322\", \"SCHEME_CODE\": \"295G\", \"SCHEME_NAME\": \"ABSL Small Cap Fund Growth\", \"SIP_AMOUNT\": \"1000.00000000\", \"SIP_START_DATE\": \"2022-08-01\", \"SIP_END_DATE\": \"2052-08-01\", \"SIP_FREQUENCY\": \"OM\", \"SIP_TYPE\": \"NA\", \"SIP_STATUS\": \"CANCELLED\", \"CSIP_FOLIO\": \"No\"}]}';
            res.setBody(jsonString);
            res.setStatusCode(200);
            return res;
        }
    }
    
    @IsTest
    static void testGetSIPResponseSuccess() {
        // Mock SIP callout
        Test.setMock(HttpCalloutMock.class, new MockIntegrationSIPCallout());
        
        // Retrieve the test asset's ID
        Asset testAssetSIP = [SELECT Id FROM Asset WHERE Name = 'Test Asset SIP' LIMIT 1];
        
        // Call the method
        Test.startTest();
        ABSLAMC_HoldingsByFolioController.resultWrapper result = ABSLAMC_HoldingsByFolioController.getSIPResponse(testAssetSIP.Id);
        Test.stopTest();
        // Assert the results
        System.assert(result != null, 'Expected result to be not null');
        System.assertEquals(true,result.isSuccess);
    }
    
      // Mock for the Holdings success callout response
    private class MockIntegrationHoldingsCallout implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String jsonString = '{\"ReturnCode\": \"1\", \"ReturnMessage\": \"Record Retrieved Successfully.\", \"listObject\": [{\"LOB\": \"MF\", \"FOLIO\": \"1043128326\", \"SCHEME_CODE\": \"16Z\", \"SCHEME_NAME\": \"ABSL Digital India Fund - Growth-DIRECT\", \"ASSET_CLASS\": \"EQUITY\", \"UNIT_HOLDINGS\": \"0.0000\", \"HOLDING_AMOUNT\": \"0.00\"}, {\"LOB\": \"MF\", \"FOLIO\": \"1043128326\", \"SCHEME_CODE\": \"66Y\", \"SCHEME_NAME\": \"ABSL PSU Equity Fund Direct-Growth\", \"ASSET_CLASS\": \"EQUITY\", \"UNIT_HOLDINGS\": \"114.8550\", \"HOLDING_AMOUNT\": \"4192.21\"}]}';
            res.setBody(jsonString);
            res.setStatusCode(200);
            return res;
        }
    }
    
    @IsTest
    static void testGetHoldingsResponseSuccess() {
        // Mock Holdings callout
        Test.setMock(HttpCalloutMock.class, new MockIntegrationHoldingsCallout());
        
        // Retrieve the test asset's ID
        Asset testAssetHolding = [SELECT Id FROM Asset WHERE Name = 'Test Asset Holdings' LIMIT 1];
        
        // Call the method
        Test.startTest();
        ABSLAMC_HoldingsByFolioController.resultWrapper result = ABSLAMC_HoldingsByFolioController.getHoldingsResponse(testAssetHolding.Id);
        Test.stopTest();
        // Assert the results
        System.assert(result != null, 'Expected result to be not null');
        System.assertEquals(true,result.isSuccess);
       
    }
    
     // Mock for the SIP error callout response
    private class MockIntegrationSIPCalloutError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(400);
            res.setBody('{"ReturnCode": "0", "ReturnMessage": "Error retrieving record."}');
            return res;
        }
    }
    
    @IsTest
    static void testGetSIPResponseError() {
        // Mock a failed SIP callout response
        Test.setMock(HttpCalloutMock.class, new MockIntegrationSIPCalloutError());

        Asset testAssetSIP = [SELECT Id FROM Asset WHERE Name = 'Test Asset SIP' LIMIT 1];

        ABSLAMC_HoldingsByFolioController.resultWrapper result = ABSLAMC_HoldingsByFolioController.getSIPResponse(testAssetSIP.Id);

        System.assert(result != null, 'Expected result to be not null');
        System.assert(!result.isSuccess, 'Expected isSuccess to be false');

    }
}