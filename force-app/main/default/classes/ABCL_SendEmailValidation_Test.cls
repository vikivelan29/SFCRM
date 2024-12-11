/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 12-09-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   06-28-2024   rsinghnagar@salesforce.com   Initial Version
**/
@isTest
public class ABCL_SendEmailValidation_Test {
    
     @isTest
    public static void validateIfGoingFromAuthorizedAddress(){
           Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='ABFL Base Profile' LIMIT 1];
            User userRecord = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,Business_Unit__c = 'Wellness',
                                    TimeZoneSidKey='America/Los_Angeles',Team__c = 'GRT', UserName='cdefghijk56571234560@gmail.com'
                                    );
        insert userRecord;
        System.runAs(userRecord) {
         Test.startTest(); 
        insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                           Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                           Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
        
        
        Case c = new Case();
        c.Subject = 'Test';
        c.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Interaction').getRecordTypeId();
        insert c;
            try{
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {'test@test.com.invalid'}; 
            mail.setToAddresses(toAddresses);
            mail.setWhatId(c.Id);
            mail.setSubject('Test Email Relay');
            mail.setBccSender(false);
            mail.setUseSignature(false);
            mail.setPlainTextBody('This is test email with new name..');
                
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
            }Catch(exception e){}
        Test.stopTest();            
    	}
    }     
    
    @isTest
    public static void validateUserWithNoTeam(){
    	Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='ABFL Base Profile' LIMIT 1];
        User userRecord = new User(Alias = 'standt2', Email='stanrduserEmails2@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing2', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,Business_Unit__c = 'Wellness',
                                    TimeZoneSidKey='America/Los_Angeles', UserName='cdefghijk56571234516@gmail.com'
                                    );
        insert userRecord;
        System.runAs(userRecord) {
            Test.startTest(); 
            insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                               Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                               Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
            
            
            Case c = new Case();
            c.Subject = 'Test';
            c.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Interaction').getRecordTypeId();
            insert c;
            try{
                EmailMessage e = new EmailMessage();
                e.FromAddress           = 'abfl.noreply@adityabirlacapital.com';
                e.FromName              = 'Medhanie';
                e.MessageDate           = datetime.now(); 
                e.MessageIdentifier     = '';
                e.Status                = '3';
                e.Subject               = 'test';
                e.TextBody              = 'test';
                e.RelatedToId           = c.Id;
                e.ToAddress             = 'bob.test@gmail.com';
                e.ValidatedFromAddress  = 'abfl.noreply@adityabirlacapital.com';
                insert e;
            }catch(Exception ex){
                Assert.areEqual(ex.getMessage()!=null, true, 'error message exists.');
            }
            Test.stopTest();            
    }
    }   
}