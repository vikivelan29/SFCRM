/**
* @description Outbound Callout to Contact Update (Email and/or Mobile Number) Deatils of Customer
*  Service Agent to manually invoke STP by clicking on the Integration Button
*  Customer Portal to create Cases by API. On Successful response, case to be marked as Closed
*
* @author Aditya Mehrotra
* @date 2024-07-01
*/
public with sharing class ABSLI_DeletePolicyNomineeIntegration implements ASF_IntegrationInvocable {
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
            String evaluationErrorMetadataName = ABSLI_Constants.DELETENOMINEE_EVALUATION_ERROR;
            result.response = Custom_Messages__mdt.getInstance(evaluationErrorMetadataName).Message__c;
            if(ABSLI_Constants.STP_SOURCES.contains(caseRecord.Source__c) && caseRecord.ABSLI_Case_Detail__r.Status_Valid_For_STP__c == false){
            	result.status = ABSLI_Constants.ERROR;
            	result.response = Custom_Messages__mdt.getInstance('ABSLI_CustomerPortal_STPFalse_Err').Message__c;
            }else{
                if (caseRecord.Technical_Source__c == 'API' && caseRecord.ABSLI_Case_Detail__r.Status_Valid_For_STP__c) 
                {
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
        Boolean anyOutOfSync = false;
        Map<Id,List<ABSLI_Nominee__c>> mCaseNominees = new Map<Id,List<ABSLI_Nominee__c>>();
        for(ABSLI_Nominee__c nominee : [SELECT ID,Case__c,Sequence_No__c,Sync_Status__c
                                        FROM ABSLI_Nominee__c WHERE Case__c =: integs.keySet()
                                        AND Action_Item__c ='Delete'])
        {
            if(!mCaseNominees.containsKey(nominee.Case__c)){
                mCaseNominees.put(nominee.Case__c,new List<ABSLI_Nominee__c>());
            }
            mCaseNominees.get(nominee.Case__c).add(nominee);
            if(nominee.Sync_Status__c=='Pending'){
                anyOutOfSync = true;
			}
        }
        
        if(anyOutOfSync == false){
            mCaseNominees.clear();
        }
        if(!mCaseNominees.isEmpty()){
            for (Case caseRecord : caseRecords) {
                String policyNumberText = '';
                List<DeletePolicyNomineeRequestWrapper> lstRequest = new List<DeletePolicyNomineeRequestWrapper>();
                if (caseRecord.Technical_Source__c == 'API') {
                    policyNumberText = caseRecord.AssetId != null
                        ? caseRecord.Asset.Policy_No__c
                        : caseRecord.LAN__c;
                } else {
                    policyNumberText = caseRecord.AssetId != null ? caseRecord.Asset.Policy_No__c : '';
                }
               	for(ABSLI_Nominee__c nominee : mCaseNominees.get(caseRecord.Id)){
                    string requestBody = JSON.serialize(
                   	new DeletePolicyNomineeRequestWrapper(
                        caseRecord.CaseNumber,
                        policyNumberText,
                      	nominee.Sequence_No__c)
                   	);
                        /*lstRequest.add(new DeletePolicyNomineeRequestWrapper(
                                caseRecord.CaseNumber,
                                policyNumberText,
                                nominee.Sequence_No__c));*/
                    
                    //string requestBody = JSON.serialize(lstRequest);
                   	for (ASF_Integration__c intSpec : integs.get(caseRecord.Id)) {
                       	if (intSpec.Processing_Class__c == ABSLI_DeletePolicyNomineeIntegration.class.getName()) {
                            system.debug('Aditya nominee:'+nominee);
                            ASF_Case_Integration__c caseInteg = new ASF_Case_Integration__c();
                            caseInteg.Integration_Ext_Id__c = intSpec.External_Id__c;
                            caseInteg.Case__c = caseRecord.Id;
                            caseInteg.Status__c = ABSLI_Constants.PENDING;
                            caseInteg.Request__c = requestBody;
                            caseInteg.Response__c = ABSLI_Constants.WAITING_API_RESPONSE;
                           	caseInteg.Is_Validation_Success__c = true;
                            caseInteg.Business_External_Id__c = nominee.Id;
                            caseInteg.Do_Not_Retry_Integration__c = intSpec.Do_Not_Retry_Integration__c;
                            newCaseIntegrations.add(caseInteg);
                                
                            Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e();
                            caseIntOut.Business_Unit__c = caseRecord.Business_Unit__c;
                            caseIntOut.Request_Payload__c = requestBody;
                            caseIntOut.Integration_Name__c = ABSLI_Constants.DELETENOMINEE_SRV_NAME;
                            caseIntOut.ServiceName__c = ABSLI_Constants.DELETENOMINEE_SRV_NAME;
                            peMap.put(index, caseIntOut);
                            indexToCaseId.put(index, caseRecord.Id);
                           	index++;
                       	}       
                 	}   
               	} 
            }
        
        
            index = 0;
            system.debug('Aditya case integ:'+newCaseIntegrations);
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
        }else{
            List<sObject> dmlRecords = new List<sObject>();
            Map<Id, String> caseStageMap = new Map<Id, String>();
            List<Case> eligibleRecords = new List<Case>();
            for(Case c:caseRecords){
                if(c.ABSLI_Case_Detail__c!=null){
                    ABSLI_Case_Detail__c caseExt = new ABSLI_Case_Detail__c(Id=c.ABSLI_Case_Detail__c);
                    caseExt.Next_Integration_Name__c = ABSLI_UpdatePolicyNomineeIntegration.class.getName();
            		dmlRecords.add(caseExt);
                }
                eligibleRecords.add(c);
            	caseStageMap.put(c.Id, c.Stage__c);
            }
            Database.SaveResult[] results = Database.update(dmlRecords, true);
 
            Map<Id, ASF_CaseMovementHelper.CaseAdditionalData> dataWrapper = ASF_CaseMovementHelper.getCaseAdditionalDataForNextStage(eligibleRecords, caseStageMap,null);
            Map<Id, List<ASF_Integration__c>> runIntegrationMap = new Map<Id, List<ASF_Integration__c>>();
            for(Case cs: caseRecords){
               	if(dataWrapper.get(cs.Id).allIntegrations!=null){
                   	for(ASF_Integration__c intRec : dataWrapper.get(cs.Id).allIntegrations){
                       	if(intRec.Processing_Class__c == ABSLI_UpdatePolicyNomineeIntegration.class.getName()){
                            if(!runIntegrationMap.containsKey(cs.Id)){
                               	runIntegrationMap.put(cs.Id,new List<ASF_Integration__c>());
                            }
                            runIntegrationMap.get(cs.Id).add(intRec);
                        }
                    }   
                }
            }
            if(!runIntegrationMap.isEmpty()){
            	ASF_IntegrationsController.runIntegration(runIntegrationMap,eligibleRecords);    
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
                if (integ.Processing_Class__c == ABSLI_DeletePolicyNomineeIntegration.class.getName()) {
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
                        (caseInt.Status__c == ABSLI_Constants.PENDING || caseInt.Status__c == ABSLI_Constants.FAILURE)
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
                Map<String, Integer> statusCountMap = new Map<String, Integer>();
                AggregateResult[] groupedResults = [SELECT COUNT(Id) recordCount, Status__c FROM ASF_Case_Integration__c
                                                        WHERE Case__c=:caseRecord.Id
                                                    	AND Business_External_Id__c!=null GROUP BY Status__c];
                for (AggregateResult ar : groupedResults) {
                    statusCountMap.put(String.valueOf(ar.get('Status__c')), Integer.valueOf(ar.get('recordCount'))==null?0:Integer.valueOf(ar.get('recordCount')));
                }
 
                /*DeletePolicyNomineeResponseWrapper jsonMap = (DeletePolicyNomineeResponseWrapper) JSON.deserialize(
                    caseInteg.Response__c,
                    DeletePolicyNomineeResponseWrapper.class
                );*/
                Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(caseInteg.Response__c);
                
                if (String.valueOf(jsonMap.get('LSIR_RETURN_CD')) == '00') {
                    ABSLI_Nominee__c nominee = new ABSLI_Nominee__c(Id=caseInteg.Business_External_Id__c);
                    nominee.Sync_Status__c = 'Success';
                    update nominee;
                    //On Case resolution send Email and SMS notification to the customer based on Custom Metdata
                    if((statusCountMap.get('Pending')==0 || statusCountMap.get('Pending')==null) && 
                    	(statusCountMap.get('Failure')==0 || statusCountMap.get('Failure')==null))
                    {
                    		processSuccessResponse(caseRecord);
            		}

                }
            }
        } catch (Exception e) {
            System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABSLI_DeletePolicyNomineeIntegration.processResponse');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
        }
    }
    
    private static void processSuccessResponse(Case caseRecord){
        List<sObject> dmlRecords = new List<sObject>();
        if(caseRecord.ABSLI_Case_Detail__c != null){
           	ABSLI_Case_Detail__c caseExt = new ABSLI_Case_Detail__c(Id = caseRecord.ABSLI_Case_Detail__c);
            caseExt.Next_Integration_Name__c = ABSLI_UpdatePolicyNomineeIntegration.class.getName();
            dmlRecords.add(caseExt);            
        }
        Database.SaveResult[] results = Database.update(dmlRecords, true);
        
        Map<Id, String> caseStageMap = new Map<Id, String>();
        List<Case> eligibleRecords = new List<Case>();
       	eligibleRecords.add(caseRecord);
        caseStageMap.put(caseRecord.Id, caseRecord.Stage__c);
        Map<Id, ASF_CaseMovementHelper.CaseAdditionalData> dataWrapper = ASF_CaseMovementHelper.getCaseAdditionalDataForNextStage(eligibleRecords, caseStageMap,null);
        Map<Id, ASF_Integration__c> runIntegrationMap = new Map<Id, ASF_Integration__c>();
        if(dataWrapper.get(caseRecord.Id).allIntegrations!=null){
            for(ASF_Integration__c intRec : dataWrapper.get(caseRecord.Id).allIntegrations){
                if(intRec.Processing_Class__c == ABSLI_UpdatePolicyNomineeIntegration.class.getName()){
                    runIntegrationMap.put(caseRecord.Id, intRec);
                }
            }
        }
        
        if(!runIntegrationMap.isEmpty()){
        	ASF_IntegrationsController.runIntegration(runIntegrationMap.get(caseRecord.Id),caseRecord);    
        }
    }
    
    /**
* @description On Case resolution send Email and SMS notification to the customer based on Custom Metdata
*
* @param caseRecord - Case record from the framework
*/
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
    public class DeletePolicyNomineeRequestWrapper {
        public string TRANS_NO { get; set; }
        public string SOURCE { get; set; }
        public string MIR_POL_ID_BASE {get;set;}
        public string MIR_BNFY_SEQ_NUM {get;set;}
        
        @SuppressWarnings('PMD.ExcessiveParameterList')
        public DeletePolicyNomineeRequestWrapper(String caseNumber, String policyNumber, String sequenceNo) {
            this.TRANS_NO = caseNumber;
            this.SOURCE = ABSLI_Constants.ESB_SOURCE_ID;
            this.MIR_POL_ID_BASE = policyNumber;
            this.MIR_BNFY_SEQ_NUM = sequenceNo;
        }
    }
    /**
* @description Contact Detail Update Wrapper Class to follow through Response Body JSON
*/
    /*@SuppressWarnings('PMD.VariableNamingConventions,PMD.FieldNamingConventions')
    public class DeletePolicyNomineeResponseWrapper {
        public String MIR_RETRN_CD { get; set; }
        public String Page { get; set; }
        public String MORE_MESSAGES_IND { get; set; }
        public String MESSAGES { get; set; }
        public String LSIR_RETURN_CD { get; set; }
        public string FaultMessage{get;set;}
        public string FaultCode{get;set;}        
    }*/
}