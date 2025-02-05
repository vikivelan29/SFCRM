/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 05-13-2024
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
            eMsg.ToAddress = 'abfl.grievancehead@adityabirlacapital.com';
            eMsg.FromAddress = 'abfl.crmuat01@adityabirlacapital.com';
            eMsg.CCAddress = 'abfl.instics@adityabirlacapital.com';
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
        EmailMessage eMsg = new EmailMessage();
        List<ASF_PriorityEmailAddressesByBU__mdt> priorityEmailMdt = new List<ASF_PriorityEmailAddressesByBU__mdt> ();
        ASF_PriorityEmailAddressesByBU__mdt priorityMeta = new ASF_PriorityEmailAddressesByBU__mdt(Business_Unit__c = 'ABFL',
                                                           Email2CaseAddress__c = 'abfl.grievancehead@adityabirlacapital.com',
                                                            Case_Business_Unit__c = 'ABFL');
        priorityEmailMdt.add(priorityMeta);
        
        if(newCase.Id != null){
            eMsg.ParentId = newCase.Id;
            eMsg.ToAddress = 'abfl.instics@adityabirlacapital.com';
            eMsg.FromAddress = 'abfl.crmuat01@adityabirlacapital.com';
            eMsg.CCAddress = 'abfl.grievancehead@adityabirlacapital.com';
            eMsg.BCCAddress = 'test@test.com';
            eMsg.MessageIdentifier = 'ABC';
            eMsg.Incoming = true;
            eMsg.Headers = 'Reply-To: <test-header-id@example.com>';
            insert eMsg;
        }
        Test.startTest();
        	ASF_Email2CaseHandler.findRecipientAddressesBusUnit(eMsg, priorityEmailMdt);
        Test.stopTest();
        // EmailMessage msg = [SELECT ID,Winning_Email__c FROM EmailMessage WHERE ParentId =: newCase.Id AND Incoming = true LIMIT 1];
        //System.AssertEquals(msg.Winning_Email__c,'abfl.grievancehead@adityabirlacapital.com','Prioritisation Tested Successfully.');
    }
    
}