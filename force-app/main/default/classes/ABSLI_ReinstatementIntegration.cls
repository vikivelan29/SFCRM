public with sharing class ABSLI_ReinstatementIntegration implements ASF_IntegrationInvocable{
    
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs) {
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        Set<Id> caseIds = new Set<Id>();        
        List<Case> caseRecords = new List<Case>();
        Map<Id,List<ASF_Checklist__c>> caseIdVsCheckListMap = new Map<Id,List<ASF_Checklist__c>>();
        for (Case caseRec : caseRecs) {
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
            caseIds.add(caseRec.Id);
        }
        for(ASF_Checklist__c checklist : [SELECT Id, Case__c, Status__c FROM ASF_Checklist__c WHERE Case__c IN:caseIds AND Mandatory__c=TRUE]){
            if(!caseIdVsCheckListMap.containsKey(checklist.Case__c)){
                caseIdVsCheckListMap.put(checklist.Case__c,new List<ASF_Checklist__c>());
            }
            caseIdVsCheckListMap.get(checklist.Case__c).add(checklist);
        }
        
        for (Case caseRecord : caseRecords) {
            ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
            
            result.status = ABSLI_Constants.ERROR;
            String evaluationErrorMetadataName = ABSLI_Constants.REINSTATEMENT_EVAL_ERROR;
            
            result.response = Custom_Messages__mdt.getInstance(evaluationErrorMetadataName).Message__c;
           
            //Customer Portal and Status_Valid_For_STP__c is false 
            if(ABSLI_Constants.STP_SOURCES.contains(caseRecord.Source__c) && caseRecord.ABSLI_Case_Detail__r.Status_Valid_For_STP__c == false){
            	result.status = ABSLI_Constants.ERROR;
            	result.response = Custom_Messages__mdt.getInstance('ABSLI_CustomerPortal_STPFalse_Err').Message__c;
            }else{
             	if(caseRecord.Technical_Source__c=='LWC'){
                    if(!caseIdVsCheckListMap.isEmpty() && caseIdVsCheckListMap.get(caseRecord.Id)!=null 
                       && caseIdVsCheckListMap.get(caseRecord.Id).size()>0)
                    {
                        for(ASF_Checklist__c cList : caseIdVsCheckListMap.get(caseRecord.Id)){
                            if(!ABSLI_Constants.CHECKLIST_PASS_STATUS.split(',').contains(cList.Status__c)){
                                result.response = Custom_Messages__mdt.getInstance('ABSLI_REINSTATEMENT_ERR2').Message__c;
                                break;
                            }
                        }
                    }
                    
                }
                if (caseRecord.ABSLI_Case_Detail__r.PX_Response__c !=null) {
                    if(caseRecord.ABSLI_Case_Detail__r.PX_Response__c.containsIgnoreCase('clean') && 
                       !caseRecord.ABSLI_Case_Detail__r.PX_Response__c.containsIgnoreCase('not clean')){
                           result.status = ABSLI_Constants.SUCCESS;
                           result.response = ABSLI_Constants.EVALUATION_SUCCESS;
                       }
                }   
            }
            
            resultMap.put(caseRecord.Id, result);
        }
        return resultMap;
    }
    
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> run(
        Map<Id, List<ASF_Integration__c>> integs,
        List<Case> caseRecs
    ) {
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        
        cancelPendingCaseIntegrationRequests(integs, caseRecs);
        
        List<Case> caseRecords = new List<Case>();
        Set<Id> caseIds = new Set<Id>();
        for (Case caseRec : caseRecs) {
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
            caseIds.add(caseRec.Id);
        }
        Map<Id,List<ASF_Checklist__c>> caseIdVsCheckListMap = new Map<Id,List<ASF_Checklist__c>>();
        
        for(ASF_Checklist__c checklist : [SELECT Id, Case__c, Status__c FROM ASF_Checklist__c WHERE Case__c IN:caseIds AND Mandatory__c=TRUE]){
            if(!caseIdVsCheckListMap.containsKey(checklist.Case__c)){
                caseIdVsCheckListMap.put(checklist.Case__c,new List<ASF_Checklist__c>());
            }
            caseIdVsCheckListMap.get(checklist.Case__c).add(checklist);
        }
        
        List<ASF_Case_Integration__c> newCaseIntegrations = new List<ASF_Case_Integration__c>();
        Map<Integer, Case_Integration_Outbound__e> peMap = new Map<Integer, Case_Integration_Outbound__e>();
        Integer index = 0;
        Map<Integer, Id> indexToCaseId = new Map<Integer, Id>();
        
        for (Case caseRecord : caseRecords) {
            String casePolicyNo = '';
            if (caseRecord.Technical_Source__c == 'API') {
                casePolicyNo = caseRecord.AssetId != null
                    ? caseRecord.Asset.Policy_No__c
                    : caseRecord.LAN__c;
            }
            else{
                casePolicyNo = caseRecord.Asset.Policy_No__c;
            }
            String caseNum = caseRecord.CaseNumber;
            String COI = caseRecord.ABSLI_Case_Detail__r.COI_Covid_Quest__c;
            decimal reinstatementAmount = caseRecord.ABSLI_Case_Detail__r.Reinstatement_Amount__c;
            String medicals = caseRecord.ABSLI_Case_Detail__r.Medicals__c ;
            String pxResponse = caseRecord.ABSLI_Case_Detail__r.PX_Response__c ;
            List<ASF_Checklist__c> checkLists = caseIdVsCheckListMap.get(caseRecord.Id);
            
            String coiSignedDate = ABCL_IntegrationCommonUtility.dateFormat(caseRecord.ABSLI_Case_Detail__r?.COI_Signed_Date__c, 'dd-MM-YYYY') ;
            String CPREQ_STAT_CD  = getStateCode(COI,reinstatementAmount,
                                                 medicals, pxResponse, checkLists);
            
            string requestBody = JSON.serialize(
                new reinstatementRequestWrapper(
                    caseNum,casePolicyNo,coiSignedDate,CPREQ_STAT_CD)
            );
            for (ASF_Integration__c intSpec : integs.get(caseRecord.Id)) {
                if (intSpec.Processing_Class__c == ABSLI_ReinstatementIntegration.class.getName()) {
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
                    caseIntOut.Integration_Name__c = ABSLI_Constants.REINSTATEMENT_SERVICE_NAME;
                    caseIntOut.ServiceName__c = ABSLI_Constants.REINSTATEMENT_SERVICE_NAME;
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
    public void processResponse(ASF_Case_Integration__c caseInteg) {
        try {
            if (caseInteg.Status__c == ABSLI_Constants.SUCCESS) {
                Case caseRecord = ABSLI_IntegrationQueryHelper.getCaseInfo(caseInteg.Case__c);
                
                ReinstatementResponseWrapper jsonMap = (ReinstatementResponseWrapper) JSON.deserialize(
                    caseInteg.Response__c,
                    ReinstatementResponseWrapper.class
                );
                
                if (jsonMap.LSIR_RETURN_CD == '00') {
                    caseRecord.MoveToNext__c = true;
                    Database.update(caseRecord, AccessLevel.SYSTEM_MODE);
                }
                else{
                    // ASSIGN CASE TO KARVY TEAM.
                    Group karvyGrp = [SELECT ID FROM Group WHERE DeveloperName =: ABSLI_Constants.KARVY_QUEUE_DEVELOPER_NAME LIMIT 1];
                    caseRecord.OwnerId = karvyGrp.Id;
                    Database.update(caseRecord, AccessLevel.SYSTEM_MODE);
                }
            }
            if (caseInteg.Status__c == ABSLI_Constants.FAILURE) {
                Case caseRecord = ABSLI_IntegrationQueryHelper.getCaseInfo(caseInteg.Case__c);
                Group karvyGrp = [SELECT ID FROM Group WHERE DeveloperName =: ABSLI_Constants.KARVY_QUEUE_DEVELOPER_NAME LIMIT 1];
                caseRecord.OwnerId = karvyGrp.Id;
                Database.update(caseRecord, AccessLevel.SYSTEM_MODE);
                
            }
        } catch (Exception e) {
            System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABSLI_ReinstatementIntegration.processResponse');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
        }
    }
    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec) {
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result = evaluate(new List<Case>{ caseRec }).get(caseRec.Id);
        return result;
    }
    public ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c caseInteg, Case caseRec) {
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result = run(
            new Map<Id, List<ASF_Integration__c>>{ caseRec.Id => new List<ASF_Integration__c>{ caseInteg } },
            new List<Case>{ caseRec }
        )
            .get(caseRec.Id);
        return result;
    }
    public void cancelPendingCaseIntegrationRequests(Map<Id, List<ASF_Integration__c>> integs, List<Case> caseRecs) {
        Set<String> intIds = new Set<String>();
        for (Case caseRec : caseRecs) {
            for (ASF_Integration__c integ : integs.get(caseRec.Id)) {
                if (integ.Processing_Class__c == ABSLI_ReinstatementIntegration.class.getName()) {
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
    
    public class reinstatementRequestWrapper{
        public string SOURCE{get;set;}
        public String TRANS_NO {get;set;}
        public String POLICY_NO {get;set;}
        public String COI_SIGN_DT {get;set;}
        public String CPREQ_STAT_CD {get;set;}
        public String ANNIVERSARY_DATE {get;set;}
        public String NEW_MODE{get;set;}
        public String REMARK1 {get;set;}
        public String REMARK2 {get;set;}
        public String REMARK3 {get;set;}  
        public String REMARK4 {get;set;}  
        public String REMARK5 {get;set;}  
        
        public reinstatementRequestWrapper(String caseNum,
                                           String casePolicyNo,
                                           String coiSignedDate,
                                           String CPREQ_STAT_CD)
        {
            this.SOURCE = ABSLI_Constants.ESB_SOURCE_ID;
            this.TRANS_NO = caseNum;
            this.POLICY_NO = casePolicyNo;
            this.COI_SIGN_DT = coiSignedDate;
            this.ANNIVERSARY_DATE = '';
            this.CPREQ_STAT_CD = CPREQ_STAT_CD;
            this.NEW_MODE = '';
            this.REMARK1 = '';
            this.REMARK2 = '';
            this.REMARK3 = '';
            this.REMARK4 = '';
            this.REMARK5 = '';
        }        
    }
    
    public static String getStateCode(String COI,decimal reinstatementAmount,
                                      String medicals, String pxResponse, List<ASF_Checklist__c> checklists)
    {
        String stateCode = '';
        
        // IF COI IS NOT NULL AND REINSTATEMENTAMOUT > 0
        // 
        boolean bCroppedSignatured = false;
        for(ASF_Checklist__c checklist : checklists){
            if(checklist.Status__c == 'Signature Not Cropped' ){
                bCroppedSignatured = true;
                break;
            }
        }
        
        if(String.isNotBlank(COI) && reinstatementAmount > 0){
            // RCD Condition
            if(medicals != '' && (pxResponse =='not clean' || pxResponse == 'clean')){
                stateCode = 'RCD';
            }
            else if (pxResponse == 'clean' && bCroppedSignatured == false)
            {
                stateCode = 'RAC';
            }
            else if (pxResponse == 'clean' && bCroppedSignatured == true)
            {
                stateCode = 'RCD';
            }
            else if (pxResponse == 'not clean'){
                stateCode = 'RCD';
            }
        }
        return stateCode;
    }
    public class ReinstatementResponseWrapper{
        String LSIR_RETURN_CD{get;set;}
    }
}