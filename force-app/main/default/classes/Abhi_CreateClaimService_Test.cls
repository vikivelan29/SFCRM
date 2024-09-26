/***************************************
*Class        :  Abhi_CreateClaimService_Test
*Author       :  Kuldeep Mishra
*Created Date :  23/08/2024
*Last Modified:  02/09/2024
*@description :  Test class for ABHI_CreateClaimService.
***************************************/
@isTest
public class Abhi_CreateClaimService_Test {

    @isTest
    static void testCreateClaimSuccess() {
        // Set up test data
        Asset testAsset = new Asset(Name = 'Test Asset', ABHI_Policy_Id__c = 'POL123');
        insert testAsset;

        Health_Provider__c testProvider = new Health_Provider__c(Name = 'Test Provider', Provider_Code__c = 'PRO123');
        insert testProvider;

        Account testAccount = new Account(Name = 'Test Account', LOB_Client_Code__c = 'ACC123');
        insert testAccount;

        Claim__c testClaim = new Claim__c(ClaimExternalId__c = 'CLAIM123');
        insert testClaim;

        Test.startTest();
        
        // Prepare the JSON request body
        String jsonBody = '[{"Claim_Number": "CLAIM123","ClaimDate": "2024-09-05","Paid_Amount": "1500.00","Date_of_admission": "2024-09-01T10:20:45", "Policy_Number": "POL123", "Hospital_Code":"PRO123", "Customer_Member_Mapping":"ACC123","Request_Type":"new req"}]';

        // Set up the mock request
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/CreateClaim';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        
        // Invoke the method
        String response = ABHI_CreateClaimService.doPost();
        
        Test.stopTest();
         // Adjust assertion to match the actual response structure
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response);
        String statusCode = (String) responseMap.get('StatusCode');
        System.assertEquals('200', statusCode, 'Response should indicate success');
        
        // Verify the record is created
        Claim__c createdClaim = [SELECT Id,Claim_Date__c,Paid_Amount__c,Date_of_admission__c,Policy_Number__r.ABHI_Policy_Id__c, ClaimExternalId__c FROM Claim__c WHERE ClaimExternalId__c = 'CLAIM123' LIMIT 1];
        System.assertNotEquals(null, createdClaim, 'Claim record should be created');
        System.assertEquals(Date.valueOf('2024-09-05'), createdClaim.Claim_Date__c , 'ClaimDate should be correctly converted');
        System.assertEquals(1500.00, createdClaim.Paid_Amount__c, 'Paid_Amount should be correctly converted');
        System.assertEquals(DateTime.valueOf('2024-09-01 10:20:45'), createdClaim.Date_of_admission__c, 'Date_of_admission should be correctly converted');
        System.assertEquals('POL123', createdClaim.Policy_Number__r.ABHI_Policy_Id__c, 'Policy_Number should be correctly linked');
        

    }

    @isTest
    static void testCreateClaimErrorHandling() {

        Test.startTest();
        
        // Prepare JSON with missing required fields
        String jsonBody = '[{"Claim_Number": "CLAIM123", "Policy_Number": "PRO123"}]';
        
        // Set up the mock request
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/CreateClaim';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        
        // Invoke the method
        String response = ABHI_CreateClaimService.doPost();
        
        Test.stopTest();
         System.debug('Response from doPost: ' + response);
  // Adjust assertion to match the actual response structure
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response);
        String statusCode = (String) responseMap.get('StatusCode');
        System.assertEquals('100', statusCode, 'Response should indicate Failures');
    }
    
    @isTest
    static void testExceptionHandling() {

        Test.startTest();
        
        // Prepare JSON with an invalid format to trigger exception
        String jsonBody = '[{"Claim_Number": "CLAIM123", "Policy_Number": 12345, "Date_of_admission": "InvalidDate", "Claim_Amount":"InvalidCurrency"}]'; // Policy_Number should be a string
        
        // Set up the mock request
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/CreateClaim';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        
        // Invoke the method
        String response = ABHI_CreateClaimService.doPost();
        
        Test.stopTest();
                // Debug response
        System.debug('Response from PostErrorHandleing: ' + response);
        
        // Validate the response
        // Adjust assertion to match the actual response structure
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response);
        String statusCode = (String) responseMap.get('StatusCode');
        System.assertEquals('100', statusCode, 'Response should indicate Failures');
    }

}