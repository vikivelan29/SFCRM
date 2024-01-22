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
        testCase.Customer_Payload__c = JSON.serialize(customWrap);
        List<Case> caseList = new List<Case>{testCase};
        PAY_CaseTriggerHelper.createCustomerForCreateCaseAPI((List<Sobject>)caseList);
        customWrap.CompanyName = 'Test';
        customWrap.ClientCode = 'T_32815'; 
        testCase.Customer_Payload__c = JSON.serialize(customWrap);
        PAY_CaseTriggerHelper.createCustomerForCreateCaseAPI((List<Sobject>)caseList);
    }
}