/**
 * @description Outbound Callout to Update Bank Account Deatils of Customer
 *  Service Agent to manually invoke STP by clicking on the Bank Account Update Integration Button
 *  Customer Portal to create Cases by API. On Successful response, case to be marked as Closed
 *
 * @author Abinash Panigrahi
 * @date 2024-05-28
 */
public with sharing class ABSLI_BankAccountUpdateIntegration implements ASF_IntegrationInvocable {

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
					ABSLI_Constants.BANKACCOUNTUPDATE_EVALUATION_ERROR
				)
				.Message__c;
			
            //Customer Portal and Status_Valid_For_STP__c is false 
            if(ABSLI_Constants.STP_SOURCES.contains(caseRecord.Source__c) && caseRecord.ABSLI_Case_Detail__r.Status_Valid_For_STP__c == false){
            	result.status = ABSLI_Constants.ERROR;
            	result.response = Custom_Messages__mdt.getInstance('ABSLI_CustomerPortal_STPFalse_Err').Message__c;
            }else{
            	if (caseRecord.ABSLI_Case_Detail__r.Status_Valid_For_STP__c && caseRecord.Technical_Source__c == 'API') {
                    result.status = ABSLI_Constants.SUCCESS;
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
			string requestBody = JSON.serialize(
				new BAURequestWrapper(
					caseRecord.CaseNumber,
					caseRecord.LAN__c == null ? caseRecord.Asset?.Policy_No__c : caseRecord.LAN__c,
					caseRecord.ABSLI_Case_Detail__r?.IFSC_Code__c,
					caseRecord.ABSLI_Case_Detail__r?.Account_Number__c,
					caseRecord.ABSLI_Case_Detail__r?.Account_Type__c,
					ABCL_IntegrationCommonUtility.dateFormat(caseRecord.ABSLI_Case_Detail__r?.Bank_IMPS_Date__c, 'dd-MM-YYYY'),
					caseRecord.ABSLI_Case_Detail__r?.Bank_Account_Holder_Name__c
				)
			);
			for (ASF_Integration__c intSpec : integs.get(caseRecord.Id)) {
				if (intSpec.Processing_Class__c == ABSLI_BankAccountUpdateIntegration.class.getName()) {
					ASF_Case_Integration__c caseInteg = new ASF_Case_Integration__c();
					caseInteg.Integration_Ext_Id__c = intSpec.External_Id__c;
					caseInteg.Case__c = caseRecord.Id;
					caseInteg.Status__c = ABSLI_Constants.PENDING;
					caseInteg.Request__c = requestBody;
					caseInteg.Response__c = ABSLI_Constants.WAITING_API_RESPONSE;
                    caseInteg.Is_Validation_Success__c = true;
                    caseInteg.Do_Not_Retry_Integration__c = intSpec.Do_Not_Retry_Integration__c;
					newCaseIntegrations.add(caseInteg);

					Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e();
					caseIntOut.Business_Unit__c = caseRecord.Business_Unit__c;
					caseIntOut.Request_Payload__c = requestBody;
					caseIntOut.Integration_Name__c = ABSLI_Constants.BANKACCOUNTUPDATE_SERVICE_NAME;
					caseIntOut.ServiceName__c = ABSLI_Constants.BANKACCOUNTUPDATE_SERVICE_NAME;
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
				wrap.response = Custom_Messages__mdt.getInstance(ABSLI_Constants.BANKACCOUNTUPDATE_SUCCESS_MESSAGE)
					.Message__c;
				resultMap.put(indexToCaseId.values()[index], wrap);
			} else {
				ASF_IntegrationsController.IntegrationWrapper wrap = new ASF_IntegrationsController.IntegrationWrapper();
				wrap.status = ABSLI_Constants.ERROR;
				wrap.response = Custom_Messages__mdt.getInstance(ABSLI_Constants.BANKACCOUNTUPDATE_FAILURE_MESSAGE)
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
				if (integ.Processing_Class__c == ABSLI_BankAccountUpdateIntegration.class.getName()) {
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

				BAUResponseWrapper jsonMap = (BAUResponseWrapper) JSON.deserialize(
					caseInteg.Response__c,
					BAUResponseWrapper.class
				);

				if (jsonMap.LSIR_RETURN_CD == '00') {
                    caseRecord.MoveToNext__c = true;
				    Database.update(caseRecord, AccessLevel.SYSTEM_MODE);
				}
			}
		} catch (Exception e) {
			System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
			ABCL_Logger.enableExceptionLogging();
			ABCL_Logger.push('ABSLI_BankAccountUpdateIntegration.processResponse');
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
	 * @description Policy Account Statement (PAS) Wrapper Class to build Integration Request Body JSON
	 */
	@SuppressWarnings('PMD.VariableNamingConventions,PMD.FieldNamingConventions,PMD.PropertyNamingConventions')
	public class BAURequestWrapper {
		public string TRANS_NO { get; set; }
		public service service { get; set; }

		@SuppressWarnings('PMD.ExcessiveParameterList')
		public BAURequestWrapper(
			String caseNumber,
			String policyNumber,
			String ifscCode,
			String accountNumber,
			String accountType,
			String bankIMPSDate,
			String bankAccountHolderName
		) {
			this.TRANS_NO = caseNumber;
			this.service = new service(
				policyNumber,
				ifscCode,
				accountNumber,
				accountType,
				bankIMPSDate,
				bankAccountHolderName
			);
		}
	}

	@SuppressWarnings('PMD.VariableNamingConventions,PMD.FieldNamingConventions,PMD.PropertyNamingConventions')
	public class service {
		public string source { get; set; }
		public string polId { get; set; }
		public string ifsc_code { get; set; }
		public string acc_no { get; set; }
		public string acc_type { get; set; }
		public string micr_code { get; set; }
		public string trantype { get; set; }
		public string IMPS_Flag { get; set; }
		public string IMPS_Date { get; set; }
		public string Account_Holder_Name { get; set; }
		public string IMPS_Status_Code { get; set; }
		public string IMPS_Status_Desc { get; set; }

		@SuppressWarnings('PMD.ExcessiveParameterList')
		public service(
			String policyNumber,
			String ifscCode,
			String accountNumber,
			String accountType,
			String bankIMPSDate,
			String bankAccountHolderName
		) {
			this.source = ABSLI_Constants.ESB_SOURCE_ID;
			this.polId = policyNumber;
			this.ifsc_code = ifscCode;
			this.acc_no = accountNumber;
			this.acc_type = accountType;
			this.micr_code = ABSLI_Constants.BANKACCOUNTUPDATE_MICR_CODE;
			this.trantype = ABSLI_Constants.BANKACCOUNTUPDATE_TRANSTYPE;
			this.IMPS_Flag = ABSLI_Constants.BANKACCOUNTUPDATE_IMPSFLAG;
			this.IMPS_Date = bankIMPSDate;
			this.Account_Holder_Name = bankAccountHolderName;
			this.IMPS_Status_Code = ABSLI_Constants.BANKACCOUNTUPDATE_IMPS_STATUSCODE;
			this.IMPS_Status_Desc = ABSLI_Constants.BANKACCOUNTUPDATE_IMPS_STATUSDESC;
		}
	}

	/**
	 * @description Policy Account Statement (PAS) Wrapper Class to follow through Response Body JSON
	 */
	@SuppressWarnings('PMD.VariableNamingConventions,PMD.FieldNamingConventions,PMD.PropertyNamingConventions')
	public class BAUResponseWrapper {
		public String LSIR_RETURN_CD { get; set; }
		public String MIR_NEFT_IFSC_CD { get; set; }
		public String MIR_NEFT_IFSC_CD_UP { get; set; }
		public String MIR_RETRN_CD { get; set; }
		public String Page { get; set; }
		public String MIR_NEFT_ACCT_NUM_UP { get; set; }
		public String MIR_NEFT_ACCT_TYP_CD { get; set; }
		public String MIR_NEFT_BNK_MICR_CD_UP { get; set; }
		public String MIR_IMPS_FLAG { get; set; }
		public String MIR_IMPS_DATE { get; set; }
		public String MESSAGES { get; set; }
		public String ProcessMessage { get; set; }
		public String MIR_ACC_HLDR_NM { get; set; }
		public String MIR_IMPS_STATUS_CODE { get; set; }
		public String MIR_IFSC_SEQ_NUM { get; set; }
		public String TRANS_NO { get; set; }
		public String ProcessCode { get; set; }
		public String MIR_NEFT_BNK_MICR_CD { get; set; }
		public String MIR_NO_OF_IFSC_REC { get; set; }
		public String MIR_NEFT_ACCT_TYP_CD_UP { get; set; }
		public String MIR_IMPS_ACC_HLDR_NM { get; set; }
		public String MIR_NEFT_BNK_BR_NM { get; set; }
		public String MIR_NEFT_BNK_NM { get; set; }
		public String MIR_NEFT_ACCT_NUM { get; set; }
		public String MIR_IMPS_STATUS_DES { get; set; }
	}
}