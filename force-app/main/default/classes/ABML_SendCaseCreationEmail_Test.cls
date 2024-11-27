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
            
            List<EmailMessage> listOfEmailMessage = new List<EmailMessage>();  
            
            for(Integer emailMessageCount = 0; emailMessageCount < 3; emailMessageCount++){
                                
                EmailMessage objEmailMessage = new EmailMessage();            
                objEmailMessage.ParentId = testCase.Id;
                objEmailMessage.Incoming = true;
                objEmailMessage.Subject = 'Test Email ' + emailMessageCount;
                objEmailMessage.ToAddress = 'test@example.com';
                objEmailMessage.FromAddress = 'customer@example.com';
                objEmailMessage.Winning_Email__c = 'abml.test@adityabirlacapital.com';
                objEmailMessage.TextBody = 'Test email';
                listOfEmailMessage.add(objEmailMessage);           
            }        
            
            listOfEmailMessage[0].Headers = 'In-Reply-To:';
            
            insert listOfEmailMessage;
            

            
        }
    }
    
    @isTest
    static void testSendEmailOnABMLCaseCreation() {
        
        User objUser = [SELECT Id, Name FROM User WHERE Business_Unit__c = 'ABML' and LastName = 'Test' LIMIT 1];
        System.runAs(objUser){
            
            List<EmailMessage> emailMessageList = [SELECT Id, ParentId, Incoming, Headers, ReplyToEmailMessageId, Winning_Email__c FROM EmailMessage];
            Test.startTest();
            ABML_SendCaseCreationEmail.sendEmailOnABMLCaseCreation(emailMessageList);
            Test.stopTest();
            
            List<Case> updatedCases = [SELECT Id, Origin FROM Case WHERE Id IN (SELECT ParentId FROM EmailMessage)];
            System.assertEquals(1, updatedCases.size(),'Case Update Success');
            
            List<EmailMessage> emailMessages = [SELECT Id, ParentId FROM EmailMessage WHERE ParentId IN :updatedCases];
            System.assertEquals(3, emailMessages.size(),'Email Message Success');
        }
    }
    
}