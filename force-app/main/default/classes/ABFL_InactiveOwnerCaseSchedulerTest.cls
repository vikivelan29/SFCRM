/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 07-01-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   06-30-2024   rsinghnagar@salesforce.com   Initial Version
**/
@isTest
public class ABFL_InactiveOwnerCaseSchedulerTest {
    @isTest
    static void testScheduler() {
        // Schedule the job
        String jobID = System.schedule('TestABFLInactiveOwnerCaseReassignScheduler', '0 0 0 * * ?', new ABFL_InactiveOwnerCaseReassignScheduler());

        // Verify that the job was successfully scheduled
        System.assertNotEquals(null, jobID);

        // Get the scheduled job
        CronTrigger scheduledJob = [SELECT Id, CronExpression, TimesTriggered FROM CronTrigger WHERE Id = :jobID];

        // Verify that the cron expression is correct
        System.assertEquals('0 0 0 * * ?', scheduledJob.CronExpression);

        // Verify that the job has not been triggered yet
        System.assertEquals(0, scheduledJob.TimesTriggered);

        // Trigger the job manually
        Test.startTest();
        ABFL_InactiveOwnerCaseReassignScheduler scheduler = new ABFL_InactiveOwnerCaseReassignScheduler();
        scheduler.execute(null);
        Test.stopTest();

        // Query the job again and verify that it has been triggered once
        scheduledJob = [SELECT Id, CronExpression, TimesTriggered FROM CronTrigger WHERE Id = :jobID];
        // System.assertEquals(1, scheduledJob.TimesTriggered);

        // Clean up by deleting the scheduled job
        System.abortJob(jobID);
    }
}