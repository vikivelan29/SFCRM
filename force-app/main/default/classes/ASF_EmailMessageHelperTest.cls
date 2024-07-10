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
    @isTest
    public static void validateIfGoingFromAuthorizedAddressReopen(){
        
        insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                           Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                           Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
        ASF_TestDataFactory.createC3IntegrationsAndCase();
        String cccId = [SELECT Id,CCC_External_Id__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c != null].CCC_External_Id__c;
        Case c = new Case();
        c.Subject = 'Test';
        c.RecordTypeId = ASF_Constants.RT_INTERACTION;
        insert c;
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {'test@test.com.invalid'}; 
        mail.setToAddresses(toAddresses);
        mail.setWhatId(c.Id);
        mail.setSubject('Test Email Relay');
        mail.setBccSender(false);
        mail.setUseSignature(false);
        mail.setPlainTextBody('This is test email with new name..');
        Messaging.SendEmailResult[] initialResults = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        
        EmailMessage initialEmailMessage = new EmailMessage(
            ParentId = c.Id,
            FromAddress = 'testuser@example.com',
            ToAddress = toAddresses[0],
            Subject = 'Test Email Relay',
            TextBody = 'This is test email with new name..',
            MessageIdentifier = '<initialMessageId@example.com>'
        );
        insert initialEmailMessage;
        
        c.RecordTypeId = ASF_Constants.RT_FRAMEWORK;
        c.CCC_External_Id__c = cccId;
        c.Status = ASF_Constants.ONCREATECLOSESTATUS;
        c.Stage__c = ASF_Constants.ONCREATECLOSESTAGE;
        c.Reopen_Days__c = 3;
        update c;
        
        Messaging.SingleEmailMessage mail2 = new Messaging.SingleEmailMessage();
        mail2.setToAddresses(toAddresses);
        mail2.setWhatId(c.Id);
        mail2.setSubject('Test Email Relay');
        mail2.setBccSender(false);
        mail2.setUseSignature(false);
        mail2.setPlainTextBody('This is test email with new name..');
        Map<String, String> headers = new Map<String, String>();
        mail2.setInReplyTo('<initialMessageId@example.com>');
        mail2.setReferences('<initialMessageId@example.com>');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail2 }); 
    } 
    
}