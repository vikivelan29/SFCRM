@isTest public class RNWL_EmailMessageTriggerHandlerTest { 
    
    @isTest static void testValidateEmailCount() {
        
        Account acc=  new Account(name='Test Account' , Client_Code__c = 'PT87552250' , Chronic_Disease__c = 'test', PED__c = 'test');
        insert acc;
        
        Asset objAsset =  new Asset(name='21-24-0000759-02', ABHI_Policy_Id__c='21-24-0000759-02', LAN__c = '21-24-0000759-02');
        insert objAsset;
        
        Opportunity oppRec = new Opportunity();
        oppRec.Name = 'Testabc' ;
        oppRec.Policy__c = objAsset.Id;
        oppRec.AccountId = acc.Id;
        oppRec.CloseDate = Date.today();
        oppRec.StageName = 'In Progress';
        oppRec.Policy_Number__c = '21-24-0000759-02';
        insert oppRec;
          
        List<EmailMessage> emailMessages = new List<EmailMessage>(); 
        for (Integer i = 0; i < 5; i++) { 
            EmailMessage msg = new EmailMessage( RelatedToId = oppRec.Id, Status = '3',Subject = 'Test Email ' + i ); 
            emailMessages.add(msg);
        } 
        insert emailMessages;  
        
        
        Test.startTest(); 
        
        try { 
            EmailMessage msg = new EmailMessage( RelatedToId = oppRec.Id, Status = '3',Subject = 'Test Email ' ); 
            insert msg;  
            System.assert(false, 'Expected a validation error, but did not receive one.'); 
        } catch (DmlException e)
        { 
            System.assert(e.getMessage().contains('You have exceeded the daily limit for sending this notification') || e.getMessage().contains('You have exceeded the overall limit for sending this notification'), 'Unexpected error message: ' + e.getMessage());
        } 
        Test.stopTest(); 
    }
}