public with sharing class ABSLI_EscalatedIGMSComplaintIntegration implements ASF_IntegrationInvocable{

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
            result.status = ABSLI_Constants.SUCCESS;
            result.response = ABSLI_Constants.EVALUATION_SUCCESS;            
            /*if (caseRecord.ABSLI_Case_Detail__r.Resolved_Date__c == null)
            {
                result.status = ABSLI_Constants.ERROR;
                String evaluationErrorMetadataName = ABSLI_Constants.IGMS_ESCALATECOMPLAINT_EVAL_ERROR;
                result.response = Custom_Messages__mdt.getInstance(evaluationErrorMetadataName).Message__c;
            }*/

            if(caseRecord.ABSLI_Case_Detail__r.IGMS_Complaint_Status__c == '6'){
                result.status = ABSLI_Constants.ERROR;
                result.response = 'Escalate To IGMS is not possible for an Escalated Case';
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
        Map<String,List<Case>> mIGMSStatusRelatedCases = new Map<String,List<Case>>();
        mIGMSStatusRelatedCases.put('ESC', new List<Case>());
        mIGMSStatusRelatedCases.put('REOP', new List<Case>());
		Map<Id, String> caseStageMap = new Map<Id, String>();
        
        List<Case> caseRecords = new List<Case>();
        for (Case caseRec : caseRecs) {
            Case queriedCase = ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id);
            caseRecords.add(queriedCase);
            if(queriedCase.ABSLI_Case_Detail__r.IGMS_Complaint_Status__c == '4')
            {
                mIGMSStatusRelatedCases.get('ESC').add(queriedCase);
            }
            else if(queriedCase.ABSLI_Case_Detail__r.IGMS_Complaint_Status__c == '5')
            {
                mIGMSStatusRelatedCases.get('REOP').add(queriedCase);
            }
            caseStageMap.put(caseRec.Id, caseRec.Stage__c);
        }
        
        
        Map<Id, ASF_CaseMovementHelper.CaseAdditionalData> dataWrapper = ASF_CaseMovementHelper.getCaseAdditionalDataForNextStage(caseRecs, caseStageMap,null);
        Map<Id, List<ASF_Integration__c>> runIntegrationMap = new Map<Id, List<ASF_Integration__c>>();
        for(Id caseId : dataWrapper.keySet()){
            if(!runIntegrationMap.containsKey(caseId)){
                runIntegrationMap.put(caseId, new List<ASF_Integration__c>());
            }
            if(runIntegrationMap.containsKey(caseId) && dataWrapper.containsKey(caseId) && dataWrapper.get(caseId).allIntegrations != null){
                runIntegrationMap.get(caseId).addAll(dataWrapper.get(caseId).allIntegrations);
            }
        }
        
        if(mIGMSStatusRelatedCases.get('ESC').size()>0)
        {
            ABSLI_IGMSIntegrationHelper.createEscalatedComplaintRequest(mIGMSStatusRelatedCases.get('ESC'),runIntegrationMap,resultMap);
        }
        if(mIGMSStatusRelatedCases.get('REOP').size()>0)
        {
            ABSLI_IGMSIntegrationHelper.createReopenedComplaintRequest(mIGMSStatusRelatedCases.get('REOP'),runIntegrationMap,resultMap);
        }

        system.debug('resultMap---->'+resultMap);
        return resultMap;
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
                
                EscalationComplaintResponseWrapper jsonMap = (EscalationComplaintResponseWrapper) JSON.deserialize(
                    caseInteg.Response__c,
                    EscalationComplaintResponseWrapper.class
                );
                List<sObject> dmlRecords = new List<sObject>();
                if (jsonMap.ReturnCode == ABSLI_Constants.IGMS_ESCALATEDCOMPLAINT_SUCCESS_RET_CD) {
                    if(caseRecord.ABSLI_Case_Detail__c != null){
                        ABSLI_Case_Detail__c caseExt = new ABSLI_Case_Detail__c(Id = caseRecord.ABSLI_Case_Detail__c);
                        caseExt.IRDAI_Token_Number__c = jsonMap.IRDA_TOKEN_NUMBER;
                        caseExt.Escalated_Date__c = System.Today();
                        caseExt.IGMS_Complaint_Status__c = '5';
                        caseExt.Next_Integration_Name__c = ABSLI_Constants.IGMS_REOPENEDCOMLPAINT_NEXT_INT;
                        dmlRecords.add(caseExt);
                        
                        Database.SaveResult[] results = Database.update(dmlRecords, true);
                        
                        Map<Id, String> caseStageMap = new Map<Id, String>();
                        List<Case> eligibleRecords = new List<Case>();
                        eligibleRecords.add(caseRecord);
                        caseStageMap.put(caseRecord.Id, caseRecord.Stage__c);
                        Map<Id, ASF_CaseMovementHelper.CaseAdditionalData> dataWrapper = ASF_CaseMovementHelper.getCaseAdditionalDataForNextStage(eligibleRecords, caseStageMap,null);
                        Map<Id, ASF_Integration__c> runIntegrationMap = new Map<Id, ASF_Integration__c>();
                        for(ASF_Integration__c intRec : dataWrapper.get(caseRecord.Id).allIntegrations){
                            if(intRec.Processing_Class__c == ABSLI_Constants.IGMS_REOPENEDCOMLPAINT_NEXT_INT){
                                runIntegrationMap.put(caseRecord.Id, intRec);
                            }
                        }
                        
                        ASF_IntegrationsController.runIntegration(runIntegrationMap.get(caseRecord.Id),caseRecord);
                    }
                    
                }
            }
        } catch (Exception e) {
            System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABSLI_EscalatedIGMSComplaintIntegration.processResponse');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
        }
    }

    /**
    * @description IGMS Escalate Case Wrapper Class to build Integration Request Body JSON
    */
    @SuppressWarnings('PMD.VariableNamingConventions,PMD.FieldNamingConventions')
    public class objReq {
        public string Status_Change_Date { get; set; }
        public string IRDAI_Token_Number { get; set; }
        public string IRDA_Token_Number {get;set;}
        public string Entity_Complaint_Ref_Number {get;set;}
        public string Complaint_Status_Id {get;set;}
        public string Escalated_Remark{get;set;}
        public string Escalated_Date{get;set;}
        public String Addressed_To_Insurer { get; set; }
        public String Trans_Login_Id { get; set; }
        public string Option{get;set;}
        public string Mode{get;set;}
        
        @SuppressWarnings('PMD.ExcessiveParameterList')
        public objReq() {
            this.Complaint_Status_Id = '5';
            this.Status_Change_Date = ABCL_IntegrationCommonUtility.dateFormat(System.today(), 'dd-MM-YYYY');
            this.Escalated_Date = ABCL_IntegrationCommonUtility.dateFormat(System.today(), 'dd-MM-YYYY');
            this.Addressed_To_Insurer = ABSLI_Constants.ABSLI_IGMS_ADDRESS_TO_INSURER_Y;
            this.Trans_Login_Id = ABSLI_Constants.ABSLI_IGMS_TRANS_LOGIN_ID;
            this.Option = ABSLI_Constants.ABSLI_IGMS_OPTION;
            this.Mode = ABSLI_Constants.ABSLI_IGMS_MODE_UPDATE;
        }
    }
    /**
    @description IGMS Escalate Case Class to follow through Response Body JSON
    */
    @SuppressWarnings('PMD.VariableNamingConventions,PMD.FieldNamingConventions')
    public class EscalationComplaintResponseWrapper {
        public String ReturnMessage { get; set; }
        public String ReturnCode { get; set; }
        public String IRDA_TOKEN_NUMBER { get; set; }
        public String ENTITY_COMPLAINT_REF_NUMBER { get; set; }
    }
}