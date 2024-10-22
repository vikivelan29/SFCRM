@isTest
public class RNWL_PreviousPolicyDetailTriggerTest {
	@TestSetup
    public static void setup(){
        Account acc=  new Account(name='Test Account' ,Client_Code__c = 'PT87552250');
        insert acc;
        
        Asset objAsset =  new Asset(name='71-20-00040-01-02', ABHI_Policy_Id__c='21-24-0000759-01', LAN__c = '21-24-0000759-01');
        insert objAsset;
        
        Opportunity oppRec = new Opportunity();
        oppRec.Name = 'Testabc' ;
        oppRec.AccountId = acc.Id;
        oppRec.CloseDate = Date.today();
		oppRec.Policy__c = objAsset.Id;
        oppRec.StageName = 'In Progress';
        oppRec.Policy_Number__c = 'GFB-HB-22-2024165-004';
       	insert oppRec;
    }
    
    @IsTest
    static void invokeTrigger(){
        Test.startTest();
        
        Asset asst = [Select id from Asset Limit 1];
        Previous_Policy_Details__c policy =  new Previous_Policy_Details__c();
        policy.PreviousPolicyNumber__c= 'GFB-HB-22-2024165-004';
        policy.Policy__c = asst.Id;
        insert policy;
        
        Test.stopTest();
    }
}