/*********************************************************
*Class        :  ABSLI_PanUpdateIntegration
*Author       :  Aditya Mehrotra
*Created Date :  05/24/2024
*Last Modified:  05/24/2024
*@description :  Class for PAN Updation
*********************************************************/
public class ABSLI_PanUpdateIntegration implements ASF_IntegrationInvocable{
	
    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = ABSLI_Constants.ERROR;
        result.response = Custom_Messages__mdt.getInstance('ABSLI_PanUpdateIntegration_FROMBTN').Message__c;
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> returnMap = evaluate(new List<Case>{caseRec});
        return returnMap.get(caseRec.Id);
    }
    
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        List<Case> caseRecords = new List<Case>();
        Set<Id> caseIds = new Set<Id>();
        Map<Id,List<ASF_Checklist__c>> caseIdVsCheckListMap = new Map<Id,List<ASF_Checklist__c>>();
        for(Case caseRec : caseRecs){
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
            caseIds.add(caseRec.Id);
        }
        Map<Id,Boolean> caseSignatureMatchedMap = new Map<Id,Boolean>();
        for(ASF_Checklist__c checklist : [SELECT Id, Case__c, Status__c FROM ASF_Checklist__c WHERE Case__c IN:caseIds AND Mandatory__c=TRUE]){
            if(!caseIdVsCheckListMap.containsKey(checklist.Case__c)){
                caseIdVsCheckListMap.put(checklist.Case__c,new List<ASF_Checklist__c>());
            }
            if(checklist.Status__c == ABSLI_Constants.CHECKLIST_SIGNATURE_MATCHED){
                caseSignatureMatchedMap.put(checklist.Case__c,true);
            }
            caseIdVsCheckListMap.get(checklist.Case__c).add(checklist);
        }
        for(Case caseRecord : caseRecords){
            ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
            result.status = ABSLI_Constants.ERROR;
            result.response = Custom_Messages__mdt.getInstance('ABSLI_PanUpdateIntegration_ERR1').Message__c;

            if(ABSLI_Constants.SURRENDER_WITHDRAWAL_CASE_TYPES.contains(caseRecord.CCC_External_ID__c)){
                result.status = ABSLI_Constants.ERROR;
                String evaluationErrorMetadataName = ABSLI_Constants.ABSLI_PANUPDATE_NOT_REQUIRED_ERROR;
                result.response = Custom_Messages__mdt.getInstance(evaluationErrorMetadataName).Message__c;
            }
            
            //Customer Portal and Status_Valid_For_STP__c is false 
            if(ABSLI_Constants.STP_SOURCES.contains(caseRecord.Source__c) && caseRecord.ABSLI_Case_Detail__r.Status_Valid_For_STP__c == false){
            	result.status = ABSLI_Constants.ERROR;
            	result.response = Custom_Messages__mdt.getInstance('ABSLI_CustomerPortal_STPFalse_Err').Message__c;
            } else {
                
                if(caseRecord.ABSLI_Case_Detail__r.Status_Valid_For_STP__c == true && caseRecord.Technical_Source__c=='API'){
                	result.status = ABSLI_Constants.SUCCESS;
            	}
                
                if(!ABSLI_Constants.SURRENDER_WITHDRAWAL_CASE_TYPES.contains(caseRecord.CCC_External_ID__c)){
                    if(caseRecord.ABSLI_Case_Detail__r.Status_Valid_For_STP__c == true && caseRecord.Technical_Source__c=='LWC'){
                        if(!caseIdVsCheckListMap.isEmpty() && caseIdVsCheckListMap.get(caseRecord.Id)!=null 
                               && caseIdVsCheckListMap.get(caseRecord.Id).size()>0)
                        {
                            for(ASF_Checklist__c cList : caseIdVsCheckListMap.get(caseRecord.Id)){
                                if(!ABSLI_Constants.CHECKLIST_PASS_STATUS.split(',').contains(cList.Status__c)){
                                    result.response = Custom_Messages__mdt.getInstance('ABSLI_PanUpdateIntegration_ERR2').Message__c;
                                    break;
                                }else{
                                    result.status = ABSLI_Constants.SUCCESS;
                                }
                            }
                        }else{
                            result.status = ABSLI_Constants.SUCCESS;
                        }
                    }
                } else {
                    if(String.isNotBlank(caseRecord.ABSLI_Case_Detail__r.PAN_Number__c)){
                        if (caseRecord.ABSLI_Case_Detail__r.TDS_Indicator__c == 'Y' && String.isBlank(caseRecord.Account.PAN__c)) 
                        {
                            if(caseSignatureMatchedMap.containsKey(caseRecord.Id) && caseSignatureMatchedMap.get(caseRecord.Id)) {
                                if(caseRecord.ABSLI_Case_Detail__r.Status_Valid_For_STP__c){
                                    result.status = ABSLI_Constants.SUCCESS;
                                    result.response = ABSLI_Constants.EVALUATION_SUCCESS;
                                } else{
                                    result.status = ABSLI_Constants.ERROR;
                                    result.response = Custom_Messages__mdt.getInstance('ABSLI_PanUpdateIntegration_ERR1').Message__c;
                                }
                            } else {
                                String evaluationErrorMetadataName = ABSLI_Constants.ABSLI_SIGNATURE_NOT_MATCHING_ERROR;
                                result.status = ABSLI_Constants.ERROR;
                                result.response = Custom_Messages__mdt.getInstance(evaluationErrorMetadataName).Message__c;
                            }
                        }
                    }else{
                        result.status = ABSLI_Constants.ERROR;
                        result.response = Custom_Messages__mdt.getInstance('ABSLI_PanUpdateIntegration_ERR3').Message__c;
                    }
                }
                
            }
            resultMap.put(caseRecord.Id, result);
        }
        return resultMap;
    }
    
    public ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c integ, Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        Map<Id, List<ASF_Integration__c>> integMap = new Map<Id,List<ASF_Integration__c>>();
        integMap.put(caseRec.Id,new List<ASF_Integration__c>{integ});
        Map<Id,ASF_IntegrationsController.IntegrationWrapper> resultMap = run(integMap,new List<Case>{caseRec});
        return resultMap.get(caseRec.Id);
    }
    
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> run(Map<Id, List<ASF_Integration__c>> integs, List<Case> caseRecs){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        
        Set<String> intIds = new Set<String>();
        for(Case caseRec : caseRecs){
            for(ASF_Integration__c integ : integs.get(caseRec.Id)){
                if(integ.Processing_Class__c == ABSLI_PanUpdateIntegration.class.getName()){
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
        for(Case caseRec : caseRecs){
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
        }
        
        List<ASF_Case_Integration__c> newCaseIntegrations = new List<ASF_Case_Integration__c>();
        Map<Integer, Case_Integration_Outbound__e> peMap = new Map<Integer, Case_Integration_Outbound__e>();
        Integer index = 0;
        Map<Integer, Id> indexToCaseId = new Map<Integer, Id>();
        for(Case caseRecord : caseRecords){
            for(ASF_Integration__c integ : integs.get(caseRecord.Id)){
                if(integ.Processing_Class__c == ABSLI_PanUpdateIntegration.class.getName()){
                    
                    String transaction_no = String.valueOf(caseRecord.CaseNumber);
                    String source = System.label.ABSLI_ESB_SOURCE_VAL ;
                    String policyNumber = String.valueOf(caseRecord.Asset.Policy_No__c);
                    if(policyNumber == '' || policyNumber == null){
                        policyNumber = String.valueOf(caseRecord.LAN__c);
                    }
					String panNumber = String.valueOf(caseRecord.ABSLI_Case_Detail__r.PAN_Number__c);
                    
                    ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
                    caseInt.Case__c  = caseRecord.Id;
                    caseInt.Integration_Ext_Id__c = integ.External_Id__c;
                    caseInt.Status__c = ABSLI_Constants.PENDING;
                    caseInt.Request__c  =  JSON.serialize(new PanUpdateRequest(transaction_no,source,
                                                                                  policyNumber,
                                                                                  panNumber,
                                                                              caseRecord.Account.Client_Code__c));
                    caseInt.Response__c = ABSLI_Constants.WAITING_API_RESPONSE;
                    caseInt.Is_Validation_Success__c = true;
                    newCaseIntegrations.add(caseInt);
                    
                    Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
                    caseIntOut.Business_Unit__c  = caseRecord.Business_Unit__c;
                    //caseIntOut.Case_Integration_ID__c = caseInt1.Name;
                    caseIntOut.ServiceName__c = ABSLI_Constants.PanUpdateSrvName;
                    caseIntOut.Integration_Name__c  = ABSLI_Constants.PanUpdateSrvName;
                    caseIntOut.Request_Payload__c  =  JSON.serialize(new PanUpdateRequest(transaction_no,source,
                                                                                             policyNumber,
                                                                                             panNumber,
                                                                                         caseRecord.Account.Client_Code__c));
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
    
    public void processResponse(ASF_Case_Integration__c caseInteg){
        Boolean integrationFailure = true;
        Case caseRec =[SELECT Id,MoveToNext__c,ABSLI_Case_Detail__c,CCC_External_ID__c FROM Case WHERE Id=:caseInteg.Case__c ];
        if(caseInteg.Status__c==ABHFL_Constants.SUCCESS){
            Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(caseInteg.Response__c);
            if(String.valueOf(jsonMap.get('ProcessCode'))=='00'){
                integrationFailure = false;
                if(!ABSLI_Constants.SURRENDER_WITHDRAWAL_CASE_TYPES.contains(caseRec.CCC_External_ID__c)){
                    caseRec.MoveToNext__c = true;
                    if(!Test.IsRunningTest() && Schema.sObjectType.Case.isUpdateable())
                    {
                        update caseRec;            
                    }
                }else {
                    List<sObject> dmlRecords = new List<sObject>();
                    if(caseRec.ABSLI_Case_Detail__c != null){
                        ABSLI_Case_Detail__c caseExt = new ABSLI_Case_Detail__c(Id = caseRec.ABSLI_Case_Detail__c);
                        caseExt.Is_PAN_Update_Successful__c = true;
                        dmlRecords.add(caseExt);
                        Database.SaveResult[] results = Database.update(dmlRecords, true);
                    }
                }
            }
            else{	
               	//handleTransferFailure(caseRec);
           	}   
        }
    }
    
    public class PanUpdateRequest{
        public string TRANS_NO{get;set;}
        public updatePANDetails updatePANDetails{get;set;}
        
        public PanUpdateRequest(String caseNum,String src,
                                   String policyNumber, String panNumber,String clientId)
        {
            this.TRANS_NO = caseNum;
            updatePANDetails cls = new updatePANDetails();
            cls.source = src;
            cls.policyNumber = policyNumber;
            cls.panNumber = panNumber;            
            cls.panValidationStatus = 'Y';
            cls.clientId = clientId;
            this.updatePANDetails = cls;
        }
    }
    
    public class updatePANDetails{
        public string source{get;set;}
        public string policyNumber{get;set;}
        public string panNumber{get;set;}
        public string panValidationStatus{get;set;}
        public string clientId{get;set;}
    }
    
}