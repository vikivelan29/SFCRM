/**
* @description Outbound Callout to Surrender Policy of a Customer
*
* @author Siddarth Jaitly
* @date 2024-08-09
*/
public with sharing class ABSLI_SurrenderPolicyIntegration implements ASF_IntegrationInvocable{
    /**
    * @description Invoked from the ASF_IntegrationsController class, this method evaluates whether integration should be fired or not
    *
    * @param caseRecs - List of Case record from the framework
    * @return Map<Id, ASF_IntegrationsController.IntegrationWrapper>
    */
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs) {
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        
        List<Case> caseRecords = new List<Case>();
        Set<Id> caseIds = new Set<Id>();
        for (Case caseRec : caseRecs) {
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
            caseIds.add(caseRec.Id);
        }

        Map<Id,Boolean> caseSignatureMatchedMap = new Map<Id,Boolean>();
        List<ASF_Checklist__c> checklistRecords = [SELECT Id, Description__c, Label__c,Case__c, Status__c FROM ASF_Checklist__c where case__c in: caseIds and Status__c =: ABSLI_Constants.CHECKLIST_SIGNATURE_MATCHED];
        for(ASF_Checklist__c checklist : checklistRecords){
            caseSignatureMatchedMap.put(checklist.Case__c,true);
        }
        
        for (Case caseRecord : caseRecords) {
            ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
            
            result.status = ABSLI_Constants.ERROR;
            String evaluationErrorMetadataName = ABSLI_Constants.ABSLI_SIGNATURE_NOT_MATCHING_ERROR;
            result.response = Custom_Messages__mdt.getInstance(evaluationErrorMetadataName).Message__c;

            /*if (caseRecord.ABSLI_Case_Detail__r.TDS_Indicator__c == 'Y' && String.isBlank(caseRecord.Account.PAN__c)) 
            {
                if(caseSignatureMatchedMap.containsKey(caseRecord.Id) && caseSignatureMatchedMap.get(caseRecord.Id)) {
                    result.status = ABSLI_Constants.SUCCESS;
                    result.response = ABSLI_Constants.EVALUATION_SUCCESS;
                } else {
                    evaluationErrorMetadataName = ABSLI_Constants.ABSLI_SIGNATURE_NOT_MATCHING_ERROR;
                    result.response = Custom_Messages__mdt.getInstance(evaluationErrorMetadataName).Message__c;
                }
            }*/
			//Customer Portal and Status_Valid_For_STP__c is false 
            if(ABSLI_Constants.STP_SOURCES.contains(caseRecord.Source__c) && caseRecord.ABSLI_Case_Detail__r.Status_Valid_For_STP__c == false){
            	result.status = ABSLI_Constants.ERROR;
            	result.response = Custom_Messages__mdt.getInstance('ABSLI_CustomerPortal_STPFalse_Err').Message__c;
            }else{
             	if(caseRecord.Technical_Source__c == 'LWC' && caseSignatureMatchedMap.containsKey(caseRecord.Id) && caseSignatureMatchedMap.get(caseRecord.Id)) {
                    result.status = ABSLI_Constants.SUCCESS;
                    result.response = ABSLI_Constants.EVALUATION_SUCCESS;
                }  
                if(caseRecord.Technical_Source__c == 'API'){
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
            SurrenderPolicyRequestBody requestJSON = new SurrenderPolicyRequestBody();
            requestJSON.TransNo = caseRecord.caseNumber;
            requestJSON.PolicyID = caseRecord.Asset.Policy_No__c;
            requestJSON.EffectiveDt = String.valueOf(ABCL_IntegrationCommonUtility.dateFormat(System.today(), 'dd-MM-YYYY'));
            requestJSON.IFSC_Code = caseRecord.ABSLI_Case_Detail__r.IFSC_Code__c;
            requestJSON.MICR_Code = ABSLI_Constants.BANKACCOUNTUPDATE_MICR_CODE;
            requestJSON.BankAccountNo = caseRecord.ABSLI_Case_Detail__r.Account_Number__c;
            requestJSON.BankName = caseRecord.ABSLI_Case_Detail__r.Bank_Name__c;
            requestJSON.BankBranchName = caseRecord.ABSLI_Case_Detail__r.Branch_Name__c;
            requestJSON.UserBranchName = ABSLI_Constants.SURRENDER_WITHDRAWAL_USER_BRANCH_NAME;
            requestJSON.UserBranchCode = ABSLI_Constants.SURRENDER_WITHDRAWAL_USER_BRANCH_CODE;
            requestJSON.Zone = caseRecord.Asset.Zone__c;
            requestJSON.TranType = ABSLI_Constants.TRANSACTION_TYPE_NEFT;
            requestJSON.SignatureVerificationbyBranch = 'Y';
            requestJSON.SignatureVerificationbyBackoffice = 'Y';
            requestJSON.BankAccountType = caseRecord.ABSLI_Case_Detail__r.Account_Type__c;
            requestJSON.action = ABSLI_Constants.ACTION_SURRENDER;
            requestJSON.FT_Amount_BR = '0';
            requestJSON.TDS_Ind = caseRecord.ABSLI_Case_Detail__r.TDS_Indicator__c == 'Y'?'true':'false';
            String surrenderAmount = '0';
            if(caseRecord.ABSLI_Case_Detail__r.Cash_Surrender_Value__c != null){
                surrenderAmount = String.valueOf(caseRecord.ABSLI_Case_Detail__r.Cash_Surrender_Value__c.round());
            }
            requestJSON.surrenderamount = surrenderAmount;

            string requestBody = JSON.serialize(requestJSON);
            for (ASF_Integration__c intSpec : integs.get(caseRecord.Id)) {
                    if(intSpec.Processing_Class__c == ABSLI_SurrenderPolicyIntegration.class.getName()){
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
                    caseIntOut.Integration_Name__c = ABSLI_Constants.SURRENDER_POLICY_SRV_NAME;
                    caseIntOut.ServiceName__c = ABSLI_Constants.SURRENDER_POLICY_SRV_NAME;
                    peMap.put(index, caseIntOut);
                    indexToCaseId.put(index, caseRecord.Id);
                    index++;
                }
            }
        }
            
        index = 0;
        if(newCaseIntegrations.size()>0){
            List<Database.SaveResult> results = Database.insert(newCaseIntegrations, false, AccessLevel.SYSTEM_MODE);
            Map<Id, ASF_Case_Integration__c> caseIntegrations = new Map<Id, ASF_Case_Integration__c>(
                ABSLI_IntegrationQueryHelper.getCaseIntegrations(newCaseIntegrations)
            );
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {
                    Case_Integration_Outbound__e caseIntOut = peMap.get(index);
                    System.debug('caseIntegrations --> '+caseIntegrations.get(sr.getId()).Name + ' caseIntOut --> '+caseIntOut);
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
                if (integ.Processing_Class__c == ABSLI_SurrenderPolicyIntegration.class.getName()) {
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
                        caseInt.Status__c == ABSLI_Constants.PENDING || caseInt.Status__c == ABSLI_Constants.FAILURE
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
                List<sObject> dmlRecords = new List<sObject>();
                if(caseRecord.ABSLI_Case_Detail__c != null){
                    ABSLI_Case_Detail__c caseExt = new ABSLI_Case_Detail__c(Id = caseRecord.ABSLI_Case_Detail__c);
                    caseExt.Is_Surrender_Withdrawal_Successful__c = true;
                    dmlRecords.add(caseExt);
                    Database.SaveResult[] results = Database.update(dmlRecords, true);
                }
            }
        } catch (Exception e) {
            System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABSLI_AttendEscIGMSComplaintIntegration.processResponse');
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

    public class SurrenderPolicyRequestBody{
        public String TransNo;
        public String policyid;
        public String effectivedt;
        public String ifsc_code;
        public String micr_code;
        public String bankaccountno;
        public String bankname;
        public String bankbranchname;
        public String userbranchname;
        public String userbranchcode;
        public String zone;
        public String trantype;
        public String signatureverificationbybranch;
        public String signatureverificationbybackoffice;
        public String bankaccounttype;
        public String action;
        public String FT_Amount_BR;
        public String TDS_Ind;
        public String surrenderamount;
    }
    
}