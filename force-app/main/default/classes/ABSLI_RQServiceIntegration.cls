/*********************************************************
*Class        :  ABSLI_RQServiceIntegration
*Author       :  Aditya Mehrotra
*Created Date :  07/17/2024
*Last Modified:  07/17/2024
*@description :  Class for RQ Service API for Reinstatement Journey
*********************************************************/
public class ABSLI_RQServiceIntegration implements ASF_IntegrationInvocable{
	
    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = ABSLI_Constants.ERROR;
        result.response = Custom_Messages__mdt.getInstance('ABSLI_RQServiceIntegration_FROMBTN').Message__c;
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
            result.response = Custom_Messages__mdt.getInstance('ABSLI_RQServiceIntegration_FROMBTN').Message__c;
            
            if(caseRecord.Technical_Source__c=='LWC' && caseRecord.AssetId!=null){
                result.status = ABSLI_Constants.SUCCESS;
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
                if(integ.Processing_Class__c == ABSLI_RQServiceIntegration.class.getName()){
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
                    if(integ.External_Id__c == caseInt.Integration_Ext_Id__c && caseInt.Status__c == ABSLI_Constants.PENDING){
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
                if(integ.Processing_Class__c == ABSLI_RQServiceIntegration.class.getName()){
                    
                    String source = System.label.ABSLI_ESB_SOURCE_VAL ;
                    String policyNumber = String.valueOf(caseRecord.Asset.Policy_No__c);
                    
                    ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
                    caseInt.Case__c  = caseRecord.Id;
                    caseInt.Integration_Ext_Id__c = integ.External_Id__c;
                    caseInt.Status__c = ABSLI_Constants.PENDING;
                    caseInt.Is_Validation_Success__c = true;
                    caseInt.Request__c  =  JSON.serialize(new RQServiceRequest(source,policyNumber));
                    caseInt.Response__c = ABSLI_Constants.WAITING_API_RESPONSE;
                    newCaseIntegrations.add(caseInt);
                    
                    Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
                    caseIntOut.Business_Unit__c  = caseRecord.Business_Unit__c;
                    //caseIntOut.Case_Integration_ID__c = caseInt1.Name;
                    caseIntOut.ServiceName__c = ABSLI_Constants.RQApiSrvName;
                    caseIntOut.Integration_Name__c  = ABSLI_Constants.RQApiSrvName;
                    caseIntOut.Request_Payload__c  =  JSON.serialize(new RQServiceRequest(source,policyNumber));
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
                    wrap.status = ABSLI_Constants.ERROR;
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
                wrap.status = ABSLI_Constants.SUCCESS;
                wrap.response = Custom_Messages__mdt.getInstance('REKYC_RUN_SUCCESS').Message__c;
                resultMap.put(indexToCaseId.values()[index], wrap);
            }else{
                ASF_IntegrationsController.IntegrationWrapper wrap = new ASF_IntegrationsController.IntegrationWrapper();
                wrap.status = ABSLI_Constants.ERROR;
                resultMap.put(indexToCaseId.values()[index], wrap);
            }
            index++;
        }
        
        return resultMap;
    }
    
    public void processResponse(ASF_Case_Integration__c caseInteg){
        Boolean integrationFailure = true;
        System.debug(caseInteg.Response__c);
        
        ASF_Case_Integration__c caseIntegration = new ASF_Case_Integration__c(Id = caseInteg.Id);
        caseIntegration.Is_Validation_Success__c = true;
        ASF_TriggerSkipperUtility.markTriggerRun('ASF_Case_Integration__c');
        update caseIntegration;
        ASF_TriggerSkipperUtility.resetTriggerRun('ASF_Case_Integration__c');
        
        if(caseInteg.Status__c==ABSLI_Constants.SUCCESS){
            rqServiceResponseWrapper response = (rqServiceResponseWrapper) JSON.deserialize(
                    caseInteg.Response__c,
                    rqServiceResponseWrapper.class
                );
            
            if(true){
                Case caseRec =[SELECT Id,ABSLI_Case_Detail__c 
                               FROM Case 
                               WHERE Id=:caseInteg.Case__c FOR UPDATE];
                ABSLI_Case_Detail__c caseExt = [SELECT Id, COI_Covid_Quest__c, Medicals__c, Reinstatement_Amount__c 
                                                FROM ABSLI_Case_Detail__c
                                                WHERE ID=:caseRec.ABSLI_Case_Detail__c FOR UPDATE];
                integrationFailure = false;
                String[] coiList = new List<String>();
                if(Schema.sObjectType.ABSLI_Case_Detail__c.isUpdateable())
                {
                    System.debug('response --> '+response);
                    String reinstatementAmtString = String.ValueOf(response.RqRes.Response.Details.NETAMOUNT);
                    decimal reinstetementAmt = 0;
                    //List<String> medicalsString = response.RqRes.Response.Details.MEDICALREQUIREMENTS.MEDICALDETAILS;
                    //String medicalsFieldValue = '';
                    coiList = response.RqRes.Response.Details.COIFORMS.FORM;
                    if(reinstatementAmtString != null){
                        reinstatementAmtString = reinstatementAmtString.replaceAll(',','');
                        reinstetementAmt = decimal.valueOf(reinstatementAmtString);
                        caseExt.Reinstatement_Amount__c = reinstetementAmt;
                    }
                    List<String> medicalsList = response.RqRes.Response.Details.MEDICALREQUIREMENTS.getMedicalsList();
                    
                    if (medicalsList.size() > 0) {
                        List<String> finalMedicalsVal = new List<String>();
                    
                        for (String str : medicalsList) {
                            if (!str.containsIgnoreCase(ABSLI_Constants.COVID_19_QUE_STRING)) {
                                finalMedicalsVal.add(str);
                            }
                        }
                    
                        String medicalsFieldValue = finalMedicalsVal.size() > 0
                            ? String.join(finalMedicalsVal, ',')
                            : String.join(medicalsList, ',');
                    
                        caseExt.Medicals__c = medicalsFieldValue;
                    }
                    if(coiList.size()>0){
                        String coiString = String.JOIN(coiList,',');
                        caseExt.COI_Covid_Quest__c =coiString;
                        if(coiString.countMatches('COVID_QUE') > 1){
                            caseRec.Notes__c = '3';
                            caseRec.Comments = 'More than one COVID_QUE in RQ Response.';
							Database.update(caseRec, AccessLevel.SYSTEM_MODE);
                        }
                    }
                    if(!Test.IsRunningTest()){
                    	update caseExt;    
                    }
                } 
            }
            else{	
               	//handleTransferFailure(caseRec);
           	} 
			
        }
    }
    
    public class RQServiceRequest{
        public RQDetails RqReq{get;set;}
        public RQServiceRequest(String source, String policy){
            this.RqReq = new RQDetails(source, policy);
        }
    }
    
    public class RQDetails{
        public innerDetails Details{get;set;}
        public RQDetails(String source, String policy){
            this.Details = new innerDetails(source, policy);
        }
    }
    
    public class innerDetails{
        public String source_ESB{get;set;}
        public String POLICYID{get;set;}
        public String MAILVIEW{get;set;}
        public String DESIGCODE{get;set;}
        public String SOURCE{get;set;}
        public String CHANNEL{get;set;}
        public String OUTPUTYPE{get;set;}
        public String RERQ{get;set;}
        
        public innerDetails(String source, String policy){
            this.source_ESB = source;
            this.POLICYID = policy;
            this.MAILVIEW = 'Y';
            this.DESIGCODE = 'Y';
            this.SOURCE = 'WS';
            this.CHANNEL = '1';
            this.OUTPUTYPE = '1';
            this.RERQ = 'Y';
        }
    }
    public class rqServiceResponseWrapper{
        public root RqRes; 
    }
    public class root{
        public secondNode Response;
    }
    public class secondNode{
        public detail Details;
    }
    public class detail{
        public String NETAMOUNT;
        public MedicalRequirements MEDICALREQUIREMENTS;
        public coiform COIFORMS;
    }
    public class MedicalRequirements {
        public List<String> MEDICALDETAILS_LIST; 
        public String MEDICALDETAILS_SINGLE; 

        public List<String> getMedicalsList() {
            List<String> medicalsList = new List<String>();
            if (MEDICALDETAILS_LIST != null) {
                medicalsList = MEDICALDETAILS_LIST;
            } else if (MEDICALDETAILS_SINGLE != null) {
                medicalsList.add(MEDICALDETAILS_SINGLE);
            }
            return medicalsList;
        }
    }
    public class coiform{
        public List<String> FORM;
    }
    
}