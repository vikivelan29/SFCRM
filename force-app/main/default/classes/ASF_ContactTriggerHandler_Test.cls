@isTest
public class ASF_ContactTriggerHandler_Test {
    
    @TestSetup
    private static void dataSetup(){
        Id nonIndividualRecTypeId = Schema.sObjectType.Account.getRecordTypeInfosByDeveloperName().get('Non_Individual').getRecordTypeId();
        Account acc = new Account ();
        acc.RecordTypeId = nonIndividualRecTypeId;
        acc.Client_Code__c ='TEST_1011010110';
        acc.Name = 'Aditya Birla Test Company';
        acc.Line_of_Business__c = 'Payments';
        acc.Business_Unit__c = 'Payments';
        insert acc;
        
    }
    
    @isTest
    private static void createMultipleContactInInsert(){
        List<Contact> conList = new List<Contact>();        
        
        for(Integer i=0;i<2;i++){
            Contact accContact = new Contact();
            accContact.FirstName = 'Test_MerchantContactFNm'+i;
            accContact.LastName = 'Test_MerchantContactLNm'+i;
            accContact.Phone = '111111111'+i;
            accContact.Email = 'invalid+'+i+'@invalid.donotsendemail.com.net';
            accContact.Account = new Account(Client_Code__c='TEST_1011010110');
            conList.add(accContact);
        }
        if(conList.size()>0){
            insert conList;
        }
        
        // Add third Contact Later.
        Contact accContact = new Contact();
        accContact.FirstName = 'Test_MerchantContactFNm';
        accContact.LastName = 'Test_MerchantContactLNm';
        accContact.Phone = '1111111110101';
        accContact.Email = 'invalid010101001@invalid.donotsendemail.com.net';
        accContact.Account = new Account(Client_Code__c='TEST_1011010110');
        
        Test.startTest();
        	insert accContact; 
        Test.stopTest();
        
        Integer count = [SELECT count() FROM Contact];
        Assert.areEqual(3, count);
    }
    
}