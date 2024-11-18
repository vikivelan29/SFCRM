@isTest
public class RNWL_AccountTriggerHelperTest {
    
    @TestSetup
    public static void setup(){

        Account acc = RNWL_TestDataFactory.insertBusinessAccount('test', 'strCRN');
        Asset asset = RNWL_TestDataFactory.createAsset(acc.Id,''); 
        Opportunity opp = RNWL_TestDataFactory.createOpportunityRecords(acc.Id, asset.Id);
        
    }
    
    @isTest
    private static void updateOppsUponAccountDataChangeTest(){
        
        Account acc = [Select Id, Phone FROM Account LIMIT 1];
        Test.startTest();
        	acc.Phone = '2345678895';
        	update acc;
        Test.stopTest();
        List<Opportunity> opps = [SELECT Id, Mobile_Number__c FROM Opportunity WHERE AccountId = : acc.Id];
        System.assertEquals(acc.Phone, opps[0].Mobile_Number__c, 'Uhh Ohh! The Opps Phone is not updated');
    }
    
    

}