/**
 * @description This batch is used to run the integration for closed IGMS complaints ABHI.
 * Frequency - Job to run once a day at 3 AM 
 * @author - Shubham Sinha
 * @date 2024-10-04
 */
public with sharing class ABHI_ClosedIGMSComplaintBatch implements Database.Batchable<SObject>, Database.Stateful,Schedulable {
    public String strQuery = '';

    public ABHI_ClosedIGMSComplaintBatch(String strQuery) {
        this.strQuery = strQuery;
    }

    public ABHI_ClosedIGMSComplaintBatch() {
        Integer daysForClosedCases = Integer.valueOf(Label.ABSLI_Complaint_Closure_Batch_Days);
        this.strQuery =
            'SELECT Id, IRDAI_Token_Number__c ' +
            'FROM Case ' +
            'WHERE Nature__c = \'Complaint\' ' + 
            'AND IRDAI_Token_Number__c != null ' +
            'AND ClosedDate < LAST_N_DAYS:' + daysForClosedCases + ' ' +
            'AND IsClosed = true ' +
            'AND ABHI_Case_Detail__r.Escalated__c = false '+
            'AND ABHI_Case_Detail__r.IGMS_Complaint_Status__c = \'4\' '+
            'AND Business_Unit__c = \'ABHI\'';
	}


    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(strQuery);
    }

    public void execute(Database.BatchableContext bc, List<Case> caseRecords) {
        try {
            Map<String, ASF_Integration__c> integrationMasterConfigs = ABHI_IntegrationQueryHelper.getIntegrationInfo(
                new Set<String>{
                    'ABHI_ClosedIGMSComplaintIntegration'
                }
            );

            List<Case> eligibleClosedComplaintRecs = new List<Case>();
            Map<Id, List<ASF_Integration__c>> closedComplaintInt = new Map<Id, List<ASF_Integration__c>>();

            for (Case caseRecord : caseRecords) {
                eligibleClosedComplaintRecs.add(caseRecord);
                closedComplaintInt.put(
                    caseRecord.Id,
                    new List<ASF_Integration__c>{
                        integrationMasterConfigs.get('ABHI_ClosedIGMSComplaintIntegration')
                    }
                );
            }

            if (!eligibleClosedComplaintRecs.isEmpty()) {
                ASF_IntegrationsController.runIntegration(closedComplaintInt, eligibleClosedComplaintRecs);
            }
        } catch (Exception e) {
            System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABHI_ClosedIGMSComplaintBatch.execute');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
        }
    }

    public void finish(Database.BatchableContext bc) {
    }
    public void execute(SchedulableContext SC) {
    	Database.executeBatch(this, 200);  
    }
}