/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-15-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public with sharing class PAY_CustomerSearchController_Test {

    @isTest
    static void testSearchCustomerExternal(){
        Account accountsToInsert = new Account();
        accountsToInsert.Name = 'Test';
        accountsToInsert.Phone = '3827462';
        insert accountsToInsert;
        List<Id> searchResults = new List<Id>{accountsToInsert.Id};
		StaticResourceCalloutMock  mock = new StaticResourceCalloutMock ();
        mock.setStaticResource('CustomerSearchMockResponse');
        mock.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, mock);
        test.startTest();
            List<PAY_CustomerSearchController.CustomerDetailsWrapper> customerDetails = PAY_CustomerSearchController.searchCustomerExternal(accountsToInsert.Phone, 'Phone');
        	mock.setStaticResource('MerchantSearchMockResponse');    
        	List<PAY_CustomerSearchController.CustomerDetailsWrapper> merchantDetails = PAY_CustomerSearchController.searchCustomerExternal(accountsToInsert.Phone, '');
        test.stopTest();
        System.AssertEquals(merchantDetails.size(),1);
    }
    
    @isTest
    static void testCreateCustomer(){
		PAY_CustomerSearchController.CustomerDetailsWrapper customerDetails = new PAY_CustomerSearchController.CustomerDetailsWrapper();
        customerDetails.Name = 'Test Customer';
        customerDetails.Phone = '438101222';
        customerDetails.ClientCode = 'T_39281';
        customerDetails.CustomerType = 'Individual';
        customerDetails.Email = 'test@test.com';
        customerDetails.CustomerExistsInSFDC = false;
        customerDetails.DoingBusinessAs = 'Test';
        customerDetails.ContactFirstName = 'Test';
        customerDetails.ContactLastName = 'Test';
        customerDetails.LineOfBusiness = 'Payments';
        customerDetails.CustomerSince = String.valueof(system.today());
        customerDetails.Id = 'test';
        test.startTest();
            Account createdIndividualAccount = PAY_CustomerSearchController.createCustomer(customerDetails);
            customerDetails.CustomerType = 'Non_Individual';
            customerDetails.ClientCode = 'T_39282';
            Account createdNonIndividualAccount = PAY_CustomerSearchController.createCustomer(customerDetails);
        test.stopTest();
        List<Contact> contactList = [Select id from Contact where FirstName = 'Test' and LastName = 'Test'];
        System.assert(contactList.size() > 0);
        
        
    }
}