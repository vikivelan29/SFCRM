/**
 * @description       : Schedules the Batch job to run at 1 AM everyday.
 * @author            : SaiRahul
 * @group             : 
 * @last modified on  : 05-13-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   05-13-2024   rsinghnagar@salesforce.com   Initial Version
**/
public with sharing class ABFL_UserTeamDataUpdateBatchScheduler implements Schedulable {
    /**
    * @description 
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    * @param sc 
    **/
    public void execute(SchedulableContext sc) {
        ABFL_UserTeamDataUpdateBatch batch = new ABFL_UserTeamDataUpdateBatch();
        Database.executeBatch(batch);
    }
}