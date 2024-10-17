@isTest
public class RNWL_CreateRenewalsTest {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    
    @TestSetup
    public static void setup(){
        User objUser = new User(profileId = SYSTEMADMIN_PROFILE.Id, email = 'test1@salesforce.com',
                                Username = 'Test1'+String.valueOf(Integer.valueof((Math.random() * 10)))+'@mock.com',
                                alias = 'test', lastname = 'lastname', emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                                languagelocalekey = 'en_US', timezonesidkey = 'GMT',IsActive = true);
        insert objUser;
        Account acc = ASF_TestDataFactory.insertBusinessAccount('test', 'strCRN');
        
        List<Asset> assetList = new List<Asset>();
        
        Asset asset = new Asset();
        asset.Name = 'testPolicy';
        asset.Account_no__c = acc.Id;
        asset.LAN__c = '12345678';
        
        assetList.add(asset);
        
        Asset asset1 = new Asset();
        asset1.Name = 'test1Policy';
        asset1.Account_no__c = acc.Id;
        asset1.LAN__c = '98777666';
        
        assetList.add(asset1);
        
        insert assetList;
        
        
    }
    
    @isTest
    public static void testRenewalsSucess(){
        List<RNWL_CreateRenewals.RenewalRequestWrapper> RenewalRequestWrapper = new List<RNWL_CreateRenewals.RenewalRequestWrapper>();
        RNWL_CreateRenewals.RenewalRequestWrapper RenewalRequest1 = new RNWL_CreateRenewals.RenewalRequestWrapper();
        RenewalRequest1.policyNumber = '12345678';
        RenewalRequest1.proposalNumber = '111222';
        RenewalRequest1.policyInceptionDate = String.valueOf(Date.today());

        RenewalRequestWrapper.add(RenewalRequest1);
        
        RNWL_CreateRenewals.RenewalRequestWrapper RenewalRequest2 = new RNWL_CreateRenewals.RenewalRequestWrapper();
        RenewalRequest2.policyNumber = '98777666';
        RenewalRequest2.proposalNumber = '111333';
        RenewalRequest2.policyInceptionDate = String.valueOf(Date.today());

        RenewalRequestWrapper.add(RenewalRequest2);
        
        Test.startTest();
        RNWL_CreateRenewals.RenewalResponseWrapper response = RNWL_CreateRenewals.doPost(RenewalRequestWrapper);
        Test.stopTest();
        Assert.isFalse(response.hasErrors);
    }
    
    @isTest
    public static void testRenewalsFailure(){
        List<RNWL_CreateRenewals.RenewalRequestWrapper> RenewalRequestWrapper = new List<RNWL_CreateRenewals.RenewalRequestWrapper>();
        RNWL_CreateRenewals.RenewalRequestWrapper RenewalRequest1 = new RNWL_CreateRenewals.RenewalRequestWrapper();
        RenewalRequest1.policyNumber = '12345678';
        RenewalRequest1.proposalNumber = '111222';
        RenewalRequest1.policyInceptionDate = String.valueOf(Date.today());

        RenewalRequestWrapper.add(RenewalRequest1);
        
        RNWL_CreateRenewals.RenewalRequestWrapper RenewalRequest2 = new RNWL_CreateRenewals.RenewalRequestWrapper();
        RenewalRequest2.policyNumber = '12345678';
        RenewalRequest2.proposalNumber = '111333';
        RenewalRequest2.policyInceptionDate = String.valueOf(Date.today());

        RenewalRequestWrapper.add(RenewalRequest2);
        
        Test.startTest();
        RNWL_CreateRenewals.RenewalResponseWrapper response = RNWL_CreateRenewals.doPost(RenewalRequestWrapper);
        Test.stopTest();
        Assert.isNotNull(response.errorRecords[0], 'Renewal Request Creation Success');
    }
    

}