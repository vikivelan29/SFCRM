@isTest
public class ABHI_ViewPolicyInformation_Cntrl_Test {
    
    @testSetup
    static void setupTestData() {
        // Insert a test Account record
        Account testAcc = new Account(Name = 'Test Account', Client_Code__c = '123456');
        insert testAcc;
    }

    @SuppressWarnings('PMD.ApexDoc')
    // Mock class to simulate callout with updated response body
    private class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"AppRegDetails":{"AddressLine1":"S/O Prakashrao Bhule HANUMAN CHAWK Thugaon Pimpri","AddressLine2":"Amravati 444723 Maharashtra India","AddressLine3":"null","AlternateMobile":"","CII_Number":"","City":"Chandur","CoreSystemId":"PT87545156","CreatedAt":"17/04/2024","DateOfBirth":"29/12/1997","Education":"","Email":"test@gmail.com","FullName":"AKSHAYPRAKASHRAOBHULE","Gender":"M","Invalid_LoginAttempts":"","IsRegistered":"No","MemberId":"PT87545156","MobilePhone":"9792479774","Occupation":"1050","PanNo":"","PartyId":"PT87545156","Pin":"444723","Policy_Type":"Retail","State":"MAHARASHTRA","vchRelation":" ","WellnessPartyId":"1223647","appDownloadDate":"NA","appRegiterDate":"NA","isAppDownloaded":"No","isAppRegistered":"No","lastAccessDate":"NA"},"HealthReturns":{"Response":[{"MemberCode":"PT87545156","MemberName":"AKSHAY PRAKASHRAO BHULE"}],"PolObj":[{"PolicyNumber":"12-24-0000239-01","PolicyType":"Individua","ProposerName":"AKSHAY PRAKASHRAO BHULE"}],"HealthReturnObj":[{"PolicyNumber":"12-24-0000239-01","PolicyType":"Individua","ProposerName":"AKSHAY PRAKASHRAO BHULE","Amount_Earn_Burn":"0","Source_Earn_Burn":"Activity","Frequency_Earn_Burn":"Earn"},{"PolicyNumber":"12-24-0000239-01","PolicyType":"Individua","ProposerName":"AKSHAY PRAKASHRAO BHULE","Amount_Earn_Burn":"0","Source_Earn_Burn":"Activity","Frequency_Earn_Burn":"Earn"}],"TotalHealthReturnObj":[{"PolicyNumber":"12-24-0000239-01","PolicyType":"Individua","ProposerName":"AKSHAY PRAKASHRAO BHULE","Total_Earn":"0.0","Total_Burn":"0.0","Total_Balance":"0"},{"PolicyNumber":"12-24-0000239-01","PolicyType":"Individua","ProposerName":"AKSHAY PRAKASHRAO BHULE","Total_Earn":"0.0","Total_Burn":"0.0","Total_Balance":"0"}]},"StatusCode":1000,"Message":"Success"}');
            return res;
        }
    }
    
    @isTest
    static void testViewPolicyInformationApiCallout() {
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        // Fetch the test Account record
        Account acc = [SELECT Id FROM Account LIMIT 1];

        // Perform the callout method
        Test.startTest();
        ABHI_ViewPolicyInformation_Controller.ResponseWrapper resp = ABHI_ViewPolicyInformation_Controller.viewPolicyInformationApiCallout(acc.Id);
        Test.stopTest();

        // Validate the response
        System.assertEquals(1000, resp.StatusCode, 'StatusCode should be 1000');
        System.assertEquals('Success', resp.Message, 'Message should be Success');
        
        // Validate AppRegDetails
        System.assertNotEquals(null, resp.AppRegDetails, 'AppRegDetails should not be null');
        System.assertEquals('No', resp.AppRegDetails.IsRegistered, '');
        System.assertEquals('No', resp.AppRegDetails.isAppDownloaded, '');
        
        // Validate HealthReturns
        System.assertNotEquals(null, resp.HealthReturns, 'HealthReturns should not be null');
        System.assertEquals('0', resp.HealthReturns.TotalHealthReturnObj[0].Total_Balance, 'Total_Balance should be 0');
    }

    @isTest
    static void testPrepareRequestPayload() {
        // Fetch the test Account record
        Account acc = [SELECT Id, Client_Code__c FROM Account LIMIT 1];
        
        // Create an instance of the controller
        ABHI_ViewPolicyInformation_Controller controller = new ABHI_ViewPolicyInformation_Controller();

        // Call the prepareRequestPayload method
        ABHI_ViewPolicyInformation_Controller.RequestWrapper reqWrapper = controller.prepareRequestPayload(acc.Id);

        // Validate the request payload
        System.assertEquals(acc.Client_Code__c, reqWrapper.MemberNumber, 'MemberNumber should match the Client_Code__c');
        System.assertNotEquals(null, reqWrapper.RequestType, 'RequestType should not be null');
        System.assertEquals(1, reqWrapper.RequestType.size(), 'There should be 1 RequestType object');
        System.assertEquals('GetHealthReturn', reqWrapper.RequestType[0].HealthReturns, 'HealthReturns should be GetHealthReturn');
        System.assertEquals('UserInfo', reqWrapper.RequestType[0].AppRegDetails, 'AppRegDetails should be UserInfo');
    }
}