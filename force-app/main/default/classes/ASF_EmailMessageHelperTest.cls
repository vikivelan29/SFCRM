@isTest
public class ASF_EmailMessageHelperTest {
    
    @isTest
    public static void validateIfGoingFromAuthorizedAddress(){
        Case c = new Case();
        c.Subject = 'Test';
        c.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Interaction').getRecordTypeId();
        insert c;
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {'test@test.com.invalid'}; 
        mail.setToAddresses(toAddresses);
        mail.setWhatId(c.Id);
        mail.setSubject('Test Email Relay');
        mail.setBccSender(false);
        mail.setUseSignature(false);
        mail.setPlainTextBody('This is test email with new name..');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
    } 
    
}