/*********************************************************
*@Class        :  ABSLI_ComplaintsIGMSSync
*@Author       :  Dhinesh
*@Created Date :  05/22/2024
*@Last Modified:  06/03/2024
*@description  :  Class for Complaints IGMS Sync integration.
*********************************************************/
public without sharing class ABSLI_ComplaintsIGMSSync implements ASF_IntegrationInvocable{
	
     public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){

        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result = evaluate(new List<Case>{caseRec}).get(caseRec.Id);

        return result;
    }

    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        System.debug(caseRecs);
        List<Case> caseRecords = new List<Case>();
        for(Case caseRec : caseRecs){
            System.debug(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
        }

        System.debug('@@caseRecords --> '+caseRecords);

        for(Case caseRecord : caseRecords){
            ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
            result.status = ABSLI_Constants.ERROR;
            result.response = result.response = Custom_Messages__mdt.getInstance('ABSLI_MobileUpdateIntegration_ERR1').Message__c;
			if(caseRecord.ABSLI_Case_Detail__r.Complaint_Category__c != 'Complaint'){
                result.status = ABSLI_Constants.ERROR;
                result.response = 'IGMS Sync is only Applicable for Complaint Type';
            }
            if(caseRecord.ABSLI_Case_Detail__r.Complaint_Category__c != 'Complaint'){
                result.status = ABSLI_Constants.ERROR;
                result.response = 'IGMS Sync is only Applicable for Complaint Type';
            }
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
            if(bErrorOccured){
                errorMessage = errorMessage.removeEnd(', ');
                result.response = errorMessage;
                resultMap.put(caseRecord.Id, result);
                continue;
            }
            
            
            // 2. Check if IRDAI Token Number is NULL. 
            if (ABSLI_Constants.IGMS_COMPLAINT_CATEGORIES.contains(caseRecord.ABSLI_Case_Detail__r.Complaint_Category__c) 
                && caseRecord.IRDAI_Token_Number__c == null)
            {
                result.status = ABSLI_Constants.SUCCESS;
                result.response = ABSLI_Constants.EVALUATION_SUCCESS;
            }
            resultMap.put(caseRecord.Id, result);
            System.debug('@@@resultMap VP---> '+resultMap);
        }

        return resultMap;
    }
    
    /****************************************************************************************************************
    * @description - Run Method
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c integ, Case caseRec){

        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result = run(new Map<Id, List<ASF_Integration__c>>{caseRec.Id => new List<ASF_Integration__c>{integ}}, new List<Case>{caseRec}).get(caseRec.Id);

        return result;
    }
    
    /****************************************************************************************************************
    * @description - Run Method
    *****************************************************************************************************************/
	public Map<Id, ASF_IntegrationsController.IntegrationWrapper> run(Map<Id, List<ASF_Integration__c>> integs, List<Case> caseRecs){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();

        Set<String> intIds = new Set<String>();
        for(Case caseRec : caseRecs){
            for(ASF_Integration__c integ : integs.get(caseRec.Id)){
                if(integ.Processing_Class__c == ABSLI_ComplaintsIGMSSync.class.getName()){
                    intIds.add(integ.External_Id__c);
                }
            }
        }

        List<ASF_Case_Integration__c> existingCaseIntegrations = new List<ASF_Case_Integration__c>();
        for(ASF_Case_Integration__c caseInt : [SELECT Id, Status__c, Case__c, Integration_Ext_Id__c FROM ASF_Case_Integration__c
                                               WHERE Case__c IN :caseRecs
                                               AND Integration_Ext_Id__c IN :intIds])
        {
            if(integs.containsKey(caseInt.Case__c)){
                for(ASF_Integration__c integ : integs.get(caseInt.Case__c))
                {
                    if(integ.External_Id__c == caseInt.Integration_Ext_Id__c && caseInt.Status__c == ABHFL_Constants.PENDING){
                        caseInt.Status__c = ABSLI_Constants.CANCELED;
                        existingCaseIntegrations.add(caseInt);
                    }
                }
            }
        }

        ASF_TriggerSkipperUtility.markTriggerRun('ASF_Case_Integration__c');
        update existingCaseIntegrations;
        ASF_TriggerSkipperUtility.resetTriggerRun('ASF_Case_Integration__c');


        List<Case> caseRecords = new List<Case>();
        Set<String> caseDetailIds = new Set<String>();
        for(Case caseRec : caseRecs){
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
        }
        for(Case casRecor : caseRecords){
            if (casRecor.ABSLI_Case_Detail__c != null) {
                caseDetailIds.add(casRecor.ABSLI_Case_Detail__c);
            }
        }
        Map<Id, ABSLI_Case_Detail__c> caseDetailMap = new Map<Id, ABSLI_Case_Detail__c>();
        for (ABSLI_Case_Detail__c detail : [SELECT Id, Complaint_Category__c FROM ABSLI_Case_Detail__c WHERE Id IN :caseDetailIds]) {
            caseDetailMap.put(detail.Id, detail);
        }
        List<ABSLI_Case_Detail__c> caseDetailsToUpdate = new List<ABSLI_Case_Detail__c>();
		for(Case caseRec : caseRecords){
			caseRec.IRDAI_Token_Number__c = 'Sample123';
 			ABSLI_Case_Detail__c caseDetail = caseDetailMap.get(caseRec.ABSLI_Case_Detail__c);
            caseDetail.Pending_Date__c = Date.newInstance(2024, 6, 6);
            caseDetail.IRDAI_Token_Number__c = 'Sample123';
            caseDetailsToUpdate.add(caseDetail);
        }
        update caseDetailsToUpdate;
        update caseRecords;
        
        List<ASF_Case_Integration__c> newCaseIntegrations = new List<ASF_Case_Integration__c>();
        Map<Integer, Case_Integration_Outbound__e> peMap = new Map<Integer, Case_Integration_Outbound__e>();
        Integer index = 0;
        Map<Integer, Id> indexToCaseId = new Map<Integer, Id>();
        for(Case caseRecord : caseRecords){
            for(ASF_Integration__c integ : integs.get(caseRecord.Id))
            {
                if(integ.Processing_Class__c == ABSLI_ComplaintsIGMSSync.class.getName()){
                    String transaction_no = String.valueOf(caseRecord.CaseNumber);
                    String source = System.label.ABSLI_ESB_SOURCE_VAL ;
                    String strClientId = String.valueOf(caseRecord.Account.Client_Code__c);
                    if(strClientId == null || strClientId == ''){
                        strClientId = String.ValueOf(caseRecord.Client_Code_Text__c);
                    }
                    String strBusiness = '';

                    ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
                    caseInt.Case__c  = caseRecord.Id;
                    caseInt.Integration_Ext_Id__c = integ.External_Id__c;
                    caseInt.Status__c = ABSLI_Constants.PENDING;
                    caseInt.Request__c  =  JSON.serialize(new IGMSSyncRequest(transaction_no,source,
                                                                                  strClientId,
                                                                                  'Thane'));
                    caseInt.Response__c = ABSLI_Constants.WAITING_API_RESPONSE;
                    newCaseIntegrations.add(caseInt);

                    Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
                    caseIntOut.Business_Unit__c  = caseRecord.Business_Unit__c;
                    //caseIntOut.Case_Integration_ID__c = caseInt1.Name;
                    caseIntOut.ServiceName__c = 'IGMSSyncAPI';
                    caseIntOut.Integration_Name__c  = 'IGMSSyncAPI';
                    caseIntOut.Request_Payload__c  =  JSON.serialize(new IGMSSyncRequest(transaction_no,source,
                                                                                             strClientId,
                                                                                             'Thane'));
                    peMap.put(index, caseIntOut);
                    indexToCaseId.put(index, caseRecord.Id);
                    index++;
                }
            }
        }

        index = 0;

        if(Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
            List<Database.SaveResult> results = Database.insert(newCaseIntegrations, false);
            Map<Id, ASF_Case_Integration__c> caseIntegrations = new Map<Id, ASF_Case_Integration__c>([SELECT Name, Case__c FROM ASF_Case_Integration__c WHERE Id IN :newCaseIntegrations ]);
            for(Database.SaveResult sr : results){
                if(sr.isSuccess()){
                    Case_Integration_Outbound__e caseIntOut = peMap.get(index);
                    caseIntOut.Case_Integration_ID__c = caseIntegrations.get(sr.getId()).Name;
                    peMap.put(index, caseIntOut);
                }else{
                    ASF_IntegrationsController.IntegrationWrapper wrap = new ASF_IntegrationsController.IntegrationWrapper();
                    wrap.status = ABHFL_Constants.ERROR;
                    resultMap.put(indexToCaseId.get(index), wrap);
                    peMap.remove(index);
                    indexToCaseId.remove(index);
                }
                index++;
            }
        }

        List<Database.SaveResult> publishResults = EventBus.publish(peMap.values());
        index = 0;
        for(Database.SaveResult publishResult : publishResults){
            if(publishResult.isSuccess()){
                ASF_IntegrationsController.IntegrationWrapper wrap = new ASF_IntegrationsController.IntegrationWrapper();
                wrap.status = ABHFL_Constants.SUCCESS;
                wrap.response = Custom_Messages__mdt.getInstance('REKYC_RUN_SUCCESS').Message__c;
                resultMap.put(indexToCaseId.values()[index], wrap);
            }else{
                ASF_IntegrationsController.IntegrationWrapper wrap = new ASF_IntegrationsController.IntegrationWrapper();
                wrap.status = ABHFL_Constants.ERROR;
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

					
                }
             }catch(Exception e){
                 
             }
    }


	public class IGMSSyncRequest{
        public string TRANS_NO{get;set;}
        public service service{get;set;}

        public IGMSSyncRequest(String caseNum,String src,
                                   String commonClientCd,
                                   String res)
        {
            this.TRANS_NO = caseNum;
            service cls = new service();
            cls.source = src;
            cls.strClientId = commonClientCd;
            cls.strResidence = res;

            this.service = cls;
        }

    }
	
    public class service{
        public string source{get;set;}
        public string strClientId{get;set;}
        public string strBusiness{get;set;}
        public string strResidence{get;set;}
    }
    public class IGMSSyncResponse{
        public string TRANS_NO{get;set;}
        public string ProcessMessage{get;set;}
        public string ProcessCode{get;set;}
    }

    
}