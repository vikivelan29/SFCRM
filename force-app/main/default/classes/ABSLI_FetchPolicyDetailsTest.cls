@isTest
public class ABSLI_FetchPolicyDetailsTest {
    @TestSetup
    public static void setPolicyData(){
        Account accRec = ASF_TestDataFactory.insertPersonAccount('testFname', 'testLname', '100');
        accRec.PersonBirthdate = Date.today();
        update accRec;
        
        Asset assetRec = ASF_TestDataFactory.createAsset(accRec.Id, 'Loans');
        assetRec.Policy_No__c = '1234';
        update assetRec;
    }
    @isTest
    public static void getPolicyDetailsFromDWHTest(){
        List<Asset> policies = [SELECT ID FROM ASSET];
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('ABSLI_FetchPolicyDetailMockResponse');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        ABSLI_FetchPolicyDetails.fetchPolicyResponseWrapper resp = ABSLI_FetchPolicyDetails.getPolicyDetailsFromDWH(policies[0].Id);
        Test.stopTest();
    }
    @isTest
    public static void coverClassVariables(){
        ABSLI_FetchPolicyDetails.fetchPolicyResponseWrapper resp = new ABSLI_FetchPolicyDetails.fetchPolicyResponseWrapper();
        resp.statusCode = '00';
        resp.message = 'Record retrieved successfully.';
        ABSLI_FetchPolicyDetails.detail cls = new ABSLI_FetchPolicyDetails.detail();
        cls.POL_ID='003149963';
        cls.FND_ID='I0003';
        cls.FUND_VALUE=0.00;
        cls.NAV= 68.519600000;
        cls.FUND_NAME =  'Individual Life - Enhancer';
        cls.TOT_UNITS = 0.000000000;
        resp.FUND_DETAILS = new List<ABSLI_FetchPolicyDetails.detail>{cls};


    }

}