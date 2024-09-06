public with sharing class ABHI_PendingIGMSComplaintIntegration implements ASF_IntegrationInvocable{
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs) {
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        
        List<Case> caseRecords = new List<Case>();
        for (Case caseRec : caseRecs) {
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
        }
        
        for (Case caseRecord : caseRecords) {
            ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
            
            result.status = ABSLI_Constants.ERROR;
            String evaluationErrorMetadataName = ABSLI_Constants.IGMS_REGCOMPLAINT_EVAL_ERROR;
            
            result.response = Custom_Messages__mdt.getInstance(evaluationErrorMetadataName).Message__c;
            
            // VALIDATION TO HAPPEN HERE
            // 1. CHECK IF THE NEXT INTEGRATION NAME IS EQUALS TO THIS CLASS NAME.
            
            // 2. Check if IRDAI Token Number is NULL. 
            if (caseRecord.ABHI_Case_Detail__r.Next_Integration_Name__c == ABHI_PendingIGMSComplaintIntegration.class.getName()
                && caseRecord.ABHI_Case_Detail__r.Acknowledged_Date__c != null 
                && caseRecord.ABHI_Case_Detail__r.IGMS_Complaint_Status__c == '2')
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
* @param caseIntegs - List of ASF_Integration record
* @param caseRecs - List of Case record from the framework
* @return Map<Id, ASF_IntegrationsController.IntegrationWrapper>
*/
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> run(
        Map<Id, List<ASF_Integration__c>> integs,
        List<Case> caseRecs
    ) {
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        
        List<Case> caseRecords = new List<Case>();
        for (Case caseRec : caseRecs) {
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
        }
        
        ABHI_IGMSIntegrationHelper.createPendingComplaintRequest(caseRecords,integs,resultMap);
        
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
                if (integ.Processing_Class__c == ABHI_PendingIGMSComplaintIntegration.class.getName()) {
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
                Case caseRecord = ABHI_IntegrationQueryHelper.getCaseInfo(caseInteg.Case__c);
                
                PendingComplaintResponseWrapper jsonMap = (PendingComplaintResponseWrapper) JSON.deserialize(
                    caseInteg.Response__c,
                    PendingComplaintResponseWrapper.class
                );
                List<sObject> dmlRecords = new List<sObject>();
                if (jsonMap.ReturnCode == ABSLI_Constants.IGMS_ACKCOMPLAINT_SUCCESS_RET_CD) {
                    if(caseRecord.ABHI_Case_Detail__c != null){
                        ABHI_Case_Detail__c caseExt = new ABHI_Case_Detail__c(Id = caseRecord.ABHI_Case_Detail__c);
                        caseExt.IRDAI_Token_Number__c = jsonMap.IRDA_TOKEN_NUMBER;
                        caseExt.Pending_Date__c = System.Today();
                        caseExt.IGMS_Complaint_Status__c = '3';
                        dmlRecords.add(caseExt);
                        caseRecord.MoveToNext__c = true;
                        dmlRecords.add(caseRecord);
                        Database.SaveResult[] results = Database.update(dmlRecords, true);
                    }
                    
                }
            }
        } catch (Exception e) {
            System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABHI_PendingIGMSComplaintIntegration.processResponse');
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
        
        @SuppressWarnings('PMD.ExcessiveParameterList')
        public objReq() {
            this.Complaint_Status_Id = '3';
            this.Status_Change_Date = ABCL_IntegrationCommonUtility.dateFormat(System.today(), 'dd-MM-YYYY');
            this.Option = ABSLI_Constants.ABSLI_IGMS_OPTION;
            this.Mode = ABSLI_Constants.ABSLI_IGMS_MODE_UPDATE;
            this.Addressed_To_Insurer = ABSLI_Constants.ABSLI_IGMS_ADDRESS_TO_INSURER_Y;
            this.Trans_Login_Id = 'abhiadmin';
             this.Ack_Officer_Designation= '';
            this.Ack_Officer_Name= 'SM';
            this.BOC_Or_Collection_Number= '';
            this.Branch_Code= 'MU01';
            this.Cheque_Number= '';
            this.Claim_Clsr_Additional_Info= '';
            this.Claim_Received_Amount= '';
            this.Claim_Requested_Amount= '';
            this.Is_Complainant_Informed= '';
            this.Others_Clsr_Additional_Info= '';
            this.Request_IRDAI_For_Closure = '';
        }
    }
    /**
* @description Contact Detail Update Wrapper Class to follow through Response Body JSON
*/
    @SuppressWarnings('PMD.VariableNamingConventions,PMD.FieldNamingConventions')
    public class PendingComplaintResponseWrapper {
        public String ReturnMessage { get; set; }
        public String ReturnCode { get; set; }
        public String IRDA_TOKEN_NUMBER { get; set; }
        public String ENTITY_COMPLAINT_REF_NUMBER { get; set; }
    }
}