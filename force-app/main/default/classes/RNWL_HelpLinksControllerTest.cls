/***********************************************************
*Class        :  RNWL_HelpLinksControllerTest
*Author       :  Joshna
*Created Date :  16/10/2024
*Last Modified:  16/10/2024
*@description  : Test class for RNWL_HelpLinksController
***********************************************************/
@isTest
public class RNWL_HelpLinksControllerTest {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    
    @TestSetup
    public static void setup(){
        User objUser = new User(profileId = SYSTEMADMIN_PROFILE.Id, email = 'test1@salesforce.com',
                                Username = 'Test1'+String.valueOf(Integer.valueof((Math.random() * 10)))+'@mock.com',
                                alias = 'test', lastname = 'lastname', emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                                languagelocalekey = 'en_US', timezonesidkey = 'GMT',IsActive = true);
        insert objUser;
        Account acc = ASF_TestDataFactory.insertBusinessAccount('test', 'strCRN');
        
        Asset asset = ASF_TestDataFactory.createAsset(acc.Id,''); 
        ASF_TestDataFactory.insertBusinessAccount('test before opp', 'strCRN');  
        Opportunity objOpportunity = RNWL_TestDataFactory.createOpportunityRecords(acc.Id, asset.Id);
    }
    
    @isTest
    public static void test_BeforeTest(){
        Opportunity opp = [Select Id FROM Opportunity LIMIT 1];
        Account acc = [Select Id,Phone FROM Account LIMIT 1];
        Test.startTest();
        RNWL_HelpLinksController.getAutoCalculationLink(opp.Id);
        acc.Phone = '9988778899';
        update acc;
        RNWL_HelpLinksController.getAutoCalculationLink(opp.Id);
        RNWL_HelpLinksController.getAutoCalculationLink(null);        
        Test.stopTest();
    }

}