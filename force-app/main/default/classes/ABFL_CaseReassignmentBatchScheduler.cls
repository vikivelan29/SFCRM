global class ABFL_CaseReassignmentBatchScheduler  implements Schedulable {
    global void execute(SchedulableContext SC) {
        ABFL_CaseReassignmentBatch batch = new ABFL_CaseReassignmentBatch();
        Database.executeBatch(batch);
    }
}