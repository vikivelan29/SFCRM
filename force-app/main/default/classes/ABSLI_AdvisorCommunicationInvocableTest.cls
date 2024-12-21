@isTest
public class ABSLI_AdvisorCommunicationInvocableTest {
    @testSetup
    static void setupTestData() {
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'ABSLI_Advisor' LIMIT 1];

        Id recordTypeId = rt.Id;
        
        Account supervisor = new Account(
            LastName = 'Supervisor',
            RecordTypeId = recordTypeId,
            Partner_Branch_Code__c = 'BR001',
            PersonEmail = 'supervisor@example.com',
            Supervisor_Email__c = 'supervisor@example.com',
            Supervisor_Mobile_Number__c = '1234567890'
        );
        insert supervisor;
        
        /*Account advisor1 = new Account(
            LastName = 'Advisor1',
            RecordTypeId = recordTypeId,
            Partner_Branch_Code__c = 'BR001',
            PersonEmail = 'advisor1@example.com',
            Supervisor_Email__c = 'supervisor2@example.com',
            PersonMobilePhone = '0987654321'
        );
        insert advisor1;*/

        Account advisor2 = new Account(
            LastName = 'Advisor2',
            RecordTypeId = recordTypeId,
            Partner_Branch_Code__c = 'BR002',
            PersonEmail = 'advisor2@example.com',
            Supervisor_Email__c = 'supervisor23@example.com',
            PersonMobilePhone = '1122334455',
            Supervisor_Mobile_Number__c = '1234567890'
        );
        insert advisor2;

        Account advisor3 = new Account(
            LastName = 'Advisor3',
            RecordTypeId = recordTypeId,
            Partner_Branch_Code__c = 'BR002',
            PersonEmail = 'advisor3@example.com',
            Supervisor_Email__c = 'supervisor233@example.com',
            PersonMobilePhone = '5566778899'
        );
        insert advisor3;
    }

    @isTest
    static void testMultipleAdvisors() {
        List<ABSLI_AdvisorCommunicationInvocable.EmailInputWrapper> inputList = new List<ABSLI_AdvisorCommunicationInvocable.EmailInputWrapper>();
        ABSLI_AdvisorCommunicationInvocable.EmailInputWrapper input = new ABSLI_AdvisorCommunicationInvocable.EmailInputWrapper();
        input.partnerBranchCode = 'BR002';
        inputList.add(input);

        Test.startTest();
        List<ABSLI_AdvisorCommunicationInvocable.EmailOutputWrapper> result = ABSLI_AdvisorCommunicationInvocable.getRecipients(inputList);
       

        System.assertEquals(1, result.size());
        System.assertEquals(2, result[0].outcome);
        System.assertEquals('supervisor23@example.com', result[0].toEmailAddresses);
        System.assertEquals('1234567890', result[0].supervisorMobileNumber);
        
        //Single Advisor
        List<ABSLI_AdvisorCommunicationInvocable.EmailInputWrapper> inputList1 = new List<ABSLI_AdvisorCommunicationInvocable.EmailInputWrapper>();
        ABSLI_AdvisorCommunicationInvocable.EmailInputWrapper input1 = new ABSLI_AdvisorCommunicationInvocable.EmailInputWrapper();
        input1.partnerBranchCode = 'BR001';
        inputList1.add(input1);
      
        List<ABSLI_AdvisorCommunicationInvocable.EmailOutputWrapper> result1 = ABSLI_AdvisorCommunicationInvocable.getRecipients(inputList1);
        System.assertEquals('supervisor@example.com', result1[0].toEmailAddresses);
        Test.stopTest();
    }
    
}