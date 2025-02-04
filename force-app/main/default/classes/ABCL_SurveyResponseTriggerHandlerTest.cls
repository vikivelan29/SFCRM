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
        
         Account acc2= new Account(
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
            Business_Unit__c = 'ABHFL'
        );
        insert acc2;
        Asset ast2 = new Asset(Name='AccountFinacial',AccountId=acc2.Id, LAN__c = 'LAN_TEST_1212',Business_Unit__c = 'ABHFL' );
        insert ast2;
        
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
        
        Case c2 = new Case();
        c2.Subject = 'SURVEY RESPONSE CASE TEST';
        c2.AccountId = acc2.Id;
        c2.AssetId = ast2.Id;
        c2.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Interaction').getRecordTypeId();
        insert c2;
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
        
         List<Case> cases1 = [SELECT ID,Account.Client_Code__c,Asset.LAN__c,caseNumber FROM Case WHERE RecordType.DeveloperName = 'Interaction' AND Account.Business_Unit__c = 'ABHFL'  LIMIT 1];
        Survey_Response__c surveyResponse1 = new Survey_Response__c();
        surveyResponse1.Litmus_Project_Name__c='AMC- Call Centre';
        surveyResponse1.Request_Datetime__c= System.now().addDays(-7);
        surveyResponse1.Responded_on__c= System.now().addDays(-2);
        surveyResponse1.Rated_Language__c='english';
        surveyResponse1.Primary_Question_NPS__c=10;
        surveyResponse1.Primary_Comment__c='Test';
        surveyResponse1.Rated_Medium__c='SMS';
        surveyResponse1.Client_Code_Text__c='MF-LAN_TEST_121223';
        surveyResponse1.LAN_Text__c='MF-LAN_TEST_121223';
        surveyResponse1.Business_Unit__c='ABHFL';
        //surveyResponse.Case__c = cases1[0].Id; 
        surveyResponse1.Case_Text__c = cases1[0].caseNumber; 
        surveyResponse1.Invitation_Id__c='TESTING_002'+ System.currentTimeMillis();
        responses.add(surveyResponse1);
        
        if(responses.size()>0){
            insert responses;
            
            Survey_Response__c sResponse = [SELECT ID,Client_Code__r.Client_Code__c,LAN__r.LAN__c FROM Survey_Response__c WHERE ID =: responses[0].Id];
			System.assertEquals(responses[0].Client_Code_Text__c, sResponse.Client_Code__r.Client_Code__c, 'Matching Client Code');            
        }
    }
    
}