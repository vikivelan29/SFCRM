/*********************************************************
** Class        :  ABFL_InactiveOwnerCaseReassignScheduler
** Author       :  Sara
** Description  :  Schedules ABFL_InactiveOwnerCaseReassignmentBatch Batch job to run at 1 AM everyday.
** Created Date :  03/05/2024
*********************************************************/
public class ABFL_InactiveOwnerCaseReassignScheduler {
    public void execute(SchedulableContext sc) {
        ABFL_InactiveOwnerCaseReassignmentBatch batch = new ABFL_InactiveOwnerCaseReassignmentBatch();
        Database.executeBatch(batch);
    }
}