@isTest public class RNWL_EmailMessageTriggerHandlerTest { 
    
    @TestSetup
    public static void setup(){
        Account acc=  new Account(name='Test Account' , Client_Code__c = 'PT87552250' , Chronic_Disease__c = 'test', PED__c = 'test');
        insert acc;
        
        Asset objAsset =  new Asset(name='21-24-0000759-02', ABHI_Policy_Id__c='21-24-0000759-02', LAN__c = '21-24-0000759-02');
        insert objAsset;
        
        Opportunity oppRec = new Opportunity();
        oppRec.Name = 'Opp1' ;
        oppRec.Policy__c = objAsset.Id;
        oppRec.AccountId = acc.Id;
        oppRec.CloseDate = Date.today();
        oppRec.StageName = 'In Progress';
        oppRec.Policy_Number__c = '21-24-0000759-02';
        
        Opportunity oppRec1 = new Opportunity();
        oppRec1.Name = 'Opp2' ;
        oppRec1.Policy__c = objAsset.Id;
        oppRec1.AccountId = acc.Id;
        oppRec1.CloseDate = Date.today();
        oppRec1.StageName = 'In Progress';
        oppRec1.Policy_Number__c = '21-24-0000759-02134';
        
        List<Opportunity> lstOpp = new List<Opportunity>();
        lstOpp.add(oppRec);
        lstOpp.add(oppRec1);
        
        insert lstOpp;
        
        EmailMessage msg1 = new EmailMessage( RelatedToId = lstOpp[0].Id, Status = '3',Subject = 'Test Email'); 
        insert msg1;
        
        
    }
    
    
    @isTest static void testValidateEmailCount() {
        
        Opportunity obj = [SELECT Id FROM Opportunity WHERE Name = 'Opp1'];
        Test.startTest(); 
        
        try { 
            EmailMessage msg = new EmailMessage( RelatedToId = obj.Id, Status = '3',Subject = 'Test Email ' ); 
            insert msg;   
            System.assert(false, 'Expected a validation error, but did not receive one.'); 
        } catch (DmlException e)
        { 
            System.assert(e.getMessage().contains('You have exceeded the daily limit for sending this notification') || e.getMessage().contains('You have exceeded the overall limit for sending this notification'), 'Unexpected error message: ' + e.getMessage());
        } 
        Test.stopTest(); 
    }
    
    @IsTest
    static void testValidateEmailCountBulk(){   
        Opportunity obj = [SELECT Id FROM Opportunity WHERE Name = 'Opp1'];
        
        Test.startTest(); 
        
        try { 
                      
            List<EmailMessage> emailMessages = new List<EmailMessage>(); 
            for (Integer i = 0; i < 2; i++) { 
                EmailMessage msg = new EmailMessage( RelatedToId = obj.Id, Status = '3',Subject = 'Test Email ' + i ); 
                emailMessages.add(msg);
            } 
            
            insert emailMessages;   
            System.assert(false, 'Expected a validation error, but did not receive one.'); 
        } catch (DmlException e)
        { 
            System.assert(e.getMessage().contains('You have exceeded the daily limit for sending this notification') || e.getMessage().contains('You have exceeded the overall limit for sending this notification'), 'Unexpected error message: ' + e.getMessage());
        } 
        Test.stopTest(); 
    }
}