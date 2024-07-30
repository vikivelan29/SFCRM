/**
 * @description This API is used to run the integration for closed IGMS complaints.
 * Frequency - Job to run once a day at 11:30 PM
 * @author - Dhinesh
 * @date 2024-07-04
 */
public with sharing class ABSLI_ClosedIGMSComplaintBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {
    public String strQuery = '';

    public ABSLI_ClosedIGMSComplaintBatch(String strQuery) {
        this.strQuery = strQuery;
    }

    public ABSLI_ClosedIGMSComplaintBatch() {
        Integer daysForClosedCases = Integer.valueOf(Label.ABSLI_Complaint_Closure_Batch_Days);
        this.strQuery =
            'SELECT Id, IRDAI_Token_Number__c ' +
            'FROM Case ' +
            'WHERE Nature__c = \'Complaint\' ' +
            'AND IRDAI_Token_Number__c != null ' +
            'AND ClosedDate < LAST_N_DAYS:' + daysForClosedCases + ' ' +
            'AND IsClosed = true ' +
            'AND ABSLI_Case_Detail__r.Escalated__c = false';
	}


    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(strQuery);
    }

    public void execute(Database.BatchableContext bc, List<Case> caseRecords) {
        try {
            Map<String, ASF_Integration__c> integrationMasterConfigs = ABSLI_IntegrationQueryHelper.getIntegrationInfo(
                new Set<String>{
                    'ABSLI_ClosedIGMSComplaintIntegration'
                }
            );

            List<Case> eligibleClosedComplaintRecs = new List<Case>();
            Map<Id, List<ASF_Integration__c>> closedComplaintInt = new Map<Id, List<ASF_Integration__c>>();

            for (Case caseRecord : caseRecords) {
                eligibleClosedComplaintRecs.add(caseRecord);
                closedComplaintInt.put(
                    caseRecord.Id,
                    new List<ASF_Integration__c>{
                        integrationMasterConfigs.get('ABSLI_ClosedIGMSComplaintIntegration')
                    }
                );
            }

            if (!eligibleClosedComplaintRecs.isEmpty()) {
                ASF_IntegrationsController.runIntegration(closedComplaintInt, eligibleClosedComplaintRecs);
            }
        } catch (Exception e) {
            System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABSLI_ClosedIGMSComplaintBatch.execute');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
        }
    }

    public void finish(Database.BatchableContext bc) {
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new ABSLI_ClosedIGMSComplaintBatch(), ABSLI_Constants.FETCHNEFTREF_BATCH_SIZE);
    }

    public void schedule() {
        String cronExpression = Label.ABSLI_Complaint_Closure_CRON;
        
        // CRON Expression (Time interval) is in 'Seconds Minutes Hours Day Month Week Year' format
        System.schedule(
            ABSLI_Constants.CLOSED_COMPLAINT_SCHEDULE_JOB + ' Run',
            cronExpression,
            new ABSLI_ClosedIGMSComplaintBatch()
        );
    }

}