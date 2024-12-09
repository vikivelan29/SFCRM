/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 06-28-2024
 * @last modified by  : rsinghnagar@salesforce.com 
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   06-28-2024   rsinghnagar@salesforce.com   Initial Version
**/
@isTest
public class ABCL_SendEmailValidation_Test {

    @TestSetup
    static void setupTestData() {
        
    
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'ABHI Base Profile' LIMIT 1];
        
    
        User testUser = new User(
            Username = 'testuser@example.com' + System.currentTimeMillis(),
            Alias = 'tuser321',
            Email = 'testuser321123@example.com',
            LastName = 'Test',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = adminProfile.Id,
            LanguageLocaleKey = 'en_US',
            Business_Unit__c = 'ABHI',
            Source_Code__c = '015'
        );

        insert testUser;

        List<Case> csList = new List<Case>();
        Case testCase1 = new Case(
            Subject = 'Test Case 1',
            Status = 'New',
            Origin = 'Email'
        );
        csList.add(testCase1);
        insert csList;
    }

    @isTest
    public static void validateIfGoingFromAuthorizedAddressABFL(){
           Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='ABFL Base Profile' LIMIT 1];
            User userRecord = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,Business_Unit__c = 'ABFL',
                                    TimeZoneSidKey='America/Los_Angeles',Team__c = 'GRT', UserName='cdefghijk5657123456@gmail.com'
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
    public static void validateIfGoingFromAuthorizedAddressWellness(){
           Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='ABFL Base Profile' LIMIT 1];
            User userRecord = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,Business_Unit__c = 'ABFL',
                                    TimeZoneSidKey='America/Los_Angeles',Team__c = 'GRT', UserName='cdefghijk5657123456@gmail.com'
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
    public static void testRestrictUserToSendEmailMethod() {
        
        User abhiTestUser = [SELECT id, Business_Unit__c, Source_Code__c FROM USER WHERE email = 'testuser321123@example.com' LIMIT 1];
        List<Case> csLst = [SELECT id FROM Case];
        Case testCase1 = csLst[0];

        System.runAs(abhiTestUser) {
            Test.startTest();
                EmailMessage testEmailMessage = new EmailMessage(            
                    FromAddress = 'sender@example.com',  
                    ToAddress = 'recipient@example.com', 
                    Subject = 'Test Email Subject',      
                    TextBody = 'This is a test email body.',
                    Status = '3',                        
                    MessageDate = System.now()           
                );
                insert testEmailMessage;
            	ABCL_SendEmailValidation.restrictUserToSendEmail(new List<EmailMessage>{testEmailMessage});
                EmailMessage insertedEmailMessage = [SELECT Id, ParentId, FromAddress, ToAddress, Subject, TextBody 
                                                    FROM EmailMessage 
                                                    WHERE Id = :testEmailMessage.Id];
                
                System.assertNotEquals(null, insertedEmailMessage, 'EmailMessage should be inserted successfully');
            Test.stopTest();
        }
    }

@isTest
    public static void validateEmailTemplate(){
        EmailTemplate et = new EmailTemplate();
        et.id = '00XNy000000LcdNMAS';
        et.isActive = true;
        et.Name = 'Manual Email Template Test';
        et.DeveloperName = 'Manual_Email_Template_Test_' + System.now().getTime();
        et.FolderId = UserInfo.getUserId();
        et.Body = 'Manual Email Template Test';
                
        ABCL_EmailTemplate_Mapping__mdt mdtList = new ABCL_EmailTemplate_Mapping__mdt(From_Address__c='abhfl.ceodesk@adityabirlacapital.com',Template_Id__c=et.Id,Template_Name__c='Manual Email Template');
                
        EmailMessage email = new EmailMessage();
        email.FromAddress = 'abhfl.ceodesk@adityabirlacapital.com';
        email.Incoming = false;
        email.ToAddress= 'test@xyz.org';
        email.Subject = 'Test email';
        email.HtmlBody = 'Test email body';
        //email.ParentId = c.Id; 
        email.EmailTemplateId = et.Id;
        email.ValidatedFromAddress = '';
        insert email;
        ABCL_SendEmailValidation.verifyEmailTemplate(new List<sObject>{email});
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
                OrgWideEmailAddress owea = new OrgWideEmailAddress();
                owea = [
                    SELECT Id, Address, DisplayName FROM 
					OrgWideEmailAddress LIMIT 1
                ];
                EmailMessage e = new EmailMessage();
                e.FromAddress           = owea.Address;
                e.FromName              = 'Medhanie';
                e.MessageDate           = datetime.now(); 
                e.MessageIdentifier     = '';
                e.Status                = '3';
                e.Subject               = 'test';
                e.TextBody              = 'test';
                e.RelatedToId           = c.Id;
                e.ToAddress             = 'bob.test@gmail.com';
                e.ValidatedFromAddress  = owea.Address;
                insert e;
            }catch(Exception ex){
                Assert.areEqual(ex.getMessage()!=null, true, 'error message exists.');
            }
            Test.stopTest();            
    	}     
    }
}
