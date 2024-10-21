/*********************************************************
 *Class          :   ABSLAMC_Email2CaseHandlerTest
 *Author         :   Udit Singhal
 *Created Date   :   19-09-2024
 *Last Modified  :   19-09-2024
 *@description   :   Test class for ABSLAMC_Email2CaseHandler
 *********************************************************/
@isTest
public class ABSLAMC_Email2CaseHandlerTest{
    @IsTest(seeAllData = false)
    static void handleAbslamcHwcEmails_Test(){
        Account accountRecord = new Account();
        accountRecord.Name = 'Test Account';
        accountRecord.Handle_With_Care_HWC__c = ABSLAMC_Constants.Y;
        accountRecord.HWC_Reason__c = ABSLAMC_Constants.ABSLAMC_HWC_REASON_SOCIAL_MEDIA;
        insert accountRecord;
        
        Case newCase = new Case();
        newCase.AccountId = accountRecord.Id;
        newCase.Subject = 'Test Case Creation';
        newCase.CCC_External_Id__c = '';
        newCase.Source__c = 'Email';
        newCase.Stage__c = 'Open';
        newCase.SuppliedEmail = 'a.balasubramanian@adityabirlacapital.com';
        newCase.Business_Unit__c = 'ABSLAMC';
        newCase.origin = 'ABSLAMC Email';
        insert newCase;
        
        if (newCase.Id != null){
            EmailMessage eMsg = new EmailMessage();
            eMsg.ParentId = newCase.Id;
            eMsg.ToAddress = 'a.balasubramanian@adityabirlacapital.com';
            eMsg.FromAddress = 'valid.finance@adityabirlacapital.com';
            eMsg.MessageIdentifier = 'ABC';
            eMsg.Incoming = true;
            insert eMsg;
        }
        
        List<Group> abslamcPhdQueue = [SELECT Id, DeveloperName
                                       FROM Group
                                       WHERE DeveloperName = :ABSLAMC_Constants.ABSLAMC_PHD_QUEUE AND Type = 'Queue'
                                       LIMIT 1];
        
        Case caseRecord = [SELECT Id, OwnerId
						   FROM Case
						   WHERE Id = :newCase.Id];
                               
        Assert.areEqual(abslamcPhdQueue[0].Id, caseRecord.OwnerId, 'Case not assigned to PHD queue');
    }

}