/*********************************************************
*Class        :  ABSLI_ModeChangeIntegration
*Author       :  Aditya Mehrotra
*Created Date :  06/05/2024
*Last Modified:  06/05/2024
*@description :  Class for Mode Updation
*********************************************************/
public class ABSLI_ModeChangeIntegration implements ASF_IntegrationInvocable{
	
    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = ABSLI_Constants.ERROR;
        result.response = Custom_Messages__mdt.getInstance('ABSLI_ModeChangeIntegration_FROMBTN').Message__c;
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
            result.response = Custom_Messages__mdt.getInstance('ABSLI_ModeChangeIntegration_FROMBTN').Message__c;
            
            if(caseRecord.ABSLI_Case_Detail__r.Status_Valid_For_STP__c == true && caseRecord.Technical_Source__c=='API'){
              	if(String.isBlank(caseRecord.Asset.Policy_No__c)){
                    result.response = Custom_Messages__mdt.getInstance('ABSLI_ModeChangeIntegration_ERR1').Message__c;
                }else if(caseRecord.ABSLI_Case_Detail__r.Anniversary_Date__c == null){
                    result.response = Custom_Messages__mdt.getInstance('ABSLI_ModeChangeIntegration_ERR2').Message__c;
                }else if(caseRecord.ABSLI_Case_Detail__r.New_Frequency__c == null || caseRecord.ABSLI_Case_Detail__r.New_Frequency__c == ''){
                    result.response = Custom_Messages__mdt.getInstance('ABSLI_ModeChangeIntegration_ERR3').Message__c;
                }else{
                    result.status = ABSLI_Constants.SUCCESS;
                }  
            }else if(caseRecord.Technical_Source__c=='LWC'){
                result.response = Custom_Messages__mdt.getInstance('ABSLI_MODECHANGE_ERR_BTN').Message__c;
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
                if(integ.Processing_Class__c == ABSLI_ModeChangeIntegration.class.getName()){
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
                if(integ.Processing_Class__c == ABSLI_ModeChangeIntegration.class.getName()){
                    
                    String transaction_no = String.valueOf(caseRecord.CaseNumber);
                    String source = System.label.ABSLI_ESB_SOURCE_VAL ;
                    String policyNumber = String.valueOf(caseRecord.Asset.Policy_No__c);
                    DateTime dateTimeToFormat = DateTime.newInstance(caseRecord.ABSLI_Case_Detail__r.Anniversary_Date__c, Time.newInstance(0, 0, 0, 0));
					String anniversaryDate = dateTimeToFormat.format('dd-MM-yyyy');
                    String newMode = String.valueOf(caseRecord.ABSLI_Case_Detail__r.New_Frequency__c);
                    
                    ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
                    caseInt.Case__c  = caseRecord.Id;
                    caseInt.Integration_Ext_Id__c = integ.External_Id__c;
                    caseInt.Status__c = ABSLI_Constants.PENDING;
                    caseInt.Request__c  =  JSON.serialize(new ModeChangeRequest(source,transaction_no,
                                                                                  policyNumber,anniversaryDate,
                                                                                  newMode));
                    caseInt.Response__c = ABSLI_Constants.WAITING_API_RESPONSE;
                    newCaseIntegrations.add(caseInt);
                    
                    Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
                    caseIntOut.Business_Unit__c  = caseRecord.Business_Unit__c;
                    //caseIntOut.Case_Integration_ID__c = caseInt1.Name;
                    caseIntOut.ServiceName__c = ABSLI_Constants.ModeChangeSrvName;
                    caseIntOut.Integration_Name__c  = ABSLI_Constants.ModeChangeSrvName;
                    caseIntOut.Request_Payload__c  =  JSON.serialize(new ModeChangeRequest(source,transaction_no,
                                                                                  policyNumber,anniversaryDate,
                                                                                  newMode));
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
        Case caseRec =[SELECT Id,MoveToNext__c,Technical_Source__c FROM Case WHERE Id=:caseInteg.Case__c ];
        if(caseInteg.Status__c==ABHFL_Constants.SUCCESS){
            Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(caseInteg.Response__c);
            if(String.valueOf(jsonMap.get('RESPONSE'))=='00'){
                integrationFailure = false;
                if(!Test.IsRunningTest() && Schema.sObjectType.Case.isUpdateable())
                {
                	caseRec.MoveToNext__c = true;    
                    update caseRec;
                }
            }
            else{	
               	//handleTransferFailure(caseRec);
           	}   
        }
    }
    
    public class ModeChangeRequest{
        public String SOURCE{get;set;}
        public String TRANS_NO{get;set;}
        public String POLICY_NO{get;set;}
        public String TRAN_TYPE{get;set;}
        public String ANNIVERSARY_DATE{get;set;}
        public String NEW_MODE{get;set;}
        public String REMARK1{get;set;}
        public String REMARK2{get;set;}
        public String REMARK3{get;set;}
        public String REMARK4{get;set;}
        public String REMARK5{get;set;}
        
        public ModeChangeRequest(String src,String caseNum,
                                   String policyNumber, String annDate, String newMode)
        {
            this.SOURCE = src;
            this.TRANS_NO = caseNum;
            this.POLICY_NO = policyNumber;
            this.TRAN_TYPE = 'MODE_CHANGE';
            this.ANNIVERSARY_DATE = annDate;
            this.NEW_MODE = newMode;
            this.REMARK1 = '';
            this.REMARK2 = '';
            this.REMARK3 = '';
            this.REMARK4 = '';
            this.REMARK5 = '';
        }
    }
    
}