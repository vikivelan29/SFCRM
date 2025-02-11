@IsTest
public class ABCD_CustomerInfoController_Test {

	@IsTest
    static void testSearchCustomerExternal(){
		List<ABCD_CustomerInfoController.CustomerInfo> phoneSearch = ABCD_CustomerInfoController.searchCustomerExternal('9837236263','Phone');
        List<ABCD_CustomerInfoController.CustomerInfo> emailSearch = ABCD_CustomerInfoController.searchCustomerExternal('abcd@gmail.com','Email');
        List<ABCD_CustomerInfoController.CustomerInfo> genericSearch = ABCD_CustomerInfoController.searchCustomerExternal('abcd@gmail.com','');
        System.Assert(phoneSearch.size()>0);
        System.Assert(emailSearch.size()>0);
        System.Assert(genericSearch.size()>0); 
    }
    
    @IsTest
    static void testCreateCustomerList(){
		ABCD_CustomerInfoController.CustomerInfo custInfo = new ABCD_CustomerInfoController.CustomerInfo();
        custInfo.customerName = 'Test';
        custInfo.dob = '1990-01-01';
        Account createdAccount = ABCD_CustomerInfoController.createCustomer(custInfo);
        System.assert(createdAccount != null);
    }
    
    @IsTest
    static void testGetTabDataTest(){
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('Test_Cmp','Test_1');
        String assetHoldings = ABCD_CustomerInfoController.getTabData('Asset Holdings',accRec.Id);
        String liabilities = ABCD_CustomerInfoController.getTabData('Liabilities',accRec.Id);
        String protection = ABCD_CustomerInfoController.getTabData('Protection',accRec.Id);
        String vas = ABCD_CustomerInfoController.getTabData('VAS',accRec.Id);
        System.assert(assetHoldings != null);
        System.assert(liabilities != null);
        System.assert(protection != null);
        System.assert(vas != null);
    }
}