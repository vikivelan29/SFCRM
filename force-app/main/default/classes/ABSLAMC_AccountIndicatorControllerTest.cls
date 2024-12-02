@isTest
public class ABSLAMC_AccountIndicatorControllerTest {

    @testSetup
    static void setupTestData() {
        
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        List<Case> cases = new List<Case>{
            new Case(AccountId = testAccount.Id, Stage__c = 'Open',Source__c = 'Social Media', Nature__c = 'Complaint', Escalated_Date_Time__c = DateTime.now().addDays(-1), SLA_Broken__c = true, Case_SLA_Threshold_2__c = DateTime.now().addDays(1)),
            new Case(AccountId = testAccount.Id, Stage__c = 'Open', Nature__c = 'Request', Escalated_Date_Time__c = null, SLA_Broken__c = false, Case_SLA_Threshold_2__c = DateTime.now().addMinutes(30)),
            new Case(AccountId = testAccount.Id, Stage__c = 'In Progress', Nature__c = 'Complaint', Escalated_Date_Time__c = null, SLA_Broken__c = true, Case_SLA_Threshold_2__c = DateTime.now().addDays(-1))
        };
        insert cases;

        Survey_Response__c surveyResponse = new Survey_Response__c(
            Client_Code__c = testAccount.Id,
            Primary_Question_NPS__c = 10,
            Responded_on__c = Date.today(),
            Case__c = cases[0].Id,
            Journey__c = 'Test'
        );
        insert surveyResponse;
    }

    @isTest
    static void testGetCasesForAccount() {
        
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Map<String, List<Case>> result = ABSLAMC_AccountIndicatorController.getCasesForAccount(testAccount.Id);

        System.assert(result.containsKey('Open Cases'), 'Open Cases should be present');
        System.assertEquals(3, result.get('Open Cases').size(), 'There should be 2 open cases');
        
        System.assert(result.containsKey('Open Complaints'), 'Open Complaints should be present');
        System.assertEquals(2, result.get('Open Complaints').size(), 'There should be 2 open complaints');
        
        System.assert(result.containsKey('Escalated Cases'), 'Escalated Cases should be present');
        System.assertEquals(1, result.get('Escalated Cases').size(), 'There should be 1 escalated case');
        
        System.assert(result.containsKey('Open Cases Breached SLA'), 'Open Cases Breached SLA should be present');
        System.assertEquals(2, result.get('Open Cases Breached SLA').size(), 'There should be 2 cases with breached SLA');
        
        System.assert(result.containsKey('Open Cases Nearing SLA Breach'), 'Open Cases Nearing SLA Breach should be present');
        System.assertEquals(2, result.get('Open Cases Nearing SLA Breach').size(), 'There should be 1 case nearing SLA breach');
    }

    @isTest
    static void testGetLatestNPSData() {
   
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Map<String, String> npsData = ABSLAMC_AccountIndicatorController.getLatestNPSData(testAccount.Id);

        System.assertNotEquals(null, npsData, 'NPS Data map should not be null');
        System.assertEquals('10', npsData.get('Score'), 'NPS Score should be 10');
        System.assertEquals(String.valueOf(Date.today()), npsData.get('Latest Response'), 'Latest Response should match today\'s date');
        System.assert(npsData.containsKey('Journey'), 'Journey should be present in the NPS data');
    }
}