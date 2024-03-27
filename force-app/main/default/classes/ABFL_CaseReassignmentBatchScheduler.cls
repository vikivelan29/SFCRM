/**
 * @description       : 
 * @author            : srujana@techforceservices.com
 * @group             : 
 * @last modified on  : 03-14-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   03-14-2024   srujana@techforceservices.com   Initial Version
**/
public with sharing class ABFL_CaseReassignmentBatchScheduler  implements Schedulable {
    public void execute(SchedulableContext sc) {
        ABFL_CaseReassignmentBatch batch = new ABFL_CaseReassignmentBatch();
        Database.executeBatch(batch);
    }
}