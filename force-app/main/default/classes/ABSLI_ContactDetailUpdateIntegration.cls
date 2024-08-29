/**
 * @description Outbound Callout to Contact Update (Email and/or Mobile Number) Deatils of Customer
 *  Service Agent to manually invoke STP by clicking on the Integration Button
 *  Customer Portal to create Cases by API. On Successful response, case to be marked as Closed
 *
 * @author Abinash Panigrahi
 * @date 2024-05-28
 */
public with sharing class ABSLI_ContactDetailUpdateIntegration implements ASF_IntegrationInvocable {
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

		Set<Id> skipcaseIds = new Set<Id>();
		for (ASF_Checklist__c filteredChecklist : [
			SELECT Id, Case__c
			FROM ASF_Checklist__c
			WHERE Status__c NOT IN ('Yes', 'Signature Matched', 'Completed')
            AND Case__c IN: caseRecords
		]) {
			skipcaseIds.add(filteredChecklist.Case__c);
		}

		for (Case caseRecord : caseRecords) {
			ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();

			result.status = ABSLI_Constants.ERROR;
            //Customer Portal and Status_Valid_For_STP__c is false 
            if(caseRecord.Source__c == ABSLI_Constants.CUSTOMER_PORTAL && caseRecord.ABSLI_Case_Detail__r.Status_Valid_For_STP__c == false){
            	result.status = ABSLI_Constants.ERROR;
            	result.response = Custom_Messages__mdt.getInstance('ABSLI_CustomerPortal_STPFalse_Err').Message__c;
            }else{
                String evaluationErrorMetadataName = '';
                if (ABSLI_Constants.CONTACTUPDATE_EVALUATE_ERROR.containsKey(caseRecord.CCC_External_Id__c)) {
                    evaluationErrorMetadataName = ABSLI_Constants.CONTACTUPDATE_EVALUATE_ERROR.get(
                        caseRecord.CCC_External_Id__c
                    );
                }
                result.response = Custom_Messages__mdt.getInstance(evaluationErrorMetadataName).Message__c;
    
                if (
                    (caseRecord.Technical_Source__c == 'API' && caseRecord.ABSLI_Case_Detail__r.Status_Valid_For_STP__c) ||
                    (caseRecord.Technical_Source__c == 'LWC' &&
                    caseRecord.ABSLI_Case_Detail__r.Source_Request_submitted_by__c == 'Customer' &&
                    caseRecord.ABSLI_Case_Detail__r.Country_Code__c == '91' &&
                    !skipcaseIds.contains(caseRecord.Id))
                ) {
                    result.status = ABSLI_Constants.SUCCESS;
                    result.response = ABSLI_Constants.EVALUATION_SUCCESS;
                }
            }
			resultMap.put(caseRecord.Id, result);
		}

		return resultMap;
	}

	/**
	 * @description Invoked from the ASF_IntegrationsController class, this method runs the integration and creates Case Integration record
	 *
	 * @param caseIntegs - List of ASF_Integration record
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
			String caseClientCodeText = '';
			if (caseRecord.Technical_Source__c == 'API') {
				caseClientCodeText = caseRecord.AccountId != null
					? caseRecord.Account.Client_Code__c
					: caseRecord.Client_Code_Text__c;
			} else {
				caseClientCodeText = caseRecord.AccountId != null ? caseRecord.Account.Client_Code__c : '';
			}
			string requestBody = JSON.serialize(
				new ContactDetailRequestWrapper(
					caseRecord.CaseNumber,
					caseClientCodeText,
					caseRecord.ABSLI_Case_Detail__r?.Mobile_Number__c,
					caseRecord.ABSLI_Case_Detail__r?.Email_Id__c
				)
			);
			for (ASF_Integration__c intSpec : integs.get(caseRecord.Id)) {
				if (intSpec.Processing_Class__c == ABSLI_ContactDetailUpdateIntegration.class.getName()) {
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
					caseIntOut.Integration_Name__c = ABSLI_Constants.CONTACTUPDATE_SERVICE_NAME;
					caseIntOut.ServiceName__c = ABSLI_Constants.CONTACTUPDATE_SERVICE_NAME;
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
				wrap.response = Custom_Messages__mdt.getInstance(ABSLI_Constants.CONTACTUPDATE_SUCCESS_MESSAGE)
					.Message__c;
				resultMap.put(indexToCaseId.values()[index], wrap);
			} else {
				ASF_IntegrationsController.IntegrationWrapper wrap = new ASF_IntegrationsController.IntegrationWrapper();
				wrap.status = ABSLI_Constants.ERROR;
				wrap.response = Custom_Messages__mdt.getInstance(ABSLI_Constants.CONTACTUPDATE_FAILURE_MESSAGE)
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
				if (integ.Processing_Class__c == ABSLI_ContactDetailUpdateIntegration.class.getName()) {
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
	 * If ProcessCode = 0, Successful Transaction. Then Resolve Case
	 *
	 * @param caseInteg - ASF_Integration record
	 * @return
	 */
	public void processResponse(ASF_Case_Integration__c caseInteg) {
		try {
			if (caseInteg.Status__c == ABSLI_Constants.SUCCESS) {
				Case caseRecord = ABSLI_IntegrationQueryHelper.getCaseInfo(caseInteg.Case__c);

				ContactDetailResponseWrapper jsonMap = (ContactDetailResponseWrapper) JSON.deserialize(
					caseInteg.Response__c,
					ContactDetailResponseWrapper.class
				);

				if (jsonMap.ProcessCode == '00') {
					caseRecord.MoveToNext__c = true;
					Database.update(caseRecord, AccessLevel.SYSTEM_MODE);
				}
			}
		} catch (Exception e) {
			System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
			ABCL_Logger.enableExceptionLogging();
			ABCL_Logger.push('ABSLI_ContactDetailUpdateIntegration.processResponse');
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
	 * @description Contact Detail Update Wrapper Wrapper Class to build Integration Request Body JSON
	 */
	@SuppressWarnings('PMD.VariableNamingConventions,PMD.FieldNamingConventions')
	public class ContactDetailRequestWrapper {
		public string TRANS_NO { get; set; }
		public service service { get; set; }

		@SuppressWarnings('PMD.ExcessiveParameterList')
		public ContactDetailRequestWrapper(String caseNumber, String clientCode, String phoneNum, String emailAddr) {
			this.TRANS_NO = caseNumber;
			this.service = new service(clientCode, phoneNum, emailAddr);
		}
	}

	@SuppressWarnings('PMD.VariableNamingConventions,PMD.FieldNamingConventions')
	public class service {
		public string source { get; set; }
		public string strClientId { get; set; }
		public string strBusiness { get; set; }
		public string strCellularPhone { get; set; }
		public string strEmail { get; set; }
		public string strPager { get; set; }
		public string strResidence { get; set; }

		@SuppressWarnings('PMD.ExcessiveParameterList')
		public service(String clientCode, String phoneNum, String emailAddr) {
			this.source = ABSLI_Constants.ESB_SOURCE_ID;
			this.strClientId = clientCode;
			this.strBusiness = '';
			this.strCellularPhone = phoneNum;
			this.strEmail = emailAddr;
			this.strPager = '';
			this.strResidence = '';//Thane
		}
	}

	/**
	 * @description Contact Detail Update Wrapper Class to follow through Response Body JSON
	 */
	@SuppressWarnings('PMD.VariableNamingConventions,PMD.FieldNamingConventions')
	public class ContactDetailResponseWrapper {
		public String TRANS_NO { get; set; }
		public String ProcessMessage { get; set; }
		public String ProcessCode { get; set; }
		public String FaultCode { get; set; }
		public String FaultMessage { get; set; }
	}
}