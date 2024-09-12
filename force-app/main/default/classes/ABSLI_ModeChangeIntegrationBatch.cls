/**
 * @description When the customer in customer portal requests for a Mode Change AND this API is called on the Anniversary Date
 * Frequency - Job to run once in a day; 8.30 AM
 *
 * @author Abinash Panigrahi
 * @date 2022-06-19
 */
public with sharing class ABSLI_ModeChangeIntegrationBatch implements Database.Batchable<SObject>, Database.AllowsCallouts, Schedulable {
	public string strQuery = '';
    public String caseConfigId = ABSLI_Constants.MODECHANGE_CASECATEGORYCONFIG;
    public String defaultStage = ABSLI_Constants.MODECHANGE_DEFAULTSTAGE;

	public ABSLI_ModeChangeIntegrationBatch(String strQuery) {
		this.strQuery = strQuery;
	}

	public ABSLI_ModeChangeIntegrationBatch() {
		this.strQuery =
			'SELECT Id, ABSLI_Case_Detail__r.Anniversary_Date__c FROM Case WHERE Stage__c =: defaultStage ' +
            'AND ABSLI_Case_Detail__r.Anniversary_Date__c = LAST_N_DAYS:10 AND IsClosed = false ' +
            'AND CCC_External_Id__c =: caseConfigId AND ABSLI_Case_Detail__r.Status_Valid_For_STP__c = true';
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
		return Database.getQueryLocator(strQuery + ' LIMIT 0');
	}

	public void execute(Database.BatchableContext bc, List<Case> caseRecords) {
		try {
            Map<String, ASF_Integration__c> integrationMasterConfigs = ABSLI_IntegrationQueryHelper.getIntegrationInfo(
				new Set<String>{
					ABSLI_ModeChangeIntegration.class.getName()
				}
			);

			List<Case> eligibleModeChangeRecs = new List<Case>();
			Map<Id, List<ASF_Integration__c>> modeChangeInt = new Map<Id, List<ASF_Integration__c>>();
			for (Case caseRecord : caseRecords) {
					eligibleModeChangeRecs.add(caseRecord);
					modeChangeInt.put(
						caseRecord.Id,
						new List<ASF_Integration__c>{
							integrationMasterConfigs.get(ABSLI_ModeChangeIntegration.class.getName())
						}
					);
			}

			if (!eligibleModeChangeRecs.isEmpty()) {
				ASF_IntegrationsController.runIntegration(modeChangeInt, eligibleModeChangeRecs);
			}
		} catch (Exception e) {
			System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
			ABCL_Logger.enableExceptionLogging();
			ABCL_Logger.push('ABSLI_ModeChangeIntegrationBatch.execute');
			ABCL_Logger.message(e.getMessage());
			ABCL_Logger.emit();
		}
	}

	public void finish(Database.BatchableContext bc) {
	}

	public void execute(SchedulableContext sc) {
        Database.executeBatch(new ABSLI_ModeChangeIntegrationBatch(), ABSLI_Constants.MODECHANGE_BATCH_SIZE);

	}

	public void schedule() {
		// CRON Expression (Time interval) is in 'Seconds Minutes Hours Day Month Week Year' fmt
		System.schedule(
			ABSLI_Constants.MODECHANGE_SCHEDULDE_JOB,
			'0 30 8 1/1 * ? *',
			new ABSLI_ModeChangeIntegrationBatch()
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