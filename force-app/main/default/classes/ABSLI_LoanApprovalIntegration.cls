/**
 * @description Approve Voucher Update Outbound API (Event Based) from Salesforce to Ingenium
 * This api is used to Approve Voucher created in Voucher Creation API. When Voucher Creation API is successful, it creates Voucher Number.
 * As soon as Voucher Number is created for the Case, invoke the Approve Voucher API for Case.
 *
 * @author Abinash Panigrahi
 * @date 2024-05-17
 */
public with sharing class ABSLI_LoanApprovalIntegration implements ASF_IntegrationInvocable {
	/**
	 * @description Invoked from the ASF_IntegrationsController class, this method evaluates whether integration should be fired or not
	 *
	 * @param caseRecs - List of Case record from the framework
	 * @return Map<Id, ASF_IntegrationsController.IntegrationWrapper>
	 */
	public Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs) {
		Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();

		List<Case> caseRecords = new List<Case>();
		for (Case caseRec : caseRecs) {
			caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
		}

		for (Case caseRecord : caseRecords) {
			ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();

			result.status = ABSLI_Constants.ERROR;
			result.response = result.response = Custom_Messages__mdt.getInstance(
					ABSLI_Constants.LOANAPPROVAL_EVALUATION_ERROR
				)
				.Message__c;

			if (
				caseRecord.ABSLI_Case_Detail__r.Voucher_Date__c != null &&
				caseRecord.ABSLI_Case_Detail__r.Voucher_Number__c != null
			) {
				result.status = ABSLI_Constants.SUCCESS;
				result.response = ABSLI_Constants.EVALUATION_SUCCESS;
			}

			resultMap.put(caseRecord.Id, result);
		}

		return resultMap;
	}

	/**
	 * @description Invoked from the ASF_IntegrationsController class, this method runs the integration and creates Case Integration record
	 *
	 * @param integs - List of ASF_Integration record
	 * @param caseRecs - List of Case record from the framework
	 * @return Map<Id, ASF_IntegrationsController.IntegrationWrapper>
	 */
	public Map<Id, ASF_IntegrationsController.IntegrationWrapper> run(
		Map<Id, List<ASF_Integration__c>> integs,
		List<Case> caseRecs
	) {
		Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();

		//Before Initiating new Integration callout, cancel existing running request
		cancelPendingCaseIntegrationRequests(integs, caseRecs);

		List<Case> caseRecords = new List<Case>();
		for (Case caseRec : caseRecs) {
			caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
		}

		List<ASF_Case_Integration__c> newCaseIntegrations = new List<ASF_Case_Integration__c>();
		Map<Integer, Case_Integration_Outbound__e> peMap = new Map<Integer, Case_Integration_Outbound__e>();
		Integer index = 0;
		Map<Integer, Id> indexToCaseId = new Map<Integer, Id>();

		for (Case caseRecord : caseRecords) {
			string requestBody = JSON.serialize(
				new LARequestWrapper(
					caseRecord.LAN__c == null ? caseRecord.Asset?.Policy_No__c : caseRecord.LAN__c,
					caseRecord.ABSLI_Case_Detail__r.Voucher_Number__c
				)
			);
			for (ASF_Integration__c intSpec : integs.get(caseRecord.Id)) {
				if (intSpec.Processing_Class__c == ABSLI_LoanApprovalIntegration.class.getName()) {
					ASF_Case_Integration__c caseInteg = new ASF_Case_Integration__c();
					caseInteg.Integration_Ext_Id__c = intSpec.External_Id__c;
					caseInteg.Case__c = caseRecord.Id;
					caseInteg.Status__c = ABSLI_Constants.PENDING;
					caseInteg.Request__c = requestBody;
					caseInteg.Response__c = ABSLI_Constants.WAITING_API_RESPONSE;
					caseInteg.Is_Validation_Success__c = true;
					newCaseIntegrations.add(caseInteg);

					Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e();
					caseIntOut.Business_Unit__c = caseRecord.Business_Unit__c;
					caseIntOut.Request_Payload__c = requestBody;
					caseIntOut.Integration_Name__c = ABSLI_Constants.LOANAPPROVAL_SERVICE_NAME;
					caseIntOut.ServiceName__c = ABSLI_Constants.LOANAPPROVAL_SERVICE_NAME;
					peMap.put(index, caseIntOut);
					indexToCaseId.put(index, caseRecord.Id);
				}
				index++;
			}
		}

		index = 0;

		List<Database.SaveResult> results = Database.insert(newCaseIntegrations, false, AccessLevel.SYSTEM_MODE);
		Map<Id, ASF_Case_Integration__c> caseIntegrations = new Map<Id, ASF_Case_Integration__c>(
			ABSLI_IntegrationQueryHelper.getCaseIntegrations(newCaseIntegrations)
		);
		for (Database.SaveResult sr : results) {
			if (sr.isSuccess()) {
				Case_Integration_Outbound__e caseIntOut = peMap.get(index);
				caseIntOut.Case_Integration_ID__c = caseIntegrations.get(sr.getId()).Name;
				peMap.put(index, caseIntOut);
			} else {
				ASF_IntegrationsController.IntegrationWrapper wrap = new ASF_IntegrationsController.IntegrationWrapper();
				wrap.status = ABSLI_Constants.ERROR;
				resultMap.put(indexToCaseId.get(index), wrap);
				peMap.remove(index);
				indexToCaseId.remove(index);
			}
			index++;
		}

		List<Database.SaveResult> publishResults = EventBus.publish(peMap.values());
		index = 0;
		for (Database.SaveResult publishResult : publishResults) {
			if (publishResult.isSuccess()) {
				ASF_IntegrationsController.IntegrationWrapper wrap = new ASF_IntegrationsController.IntegrationWrapper();
				wrap.status = ABSLI_Constants.SUCCESS;
				wrap.response = Custom_Messages__mdt.getInstance(ABSLI_Constants.LOANAPPROVAL_SUCCESS_MESSAGE)
					.Message__c;
				resultMap.put(indexToCaseId.values()[index], wrap);
			} else {
				ASF_IntegrationsController.IntegrationWrapper wrap = new ASF_IntegrationsController.IntegrationWrapper();
				wrap.status = ABSLI_Constants.ERROR;
				wrap.response = Custom_Messages__mdt.getInstance(ABSLI_Constants.LOANAPPROVAL_FAILURE_MESSAGE)
					.Message__c;
				resultMap.put(indexToCaseId.values()[index], wrap);
			}
			index++;
		}

		return resultMap;
	}

	/**
	 * @description Before Initiating new Integration callout, cancel existing running request
	 *
	 * @param integs - List of Integration configs
	 * @param caseRecs - List of Case record from the framework
	 */
	public void cancelPendingCaseIntegrationRequests(Map<Id, List<ASF_Integration__c>> integs, List<Case> caseRecs) {
		Set<String> intIds = new Set<String>();
		for (Case caseRec : caseRecs) {
			for (ASF_Integration__c integ : integs.get(caseRec.Id)) {
				if (integ.Processing_Class__c == ABSLI_LoanApprovalIntegration.class.getName()) {
					intIds.add(integ.External_Id__c);
				}
			}
		}

		List<ASF_Case_Integration__c> existingCaseIntegrations = new List<ASF_Case_Integration__c>();
		for (ASF_Case_Integration__c caseInt : ABSLI_IntegrationQueryHelper.getCaseIntegrations(caseRecs, intIds)) {
			if (integs.containsKey(caseInt.Case__c)) {
				for (ASF_Integration__c integ : integs.get(caseInt.Case__c)) {
					if (
						integ.External_Id__c == caseInt.Integration_Ext_Id__c &&
						caseInt.Status__c == ABSLI_Constants.PENDING
					) {
						caseInt.Status__c = ABSLI_Constants.CANCELED;
						existingCaseIntegrations.add(caseInt);
					}
				}
			}
		}

		ASF_TriggerSkipperUtility.markTriggerRun('ASF_Case_Integration__c');
		Database.update(existingCaseIntegrations, AccessLevel.SYSTEM_MODE);
		ASF_TriggerSkipperUtility.resetTriggerRun('ASF_Case_Integration__c');
	}

	/**
	 * @description Invoked from the Case Integration trigger, this method processes the response of the integration received
	 *
	 * @param caseInteg - ASF_Integration record
	 */
	public void processResponse(ASF_Case_Integration__c caseInteg) {
		try {
            Case caseRecord = ABSLI_IntegrationQueryHelper.getCaseInfo(caseInteg.Case__c);
            ABSLI_Case_Detail__c caseDetail = new ABSLI_Case_Detail__c(Id = caseRecord.ABSLI_Case_Detail__c);
			if (caseInteg.Status__c == ABSLI_Constants.SUCCESS) {
				LAResponseWrapper jsonMap = (LAResponseWrapper) JSON.deserialize(
					caseInteg.Response__c,
					LAResponseWrapper.class
				);

				if (jsonMap.lsir_return_cd == '00') {
					caseDetail.Approver_Remarks__c = jsonMap.messages;
                    caseDetail.Voucher_Approval_Date__c = System.today();
					Database.update(caseDetail, AccessLevel.SYSTEM_MODE);
				}
			}
            // if(caseInteg.Status__c == ABSLI_Constants.FAILURE){
            //     caseDetail.Status_Valid_For_STP__c = false;
            //     Database.update(caseDetail, AccessLevel.SYSTEM_MODE);

            //     caseRecord.MoveToNext__c = true;
            //     caseRecord.Is_STP__c = false;
			// 	Database.update(caseRecord, AccessLevel.SYSTEM_MODE);
            // }
		} catch (Exception e) {
			System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
			ABCL_Logger.enableExceptionLogging();
			ABCL_Logger.push('ABSLI_LoanApprovalIntegration.processResponse');
			ABCL_Logger.message(e.getMessage());
			ABCL_Logger.emit();
		}
	}

	/**
	 * @description Invoked from the ASF_IntegrationsController class, this method evaluates whether integration should be fired or not
	 *
	 * @param caseRec - Case record from the framework
	 * @return ASF_IntegrationsController.IntegrationWrapper
	 */
	public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec) {
		ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
		result = evaluate(new List<Case>{ caseRec }).get(caseRec.Id);
		return result;
	}

	/**
	 * @description Invoked from the ASF_IntegrationsController class, this method runs the integration and creates Case Integration record
	 *
	 * @param caseInteg - ASF_Integration record
	 * @param caseRec - Case record from the framework
	 * @return ASF_IntegrationsController.IntegrationWrapper
	 */
	public ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c caseInteg, Case caseRec) {
		ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
		result = run(
				new Map<Id, List<ASF_Integration__c>>{ caseRec.Id => new List<ASF_Integration__c>{ caseInteg } },
				new List<Case>{ caseRec }
			)
			.get(caseRec.Id);
		return result;
	}

	/**
	 * @description Loan Approval (LA) Wrapper Class to build Integration Request Body JSON
	 */
	public class LARequestWrapper {
		public String MIR_POL_ID;
		public String MIR_CHQ_VCHR_NUM;
		public String MIR_WEB_SERV_USER_ID;
		public String ACTION;

		public LARequestWrapper(String policyID, String voucherNumber) {
			this.MIR_POL_ID = policyID;
			this.MIR_CHQ_VCHR_NUM = voucherNumber;
			this.MIR_WEB_SERV_USER_ID = ABSLI_Constants.LOANAPPROVAL_USER_ID;
			this.ACTION = ABSLI_Constants.LOANAPPROVAL_ACTION;
		}
	}

	/**
	 * @description Loan Approval (LA) Wrapper Class to follow through Response Body JSON
	 */
	public class LAResponseWrapper {
		public String lsir_return_cd;
		public String messages;
	}
}