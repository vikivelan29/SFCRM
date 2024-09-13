/*********************************************************
*Class        :  ABSLI_SurvivalUpdateIntegration
*Author       :  Aditya Mehrotra
*Created Date :  06/19/2024
*Last Modified:  06/19/2024
*@description :  Class for Survival Update
*********************************************************/
public class ABSLI_SurvivalUpdateIntegration implements ASF_IntegrationInvocable{

    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = ABSLI_Constants.ERROR;
        result.response = Custom_Messages__mdt.getInstance('ABSLI_SurvivalUpdateIntegration_FROMBTN').Message__c;
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> returnMap = evaluate(new List<Case>{caseRec});
        return returnMap.get(caseRec.Id);
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
            result.response = Custom_Messages__mdt.getInstance('ABSLI_SurvivalUpdateIntegration_ERR1').Message__c;
            
            //Customer Portal and Status_Valid_For_STP__c is false 
            if(ABSLI_Constants.STP_SOURCES.contains(caseRecord.Source__c) && caseRecord.ABSLI_Case_Detail__r.Status_Valid_For_STP__c == false){
            	result.status = ABSLI_Constants.ERROR;
            	result.response = Custom_Messages__mdt.getInstance('ABSLI_CustomerPortal_STPFalse_Err').Message__c;
            }else{
            	if(caseRecord.ABSLI_Case_Detail__r.Status_Valid_For_STP__c == true && caseRecord.Technical_Source__c=='API'){
                    String policyNo = (caseRecord.AssetId != null ? caseRecord.Asset.Policy_No__c : ((caseRecord.LAN__c != null && caseRecord.LAN__c != 'NA') ? caseRecord.LAN__c:''));
                    if(String.isBlank(policyNo)){
                        result.response = Custom_Messages__mdt.getInstance('ABSLI_SurvivalUpdateIntegration_ERR2').Message__c;
                    }else{
                        result.status = ABSLI_Constants.SUCCESS;    
                    }
                }else if(caseRecord.Technical_Source__c=='LWC'){
                    result.status = ABSLI_Constants.SUCCESS;
                }    
            }
            
            resultMap.put(caseRecord.Id, result);
        }
        
        // CHECK IF THERE EXISTS ANY OPEN BANK UPDATE CASE AGAINST THE SAME CUSTOMER.
        if(caseRecords.size()>0){
            ABSLI_CTSTHelper.checkIfOpenBankUpdateCase(caseRecords,resultMap);
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
                if(integ.Processing_Class__c == ABSLI_SurvivalUpdateIntegration.class.getName()){
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
                if(integ.Processing_Class__c == ABSLI_SurvivalUpdateIntegration.class.getName()){
                    String source = System.label.ABSLI_ESB_SOURCE_VAL ;
                    String policyNumber = (caseRecord.AssetId != null ? caseRecord.Asset.Policy_No__c : ((caseRecord.LAN__c != null && caseRecord.LAN__c != 'NA') ? caseRecord.LAN__c:''));
                    
                    ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
                    caseInt.Case__c  = caseRecord.Id;
                    caseInt.Integration_Ext_Id__c = integ.External_Id__c;
                    caseInt.Status__c = ABSLI_Constants.PENDING;
                    caseInt.Request__c  =  JSON.serialize(new SurvivalUpdateRequest(policyNumber,source));
                    caseInt.Response__c = ABSLI_Constants.WAITING_API_RESPONSE;
                    newCaseIntegrations.add(caseInt);
                    
                    Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
                    caseIntOut.Business_Unit__c  = caseRecord.Business_Unit__c;
                    //caseIntOut.Case_Integration_ID__c = caseInt1.Name;
                    caseIntOut.ServiceName__c = ABSLI_Constants.SurvivalUpdateSrvName;
                    caseIntOut.Integration_Name__c  = ABSLI_Constants.SurvivalUpdateSrvName;
                    caseIntOut.Request_Payload__c  =  JSON.serialize(new SurvivalUpdateRequest(policyNumber,source));
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
        Case caseRec =[SELECT Id,MoveToNext__c,ABSLI_Case_Detail__r.Status_Valid_For_STP__c,Technical_Source__c 
                       FROM Case WHERE Id=:caseInteg.Case__c];
        if(caseInteg.Status__c==ABHFL_Constants.SUCCESS){
            SurvivalUpdateResponse responseWrapper = (SurvivalUpdateResponse)JSON.deserialize(caseInteg.Response__c,SurvivalUpdateResponse.class);
            if(String.valueOf(responseWrapper.getSurvivalCertificate_UpdateSC_Flag[0].Error_Code)=='00'){
                integrationFailure = false;
                if(caseRec.ABSLI_Case_Detail__r.Status_Valid_For_STP__c == true && caseRec.Technical_Source__c=='API' 
                  && !Test.IsRunningTest() && Schema.sObjectType.Case.isUpdateable())
                {
					caseRec.MoveToNext__c = true;
                   	update caseRec;
                }
            }
        }
    }
    
    public class SurvivalUpdateRequest{
        public String PolicyId{get;set;}
        public String SC_Flag{get;set;}
        public String source{get;set;}
        
        public SurvivalUpdateRequest(String policyNo, String source){
            this.PolicyId = policyNo;
            this.SC_Flag = 'Y';
            this.source = source;
        }
    }
    
    public class SurvivalUpdateResponse{
        public List<responseList> getSurvivalCertificate_UpdateSC_Flag{get;set;}
    }
    
    public class responseList{
        public String Output_Message{get;set;}
        public String Error_Code{get;set;}
    }
    
}