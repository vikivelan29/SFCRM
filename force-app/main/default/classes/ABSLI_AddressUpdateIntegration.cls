/*********************************************************
*Class        :  ABSLI_AddressUpdateIntegration
*Author       :  Aditya Mehrotra
*Created Date :  06/05/2024
*Last Modified:  06/05/2024
*@description :  Class for Address Updation
*********************************************************/
public class ABSLI_AddressUpdateIntegration implements ASF_IntegrationInvocable{
    
    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = ABSLI_Constants.ERROR;
        result.response = Custom_Messages__mdt.getInstance('ABSLI_AddressUpdateIntegration_FROMBTN').Message__c;
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
            result.response = Custom_Messages__mdt.getInstance('ABSLI_AddressUpdateIntegration_ERR1').Message__c;
			
            //Customer Portal and Status_Valid_For_STP__c is false 
            if(ABSLI_Constants.STP_SOURCES.contains(caseRecord.Source__c) && caseRecord.ABSLI_Case_Detail__r.Status_Valid_For_STP__c == false){
            	result.status = ABSLI_Constants.ERROR;
            	result.response = Custom_Messages__mdt.getInstance('ABSLI_CustomerPortal_STPFalse_Err').Message__c;
            }else{
				if(caseRecord.ABSLI_Case_Detail__r.Status_Valid_For_STP__c == true && caseRecord.Technical_Source__c=='API' 
                  && (!String.isBlank(caseRecord.AccountId) || !String.isBlank(caseRecord.Client_Code_Text__c)))
                {
                    result.status = ABSLI_Constants.SUCCESS;
                }
                else if(caseRecord.Technical_Source__c=='LWC' && 
                         (!String.isBlank(caseRecord.AccountId) || !String.isBlank(caseRecord.Client_Code_Text__c)))
                {
                    result.status = ABSLI_Constants.SUCCESS;
                    system.debug('caseRecord.ABSLI_Case_Detail__r.Country__c:'+caseRecord.ABSLI_Case_Detail__r.Country__c);
                    if(caseRecord.ABSLI_Case_Detail__r.Country__c !='IN'){
                        result.status = ABSLI_Constants.ERROR;
                        result.response = Custom_Messages__mdt.getInstance('ABSLI_AddressUpdateIntegration_ERR4').Message__c;
                    }else{
                        for(ASF_Checklist__c checkList : [SELECT Id, Case__c, Status__c FROM ASF_Checklist__c WHERE Case__c =:caseRecord.Id AND Mandatory__c=TRUE]){
                            if(!ABSLI_Constants.CHECKLIST_PASS_STATUS.split(',').contains(checkList.Status__c)){
                                result.status = ABSLI_Constants.ERROR;
                                result.response = 'Checklist/s not passed.';
                                break;
                            }
                        }
                    }
                }
                else if(String.isBlank(caseRecord.AccountId) && String.isBlank(caseRecord.Client_Code_Text__c))
                {
                    result.response =  Custom_Messages__mdt.getInstance('ABSLI_AddressUpdateIntegration_ERR2').Message__c;        
                }
                else if(String.isBlank(caseRecord.ABSLI_Case_Detail__r.Address_Line_1__c) || String.isBlank(caseRecord.ABSLI_Case_Detail__r.Country__c)
                        || String.isBlank(caseRecord.ABSLI_Case_Detail__r.City__c) || String.isBlank(caseRecord.ABSLI_Case_Detail__r.State__c)
                         || String.isBlank(caseRecord.ABSLI_Case_Detail__r.Pincode__c))
                {
                    result.response =  Custom_Messages__mdt.getInstance('ABSLI_AddressUpdateIntegration_ERR3').Message__c;      
                }                
            }
            
            resultMap.put(caseRecord.Id, result);
        }
        system.debug('Aditya resultMap:'+resultMap);
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
                if(integ.Processing_Class__c == ABSLI_AddressUpdateIntegration.class.getName()){
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
                if(integ.Processing_Class__c == ABSLI_AddressUpdateIntegration.class.getName()){
                    String transaction_no = String.valueOf(caseRecord.CaseNumber);
                    String source = System.label.ABSLI_ESB_SOURCE_VAL;
                    String clientId = String.isBlank(String.valueOf(caseRecord.Account.Client_Code__c))==true ? String.valueOf(caseRecord.Client_Code_Text__c) : String.valueOf(caseRecord.Account.Client_Code__c);
                    String addressLine1 = String.valueOf(caseRecord.ABSLI_Case_Detail__r.Address_Line_1__c);
                    String addressLine2 = String.valueOf(caseRecord.ABSLI_Case_Detail__r.Address_Line_2__c);
                    String addressLine3 = String.valueOf(caseRecord.ABSLI_Case_Detail__r.Address_Line_3__c);
                    String area = String.valueOf(caseRecord.ABSLI_Case_Detail__r.Country__c);
                    String city = String.valueOf(caseRecord.ABSLI_Case_Detail__r.City__c);
                    String state = String.valueOf(caseRecord.ABSLI_Case_Detail__r.State__c);
                    String postalCode = String.valueOf(caseRecord.ABSLI_Case_Detail__r.Pincode__c);
                    
                    ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
                    caseInt.Case__c  = caseRecord.Id;
                    caseInt.Integration_Ext_Id__c = integ.External_Id__c;
                    caseInt.Status__c = ABSLI_Constants.PENDING;
                    caseInt.Request__c  =  JSON.serialize(new AddressUpdateRequest(transaction_no,source,clientId,
                                                                                  addressLine1,addressLine2,addressLine3,
                                                                                  area,city,state,postalCode));
                    caseInt.Response__c = ABSLI_Constants.WAITING_API_RESPONSE;
                    caseInt.Do_Not_Retry_Integration__c = integ.Do_Not_Retry_Integration__c;
                    newCaseIntegrations.add(caseInt);
                    
                    Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
                    caseIntOut.Business_Unit__c  = caseRecord.Business_Unit__c;
                    //caseIntOut.Case_Integration_ID__c = caseInt1.Name;
                    caseIntOut.ServiceName__c = ABSLI_Constants.AddressUpdateSrvName;
                    caseIntOut.Integration_Name__c  = ABSLI_Constants.AddressUpdateSrvName;
                    caseIntOut.Request_Payload__c  =  JSON.serialize(new AddressUpdateRequest(transaction_no,source,clientId,
                                                                                  addressLine1,addressLine2,addressLine3,
                                                                                  area,city,state,postalCode));
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
            Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(caseInteg.Response__c);
            if(String.valueOf(jsonMap.get('ProcessCode'))=='00'){
                integrationFailure = false;
                if(Schema.sObjectType.Case.isUpdateable() && !Test.isRunningTest())
                {
					caseRec.MoveToNext__c = true;
                   	update caseRec;
                } 
            }
        }
    }
    
    public class AddressUpdateRequest{
        public string TRANS_NO{get;set;}
        public service service{get;set;}
        
        public AddressUpdateRequest(String transaction_no, String source, String clientId, String addressLine1,
                                    String addressLine2, String addressLine3, String area, String city, String state, String postalCode)
        {
            this.TRANS_NO = transaction_no;
            service cls = new service();
            cls.source = source;
            cls.clientId = clientId;
            cls.sequenceNumber = '';
            cls.addressLine1 = addressLine1;
            cls.addressLine2 = addressLine2;
            cls.addressLine3 = addressLine3;
            cls.municipalityCode = '';
            cls.addressStatus = '';
            cls.yearsAtAddress = '';
            cls.city = city;
            cls.state = state;
            cls.country = area;
            cls.postalCode = postalCode;
            cls.aptUnit = '';
            cls.residenceType = '';
            cls.area = area;
            cls.japaneseAddressCode = '';
            cls.addressLine1_2 = '';
            cls.addressLine2_2 = '';
            cls.addressLine3_2 = '';
            cls.aptUnit_2 = '';
            cls.city_2 = '';
            cls.postalCode_2 = '';
            cls.addressStatus_2 = '';
            cls.japaneseAddressCode_2 = '';
            cls.addressEffectiveDate = '';
            cls.endDate = '';
            this.service = cls;
        }
    }
    
    public class service{
        public string source{get;set;}
        public string clientId{get;set;}
        public string sequenceNumber{get;set;}
        public string addressLine1{get;set;}
        public string addressLine2{get;set;}
        public string addressLine3{get;set;}
        public string municipalityCode{get;set;}
        public string addressStatus{get;set;}
        public string yearsAtAddress{get;set;}
        public string city{get;set;}
        public string state{get;set;}
        public string country{get;set;}
        public string postalCode{get;set;}
        public string aptUnit{get;set;}
        public string residenceType{get;set;}
        public string area{get;set;}
        public string japaneseAddressCode{get;set;}
        public string addressLine1_2{get;set;}
        public string addressLine2_2{get;set;}
        public string addressLine3_2{get;set;}
        public string aptUnit_2{get;set;}
        public string city_2{get;set;}
        public string postalCode_2{get;set;}
        public string addressStatus_2{get;set;}
        public string japaneseAddressCode_2{get;set;}
        public string addressEffectiveDate{get;set;}
        public string endDate{get;set;}
    }

}