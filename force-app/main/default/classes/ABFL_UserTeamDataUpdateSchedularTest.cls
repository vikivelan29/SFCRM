/*********************************************************
** Class        :  ABFL_UserTeamDataUpdateSchedularTest
** Author       :  SaiRahul
** Description  :  Test Class to validate ABFL_UserTeamDataUpdateBatchScheduler
** Created Date :  28/02/2024
*********************************************************/

@isTest
private class ABFL_UserTeamDataUpdateSchedularTest {
 @isTest
    static void testScheduler() {
        // Schedule the job
        String jobID = System.schedule('TEST ABFL_UserTeamDataUpdateBatchScheduler', '0 0 1 * * ? *', new ABFL_UserTeamDataUpdateBatchScheduler());

        // Verify that the job was successfully scheduled
        System.assertNotEquals(null, jobID);

        // Get the scheduled job
        CronTrigger scheduledJob = [SELECT Id, CronExpression, TimesTriggered FROM CronTrigger WHERE Id = :jobID];

        // Verify that the cron expression is correct
        System.assertEquals('0 0 1 * * ? *', scheduledJob.CronExpression);

        // Verify that the job has not been triggered yet
        System.assertEquals(0, scheduledJob.TimesTriggered);

        // Trigger the job manually
        Test.startTest();
        ABFL_UserTeamDataUpdateBatchScheduler scheduler = new ABFL_UserTeamDataUpdateBatchScheduler();
        scheduler.execute(null);
        Test.stopTest();
        
        // Clean up by deleting the scheduled job
        System.abortJob(jobID);
    }
}