@isTest
private class PAY_CustomerCreationListenerTest {

    @isTest
    static void testProcessEvents() {
        PAY_Staging_Customer_to_Account__e event = new PAY_Staging_Customer_to_Account__e();
        event.Merchant_Id__c = 'TestMerchantId';
        event.Merchant_Name__c = 'TestMerchantName';
        event.Line_of_Business__c = 'TestLOB';
        event.Customer_Type__c = 'Individual';
        event.Mobile__c = '1234567890';
        event.Email__c = 'test@example.com';
        event.First_Name__c = 'TestFirstName';
        event.Last_Name__c = 'TestLastName';
        event.Merchant_Contact_Payload__c = '[{"FirstName":"TestContactFirstName","LastName":"TestContactLastName","MobilePhone":"9876543210","Email":"contact@example.com","lineOfBusiness":"TestLOB"}]';

        List<PAY_Staging_Customer_to_Account__e> testEvents = new List<PAY_Staging_Customer_to_Account__e>();
        testEvents.add(event);

        Account existingAccount = new Account(Name = 'ExistingAccount', Client_Code__c = 'TestMerchantId');
        insert existingAccount;

        Contact existingContact = new Contact(
            FirstName = 'ExistingContactFirstName',
            LastName = 'ExistingContactLastName',
            MobilePhone = '9876543210',
            Email = 'existing@example.com',
            AccountId = existingAccount.Id,
            Line_of_Business__c = 'TestLOB'
        );
        insert existingContact;

     

        Test.startTest();
        Database.SaveResult[] results = EventBus.publish(testEvents);
        Test.getEventBus().deliver();
        Test.stopTest();
		Assert.areEqual(true, results[0].isSuccess());

    }
    @isTest
    static void testProcessEventsIndividual() {
        PAY_Staging_Customer_to_Account__e event = new PAY_Staging_Customer_to_Account__e();
        event.ABC_Cust_Id__c = '134223';
        event.Mobile__c = '1111111111';
        event.Last_Name__c ='TestingLNm';
        event.Email__c = 'invalid@invalid.test.com.net';
        event.Customer_Since__c = System.today();
        event.Line_of_Business__c = 'Payments';
        event.Customer_Type__c ='Individual';
        
        STG_Customer__c stgCustomer = new STG_Customer__c();
        insert stgCustomer;
        
		event.STG_Customer_Id__c = stgCustomer.Id;
        List<PAY_Staging_Customer_to_Account__e> testEvents = new List<PAY_Staging_Customer_to_Account__e>();
        testEvents.add(event);


        Test.startTest();
        Database.SaveResult[] results = EventBus.publish(testEvents);
        Test.getEventBus().deliver();
        Test.stopTest();
	
        Assert.areEqual(true, results[0].isSuccess());
    }
    
    @isTest
    static void testProcessEventsNonIndividual() {
        PAY_Staging_Customer_to_Account__e event = new PAY_Staging_Customer_to_Account__e();
        event.ABC_Cust_Id__c = '134223';
        event.Mobile__c = '1111111110';
        event.Last_Name__c ='TestingLNmn';
        event.Email__c = 'invalidity@invalid.test.com.net';
        event.Customer_Since__c = System.today();
        event.Line_of_Business__c = 'Payments';
        event.Customer_Type__c ='Non-Individual';
		/*List<STG_Customer__c> customerStaging = [SELECT Id from STG_Customer__c];
        event.STG_Customer_Id__c = customerStaging[0].Id;*/
        
        List<PAY_Staging_Customer_to_Account__e> testEvents = new List<PAY_Staging_Customer_to_Account__e>();
        testEvents.add(event);


        Test.startTest();
        Database.SaveResult[] results = EventBus.publish(testEvents);
        Test.getEventBus().deliver();
        Test.stopTest();

		Assert.areEqual(true, results[0].isSuccess());
    }
}