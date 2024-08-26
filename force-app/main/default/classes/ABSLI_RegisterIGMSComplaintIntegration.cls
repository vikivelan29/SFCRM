/**
* @description Outbound Callout to IGMS to register Complaint on IRDAI Portal
*  
* @author Virendra Patil
* @date 2024-06-27
*/
public with sharing class ABSLI_RegisterIGMSComplaintIntegration implements ASF_IntegrationInvocable{
    
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs) {
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        
        List<Case> caseRecords = new List<Case>();
        for (Case caseRec : caseRecs) {
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
        }
        Map<String,Map<String,Set<String>>> mClassificationIGMS = ABSLI_IGMSClassificationUtility.getIGMSClassification();
        
        for (Case caseRecord : caseRecords) {
            ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
            
            result.status = ABSLI_Constants.ERROR;
            String evaluationErrorMetadataName = ABSLI_Constants.IGMS_REGCOMPLAINT_EVAL_ERROR;
            
            result.response = Custom_Messages__mdt.getInstance(evaluationErrorMetadataName).Message__c;
            
            // VALIDATION TO HAPPEN HERE
            // 1. CHECK IF Complaint Category = Complaint
            
            // 1. CHECK IF DESCRIPTION IS PRESENT
            // 2. CHECK IF IGMS TYPE OF POLICY IS SELECTED
            // 3. CHECK IF IGMS SOURCE OF COMPLAINT IS SELECTED
            String errorMessage = 'Required fields are missing : ';
            boolean bErrorOccured = false;
            if(caseRecord.Description == null || caseRecord.Description == ''){
                errorMessage += 'Description, ';
                bErrorOccured = true;
            }
            if(caseRecord.ABSLI_Case_Detail__r.IGMS_type_of_policy__c == null || 
               caseRecord.ABSLI_Case_Detail__r.IGMS_type_of_policy__c == '')
            {
                errorMessage +='IGMS type of policy, ';
                bErrorOccured = true;
            }
            if(caseRecord.ABSLI_Case_Detail__r.get('IGMS_Source_of_Complaint__c') == null || 
               caseRecord.ABSLI_Case_Detail__r.IGMS_Source_of_Complaint__c == '')
            {
                errorMessage +='IGMS Source of Complaint, ';
                bErrorOccured = true;
            }
            if((caseRecord.ABSLI_Case_Detail__r.get('Receipt_Number__c') == null || 
                caseRecord.ABSLI_Case_Detail__r.get('Receipt_Number__c') == '')
               && ABSLI_Constants.RECEIPT_NO_REQ_COMP_TYPE_CD.contains(caseRecord.IGMS_Complaint_Type_Code__c))
            {
                errorMessage +='Receipt Number, ';
                bErrorOccured = true;                
            }
            if(String.isBlank(caseRecord.Account?.PersonMobilePhone)){
                errorMessage = 'Customer Mobile Number is mandatory for IGMS Complaint Registration. Kindly reach out to your admin for further help., ';
                bErrorOccured = true;
            }
            if(String.isBlank(caseRecord.AssetId)  && String.isBlank(caseRecord.IRDAI_Token_Number__c)){
                errorMessage = 'IGMS Complaint Registration requires the Complaint to be tagged to a Policy., ';
                bErrorOccured = true;
            }
            if(caseRecord.ABSLI_Case_Detail__r.IGMS_Complaint_Status__c != null){
                errorMessage = 'Case is already sync with IGMS., ';
                //bErrorOccured = true;
            }
            if(caseRecord.IGMS_Complaint_Type_Code__c != null && ABSLI_Constants.IGMS_COMPLAINT_CATEGORIES.contains(caseRecord.ABSLI_Case_Detail__r.Complaint_Category__c)){
                ABSLI_IGMSClassificationUtility.validationWrapper returnWrapper= ABSLI_IGMSClassificationUtility.validateCurrentSelection(mClassificationIGMS, caseRecord);
                if(returnWrapper.bErrorOccured){
                    errorMessage = returnWrapper.errorMessage;
                    bErrorOccured = returnWrapper.bErrorOccured;
                }
                
            }
            if(bErrorOccured && ABSLI_Constants.IGMS_COMPLAINT_CATEGORIES.contains(caseRecord.ABSLI_Case_Detail__r.Complaint_Category__c)){
                errorMessage = errorMessage.removeEnd(', ');
                result.response = errorMessage;
                resultMap.put(caseRecord.Id, result);
                continue;
            }
            
            
            // 2. Check if IRDAI Token Number is NULL. 
            // 2.1 First Check if the Case is eligible for RegisterCaseApi. OR
            // 2.2 If Case is already Registered with IGMS (In case of API created Case OR In case of Retry)
            if (ABSLI_Constants.IGMS_COMPLAINT_CATEGORIES.contains(caseRecord.ABSLI_Case_Detail__r.Complaint_Category__c) 
                && (caseRecord.IRDAI_Token_Number__c == null || 
                    (caseRecord.IRDAI_Token_Number__c != null && ABSLI_Constants.IGMS_REGACKPEN_STATUS_CDS.contains(caseRecord.ABSLI_Case_Detail__r.IGMS_Complaint_Status__c)))) 
            {
                result.status = ABSLI_Constants.SUCCESS;
                result.response = ABSLI_Constants.EVALUATION_SUCCESS;
            }
                        
            resultMap.put(caseRecord.Id, result);
        }
        
        system.debug('resultMap---->'+resultMap);

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
                
        
        Map<String,List<Case>> mIGMSStatusRelatedCases = new Map<String,List<Case>>();
        mIGMSStatusRelatedCases.put('REG', new List<Case>());
        mIGMSStatusRelatedCases.put('ACK', new List<Case>());
        mIGMSStatusRelatedCases.put('PEN', new List<Case>());
		Map<Id, String> caseStageMap = new Map<Id, String>();
        
        List<Case> caseRecords = new List<Case>();
        for (Case caseRec : caseRecs) {
            Case queriedCase = ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id);
            caseRecords.add(queriedCase);
            if(queriedCase.ABSLI_Case_Detail__r.IGMS_Complaint_Status__c == null && 
               !queriedCase.ABSLI_Case_Detail__r.IGMS_Created_Case__c)
            {
                mIGMSStatusRelatedCases.get('REG').add(queriedCase);
            }
            else if(queriedCase.ABSLI_Case_Detail__r.IGMS_Complaint_Status__c == '1')
            {
                mIGMSStatusRelatedCases.get('ACK').add(queriedCase);
            }
            else if(queriedCase.ABSLI_Case_Detail__r.IGMS_Complaint_Status__c == '2')
            {
                mIGMSStatusRelatedCases.get('PEN').add(queriedCase);
            }
            caseStageMap.put(caseRec.Id, queriedCase.Stage__c);
        }
        
        
        Map<Id, ASF_CaseMovementHelper.CaseAdditionalData> dataWrapper = ASF_CaseMovementHelper.getCaseAdditionalDataForNextStage(caseRecords, caseStageMap,null);
        Map<Id, List<ASF_Integration__c>> runIntegrationMap = new Map<Id, List<ASF_Integration__c>>();
        for(Id caseId : dataWrapper.keySet()){
            if(!runIntegrationMap.containsKey(caseId)){
                runIntegrationMap.put(caseId, new List<ASF_Integration__c>());
            }
            if(runIntegrationMap.containsKey(caseId) && dataWrapper.containsKey(caseId) && dataWrapper.get(caseId).allIntegrations != null){
                runIntegrationMap.get(caseId).addAll(dataWrapper.get(caseId).allIntegrations);
            }
        }
        
        if(mIGMSStatusRelatedCases.get('REG').size()>0)
        {
            ABSLI_IGMSIntegrationHelper.createRegisterComplaintRequest(mIGMSStatusRelatedCases.get('REG'),runIntegrationMap,resultMap);
        }
        if(mIGMSStatusRelatedCases.get('ACK').size()>0)
        {
            ABSLI_IGMSIntegrationHelper.createAckComplaintRequest(mIGMSStatusRelatedCases.get('ACK'),runIntegrationMap,resultMap);
        }
        if(mIGMSStatusRelatedCases.get('PEN').size()>0)
        {
            ABSLI_IGMSIntegrationHelper.createPendingComplaintRequest(mIGMSStatusRelatedCases.get('PEN'),runIntegrationMap,resultMap);
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
                
                RegisterComplaintResponseWrapper jsonMap = (RegisterComplaintResponseWrapper) JSON.deserialize(
                    caseInteg.Response__c,
                    RegisterComplaintResponseWrapper.class
                );
                List<sObject> dmlRecords = new List<sObject>();
                if (jsonMap.ReturnCode == ABSLI_Constants.IGMS_REGCOMPLAINT_SUCCESS_RET_CD) {
                    if(caseRecord.ABSLI_Case_Detail__c != null){
                        System.debug(caseRecord.ABSLI_Case_Detail__c);
                        ABSLI_Case_Detail__c caseExt = new ABSLI_Case_Detail__c(Id = caseRecord.ABSLI_Case_Detail__c);
                        caseExt.IRDAI_Token_Number__c = jsonMap.IRDA_TOKEN_NUMBER;
                        caseExt.New_Registration_Date__c = System.Today();
                        caseExt.IGMS_Complaint_Registration_Date__c = System.Today();
                        caseExt.Next_Integration_Name__c = ABSLI_Constants.IGMS_REGCOMLPAINT_NEXT_INT;
                        caseExt.IGMS_Complaint_Status__c = '1';
                        dmlRecords.add(caseExt);
                        
                    }
                    caseRecord.IRDAI_Token_Number__c = jsonMap.IRDA_TOKEN_NUMBER;
                    dmlRecords.add(caseRecord);
                    Database.SaveResult[] results = Database.update(dmlRecords, true);
                    
                    Map<Id, String> caseStageMap = new Map<Id, String>();
                    List<Case> eligibleRecords = new List<Case>();
                    eligibleRecords.add(caseRecord);
                    caseStageMap.put(caseRecord.Id, caseRecord.Stage__c);
                    Map<Id, ASF_CaseMovementHelper.CaseAdditionalData> dataWrapper = ASF_CaseMovementHelper.getCaseAdditionalDataForNextStage(eligibleRecords, caseStageMap,null);
                    Map<Id, ASF_Integration__c> runIntegrationMap = new Map<Id, ASF_Integration__c>();
                    system.debug('dataWrapper---->'+dataWrapper);
                    system.debug(' dataWrapper.get(caseRecord.Id).allIntegrations---->'+ dataWrapper.get(caseRecord.Id).allIntegrations);
                    for(ASF_Integration__c intRec : dataWrapper.get(caseRecord.Id).allIntegrations){
                        if(intRec.Processing_Class__c == ABSLI_Constants.IGMS_REGCOMLPAINT_NEXT_INT){
                            runIntegrationMap.put(caseRecord.Id, intRec);
                        }
                    }
                    
                    ASF_IntegrationsController.runIntegration(runIntegrationMap.get(caseRecord.Id),caseRecord);
                }
            }
        } catch (Exception e) {
            System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABSLI_RegisterIGMSComplaintIntegration.processResponse');
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
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string Sex {get;set;}
        public string Address1 {get;set;}
        public string User_Type {get;set;}
        public string Entity_Complaint_Ref_Number{get;set;}
        public string Complaint_Details{get;set;}
        public string Date_Of_Birth{get;set;}
        public string Complaint_Date{get;set;}
        public string Complaint_Receipt_Date{get;set;}
        public string Complaint_Against_Type_Id{get;set;}
        public string Addressed_To_Insurer{get;set;}
        public string State_Id{get;set;}
        public string Complaint_Status_Id{get;set;}
        public string Insurance_Type_Id{get;set;} 
        public string Policy_Type_Id{get;set;} 
        public string Complaint_Type_Id{get;set;} 
        public string Complaint_Description_Id{get;set;} 
        public string Source_Of_Complaint{get;set;} 
        public string Status_Change_Date{get;set;} 
        public string Receipt_Number{get;set;} 
        public string Policy_Number{get;set;} 
        public string Mobile_Number{get;set;} 
        public string District_Id{get;set;} 
        public string Identifier_Type{get;set;} 
        public string Policy_Proposal_Cert_ClaimNumber{get;set;}         
        public string Trans_Login_Id{get;set;}         
        public string Option{get;set;}         
        public string Mode{get;set;}                 
        
        
        @SuppressWarnings('PMD.ExcessiveParameterList')
        public objReq() {
            this.User_Type = 'I';
            this.Complaint_Against_Type_Id = '1';
            this.State_Id = '1';
            this.Complaint_Status_Id = '1';
            this.Insurance_Type_Id = '1';
            this.Status_Change_Date = '';
            this.District_Id = '1';
            this.Identifier_Type = '1';
            this.Option = ABSLI_Constants.ABSLI_IGMS_OPTION;
            this.Mode = ABSLI_Constants.ABSLI_IGMS_MODE_REGISTER;
            this.Addressed_To_Insurer = ABSLI_Constants.ABSLI_IGMS_ADDRESS_TO_INSURER_Y;
            this.Trans_Login_Id = ABSLI_Constants.ABSLI_IGMS_TRANS_LOGIN_ID;
        }
    }
    /**
* @description Contact Detail Update Wrapper Class to follow through Response Body JSON
*/
    @SuppressWarnings('PMD.VariableNamingConventions,PMD.FieldNamingConventions')
    public class RegisterComplaintResponseWrapper {
        public String ReturnMessage { get; set; }
        public String ReturnCode { get; set; }
        public String IRDA_TOKEN_NUMBER { get; set; }
        public String ENTITY_COMPLAINT_REF_NUMBER { get; set; }
    }
}