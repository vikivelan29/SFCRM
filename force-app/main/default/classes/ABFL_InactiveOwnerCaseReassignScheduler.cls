/**
 * @description       : Schedules ABFL_InactiveOwnerCaseReassignmentBatch Batch job to run at 1 AM everyday.
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 05-13-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   05-13-2024   rsinghnagar@salesforce.com   Initial Version
**/
public without sharing class ABFL_InactiveOwnerCaseReassignScheduler implements Schedulable {
    /**
    * @description 
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    * @param sc 
    **/
    public void execute(SchedulableContext sc) {
        ABFL_InactiveOwnerCaseReassignmentBatch batch = new ABFL_InactiveOwnerCaseReassignmentBatch();
        Database.executeBatch(batch);
    }
}