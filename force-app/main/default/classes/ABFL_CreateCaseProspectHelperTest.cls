@IsTest 
private class ABFL_CreateCaseProspectHelperTest {
    
    @testSetup static void basicDataSetup() {
        // Create common test Leads
        Lead newLead = new lead();
        newLead.FirstName = 'FULLNAM2E';
        newLead.Lastname = 'name';
        newLead.MobilePhone = '1236547899';
        newLead.Email = 'Email2@gmail.com';
        newLead.PANNO__c = 'PANNO2';
        insert newLead;        
    }
    
    @IsTest(seeAllData = false)
    static void beforeInsertMethod_Test() {
        Case newCase = new Case(Business_Unit__c='ABFL');
        newCase.Prospect_payload__c='{"FULLNAME":"FULLNAME","MOBILE":"123654789","PANNO":"PANNO1","Email":"Email@gmail.com"}';
        Case newCase2 = new Case(Business_Unit__c='ABFL');
        newCase2.Prospect_payload__c='{"FULLNAME":"FULLNAM2E name","MOBILE":"1236547899","PANNO":"PANNO2","Email":"Email2@gmail.com"}';
        sObject sObjcase = newCase;
        sObject sObjcase2 = newCase2;
        List<sObject> sList = new List<sObject>();
        sList.add(sObjcase);
        sList.add(sObjcase2);
        System.runAs(new User (Id = UserInfo.getUserId())) {
            Test.StartTest();
            ABFL_CreateCaseProspectHelper.beforeInsertMethod(sList);
            Test.StopTest();   
        }
        List<Lead> ls = [select id from lead];
        System.assertEquals(2,ls.size());
        System.assertnotEquals(1,ls.size());
    }
}