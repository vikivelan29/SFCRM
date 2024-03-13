@isTest
public class ASF_Email2CaseHandler_Test {
    
    @isTest
    public static void updateMessageIdentifierOnCaseToAddressTest(){
        Case newCase = new Case();
        newCase.Subject = 'Test Case Creation';
        newCase.CCC_External_Id__c ='' ;
        newCase.Source__c =  'Email';
        newCase.Stage__c = 'Email';
        newCase.SuppliedEmail = 'abcl.abfl@gmail.com';
        newCase.Business_Unit__c  = 'ABFL'; 
        insert newCase; 
        if(newCase.Id != null){
            List<EmailMessage> messages = new List<EmailMessage>();
            
            EmailMessage eMsg = new EmailMessage();
            eMsg.ParentId = newCase.Id;
            eMsg.ToAddress = 'abfl.grievancehead@adityabirlacapital.com';
            eMsg.FromAddress = 'abfl.crmuat01@adityabirlacapital.com';
            eMsg.CCAddress = 'abfl.instics@adityabirlacapital.com';
            eMsg.BCCAddress = 'test@test.com';
            eMsg.MessageIdentifier = 'ABC';
            eMsg.Incoming = true;
            insert eMsg;
        }
        EmailMessage msg = [SELECT ID,Winning_Email__c FROM EmailMessage WHERE ParentId =: newCase.Id AND Incoming = true LIMIT 1];
        System.AssertEquals(msg.Winning_Email__c,'abfl.grievancehead@adityabirlacapital.com','Prioritisation Tested Successfully.');
    }
    
    @isTest
    public static void updateMessageIdentifierOnCaseCcAddressTest(){
        Case newCase = new Case();
        newCase.Subject = 'Test Case Creation';
        newCase.CCC_External_Id__c ='' ;
        newCase.Source__c =  'Email';
        newCase.Stage__c = 'Email';
        newCase.SuppliedEmail = 'abcl.abfl@gmail.com';
        newCase.Business_Unit__c  = 'ABFL'; 
        insert newCase; 
        if(newCase.Id != null){
            List<EmailMessage> messages = new List<EmailMessage>();
            
            EmailMessage eMsg = new EmailMessage();
            eMsg.ParentId = newCase.Id;
            eMsg.ToAddress = 'abfl.instics@adityabirlacapital.com';
            eMsg.FromAddress = 'abfl.crmuat01@adityabirlacapital.com';
            eMsg.CCAddress = 'abfl.grievancehead@adityabirlacapital.com';
            eMsg.BCCAddress = 'test@test.com';
            eMsg.MessageIdentifier = 'ABC';
            eMsg.Incoming = true;
            insert eMsg;
        }
        EmailMessage msg = [SELECT ID,Winning_Email__c FROM EmailMessage WHERE ParentId =: newCase.Id AND Incoming = true LIMIT 1];
        System.AssertEquals(msg.Winning_Email__c,'abfl.grievancehead@adityabirlacapital.com','Prioritisation Tested Successfully.');
    }
    
}