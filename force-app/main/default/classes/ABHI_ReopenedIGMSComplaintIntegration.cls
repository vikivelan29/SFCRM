public with sharing class ABHI_ReopenedIGMSComplaintIntegration  implements ASF_IntegrationInvocable{
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

    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs) {
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        
        List<Case> caseRecords = new List<Case>();
        for (Case caseRec : caseRecs) {
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
        }
        
        for (Case caseRecord : caseRecords) {
            ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
            
            result.status = ABSLI_Constants.ERROR;
            String evaluationErrorMetadataName = ABSLI_Constants.IGMS_REOPENEDCOMPLAINT_EVAL_ERROR;
            
            result.response = Custom_Messages__mdt.getInstance(evaluationErrorMetadataName).Message__c;
            
            if (caseRecord.ABHI_Case_Detail__r.Escalated_Date__c != null )
//&& caseRecord.Technical_Source__c == 'LWC')
            {
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
            objReq requestJSON = new objReq();
            
            /* ALL REQUIRED ATTRIBUTES HERE */
            requestJSON.Entity_Complaint_Ref_Number = 'ABHI'+caseRecord.CaseNumber;
            requestJSON.IRDAI_Token_Number = caseRecord.IRDAI_Token_Number__c;
            requestJSON.IRDA_Token_Number = caseRecord.IRDAI_Token_Number__c;

            string requestBody = JSON.serialize(requestJSON);
            
            for (ASF_Integration__c intSpec : integs.get(caseRecord.Id)) {
                System.debug('intSpec.Processing_Class__c --> '+intSpec.Processing_Class__c);
                if (intSpec.Processing_Class__c == ABHI_ReopenedIGMSComplaintIntegration.class.getName()) {
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
                    caseIntOut.Integration_Name__c = ABSLI_Constants.IGMS_UPDATECOMPLAINT_SRV_NAME;
                    caseIntOut.ServiceName__c = ABSLI_Constants.IGMS_UPDATECOMPLAINT_SRV_NAME;
                    peMap.put(index, caseIntOut);
                    indexToCaseId.put(index, caseRecord.Id);
                    index++;
                }
                
            }
        }
        
        System.debug(peMap);
        
        index = 0;
        if(newCaseIntegrations.size()>0){
            List<Database.SaveResult> results = Database.insert(newCaseIntegrations, false, AccessLevel.SYSTEM_MODE);
            Map<Id, ASF_Case_Integration__c> caseIntegrations = new Map<Id, ASF_Case_Integration__c>(
                ABHI_IntegrationQueryHelper.getCaseIntegrations(newCaseIntegrations)
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
                    wrap.response = Custom_Messages__mdt.getInstance(ABSLI_Constants.ABSLI_IGMSSYNC_SUCCESS_MESSAGE)
                        .Message__c;
                    resultMap.put(indexToCaseId.values()[index], wrap);
                } else {
                    ASF_IntegrationsController.IntegrationWrapper wrap = new ASF_IntegrationsController.IntegrationWrapper();
                    wrap.status = ABSLI_Constants.ERROR;
                    wrap.response = Custom_Messages__mdt.getInstance(ABSLI_Constants.ABSLI_IGMSSYNC_FAILURE_MESSAGE)
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
                if (integ.Processing_Class__c == ABHI_ReopenedIGMSComplaintIntegration.class.getName()) {
                    intIds.add(integ.External_Id__c);
                }
            }
        }
        
        List<ASF_Case_Integration__c> existingCaseIntegrations = new List<ASF_Case_Integration__c>();
        for (ASF_Case_Integration__c caseInt : ABHI_IntegrationQueryHelper.getCaseIntegrations1(caseRecs, intIds)) {
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
                Case caseRecord = ABHI_IntegrationQueryHelper.getCaseInfo(caseInteg.Case__c);
                
                 ABHI_AckIGMSComplaintIntegration.UpdateComplaintResponseWrapper jsonMap = (ABHI_AckIGMSComplaintIntegration.UpdateComplaintResponseWrapper) JSON.deserialize(
                    caseInteg.Response__c,
                    ABHI_AckIGMSComplaintIntegration.UpdateComplaintResponseWrapper.class
                );
                List<sObject> dmlRecords = new List<sObject>();
                String errorCodes = jsonMap.Body.UpdateComplaintResponse.UpdateComplaintResult.RESULT.COMPLAINTDETAILS.ERROR_CODES;
                String irdaTokenNumber = jsonMap.Body.UpdateComplaintResponse.UpdateComplaintResult.RESULT.COMPLAINTDETAILS.IRDA_TOKEN_NUMBER;
                System.debug('irdaTokenNumberAS '+irdaTokenNumber);
               if (String.isEmpty(errorCodes) && (!String.isEmpty(irdaTokenNumber))) {
                    System.debug('irdaTokenNumberAS '+irdaTokenNumber);
                    if(caseRecord.ABHI_Case_Detail__c != null){
                        ABHI_Case_Detail__c  caseExt = new ABHI_Case_Detail__c (Id = caseRecord.ABHI_Case_Detail__c );
                        caseExt.IRDAI_Token_Number__c = irdaTokenNumber;
                        caseExt.Reopened_Date__c = System.Today();
                        caseExt.IGMS_Complaint_Status__c = '6';
                        dmlRecords.add(caseExt);
                    }
                    Database.SaveResult[] results = Database.update(dmlRecords, true);
                }
            }
        } catch (Exception e) {
            System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABHI_ReopenedIGMSComplaintIntegration.processResponse');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
        }
    }
    /**
    * @description IGMS Reopened Case Wrapper Class to build Integration Request Body JSON
    */
    @SuppressWarnings('PMD.VariableNamingConventions,PMD.FieldNamingConventions')
    public class objReq {
        public string Status_Change_Date { get; set; }
        public string IRDAI_Token_Number { get; set; }
        public string IRDA_Token_Number {get;set;}
        public string Entity_Complaint_Ref_Number {get;set;}
        public string Complaint_Status_Id {get;set;}
        public String Addressed_To_Insurer { get; set; }
        public String Trans_Login_Id { get; set; }
        public string Option{get;set;}
        public string Mode{get;set;}
        
        @SuppressWarnings('PMD.ExcessiveParameterList')
        public objReq() {
            this.Complaint_Status_Id = '6';
            this.Status_Change_Date = ABCL_IntegrationCommonUtility.dateFormat(System.today(), 'dd-MM-YYYY');
            this.Addressed_To_Insurer = ABSLI_Constants.ABSLI_IGMS_ADDRESS_TO_INSURER_Y;
            this.Trans_Login_Id = 'ABHICADMIN1';
            this.Option = ABSLI_Constants.ABSLI_IGMS_OPTION;
            this.Mode = ABSLI_Constants.ABSLI_IGMS_MODE_UPDATE;
        }
    }
    /**
    @description IGMS Reopened Case Class to follow through Response Body JSON
    */
   /* @SuppressWarnings('PMD.VariableNamingConventions,PMD.FieldNamingConventions')
    public class ReopenedComplaintResponseWrapper {
        public String ReturnMessage { get; set; }
        public String ReturnCode { get; set; }
        public String IRDA_TOKEN_NUMBER { get; set; }
        public String ENTITY_COMPLAINT_REF_NUMBER { get; set; }
    }*/
}