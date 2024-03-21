@isTest
public class ABCL_SurveyResponseTriggerHandlerTest {
    
    @TestSetup
    public static void dataSetup(){
        Account acc= new Account(
            RecordTypeId = Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId(),
            FirstName='Test FName',
            LastName='Test LName',
            PersonMailingStreet='test@yahoo.com',
            PersonMailingPostalCode='12345',
            PersonMailingCity='SFO',
            PersonEmail='test@yahoo.com',
            PersonHomePhone='1234567',
            PersonMobilePhone='12345678',
            Client_Code__c = 'Test_1212',
            Business_Unit__c = 'ABFL'
        );
        insert acc;
        Asset ast = new Asset(Name='AccountFinacial',AccountId=acc.Id, LAN__c = 'LAN_TEST_1212',Business_Unit__c = 'ABFL' );
        insert ast;
        
        Case c = new Case();
        c.Subject = 'SURVEY RESPONSE CASE TEST';
        c.AccountId = acc.Id;
        c.AssetId = ast.Id;
        c.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Interaction').getRecordTypeId();
        insert c;
    }
    
    @isTest
    public static void associateCustomerAndAsset(){
        List<Case> cases = [SELECT ID,Account.Client_Code__c,Asset.LAN__c FROM Case WHERE RecordType.DeveloperName = 'Interaction' LIMIT 1];
        List<Survey_Response__c> responses = new List<Survey_Response__c>();
        if(cases.size()>0){
            Survey_Response__c surveyResponse = new Survey_Response__c();
            surveyResponse.Client_Code_Text__c = cases[0].Account.Client_Code__c;
            surveyResponse.LAN_Text__c = cases[0].Asset.LAN__c;
            surveyResponse.Business_Unit__c = 'ABFL';
            surveyResponse.Request_Datetime__c = System.now().addDays(-7);
            surveyResponse.Responded_on__c = System.now();
            surveyResponse.Rated_Language__c = 'english';
            surveyResponse.Primary_Question_NPS__c = 0;
            surveyResponse.Primary_Comment__c = 'Understanding the customer';
            surveyResponse.Rated_Medium__c = 'Email';
		    surveyResponse.Case__c = cases[0].Id; 
            surveyResponse.Invitation_Id__c = 'TESTING_001'+ System.currentTimeMillis();
            responses.add(surveyResponse);
        }
        if(responses.size()>0){
            insert responses;
            
            Survey_Response__c sResponse = [SELECT ID,Client_Code__r.Client_Code__c,LAN__r.LAN__c FROM Survey_Response__c WHERE ID =: responses[0].Id];
			System.assertEquals(responses[0].Client_Code_Text__c, sResponse.Client_Code__r.Client_Code__c, 'Matching Client Code');            
        }
    }
    
}