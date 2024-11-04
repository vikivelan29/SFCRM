/**
 * @description This API is used to fetch the NEFT Ref Number for a given Policy Number and Voucher Number combination
 * Frequency - Job to run at twice in a day; 7.30 AM & 8.30 PM
 *
 * @author Abinash Panigrahi
 * @date 2022-06-19
 */
public with sharing class ABSLI_LoanNEFTRefNumIntegrationBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {
	public string strQuery = '';
    public String subType = ABSLI_Constants.LOANVOUCHERPROCESS_SUBTYPE;

	public ABSLI_LoanNEFTRefNumIntegrationBatch(String strQuery) {
		this.strQuery = strQuery;
	}

	public ABSLI_LoanNEFTRefNumIntegrationBatch() {
		this.strQuery =
			'SELECT Id, ABSLI_Case_Detail__r.NEFT_Reference_Number__c ' +
			'FROM Case WHERE ABSLI_Case_Detail__r.Voucher_Number__c != null ' +
			'AND IsClosed = false AND CreatedDate = LAST_N_DAYS:10 AND Sub_Type_Text__c =:subType ' +
            'AND ABSLI_Case_Detail__r.Status_Valid_For_STP__c = true AND CaseNumber IN (\'00405432\',\'00401803\')';
	}

	public Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(strQuery);
	}

	public void execute(Database.BatchableContext bc, List<Case> caseRecords) {
		try {
			Map<String, ASF_Integration__c> integrationMasterConfigs = ABSLI_IntegrationQueryHelper.getIntegrationInfo(
				new Set<String>{
					ABSLI_LoanAssignmentIntegration.class.getName(),
					ABSLI_FetchNEFTRefNumIntegration.class.getName()
				}
			);

			List<Case> eligibleFetchNEFTRefRecs = new List<Case>();
			Map<Id, List<ASF_Integration__c>> fetchNEFTRefInt = new Map<Id, List<ASF_Integration__c>>();
			List<Case> eligibleLoanAssignmentRecs = new List<Case>();
			Map<Id, List<ASF_Integration__c>> loanAssignmentInt = new Map<Id, List<ASF_Integration__c>>();
			for (Case caseRecord : caseRecords) {
				if (caseRecord.ABSLI_Case_Detail__r.NEFT_Reference_Number__c == null) {
					eligibleFetchNEFTRefRecs.add(caseRecord);
					fetchNEFTRefInt.put(
						caseRecord.Id,
						new List<ASF_Integration__c>{
							integrationMasterConfigs.get(ABSLI_FetchNEFTRefNumIntegration.class.getName())
						}
					);
				} else {
					eligibleLoanAssignmentRecs.add(caseRecord);
					loanAssignmentInt.put(
						caseRecord.Id,
						new List<ASF_Integration__c>{
							integrationMasterConfigs.get(ABSLI_LoanAssignmentIntegration.class.getName())
						}
					);
				}
			}

			if (!eligibleFetchNEFTRefRecs.isEmpty()) {
				ASF_IntegrationsController.runIntegration(fetchNEFTRefInt, eligibleFetchNEFTRefRecs);
			}
			if (!eligibleLoanAssignmentRecs.isEmpty()) {
				ASF_IntegrationsController.runIntegration(loanAssignmentInt, eligibleLoanAssignmentRecs);
			}
		} catch (Exception e) {
			System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
			ABCL_Logger.enableExceptionLogging();
			ABCL_Logger.push('ABSLI_LoanNEFTRefNumIntegrationBatch.execute');
			ABCL_Logger.message(e.getMessage());
			ABCL_Logger.emit();
		}
	}

	public void finish(Database.BatchableContext bc) {
	}

	public void execute(SchedulableContext sc) {
		Database.executeBatch(new ABSLI_LoanNEFTRefNumIntegrationBatch(), ABSLI_Constants.FETCHNEFTREF_BATCH_SIZE);
	}

	public void schedule() {
		// CRON Expression (Time interval) is in 'Seconds Minutes Hours Day Month Week Year' fmt
		System.schedule(
			ABSLI_Constants.FETCHNEFTREF_SCHEDULDE_JOB + ' Run#1',
			'0 30 7 1/1 * ? *',
			new ABSLI_LoanNEFTRefNumIntegrationBatch()
		);
		System.schedule(
			ABSLI_Constants.FETCHNEFTREF_SCHEDULDE_JOB + ' Run#2',
			'0 30 19 1/1 * ? *',
			new ABSLI_LoanNEFTRefNumIntegrationBatch()
		);
	}
}