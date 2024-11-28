@isTest
public class ASF_EmailMessageHelperTest {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    @TestSetup
    public static void setup() {
        insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                          Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                          Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
        Case c = new Case();
        c.Subject = 'Test';
        c.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Interaction').getRecordTypeId();
        insert c;

        ASF_TestDataFactory.createCaseCategoryConfig();
        List<Case> caseL = ASF_TestDataFactory.createCaseRecords(1);
    }

    @isTest
    public static void validateIfGoingFromAuthorizedAddress(){
        Case c = [select id from case where recordtypeid = :ASF_Constants.RT_INTERACTION limit 1];
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
    public static void checkAndReopenClosedCasesTest(){
        
        Case c = [select id from case where recordtypeid = :ASF_Constants.RT_FRAMEWORK limit 1];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {'test@test.com.invalid'}; 
        mail.setToAddresses(toAddresses);
        mail.setWhatId(c.Id);
        mail.setSubject('Test Email Relay');
        mail.setBccSender(false);
        mail.setUseSignature(false);
        mail.setPlainTextBody('This is test email with new name..');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 

        c.Stage__c = 'Resolved';
        c.Status = 'Closed';
        c.RecordTypeId = ASF_Constants.RT_FRAMEWORK;
        c.Reopen_Days__c = 1;
        update c;
        
        Test.startTest();
        EmailMessage oldMail = [Select MessageIdentifier from EmailMessage LIMIT 1];
        Messaging.SingleEmailMessage mail2 = new Messaging.SingleEmailMessage();
        mail2.setToAddresses(toAddresses);
        mail2.setWhatId(c.Id);
        mail2.setSubject('Test Email Relay');
        mail2.setBccSender(false);
        mail2.setUseSignature(false);
        mail2.setPlainTextBody('This is test email with new name..');
        mail2.setInReplyTo(oldMail.MessageIdentifier);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail2 });
        test.stopTest();
    } 

    @isTest
    public static void checkAndReopenClosedCasesTest2(){
        
        Case c = [select id from case where recordtypeid = :ASF_Constants.RT_FRAMEWORK limit 1];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {'test@test.com.invalid'}; 
        mail.setToAddresses(toAddresses);
        mail.setWhatId(c.Id);
        mail.setSubject('Test Email Relay');
        mail.setBccSender(false);
        mail.setUseSignature(false);
        mail.setPlainTextBody('This is test email with new name..');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 

        c.Stage__c = 'Resolved';
        c.Status = 'Closed';
        c.RecordTypeId = ASF_Constants.RT_FRAMEWORK;
        c.Reopen_Days__c = -1;
        update c;
        
        Test.startTest();
        EmailMessage oldMail = [Select MessageIdentifier from EmailMessage LIMIT 1];
        Messaging.SingleEmailMessage mail2 = new Messaging.SingleEmailMessage();
        mail2.setToAddresses(toAddresses);
        mail2.setWhatId(c.Id);
        mail2.setSubject('Test Email Relay');
        mail2.setBccSender(false);
        mail2.setUseSignature(false);
        mail2.setPlainTextBody('This is test email with new name..');
        mail2.setInReplyTo(oldMail.MessageIdentifier);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail2 });
        test.stopTest();
    } 

    @isTest
    public static void checkAndReopenClosedCasesTest3(){
        
        Case c = [select id from case where recordtypeid = :ASF_Constants.RT_FRAMEWORK limit 1];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {'test@test.com.invalid'}; 
        mail.setToAddresses(toAddresses);
        mail.setWhatId(c.Id);
        mail.setSubject('Test Email Relay');
        mail.setBccSender(false);
        mail.setUseSignature(false);
        mail.setPlainTextBody('This is test email with new name..');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 

        c.Stage__c = 'Resolved';
        c.Status = 'Closed';
        c.RecordTypeId = ASF_Constants.RT_FRAMEWORK;
        c.Reopen_Days__c = null;
        update c;
        
        Test.startTest();
        EmailMessage oldMail = [Select MessageIdentifier from EmailMessage LIMIT 1];
        Messaging.SingleEmailMessage mail2 = new Messaging.SingleEmailMessage();
        mail2.setToAddresses(toAddresses);
        mail2.setWhatId(c.Id);
        mail2.setSubject('Test Email Relay');
        mail2.setBccSender(false);
        mail2.setUseSignature(false);
        mail2.setPlainTextBody('This is test email with new name..');
        mail2.setInReplyTo(oldMail.MessageIdentifier);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail2 });
        test.stopTest();
    } 
}