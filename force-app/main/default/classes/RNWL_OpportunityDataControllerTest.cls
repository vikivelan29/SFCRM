@isTest
public class RNWL_OpportunityDataControllerTest {
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
        
    }
        @isTest
    public static void test_oppUpdateSuccess(){
        Account acc = [Select Id FROM Account LIMIT 1];
        Asset asset = [Select Id FROM Asset LIMIT 1];
        
        String jsonObject = '[{' +
        '  "Policy Number" : "12456",' +
        '  "Upsell Eligibility Flag" : "Yes",' +
        '  "Propensity to Pay" : "High",' +
        '  "Renewal Calling Flag " : "Yes",' +
        '  "Calling Source" : "ATS"' +
        '}]';
        
        Test.startTest();
        Opportunity objOpportunity = ASF_TestDataFactory.createOpportunityRecords(acc.Id, asset.Id);
        String result = RNWL_OpportunityDataController.updateOpportunityRecords(jsonObject);
        Test.stopTest();
                
        Assert.areEqual('Success!', result, 'Opportunity Update Failed');
       
    }
       @isTest
    public static void test_oppUpdateFailure(){
        Account acc = [Select Id FROM Account LIMIT 1];
        Asset asset = [Select Id FROM Asset LIMIT 1];
        
        String jsonObject = '[{' +
        '  "Policy Number" : "9001999",' +
        '  "Upsell Eligibility Flag" : "Yes",' +
        '  "Propensity to Pay" : "High",' +
        '  "Renewal Calling Flag " : "Yes",' +
        '  "Calling Source" : "ATS"' +
        '}]';
        
        Test.startTest();
        Opportunity objOpportunity = ASF_TestDataFactory.createOpportunityRecords(acc.Id, asset.Id);
        String result = RNWL_OpportunityDataController.updateOpportunityRecords(jsonObject);
        Test.stopTest();
                
        Assert.areNotEqual('Success!', result, 'Opportunity Update Success');
       
    }

}