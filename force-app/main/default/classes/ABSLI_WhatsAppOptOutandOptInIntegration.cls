/*********************************************************
*@Class        :  ABSLI_WhatsAppOptOutandOptInIntegration
*@Author       :  Laxman R
*@Created Date :  06/04/2024
*@Last Modified:  06/04/2024
*@description  :  Class for WhatsApp Opt Out and Opt In Integration. 
*********************************************************/
public without sharing class ABSLI_WhatsAppOptOutandOptInIntegration implements ASF_IntegrationInvocable{
    /****************************************************************************************************************
* @LOB - ABSLI
* @Function - evaluate
* @param caseRec - Case record from the framework.
* @return - ASF_IntegrationsController.IntegrationWrapper.
* @description - Invoked from the ASF_IntegrationsController class, this method evaluates whether Amortization integration should be fired or not.
*****************************************************************************************************************/
    
    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){
        
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result = evaluate(new List<Case>{caseRec}).get(caseRec.Id);
        
        return result;
    }
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        List<Case> caseRecords = new List<Case>();
        for(Case caseRec : caseRecs){
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
        }
        for(Case caseRecord : caseRecords){
            ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
            result.status = ABSLI_Constants.ERROR;
            result.response = Custom_Messages__mdt.getInstance('ABSLI_WhatsAppOptOutIntegration_ERR1').Message__c;
            
            //Customer Portal and Status_Valid_For_STP__c is false 
            if(ABSLI_Constants.STP_SOURCES.contains(caseRecord.Source__c) && caseRecord.ABSLI_Case_Detail__r.Status_Valid_For_STP__c == false){
            	result.status = ABSLI_Constants.ERROR;
            	result.response = Custom_Messages__mdt.getInstance('ABSLI_CustomerPortal_STPFalse_Err').Message__c;
            }else{
               	if(caseRecord.Technical_Source__c=='API' &&  (caseRecord.ABSLI_Case_Detail__r.Status_Valid_For_STP__c == true && caseRecord.Is_STP__c== true)){
                    result.status = ABSLI_Constants.SUCCESS;
                }else if(caseRecord.Technical_Source__c =='LWC'){
                    result.status = ABSLI_Constants.SUCCESS;
                } 
            }
            
            resultMap.put(caseRecord.Id, result);
        }
        return resultMap;
    }
    
    public ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c integ, Case caseRec){
        
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result = run(new Map<Id, List<ASF_Integration__c>>{caseRec.Id => new List<ASF_Integration__c>{integ}}, new List<Case>{caseRec}).get(caseRec.Id);   
        
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
            String caseClientCodeText = '';
            String whatsAppoutIn = '';
                caseClientCodeText = caseRecord.AccountId != null ? caseRecord.Account.Client_Code__c : caseRecord.Client_Code_Text__c;
                System.debug('caseClientCodeText:::'+caseClientCodeText);
            if(caseRecord.Issue_Type__c == 'Whatsapp Opt In'){
                whatsAppoutIn = 'Y';
            }
            else if(caseRecord.Issue_Type__c == 'Whatsapp Opt Out'){
                whatsAppoutIn = 'N';
            }
           /* if(caseRecord.ABSLI_Case_Detail__r.WhatsApp_Opt_Out_Indicator__c != null && caseRecord.ABSLI_Case_Detail__r.WhatsApp_Opt_Out_Indicator__c != ''){
                whatsAppoutIn = caseRecord.ABSLI_Case_Detail__r.WhatsApp_Opt_Out_Indicator__c;
            }*/
            
            string requestBody = JSON.serialize(
                new WhatsAppOptOutOptInRequest(
                    ABSLI_Constants.ESB_SOURCE_ID,
                    caseRecord.CaseNumber,
                    whatsAppoutIn,
                    caseClientCodeText
                )
            );
            for (ASF_Integration__c intSpec : integs.get(caseRecord.Id)) {
                if (intSpec.Processing_Class__c == ABSLI_WhatsAppOptOutandOptInIntegration.class.getName()) {
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
                    caseIntOut.Integration_Name__c = ABSLI_Constants.WHATSAPPOPTOUT_OPTIN_NAME;
                    caseIntOut.ServiceName__c = ABSLI_Constants.WHATSAPPOPTOUT_OPTIN_NAME;
                    peMap.put(index, caseIntOut);
                    indexToCaseId.put(index, caseRecord.Id);
                }
                index++;
            }
        }
        
        index = 0;
        
        List<Database.SaveResult> results = Database.insert(newCaseIntegrations, false, AccessLevel.USER_MODE);
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
                if (integ.Processing_Class__c == ABSLI_WhatsAppOptOutandOptInIntegration.class.getName()) {
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
        Database.update(existingCaseIntegrations, AccessLevel.USER_MODE);
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
                
                WhatsAppOptOutOptInResponse jsonMap = (WhatsAppOptOutOptInResponse) JSON.deserialize(
                    caseInteg.Response__c,
                    WhatsAppOptOutOptInResponse.class
                );
                
                if (jsonMap.LSIR_RETURN_CD == '00') {
                    caseRecord.MoveToNext__c = true;
                    Database.update(caseRecord, AccessLevel.SYSTEM_MODE);
                }
                
                
            }
        } catch (Exception e) {
            System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABSLI_WhatsAppOptOutandOptInIntegration.processResponse');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
        }
    }
     
    public class WhatsAppOptOutOptInRequest{
        public String source ;	//4170703839
        public String TRANS_NO ;	//CASE_NUMBER
        public String MIR_CLI_WHTS_IND ;	//POSSIBLE VALUES Y/N
        public String MIR_CLI_ID ;	//COMMON_CLIENT_CODE
        public WhatsAppOptOutOptInRequest(
            String source,
            String TRANS_NO,
            String MIR_CLI_WHTS_IND,
            String ClientCode
        ) {
            this.source = source;
            this.TRANS_NO = TRANS_NO;
            this.MIR_CLI_WHTS_IND = MIR_CLI_WHTS_IND;
            this.MIR_CLI_ID = ClientCode;
        }
    }
    public class WhatsAppOptOutOptInResponse{
        public String LSIR_RETURN_CD;	//00
        public String MORE_MESSAGES_IND;	//N
        public String MIR_CLI_WHTS_IND;	//N
        public String TRANS_NO;	//1234
        public String MIR_RETRN_CD;	//00
        public String MESSAGES;	//CURRENCY NOT ENTERED ON MIR.  CURRENCY DEFAULTED TO (IN). ~ WHATSAPP INDICATOR UPDATE SUCCESSFULLY FOR POLICY 000653347 ~ 
        public String Page;	//BF9670-P
        public String MIR_DV_PRCES_STATE_CD;	//3
        public String MIR_CLI_ID;	//2609353029
    }
}