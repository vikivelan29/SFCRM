@isTest
public class ABCL_STGCustomerTriggerHandler_Test {
    @TestSetup
    private static void dataSetup(){
        STG_Customer__c stg =  new STG_Customer__c();
        stg.Merchant_Id__c = 'T_71609';
        stg.Doing_Business_As__c = 'ABHFL';
        stg.Merchant_Name__c = 'Aditya Birla Sun Life Insurance';
        stg.Line_of_Business__c = 'Payments';
        stg.Customer_Type__c = 'Non-Individual';
        stg.Merchant_Contact_Payload__c = '[{\"FirstName\":\"Rohit\",\"LastName\":\"Walimbe\",\"MobilePhone\":\"9123456789\",\"Email\":\"dummy@test.com.invalid\",\"Line_of_Business__c\":\"Payments\"}]';
        insert stg;
    }
    @isTest
    private static void invokeEventsTest(){
        System.debug('Done');
    }

}