@IsTest
public class ASF_TriggerSkipperUtility_Test {
    @IsTest
    static void testmarkTriggerRun() {    
        Test.startTest();
        ASF_TriggerSkipperUtility.markTriggerRun('Case');   
        Boolean bool1 = ASF_TriggerSkipperUtility.isAllowedToRun('Case', 'After');
        ASF_TriggerSkipperUtility.markTriggerRun('Case', 'Before');
        ASF_TriggerSkipperUtility.resetTriggerRun('Case');
        Boolean bool2 = ASF_TriggerSkipperUtility.isAllowedToRun('Case', 'Before');
        ASF_TriggerSkipperUtility.resetTriggerRun('Case', 'Before', true);
        ASF_TriggerSkipperUtility.isAllowedToRun('Case', 'Before');
        String success = 'Success';
        Test.stopTest();
        System.assertEquals(false, bool1);
        System.assertEquals(true, bool2);
    }
}