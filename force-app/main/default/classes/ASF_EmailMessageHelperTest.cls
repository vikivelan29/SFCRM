@isTest
public class ASF_EmailMessageHelperTest {
    
    @isTest
    public static void validateIfGoingFromAuthorizedAddress(){
        
        insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                           Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                           Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
        
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