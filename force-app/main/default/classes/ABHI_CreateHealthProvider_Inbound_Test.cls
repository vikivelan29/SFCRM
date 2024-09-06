/*********************************************************
*Class        :  ABHI_CreateHealthProvider_Inbound_Test
*Author       :  Amrit Preet Singh 
*Created Date :  12/08/2024
*Last Modified:  12/08/2024
*@description  : Test class for ABHI_CreateHealthProvider_Inbound
 * Modifications Log
 * Ver   Date         Author                            Modification
 * 1.0   12-08-2024   amritpreet.singh@salesforce.com   Initial Version
*********************************************************/
@isTest 
private class ABHI_CreateHealthProvider_Inbound_Test {
    
    @isTest 
    static void testCreateRecordsFailure(){
        Test.startTest();
        String JSONMsg = '"{\"HealthProvider\":[{\"abc\":\"CustomerPortal\"}]}"';
        createRequest(JSONMsg);
        String response = ABHI_CreateHealthProvider_Inbound.createRecords();
        Test.stopTest();
        ABHI_ResponseWrapper responseBody = (ABHI_ResponseWrapper) JSON.deserialize(response.toString(), ABHI_ResponseWrapper.class);
        System.assertEquals('100', responseBody.StatusCode);
        System.assertEquals('Failure', responseBody.StatusMessage);
    }

    @isTest 
    static void testCreateRecordsSuccess(){
        List<Health_Provider__c> hpList = new List<Health_Provider__c>();
        Health_Provider__c hp = new Health_Provider__c(
            Source__c = 'CustomerPortal',
            Provider_Code__c = '12345');
        Health_Provider__c hp1 = new Health_Provider__c(
            Source__c = 'CustomerPortal',
            Provider_Code__c = '12367');
        hpList.add(hp);
        hpList.add(hp1);
        ABHI_CreateHealthProvider_Inbound.RequestWrapper rp = new ABHI_CreateHealthProvider_Inbound.RequestWrapper();
        rp.HealthProvider = hpList;
        Test.startTest();
        createRequest(JSON.serialize(rp));
        String response = ABHI_CreateHealthProvider_Inbound.createRecords();
        Test.stopTest();
        ABHI_ResponseWrapper responseBody = (ABHI_ResponseWrapper) JSON.deserialize(response.toString(), ABHI_ResponseWrapper.class);
        System.assertEquals('200', responseBody.StatusCode);
        System.assertEquals('Success', responseBody.StatusMessage);
    }

    @isTest 
    static void testCreateRecordsDMLException(){
        List<Health_Provider__c> hpList = new List<Health_Provider__c>();
        Health_Provider__c hp = new Health_Provider__c();
        hpList.add(hp);
        ABHI_CreateHealthProvider_Inbound.RequestWrapper rp = new ABHI_CreateHealthProvider_Inbound.RequestWrapper();
        rp.HealthProvider = hpList;
        Test.startTest();
        createRequest(JSON.serialize(rp));
        String response = ABHI_CreateHealthProvider_Inbound.createRecords();
        Test.stopTest();
        ABHI_ResponseWrapper responseBody = (ABHI_ResponseWrapper) JSON.deserialize(response.toString(), ABHI_ResponseWrapper.class);
        System.assertEquals('100', responseBody.StatusCode);
        System.assertEquals('Failure', responseBody.StatusMessage);
    }

    /****************************************************************************************************
    * @Function - createRequest
    * @param body - String body to be used
    * description  - Method to create rest request for the test methods
    *****************************************************************************************************/
    private static void createRequest(String body){
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/CreateHealthProvider';
        req.requestBody = Blob.valueof(body);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response= res;
    }
}