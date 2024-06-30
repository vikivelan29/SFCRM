/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 06-30-2024
 * @last modified by  : rsinghnagar@salesforce.com 
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   06-30-2024   rsinghnagar@salesforce.com   Initial Version
**/
@isTest
public class ABFL_E2C_CreationRulesTest {

    @isTest
    static void testCheckCreationRulesWithValidEmail() {
        Case newCase = new Case();
        newCase.Subject = 'Test Case Creation';
        newCase.CCC_External_Id__c ='' ;
        newCase.Source__c =  'Email';
        newCase.Stage__c = 'Email';
        newCase.SuppliedEmail = 'ABSLI.NodalOfficer@adityabirlacapital.com';
        newCase.Business_Unit__c  = 'ABSLI';
        newCase.origin  = 'ABSLI Email';
        insert newCase; 
        if(newCase.Id != null){
            
            EmailMessage eMsg = new EmailMessage();
            eMsg.ParentId = newCase.Id;
            eMsg.ToAddress = 'abcl.abfl@gmail.com';
            eMsg.FromAddress = 'ABSLI.NodalOfficer@adityabirlacapital.com';
            eMsg.CCAddress = 'abfl.instics@adityabirlacapital.com';
            eMsg.BCCAddress = 'test@test.com';
            eMsg.MessageIdentifier = 'ABC';
            eMsg.Incoming = true;
            insert eMsg;
        }
        EmailMessage msg = [SELECT ID,Winning_Email__c FROM EmailMessage WHERE ParentId =: newCase.Id AND Incoming = true LIMIT 1];
        System.AssertEquals(msg.Winning_Email__c,null,'E2C Tested Successfully.');
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
            eMsg.FromAddress = 'care.finance1@adityabirlacapital.com';
            eMsg.Subject = 'Case assignment CRM';
            eMsg.MessageIdentifier = 'ABC';
            eMsg.Incoming = true;
            insert eMsg;
        }
        EmailMessage msg = [SELECT ID,Subject FROM EmailMessage WHERE ParentId =: newCase.Id AND Incoming = true LIMIT 1];
        System.AssertEquals(msg.Subject,'Case assignment CRM','E2C Tested Successfully.');
    }
}