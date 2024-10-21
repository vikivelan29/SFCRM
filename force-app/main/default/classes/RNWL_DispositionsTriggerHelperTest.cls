@isTest
public class RNWL_DispositionsTriggerHelperTest {
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
    }
    
    @IsTest
    private static void test_SetRenewalRequestOnDisposition(){
        Account acc = [Select Id FROM Account LIMIT 1];
        Asset asset = [Select Id FROM Asset LIMIT 1];
        Opportunity oppRec = RNWL_TestDataFactory.createOpportunityRecords(acc.Id, asset.Id);
        Test.startTest();
            Dispositions__c disp = new Dispositions__c();
            disp.Category__c = 'Renewal';
            disp.Policy_Number__c = asset.Id;
            insert disp;
        Test.stopTest();
        disp = [SELECT Id, Renewal_Request__c FROM Dispositions__c WHERE Id = :disp.id];
        System.assertEquals(oppRec.Id, disp.Renewal_Request__c, 'Uhhh Ohhh! Renewal Request is not updated!');
    }
    
    @isTest
    public static void test_BeforeTest(){
        Account acc = [Select Id FROM Account LIMIT 1];
        Asset asset = [Select Id FROM Asset LIMIT 1];
        
        Test.startTest();
        	Opportunity OppRec = RNWL_TestDataFactory.createOpportunityRecords(acc.Id, asset.Id);
        Test.stopTest();
        
        Dispositions__c disp = new Dispositions__c();
        disp.Renewal_Request__c = OppRec.Id;
        disp.Disposition_L1__c = 'Policy renewed';
        disp.Disposition_L2__c = 'Paid Confirmation Received';
        disp.Disposition_L3__c = 'Renewed As per RN';
        disp.Policy_Number__c = asset.Id;
        Insert disp;
        
        Dispositions__c dispRec1 = [Select Id,Disposition_L1__c,Disposition_L2__c,Disposition_L3__c FROM Dispositions__c where Id =: disp.Id LIMIT 1];
         
        dispRec1.Disposition_L1__c = 'Promise to Pay';
        dispRec1.Disposition_L2__c = 'PTP- Online/CP/Wallet';
        dispRec1.Disposition_L3__c = 'Will Renew As per RN';
        
        Update dispRec1;
        
        Dispositions__c dispRec = new Dispositions__c();
        dispRec.Renewal_Request__c = OppRec.Id;
        dispRec.Disposition_L1__c = 'Policy renewed';
        dispRec.Disposition_L2__c = 'Paid Confirmation Received';
        dispRec.Disposition_L3__c = 'Renewed with Rider';
        dispRec.Policy_Number__c = asset.Id;
        insert dispRec;
    }

}