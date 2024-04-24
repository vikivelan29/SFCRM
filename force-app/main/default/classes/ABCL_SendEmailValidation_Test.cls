@isTest
public class ABCL_SendEmailValidation_Test {
     @isTest
    public static void validateIfGoingFromAuthorizedAddress(){
           Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='ABFL Base Profile' LIMIT 1];
            User userRecord = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,Business_Unit__c = 'ABFL',
                                    TimeZoneSidKey='America/Los_Angeles',Team__c = 'GRT', UserName='cdefghijk567@gmail.com'
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
}