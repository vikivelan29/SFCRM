@IsTest
public class ABHFL_EbotTriggerHelper_Test {
    
    @testSetup
    static void setUpData(){
        
        List<Case> caseRecords = ASF_TestDataFactory.createCaseRecords(1);
        if(caseRecords.size() > 0){
            EmailMessage eMsg = new EmailMessage();
            eMsg.ParentId = caseRecords[0].Id;
            eMsg.CCAddress = 'test@test.com';
            eMsg.BCCAddress = 'test@test.com';
            insert eMsg;
        }
    }
    
	@IsTest
    static void testEbotTrigger(){
        List<EmailMessage> emailMsg = [Select id from emailmessage limit 1];
        if(emailMsg.size() > 0){
           EBOT_Internal_Event__e event = new EBOT_Internal_Event__e();
            event.Email_Message_ID__c = emailMsg[0].Id;
            Test.startTest();
			Database.SaveResult eventResult = EventBus.publish(event);
            Test.stopTest();
            System.assertEquals(true,eventResult.isSuccess());
        }
     }
}