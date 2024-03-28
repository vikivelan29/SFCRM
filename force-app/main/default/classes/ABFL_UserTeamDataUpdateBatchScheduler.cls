/*********************************************************
** Class        :  ABFL_UserTeamDataUpdateBatchScheduler
** Author       :  SaiRahul
** Description  :  Schedules the Batch job to run at 1 AM everyday.
** Created Date :  28/02/2024
*********************************************************/
public with sharing class ABFL_UserTeamDataUpdateBatchScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        ABFL_UserTeamDataUpdateBatch batch = new ABFL_UserTeamDataUpdateBatch();
        Database.executeBatch(batch);
    }
}