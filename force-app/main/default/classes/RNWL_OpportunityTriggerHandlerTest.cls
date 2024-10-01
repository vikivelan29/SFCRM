@isTest
public class RNWL_OpportunityTriggerHandlerTest {
    
    
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
    public static void test_BeforeTest(){
        Account acc = [Select Id FROM Account LIMIT 1];
        Asset asset = [Select Id FROM Asset LIMIT 1];
        Test.startTest();
        Opportunity objOpportunity = ASF_TestDataFactory.createOpportunityRecords(acc.Id, asset.Id);
        Test.stopTest();
        
        List<Opportunity> oppList = [Select Id, Name ,CloseDate, StageName, Policy__r.AccountId from Opportunity WHERE Id =: objOpportunity.Id];
        
        Assert.areEqual(date.today()+60, oppList[0].CloseDate, 'Expected date.today()+60 , Not found');
        Assert.areEqual('Open', oppList[0].StageName, 'Expected StageName Open , Not found');
        Assert.areEqual(asset.Id, oppList[0].Policy__c, 'Account Id mismatch');
    }
    
    @isTest
    private static void test_AfterTest(){
        Asset asst = [SELECT Id, AccountId FROM Asset LIMIT 1];
        asst.ABHI_Policy_Id__c = '12-121-21-21'; 
        asst.Assignee_Name__c = 'Ubona int';
        asst.IntermediaryName__c = 'Inter name';
        asst.Channel__c = 'Channel';
        asst.Next_Premium_Date__c = System.Today();
        asst.Maturity_Date__c = System.Today() + 365;
        asst.Name = 'xyz';
        asst.ProductName__c = 'Test Product';
        asst.GrossPremium__c = '12456';
        asst.Proposal_Type__c = 'STP';
        update asst;
        
        Test.startTest();
        ASF_TestDataFactory.createOpportunityRecords(asst.AccountId, asst.Id);
        Test.stopTest();
        System.assertEquals(1, RNWL_UbonaIntegrationController.publishResults.size());
        System.assertEquals(true, RNWL_UbonaIntegrationController.publishResults[0].success);
    }
    
    @isTest
    private static void test_UpdateTest(){  
        List<Opportunity> lstOpportunity = new List<Opportunity>();
        Account acc = [Select Id FROM Account WHERE Name = 'test before opp' LIMIT 1]; 
        
        Opportunity objOpp1 = ASF_TestDataFactory.createOpportunityRecords('Dialer Status Successful Opp', acc.Id);
        
        objOpp1.Schedule_Request_Response__c = '{"responseCode":0,"responseDesc":"Call request deleted successfully"}'; 
        
        Opportunity objOpp2 = ASF_TestDataFactory.createOpportunityRecords('Dialer Status Failed Opp', acc.Id);
        
        objOpp2.Schedule_Request_Response__c = '{"responseCode":1,"responseDesc":"Call request deleted successfully"}'; 
        
        Opportunity objOpp3 = ASF_TestDataFactory.createOpportunityRecords('Dialer Status Failed Opp', acc.Id);
        
        objOpp3.Schedule_Request_Response__c = 'a'; 
        
        Opportunity objOpp4 = ASF_TestDataFactory.createOpportunityRecords('Dialer Cancel Status Successful Opp', acc.Id);
        
        objOpp4.Cancel_Call_Response__c = '{"responseCode":0,"responseDesc":"Call request deleted successfully"}'; 
        
        Opportunity objOpp5 = ASF_TestDataFactory.createOpportunityRecords('Dialer Cancel Status Failed Opp', acc.Id);
        
        objOpp5.Cancel_Call_Response__c = '{"responseCode":1,"responseDesc":"Call  request deleted successfully"}'; 
        
        Opportunity objOpp6 = ASF_TestDataFactory.createOpportunityRecords('Dialer Cancel Status Failed Opp', acc.Id);
        
        objOpp6.Cancel_Call_Response__c = 'a'; 
        
        Opportunity objOpp7 = ASF_TestDataFactory.createOpportunityRecords('Dialer Cancel Status submit Opp', acc.Id);
        
        objOpp7.StageName = 'Closed Won';
        
        
        lstOpportunity.add(objOpp1);
        lstOpportunity.add(objOpp2);
        lstOpportunity.add(objOpp3);
        lstOpportunity.add(objOpp4);
        lstOpportunity.add(objOpp5);
        lstOpportunity.add(objOpp6);
        lstOpportunity.add(objOpp7);
        
        Set<Id> setOppId = new Set<Id>();
        setOppId.add(objOpp1.Id);
        setOppId.add(objOpp2.Id);
        setOppId.add(objOpp3.Id);
        setOppId.add(objOpp4.Id);
        setOppId.add(objOpp5.Id);
        setOppId.add(objOpp6.Id);
        setOppId.add(objOpp7.Id);
        
        Test.startTest();
        update lstOpportunity;  
        Test.stopTest();
        
        List<Opportunity> lstUpdateOpportunity = [SELECT Id, Name, Dialer_Status__c FROM Opportunity WHERE Id =: setOppId ]; 
        
        for(Opportunity objOpportunity : lstUpdateOpportunity){
            
            if(objOpportunity.Name == 'Dialer Status Successful Opp' )
                System.assertEquals(objOpportunity.Dialer_Status__c , 'Schedule Call Request Successful');
            
            if(objOpportunity.Name == 'Dialer Status Failed Opp' )
                System.assertEquals(objOpportunity.Dialer_Status__c , 'Schedule Call Request Failed');
            
            if(objOpportunity.Name == 'Dialer Cancel Status Successful Opp' )
                System.assertEquals(objOpportunity.Dialer_Status__c , 'Cancel Call Request Successful');
            
            if(objOpportunity.Name == 'Dialer Cancel Status Failed Opp' )
                System.assertEquals(objOpportunity.Dialer_Status__c , 'Cancel Call Request Failed'); 
            
            if(objOpportunity.Name == 'Dialer Cancel Status submit Opp' )
                System.assertEquals(objOpportunity.Dialer_Status__c , 'Cancel Call Request Submitted'); 
            
        } 
    }
}