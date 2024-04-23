@isTest(seeAllData = false)
public class ASF_CaseAgeInBusinessDaysBatch_Test {

    @testSetup 
    static void setupData() {
        ASF_TestDataFactory.createCaseRecords(2);
    }
    
    static testmethod void updateAgeingTest() {

        Test.StartTest();
        ASF_CaseAgeInBusinessDaysBatch batchClass= new ASF_CaseAgeInBusinessDaysBatch();
        Id jobid= Database.executeBatch(batchClass,5);
        Test.StopTest();   
    }
    
    public static testMethod void testschedule() {
		Test.StartTest();
		String sch = '0 0 23 * * ?';
		system.schedule('Test scheduler', sch, new ASF_CaseAgeInBusinessDaysBatch());
		Test.stopTest();
	}
}