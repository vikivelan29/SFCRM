/******************************************************  
* Author           - Sutanu Bose
* Date             - 11-04-2024
* Description      - Test class for ABML_SendCaseCreationEmail
********************************************************
*/
@isTest
public class ABML_SendCaseCreationEmail_Test {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name = 'System Administrator' LIMIT 1];    
    
    @testSetup
    static void setup() {
        User objUser = new User(Alias = 'user' , Email = 'standarduser@testorg.com', 
                                EmailEncodingKey = 'UTF-8', LastName = 'Test', LanguageLocaleKey = 'en_US', 
                                LocaleSidKey = 'en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
                                TimeZoneSidKey = 'America/Los_Angeles', Username = 'testUserAbml@gmail.com',
                                Business_Unit__c = 'ABML');
        insert objUser;
        System.runAs(objUser) {
            
            
            Case testCase = new Case(
                
                Origin = 'ABML Email',
                Status = 'New',
                CCC_External_Id__c ='ISCABFLABWMCOFMQR1',
                Subject = 'Test Case',
                SuppliedEmail = 'test@example.com',
                Business_unit__c = 'ABML',
                Overall_Case_Closure_SLA__c = Datetime.newInstance(2024, 11, 07)
            );
            insert testCase;
            
            Contact varNewCon = New Contact();
            varNewCon.LastName = 'Test';
            insert varNewCon;
            
            EmailMessage objEmailMessage = new EmailMessage();            
            objEmailMessage.ParentId = testCase.Id;
            objEmailMessage.Incoming = true;
            objEmailMessage.Subject = 'Test Email 1' ;
            objEmailMessage.ToAddress = 'test@example.com';
            objEmailMessage.FromAddress = 'customer@example.com';
            objEmailMessage.Winning_Email__c = 'abml.test@adityabirlacapital.com';
            objEmailMessage.TextBody = 'Test email';
            objEmailMessage.Headers = 'In-Reply-To:';
            insert objEmailMessage;
            
            EmailMessage testEmailMessage2 = new EmailMessage(
                ParentId = testCase.Id,
                Incoming = true,
                Subject = 'Test Email 2',
                ToAddress = 'test@example.com',
                FromAddress = 'customer@example.com',
                Winning_Email__c = 'abml.test@adityabirlacapital.com',
                TextBody = 'Test email 2'
            );
            insert testEmailMessage2;
            
        }
    }
    
    @isTest
    static void testSendEmailOnABMLCaseCreation() {
        
        User objUser = [SELECT Id, Name FROM User WHERE Business_Unit__c = 'ABML' and LastName = 'Test' LIMIT 1];
        System.runAs(objUser){
            
            List<EmailMessage> emailMessageList = [SELECT Id, ParentId, Incoming, Headers, ReplyToEmailMessageId, Winning_Email__c FROM EmailMessage];
            
            List<Case> updatedCases = [SELECT Id, Origin FROM Case WHERE Id IN (SELECT ParentId FROM EmailMessage)];
            System.assertEquals(1, updatedCases.size(),'Case Update Success');
            
            List<EmailMessage> emailMessages = [SELECT Id, ParentId FROM EmailMessage WHERE ParentId IN :updatedCases];           
            System.assertEquals(2, emailMessages.size(),'Email Message Success');
        }
    }
    
}