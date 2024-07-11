/**
 * @description This API is used to fetch the NEFT Ref Number for a given Policy Number and Voucher Number combination
 * Frequency - Job to run at twice in a day; 8.00 AM & 10.30 PM
 *
 * @author Abinash Panigrahi
 * @date 2022-06-19
 */
public with sharing class ABSLI_LoanVoucherProcessIntegrationBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts, Schedulable {
	public string strQuery = '';

	public ABSLI_LoanVoucherProcessIntegrationBatch(String strQuery) {
		this.strQuery = strQuery;
	}

	public ABSLI_LoanVoucherProcessIntegrationBatch() {
		this.strQuery =
			'SELECT Id, ABSLI_Case_Detail__r.Voucher_Number__c, ABSLI_Case_Detail__r.Voucher_Approval_Date__c, ' +
			'ABSLI_Case_Detail__r.Requested_Loan_Amount__c FROM Case ' +
			'WHERE (ABSLI_Case_Detail__r.Voucher_Number__c = null OR ABSLI_Case_Detail__r.Voucher_Approval_Date__c = null) ' +
            'AND CreatedDate = LAST_N_DAYS:10 AND Is_STP__c = true AND IsClosed = false' +
            'AND Sub_Type_Text__c =: ABSLI_Constants.LOANVOUCHERPROCESS_SUBTYPE';
	}

	public Database.QueryLocator start(Database.BatchableContext bc) {
        ABCL_IntegrationCallout.IntegrationResponseWrapper ingeniumResponse = ABCL_IntegrationCallout.executeCallout(
				ABSLI_Constants.FETCH_INGENIUM_CURRENTDATE_INTEGRATION_METADATA,
				null,
				null
			);
			if (ingeniumResponse.statusCode == 200 && String.isNotBlank(ingeniumResponse.responseBody)) {
				FICResponseWrapper response = (FICResponseWrapper) JSON.deserialize(
					ingeniumResponse.responseBody,
					FICResponseWrapper.class
				);
                Date ingeniumCurrentDate = Date.valueOf(response.BTCH_PRCES_DT);
                if(Date.valueOf(response.BTCH_PRCES_DT) == System.now().date() || Test.isRunningTest()){
                    return Database.getQueryLocator(strQuery);
                }
			}
		//return Database.getQueryLocator(strQuery + ' LIMIT 0');
        return Database.getQueryLocator(strQuery);
	}

	public void execute(Database.BatchableContext bc, List<Case> caseRecords) {
		try {
            Map<String, ASF_Integration__c> integrationMasterConfigs = ABSLI_IntegrationQueryHelper.getIntegrationInfo(
				new Set<String>{
					ABSLI_LoanApprovalIntegration.class.getName(),
					ABSLI_LoanRegisterIntegration.class.getName()
				}
			);

			List<Case> eligibleRegisterRecs = new List<Case>();
			Map<Id, List<ASF_Integration__c>> loanRegisterInt = new Map<Id, List<ASF_Integration__c>>();
			List<Case> eligibleApprovalRecs = new List<Case>();
			Map<Id, List<ASF_Integration__c>> loanApprovalInt = new Map<Id, List<ASF_Integration__c>>();
			for (Case caseRecord : caseRecords) {
				if (caseRecord.ABSLI_Case_Detail__r.Voucher_Number__c == null) {
					eligibleRegisterRecs.add(caseRecord);
					loanRegisterInt.put(
						caseRecord.Id,
						new List<ASF_Integration__c>{
							integrationMasterConfigs.get(ABSLI_LoanRegisterIntegration.class.getName())
						}
					);
				} else if (caseRecord.ABSLI_Case_Detail__r.Voucher_Approval_Date__c == null) {
					eligibleApprovalRecs.add(caseRecord);
					loanApprovalInt.put(
						caseRecord.Id,
						new List<ASF_Integration__c>{
							integrationMasterConfigs.get(ABSLI_LoanApprovalIntegration.class.getName())
						}
					);
				}
			}

			if (!eligibleRegisterRecs.isEmpty()) {
				ASF_IntegrationsController.runIntegration(loanRegisterInt, eligibleRegisterRecs);
			}
			if (!eligibleApprovalRecs.isEmpty()) {
				ASF_IntegrationsController.runIntegration(loanApprovalInt, eligibleApprovalRecs);
			}
		} catch (Exception e) {
			System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
			ABCL_Logger.enableExceptionLogging();
			ABCL_Logger.push('ABSLI_LoanVoucherProcessIntegrationBatch.execute');
			ABCL_Logger.message(e.getMessage());
			ABCL_Logger.emit();
		}
	}

	public void finish(Database.BatchableContext bc) {
	}

	public void execute(SchedulableContext sc) {
        Database.executeBatch(new ABSLI_LoanVoucherProcessIntegrationBatch(), ABSLI_Constants.LOANVOUCHERPROCESS_BATCH_SIZE);

	}

	public void schedule() {
		// CRON Expression (Time interval) is in 'Seconds Minutes Hours Day Month Week Year' fmt
		System.schedule(
			ABSLI_Constants.LOANVOUCHERPROCESS_SCHEDULDE_JOB + ' Run#1',
			'0 0 8 1/1 * ? *',
			new ABSLI_LoanVoucherProcessIntegrationBatch()
		);
		System.schedule(
			ABSLI_Constants.LOANVOUCHERPROCESS_SCHEDULDE_JOB + ' Run#2',
			'0 30 22 1/1 * ? *',
			new ABSLI_LoanVoucherProcessIntegrationBatch()
		);
	}

	/**
	 * @description Fetch Ingenium CurrentDate(FIC) Wrapper Class to follow through Response Body JSON
	 */
	public class FICResponseWrapper {
		public String ONLN_PRCES_DT;
		public String BTCH_PRCES_DT;
	}
}