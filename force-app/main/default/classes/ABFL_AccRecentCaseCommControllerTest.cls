@isTest
private class ABFL_AccRecentCaseCommControllerTest {
    @testSetup
    static void setupTestData(){
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1]; 
        User adminUser = new User(Alias = 'standt', Email='standarduser@testorg.com', 
             EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
             LocaleSidKey='en_US', ProfileId = p.Id, 
             TimeZoneSidKey='America/Los_Angeles', UserName='adminUserabcl@gmail.com');
        insert adminUser;
        System.runAs(adminUser) {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        List<Case> testCases = new List<Case>();
        for (Integer i = 0; i < 5; i++) {
            testCases.add(new Case(AccountId = testAccount.Id, Subject = 'Test Case ' + i));
        }
        insert testCases;

        List<CaseComment> CaseComm = new List<CaseComment>();
        for (Case testCase : testCases) {
            CaseComm.add(new CaseComment(ParentId = testCase.Id, CommentBody = 'Test Comment'));
        }
        insert CaseComm;
        }
    }

    @isTest
    static void GetAccountCaseComments_Success() {
        
		Account ac = [SELECT Id FROM Account LIMIT 1];
        List<Case> cs=[select id from Case];
        // Call the method
        Test.startTest();
        ABFL_AccRecentCaseCommController.getAccountCaseComments(ac.Id, 10);
        
        
        Test.stopTest();
        System.assertEquals(cs.size(), 5);
        ABFL_AccRecentCaseCommController.getAccountCaseComments(ac.Id, -1);
    }

}