@isTest
public class ASF_Email2CaseHandler_Test {
    
    @isTest
    public static void updateMessageIdentifierOnCaseToAddressTest(){
        Case newCase = new Case();
        newCase.Subject = 'Test Case Creation';
        newCase.CCC_External_Id__c ='' ;
        newCase.Source__c =  'Email';
        newCase.Stage__c = 'Resolved';
        newCase.Status = 'UnResolved';
        newCase.SuppliedEmail = 'abcl.abfl@gmail.com';
        newCase.Business_Unit__c  = 'ABFL'; 
        newCase.Technical_Source__c = 'Email';
        newCase.Origin = 'ABFL Email';
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
            eMsg.Send_to_EBOT__c = true;
            eMsg.Headers ='In-Reply-To:';
            insert eMsg;
        
        	EmailMessage eMsgOutgoing = new EmailMessage();
            eMsgOutgoing.ParentId = newCase.Id;
            eMsgOutgoing.ToAddress = 'abfl.grievancehead@adityabirlacapital.com';
            eMsgOutgoing.FromAddress = 'abfl.crmuat01@adityabirlacapital.com';
            eMsgOutgoing.CCAddress = 'abfl.instics@adityabirlacapital.com';
            eMsgOutgoing.BCCAddress = 'test@test.com';
            eMsgOutgoing.MessageIdentifier = 'ABC';
            eMsgOutgoing.Incoming = false;
            eMsgOutgoing.Send_to_EBOT__c = true;
            eMsgOutgoing.Headers ='In-Reply-To:';
            insert eMsgOutgoing;
		}
        //EmailMessage msg = [SELECT ID,Winning_Email__c FROM EmailMessage WHERE ParentId =: newCase.Id AND Incoming = true LIMIT 1];
        //System.AssertEquals(msg.Winning_Email__c,'abfl.grievancehead@adityabirlacapital.com','Prioritisation Tested Successfully.');
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
        newCase.Technical_Source__c = 'Email';
        newCase.Origin = 'ABFL Email';
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
        //System.AssertEquals(msg.Winning_Email__c,'abfl.grievancehead@adityabirlacapital.com','Prioritisation Tested Successfully.');
    }
    
}