@IsTest
public with sharing class PAY_CaseTriggerHelper_Test {
    
    @IsTest
    static void createCustomerForCreateCaseAPITest(){
        PAY_CaseTriggerHelper.CustomerWrapper customWrap = new PAY_CaseTriggerHelper.CustomerWrapper();
        customWrap.LineOfBusiness = 'ABFHL';
        customWrap.ClientCode = 'T_32814';
        customWrap.CompanyPhone = '928283847';
        customWrap.CompanyEmail = 'test@test.com';
        customWrap.DBA = 'Test';
        customWrap.PersonFirstName = 'Test';
        customWrap.PersonLastName = 'Test';
        customWrap.PersonMobilePhone = 'Test';
        customWrap.PersonEmail = 'Test';
        customWrap.PrimContactFirstName = 'Test';
        customWrap.PrimContactLastName = 'Test';
        customWrap.PrimContactPhone = 'Test';
        customWrap.PrimContactEmail = 'test@test.com';
        Case testCase = new Case();
        testCase.Business_Unit__c = 'Payments';
        testCase.Customer_Payload__c = JSON.serialize(customWrap);
        testCase.Technical_Source__c = 'API';
        List<Case> caseList = new List<Case>{testCase};
            Test.startTest();
        PAY_CaseTriggerHelper.createCustomerForCreateCaseAPI((List<Sobject>)caseList);
        customWrap.CompanyName = 'Test';
        customWrap.ClientCode = 'T_32815';
        testCase.Customer_Payload__c = JSON.serialize(customWrap);
        PAY_CaseTriggerHelper.createCustomerForCreateCaseAPI((List<Sobject>)caseList);
        Test.stopTest();
        
        Integer count = [SELECT count() FROM Contact];
        Integer accountCount = [SELECT count() FROM Account];
        Assert.areEqual(count, 1);
        Assert.areEqual(accountCount, 1);
    }
    @IsTest
    static void fetchCustomerInfoExtTest(){
        PAY_CaseTriggerHelper.CustomerWrapper customWrap = new PAY_CaseTriggerHelper.CustomerWrapper();
        
        Case testCase = new Case();
        testCase.Client_Code_Text__c = 'ABC12345';
        testCase.Business_Unit__c = 'Payments';
        testCase.Technical_Source__c = 'API';
        testCase.Customer_Payload__c = JSON.serialize(customWrap);
        List<Case> caseList = new List<Case>{testCase};
            Test.startTest();
        testCase.Customer_Payload__c = JSON.serialize(customWrap);
        
        StaticResourceCalloutMock  mock = new StaticResourceCalloutMock ();
        mock.setStaticResource('MerchantSearchMockResponse');
        mock.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, mock);
        PAY_CaseTriggerHelper.fetchCustomerInfoExt((List<Sobject>)caseList);
        Test.stopTest();
        
        Integer count = [SELECT count() FROM Contact];
        Integer accountCount = [SELECT count() FROM Account];
        Assert.areEqual(count, 1);
        Assert.areEqual(accountCount, 1);
    }
}