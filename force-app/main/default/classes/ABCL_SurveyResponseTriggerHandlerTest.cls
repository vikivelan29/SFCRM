/*********************************************************
*Class        :  ABCL_SurveyResponseTriggerHandlerTest
*Author       :  Virendra Patil
*Created Date :  03/03/2024
*Last Modified:  14/05/2024
*@description :  Test class class for ABCL_SurveyResponseTriggerHandler and ABCL_SurveyResponseHelper
*********************************************************/
@isTest
public class ABCL_SurveyResponseTriggerHandlerTest {
    
    /****************************************************************************************************************
     * @function - dataSetup
     * @description - method to setup data for test cases
     *****************************************************************************************************************/
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
        
        Account acc1= new Account(
            RecordTypeId = Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId(),
            FirstName='Test FName 1',
            LastName='Test LName 1',
            PersonMailingStreet='test1@yahoo.com',
            PersonMailingPostalCode='12345',
            PersonMailingCity='SFO',
            PersonEmail='test1@yahoo.com',
            PersonHomePhone='1234567',
            PersonMobilePhone='12345678',
            Client_Code__c = 'Test_121223',
            Business_Unit__c = 'ABSLAMC'
        );
        
        Asset ast1 = new Asset(Name='AccountFinacial1',AccountId=acc1.Id, LAN__c = 'LAN_TEST_121223',Business_Unit__c = 'ABSLAMC' );
        insert ast1;
        
        Case c = new Case();
        c.Subject = 'SURVEY RESPONSE CASE TEST';
        c.AccountId = acc.Id;
        c.AssetId = ast.Id;
        c.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Interaction').getRecordTypeId();
        insert c;
        
        Case c1 = new Case();
        c1.Subject = 'SURVEY RESPONSE CASE TEST';
        c1.AccountId = acc1.Id;
        c1.AssetId = ast1.Id;
        c1.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Interaction').getRecordTypeId();
        insert c1;
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
        Survey_Response__c surveyResponse = new Survey_Response__c();
        surveyResponse.Litmus_Project_Name__c='AMC- Call Centre';
        surveyResponse.Request_Datetime__c= System.now().addDays(-7);
        surveyResponse.Responded_on__c= System.now().addDays(-2);
        surveyResponse.Rated_Language__c='english';
        surveyResponse.Primary_Question_NPS__c=10;
        surveyResponse.Primary_Comment__c='Test';
        surveyResponse.Rated_Medium__c='SMS';
        surveyResponse.Client_Code_Text__c='MF-LAN_TEST_121223';
        surveyResponse.LAN_Text__c='MF-LAN_TEST_121223';
        surveyResponse.Business_Unit__c='ABSLAMC';
        surveyResponse.Invitation_Id__c='847462edfe70b0a7dcf6192dd5026c789f1f389a652067b56b46c6d2';
        responses.add(surveyResponse);
        if(responses.size()>0){
            insert responses;
            
            Survey_Response__c sResponse = [SELECT ID,Client_Code__r.Client_Code__c,LAN__r.LAN__c FROM Survey_Response__c WHERE ID =: responses[0].Id];
			System.assertEquals(responses[0].Client_Code_Text__c, sResponse.Client_Code__r.Client_Code__c, 'Matching Client Code');            
        }
    }
    
}