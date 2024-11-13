public with sharing class ABHI_EscalatedIGMSComplaintIntegration implements ASF_IntegrationInvocable{

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
            System.debug('comlaintstatus'+caseRecord.ABHI_Case_Detail__r.IGMS_Complaint_Status__c);
         	ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
            result.status = ABHI_Constants.SUCCESS;
            result.response = ABSLI_Constants.EVALUATION_SUCCESS;            
            if(caseRecord.ABHI_Case_Detail__r.IGMS_Complaint_Status__c == '6'){
                result.status = ABHI_Constants.ERROR;
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
            if(queriedCase.ABHI_Case_Detail__r.IGMS_Complaint_Status__c == '4')
            {
                mIGMSStatusRelatedCases.get('ESC').add(queriedCase);
            }
            else if(queriedCase.ABHI_Case_Detail__r.IGMS_Complaint_Status__c == '5')
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
            ABHI_IGMSIntegrationHelper.createEscalatedComplaintRequest(mIGMSStatusRelatedCases.get('ESC'),runIntegrationMap,resultMap);
        }
        if(mIGMSStatusRelatedCases.get('REOP').size()>0)
        {
            ABHI_IGMSIntegrationHelper.createReopenedComplaintRequest(mIGMSStatusRelatedCases.get('REOP'),runIntegrationMap,resultMap);
        }

        system.debug('resultMap---->'+resultMap);
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
                        caseExt.IGMS_Complaint_Status__c = '5';
                        caseExt.Escalated_Date__c =  System.Today();
                        caseExt.Next_Integration_Name__c = 'ABHI_ReopenedIGMSComplaintIntegration';
                        dmlRecords.add(caseExt);
                    }
                    Database.SaveResult[] results = Database.update(dmlRecords, true);
                   
                     Map<Id, String> caseStageMap = new Map<Id, String>();
                        List<Case> eligibleRecords = new List<Case>();
                        eligibleRecords.add(caseRecord);
                        caseStageMap.put(caseRecord.Id, caseRecord.Stage__c);
                        Map<Id, ASF_CaseMovementHelper.CaseAdditionalData> dataWrapper = ASF_CaseMovementHelper.getCaseAdditionalDataForNextStage(eligibleRecords, caseStageMap,null);
                        Map<Id, ASF_Integration__c> runIntegrationMap = new Map<Id, ASF_Integration__c>();
                        for(ASF_Integration__c intRec : dataWrapper.get(caseRecord.Id).allIntegrations){
                            if(intRec.Processing_Class__c == 'ABHI_ReopenedIGMSComplaintIntegration'){
                                runIntegrationMap.put(caseRecord.Id, intRec);
                            }
                        }
                     ASF_IntegrationsController.runIntegration(runIntegrationMap.get(caseRecord.Id),caseRecord);
                }
            }
        } catch (Exception e) {
            System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABHI_EscalatedIGMSComplaintIntegration.processResponse');
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
        public string Option{get;set;}
        public string Mode{get;set;}
        public String Addressed_To_Insurer { get; set; }
        public String Trans_Login_Id { get; set; }
        public string Ack_Officer_Designation{get;set;}                 
        public string Ack_Officer_Name{get;set;}                 
        public string BOC_Or_Collection_Number{get;set;}                 
        public string Branch_Code{get;set;}                 
        public string Cheque_Number{get;set;}                    
        public string Claim_Clsr_Additional_Info{get;set;}    
        public string Claim_Received_Amount{get;set;}                 
        public string Claim_Requested_Amount{get;set;}                 
        public string Is_Complainant_Informed{get;set;}                 
        public string Others_Clsr_Additional_Info{get;set;}                 
        public string Request_IRDAI_For_Closure{get;set;}   
        public string Final_Resolution_Remark{get;set;}
        public string Final_Resolution_Date{get;set;}
        public string Escalated_Remark{get;set;} 
        public string Escalated_Date{get;set;} 
        @SuppressWarnings('PMD.ExcessiveParameterList')
        public objReq() {
            this.Complaint_Status_Id = '5';
            this.Status_Change_Date = ABCL_IntegrationCommonUtility.dateFormat(System.today(), 'dd-MM-YYYY');
            this.Escalated_Date = ABCL_IntegrationCommonUtility.dateFormat(System.today(), 'dd-MM-YYYY');
            this.Option = ABSLI_Constants.ABSLI_IGMS_OPTION;
            this.Mode = ABSLI_Constants.ABSLI_IGMS_MODE_UPDATE;
            this.Addressed_To_Insurer = ABSLI_Constants.ABSLI_IGMS_ADDRESS_TO_INSURER_Y;
            this.Trans_Login_Id = 'ABHICADMIN1';
            this.Ack_Officer_Designation= '';
            this.Ack_Officer_Name= 'SM';
            this.BOC_Or_Collection_Number= '';
            //this.Branch_Code= 'MU01';
            this.Cheque_Number= '';
            this.Claim_Clsr_Additional_Info= '';
            this.Claim_Received_Amount= '';
            this.Claim_Requested_Amount= '';
            this.Is_Complainant_Informed= '';
            this.Others_Clsr_Additional_Info= '';
            this.Request_IRDAI_For_Closure = '';
        }
    }
}