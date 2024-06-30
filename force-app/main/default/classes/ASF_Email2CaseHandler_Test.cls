/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 06-30-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   05-13-2024   rsinghnagar@salesforce.com   Initial Version
**/
@isTest
public class ASF_Email2CaseHandler_Test {
    
    /**
    * @description 
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    **/
    @isTest
    public static void updateMessageIdentifierOnCaseToAddressTest(){
        Case newCase = new Case();
        newCase.Subject = 'Test Case Creation';
        newCase.CCC_External_Id__c ='' ;
        newCase.Source__c =  'Email';
        newCase.Stage__c = 'Email';
        newCase.SuppliedEmail = 'abcl.abfl@gmail.com';
        newCase.Business_Unit__c  = 'ABFL'; 
        insert newCase; 
        if(newCase.Id != null){
            EmailMessage eMsg = new EmailMessage();
            eMsg.ParentId = newCase.Id;
            eMsg.ToAddress = 'abhfl.ceodesk@adityabirlacapital.com';
            eMsg.FromAddress = 'abhfl.ceodesk@adityabirlacapital.com';
            eMsg.CCAddress = 'abhfl.ceodesk@adityabirlacapital.com';
            eMsg.BCCAddress = 'test@test.com';
            eMsg.MessageIdentifier = 'ABC';
            eMsg.Incoming = true;
            insert eMsg;
        }
        // EmailMessage msg = [SELECT ID,Winning_Email__c FROM EmailMessage WHERE ParentId =: newCase.Id AND Incoming = true LIMIT 1];
        //System.AssertEquals(msg.Winning_Email__c,'abfl.grievancehead@adityabirlacapital.com','Prioritisation Tested Successfully.');
    }
    
    @isTest
    public static void updateMessageIdentifierOnCaseCcAddressTest(){
        Case newCase = new Case();
        newCase.Subject = 'Test Case Creation';
        newCase.CCC_External_Id__c ='' ;
        newCase.Source__c =  'Email';
        newCase.Stage__c = 'Email';
        newCase.SuppliedEmail = 'abcl.abfl@gmail.com';
        newCase.Business_Unit__c  = 'ABFL'; 
        insert newCase; 
        if(newCase.Id != null){
            EmailMessage eMsg = new EmailMessage();
            eMsg.ParentId = newCase.Id;
            eMsg.ToAddress = 'abhfl.ceodesk@adityabirlacapital.com';
            eMsg.FromAddress = 'abhfl.ceodesk@adityabirlacapital.com';
            eMsg.CCAddress = 'abhfl.ceodesk@adityabirlacapital.com';
            eMsg.BCCAddress = 'test@test.com';
            eMsg.MessageIdentifier = 'ABC';
            eMsg.Incoming = true;
            insert eMsg;
        }
        // EmailMessage msg = [SELECT ID,Winning_Email__c FROM EmailMessage WHERE ParentId =: newCase.Id AND Incoming = true LIMIT 1];
        //System.AssertEquals(msg.Winning_Email__c,'abfl.grievancehead@adityabirlacapital.com','Prioritisation Tested Successfully.');
    }
    
}
