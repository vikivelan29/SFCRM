@isTest
public class ABFL_E2C_CreationRulesTest {

    @isTest
    static void testCheckCreationRulesWithValidEmail() {
        Case newCase = new Case();
        newCase.Subject = 'Test Case Creation';
        newCase.CCC_External_Id__c ='' ;
        newCase.Source__c =  'Email';
        newCase.Stage__c = 'Email';
        newCase.SuppliedEmail = 'abcl.abfl@gmail.com';
        newCase.Business_Unit__c  = 'ABFL';
        newCase.origin  = 'ABFL Email';
        insert newCase; 
        if(newCase.Id != null){
            
            EmailMessage eMsg = new EmailMessage();
            eMsg.ParentId = newCase.Id;
            eMsg.ToAddress = 'abcl.abfl@gmail.com';
            eMsg.FromAddress = 'valid.finance@adityabirlacapital.com';
            eMsg.CCAddress = 'abfl.instics@adityabirlacapital.com';
            eMsg.BCCAddress = 'test@test.com';
            eMsg.MessageIdentifier = 'ABC';
            eMsg.Incoming = true;
            insert eMsg;
        }
        EmailMessage msg = [SELECT ID,Winning_Email__c FROM EmailMessage WHERE ParentId =: newCase.Id AND Incoming = true LIMIT 1];
        System.AssertEquals(msg.Winning_Email__c,'abfl.instics@adityabirlacapital.com','E2C Tested Successfully.');
    }
    @isTest
    static void testCheckCreationRulesWithValidSubject() {
        Case newCase = new Case();
        newCase.Subject = 'Test Case Creation';
        newCase.CCC_External_Id__c ='' ;
        newCase.Source__c =  'Email';
        newCase.Stage__c = 'Email';
        newCase.SuppliedEmail = 'abcl.abfl@gmail.com';
        newCase.Business_Unit__c  = 'ABFL';
        newCase.origin  = 'ABFL Email';
        insert newCase; 
        if(newCase.Id != null){
            
            EmailMessage eMsg = new EmailMessage();
            eMsg.ParentId = newCase.Id;
            eMsg.ToAddress = 'abcl.abfl@gmail.com';
            eMsg.FromAddress = 'valid.finance1@adityabirlacapital.com';
            eMsg.Subject = 'Check Subject';
            eMsg.MessageIdentifier = 'ABC';
            eMsg.Incoming = true;
            insert eMsg;
        }
        EmailMessage msg = [SELECT ID,Subject FROM EmailMessage WHERE ParentId =: newCase.Id AND Incoming = true LIMIT 1];
        System.AssertEquals(msg.Subject,'Check Subject','E2C Tested Successfully.');
    }
}